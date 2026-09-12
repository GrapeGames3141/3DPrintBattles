param(
    [ValidateSet('state', 'startup', 'core', 'bot', 'pacing', 'coordinator', 'all')][string]$Suite = 'core',
    [ValidateRange(1, 60)][int]$TimeoutSeconds = 30
)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$engine = 'E:\CodexCache\godot-android-4.7.1\godot\Godot_v4.7.1-stable_win64.exe'
if (-not $projectRoot.StartsWith('E:\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Tests require the durable E: project.'
}
if (-not (Test-Path -LiteralPath $engine)) { throw "Missing engine: $engine" }

function Write-Ledger([string]$Path, $Value) {
    ConvertTo-Json -InputObject $Value -Depth 12 | Set-Content -LiteralPath $Path -Encoding utf8
}

function Quote-CrtArgument([string]$Value) {
    if ($Value.Contains('"') -or $Value.EndsWith('\')) { throw 'Unsafe test argument.' }
    return '"' + $Value + '"'
}

function Get-ProcessIdentity([int]$TaskProcessId) {
    $current = Get-CimInstance Win32_Process -Filter "ProcessId=$TaskProcessId" -ErrorAction Stop
    if ($null -eq $current) { return $null }
    return [pscustomobject]@{
        pid = [int]$current.ProcessId
        parent = [int]$current.ParentProcessId
        executable = $current.ExecutablePath
        command = $current.CommandLine
        creation = $current.CreationDate
    }
}

function Test-SameIdentity($First, $Second) {
    return $null -ne $Second -and $First.pid -eq $Second.pid -and
        $First.creation -eq $Second.creation -and
        $First.executable -eq $Second.executable -and $First.command -eq $Second.command
}

function Observe-Descendants([int]$RootId, [hashtable]$Records) {
    $pending = [Collections.Generic.Queue[int]]::new()
    $seen = @{}
    $pending.Enqueue($RootId)
    while ($pending.Count -gt 0) {
        $parentId = $pending.Dequeue()
        if ($seen.ContainsKey($parentId)) { continue }
        $seen[$parentId] = $true
        $parentNow = Get-ProcessIdentity $parentId
        if ($null -ne $parentNow -and -not (Test-SameIdentity $Records[$parentId] $parentNow)) {
            continue # Reused PIDs do not make new children task-owned.
        }
        foreach ($child in @(Get-CimInstance Win32_Process -Filter "ParentProcessId=$parentId" -ErrorAction Stop)) {
            $childRecord = Get-ProcessIdentity ([int]$child.ProcessId)
            if ($null -eq $childRecord) { continue }
            if (-not $Records.ContainsKey($childRecord.pid)) { $Records[$childRecord.pid] = $childRecord }
            if (Test-SameIdentity $Records[$childRecord.pid] $childRecord) {
                $pending.Enqueue($childRecord.pid)
            }
        }
    }
}

function Get-SaveManifest([string]$Root) {
    $entries = @(Get-ChildItem -LiteralPath $Root -File -Recurse | Sort-Object FullName | ForEach-Object {
        [ordered]@{
            path = $_.FullName.Substring($Root.Length).TrimStart('\', '/')
            size = $_.Length
            sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        }
    })
    return (ConvertTo-Json -InputObject $entries -Depth 4 -Compress)
}

function Invoke-TeamTest([string]$Scene, [string]$Marker, [string]$Fixture = '', [string]$Compatibility = '') {
    # Denied process inspection must fail before an engine starts.
    if ($null -eq (Get-ProcessIdentity $PID)) { throw 'Process inspection unavailable.' }
    $name = [IO.Path]::GetFileNameWithoutExtension($Scene)
    $token = (Get-Date -Format 'yyyyMMdd-HHmmss') + '-' + [guid]::NewGuid().ToString('N')
    $base = [IO.Path]::GetFullPath((Join-Path $projectRoot 'build\evidence')) + '\'
    $runRoot = [IO.Path]::GetFullPath((Join-Path $base "team-battle\$token"))
    if ((Test-Path -LiteralPath $runRoot) -or -not $runRoot.StartsWith($base, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Evidence path is not a fresh contained directory.'
    }
    $qaRoot = Join-Path $runRoot 'qa-save'
    $engineLog = Join-Path $runRoot 'engine.log'
    $stdoutLog = Join-Path $runRoot 'stdout.log'
    $stderrLog = Join-Path $runRoot 'stderr.log'
    $savedEnvironment = @{}
    foreach ($key in @('APPDATA', 'LOCALAPPDATA', 'TEMP', 'TMP')) {
        $savedEnvironment[$key] = [Environment]::GetEnvironmentVariable($key, 'Process')
    }
    $records = @{}
    $process = $null
    $failure = ''
    $exitCode = $null
    $stopped = @()
    $windows = @()
    $survivors = @()
    $saveBefore = ''
    $saveAfter = ''
    $started = Get-Date
    $arguments = @('--headless', '--path', $projectRoot, '--log-file', $engineLog,
        $Scene, '--', "--qa-save-root=$qaRoot", '--team-prototype')
    $argumentString = ($arguments | ForEach-Object { Quote-CrtArgument $_ }) -join ' '
    try {
        New-Item -ItemType Directory -Path $qaRoot -ErrorAction Stop | Out-Null
        if ($Fixture) {
            $fixtureBase = Join-Path $projectRoot 'tests\team_battle\startup_fixtures'
            foreach ($source in @((Join-Path $fixtureBase 'common'), (Join-Path $fixtureBase $Fixture))) {
                if (-not (Test-Path -LiteralPath $source -PathType Container)) { throw "Missing synthetic fixture: $source" }
                foreach ($file in @(Get-ChildItem -LiteralPath $source -File)) {
                    $destination = Join-Path $qaRoot $file.Name
                    if (Test-Path -LiteralPath $destination) { throw 'Fixture files must not overwrite each other.' }
                    Copy-Item -LiteralPath $file.FullName -Destination $destination -ErrorAction Stop
                }
            }
        }
        $saveBefore = Get-SaveManifest $qaRoot
        Write-Ledger (Join-Path $runRoot 'save-before.json') @(ConvertFrom-Json $saveBefore)
        foreach ($key in @('APPDATA', 'LOCALAPPDATA', 'TEMP', 'TMP')) {
            $directory = Join-Path $runRoot ('isolated-' + $key.ToLowerInvariant())
            New-Item -ItemType Directory -Path $directory -ErrorAction Stop | Out-Null
            [Environment]::SetEnvironmentVariable($key, $directory, 'Process')
        }
        $process = Start-Process -FilePath $engine -ArgumentList $argumentString -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutLog -RedirectStandardError $stderrLog
        $startRecord = [ordered]@{
            root_pid = $process.Id
            engine = $engine
            arguments = $arguments
            argument_string = $argumentString
            started = $started.ToString('o')
            console_note = 'Direct hidden engine; no console wrapper'
            qa_root = $qaRoot
            logs = @($engineLog, $stdoutLog, $stderrLog)
        }
        Write-Ledger (Join-Path $runRoot 'started.json') $startRecord
        # Retain the actual Process handle as a fallback if CIM fails after launch.
        [void]$process.Handle
        $records[$process.Id] = [pscustomobject]@{
            pid = $process.Id
            parent = $PID
            executable = $engine
            command = (Quote-CrtArgument $engine) + ' ' + $argumentString
            creation = $process.StartTime
        }
        $identity = Get-ProcessIdentity $process.Id
        if ($null -ne $identity) { $records[$process.Id] = $identity }
        $startRecord['identity'] = $records[$process.Id]
        $startRecord['window_handle'] = $process.MainWindowHandle.ToInt64()
        $startRecord['window_title'] = $process.MainWindowTitle
        Write-Ledger (Join-Path $runRoot 'started.json') $startRecord
        $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
        while (-not $process.HasExited -and [DateTime]::UtcNow -lt $deadline) {
            Observe-Descendants $process.Id $records
            Write-Ledger (Join-Path $runRoot 'observed-processes.json') @($records.Values)
            Start-Sleep -Milliseconds 200
            $process.Refresh()
        }
        if (-not $process.HasExited) { throw "Engine timeout after $TimeoutSeconds seconds." }
        $process.WaitForExit()
        $process.Refresh()
        $exitCode = $process.ExitCode
        if ($null -eq $exitCode -or $exitCode -ne 0) { throw "Engine exit was not zero: $exitCode" }
        foreach ($path in @($engineLog, $stdoutLog, $stderrLog)) {
            if (-not (Test-Path -LiteralPath $path)) { throw "Missing required log: $path" }
        }
        $combined = (@($engineLog, $stdoutLog, $stderrLog) | ForEach-Object { Get-Content -Raw -LiteralPath $_ }) -join [Environment]::NewLine
        if ($combined -match 'SCRIPT ERROR|Parse Error|ERROR:|Failed to load script') { throw 'Engine emitted a script/runtime error.' }
        if ($combined -notmatch ('(?m)^' + [regex]::Escape($Marker) + '\r?$')) { throw 'Exact test success marker missing.' }
        $startupMarker = 'PRINTFORGE_STARTUP marker=team_prototype_read_only compatibility='
        if ($Compatibility) { $startupMarker += $Compatibility }
        if ($combined -notmatch [regex]::Escape($startupMarker)) { throw 'Expected prototype startup guard marker missing.' }
    } catch {
        $failure = $_.Exception.Message
    } finally {
        try {
            if ($null -ne $process -and $records.Count -gt 0) {
                Observe-Descendants $process.Id $records
            }
            foreach ($record in @($records.Values | Sort-Object creation -Descending)) {
                if (-not (Test-SameIdentity $record (Get-ProcessIdentity $record.pid))) { continue }
                $live = Get-Process -Id $record.pid -ErrorAction Stop
                $windows += [pscustomobject]@{
                    pid = $record.pid
                    handle = $live.MainWindowHandle.ToInt64()
                    title = $live.MainWindowTitle
                }
                Stop-Process -Id $record.pid -Force -ErrorAction Stop
                $stopped += $record.pid
                [void]$live.WaitForExit(2000)
                $live.Dispose()
            }
            foreach ($record in @($records.Values)) {
                if (Test-SameIdentity $record (Get-ProcessIdentity $record.pid)) { $survivors += $record }
            }
            if ($survivors.Count -gt 0) { throw 'Recorded task process survived cleanup.' }
        } catch {
            $failure += ' Cleanup inspection failed: ' + $_.Exception.Message
        } finally {
            try {
                # This handle was created here. Never use a name-wide process kill.
                if ($null -ne $process -and -not $process.HasExited) {
                    $process.Kill()
                    $stopped += $process.Id
                    if (-not $process.WaitForExit(2000)) { $failure += ' Root process did not exit.' }
                }
                if (Test-Path -LiteralPath $runRoot) {
                    if ($saveBefore -and (Test-Path -LiteralPath $qaRoot)) {
                        $saveAfter = Get-SaveManifest $qaRoot
                        Write-Ledger (Join-Path $runRoot 'save-after.json') @(ConvertFrom-Json $saveAfter)
                        if ($saveAfter -cne $saveBefore) { $failure += ' Isolated startup save bytes or file set changed.' }
                    }
                    Write-Ledger (Join-Path $runRoot 'process-ledger.json') ([ordered]@{
                        scene = $Scene
                        root_pid = if ($process) { $process.Id } else { $null }
                        engine = $engine
                        arguments = $arguments
                        records = @($records.Values)
                        started = $started.ToString('o')
                        finished = (Get-Date).ToString('o')
                        exit_code = $exitCode
                        final_exit_code = if ($process -and $process.HasExited) { $process.ExitCode } else { $null }
                        stopped = $stopped
                        windows_before_cleanup = $windows
                        survivors = $survivors
                        failure = $failure
                        logs = @($engineLog, $stdoutLog, $stderrLog)
                        qa_root = $qaRoot
                        fixture = $Fixture
                        save_bytes_unchanged = $saveBefore -ne '' -and $saveBefore -ceq $saveAfter
                    })
                }
            } finally {
                foreach ($key in $savedEnvironment.Keys) {
                    [Environment]::SetEnvironmentVariable($key, $savedEnvironment[$key], 'Process')
                }
                if ($null -ne $process) { $process.Dispose() }
            }
        }
    }
    Write-Output "Evidence: $runRoot"
    if ($failure) { throw $failure }
    Write-Output "PASS: $name (engine exit $exitCode, no task process survivors)"
}

if ($Suite -in @('state', 'all')) {
    Invoke-TeamTest 'res://tests/team_battle/test_team_battle_state.tscn' 'TEAM_BATTLE_STATE failures=0'
}
if ($Suite -in @('startup', 'all')) {
    foreach ($case in @(
        @{ fixture = 'invalid-deck'; compatibility = 'ready' },
        @{ fixture = 'future-schema'; compatibility = 'future_schema' },
        @{ fixture = 'backup-recovered'; compatibility = 'backup_recovered' },
        @{ fixture = 'corrupt-backup'; compatibility = 'corrupt_backup' }
    )) {
        Invoke-TeamTest 'res://tests/team_battle/test_team_battle_state.tscn' 'TEAM_BATTLE_STATE failures=0' $case.fixture $case.compatibility
    }
}
if ($Suite -in @('core', 'all')) {
    Invoke-TeamTest 'res://tests/team_battle/test_team_battle_core.tscn' 'TEAM_BATTLE_CORE failures=0'
}
if ($Suite -in @('bot', 'all')) {
    Invoke-TeamTest 'res://tests/team_battle/test_team_battle_bot.tscn' 'TEAM_BATTLE_BOT failures=0'
}
if ($Suite -in @('pacing', 'all')) {
    Invoke-TeamTest 'res://tests/team_battle/test_team_battle_pacing.tscn' 'TEAM_BATTLE_PACING failures=0'
}
if ($Suite -in @('coordinator', 'all')) {
    Invoke-TeamTest 'res://tests/team_battle/test_team_battle_coordinator.tscn' 'TEAM_BATTLE_COORDINATOR failures=0'
}
