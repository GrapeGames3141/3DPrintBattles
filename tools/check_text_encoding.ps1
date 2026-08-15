param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot)
)

$utf8 = [System.Text.UTF8Encoding]::new($false, $true)
$extensions = @('.gd', '.md', '.ts')
$failures = [System.Collections.Generic.List[string]]::new()

Get-ChildItem -LiteralPath $ProjectRoot -Recurse -File |
    Where-Object { $_.Extension -in $extensions } |
    ForEach-Object {
        try {
            $text = $utf8.GetString([System.IO.File]::ReadAllBytes($_.FullName))
            if ($text.Contains([string][char]0xFFFD)) {
                $failures.Add("replacement character: $($_.FullName)")
            }
            if ($text.Contains([string][char]0x00E2)) {
                $failures.Add("possible mojibake lead byte: $($_.FullName)")
            }
        } catch {
            $failures.Add("invalid UTF-8: $($_.FullName): $($_.Exception.Message)")
        }
    }

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    exit 1
}

Write-Host "PASS: UTF-8 and mojibake audit"
