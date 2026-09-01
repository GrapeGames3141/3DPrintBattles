[CmdletBinding()]
param(
    [switch]$ValidateOnly,
    [switch]$ValidationSelfTest
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Add-Type -AssemblyName System.Drawing

$RepoRoot = Split-Path -Parent $PSScriptRoot
$FamilyRelative = 'docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/family-v2'
$FamilyDir = Join-Path $RepoRoot ($FamilyRelative -replace '/', '\')
$RuntimeDir = Join-Path $RepoRoot 'assets\creatures\2d\blueprints\v2'
$RuntimeManifestPath = Join-Path $RuntimeDir 'manifest-v2.json'
$InventoryPath = Join-Path $RepoRoot 'docs\checkpoints\evidence\m7-legacy-blueprint-package-inventory.json'
$FamilyFiles = [ordered]@{
    manifest = [ordered]@{ path = (Join-Path $FamilyDir 'family-manifest-v2.json'); sha256 = '9C70CF826C08D8C12348A74B44B505BA7A3850FC927B455685C7B18EFEE7F893' }
    contact_sheet = [ordered]@{ path = (Join-Path $FamilyDir 'family-contact-sheet-v2.png'); sha256 = '5DE9CB3C5D50F301ADD74B10E5140B415286144C3BA1E03A34EF9C51162273A8' }
    thumbnails = [ordered]@{ path = (Join-Path $FamilyDir 'family-thumbnails-160-v2.png'); sha256 = 'BFDCAF22D6D52D990F999CD58C134541AA066A3E2A65AD656CFF3E690EC43066' }
}
$CatalogOrder = @('cinderpaw','aquafin','voltwig','mossmunk','frostling','stoneback','galehopper','sparkotter','glassdrake','coralisk','runestag','brambleowl','ironmaw','aurorawing','thunderelk','coalgriffin','tidewhale','skyforge','pyraxis','verdantitan','miragefox','voidmanta','worldcoil','starloom')
$LegacyRootRelative = 'assets/creatures/2d/blueprints'
$ExpectedLegacyRelativePaths = @(
    foreach ($id in $CatalogOrder) {
        "$LegacyRootRelative/${id}_blueprint_card_v1.png"
        "$LegacyRootRelative/${id}_blueprint_card_v1.png.import"
    }
    "$LegacyRootRelative/unknown_blueprint_card_v1.png"
    "$LegacyRootRelative/unknown_blueprint_card_v1.png.import"
    "$LegacyRootRelative/provenance-v1.json"
) | Sort-Object
$PilotLinks = @{
    cinderpaw = @('docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/README.md','docs/checkpoints/evidence/m7-blueprint-grammar-human-approval.md','docs/checkpoints/evidence/m7-blueprint-family-human-approval.md')
    aurorawing = @('docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/README.md','docs/checkpoints/evidence/m7-blueprint-grammar-human-approval.md','docs/checkpoints/evidence/m7-blueprint-family-human-approval.md')
    worldcoil = @('docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/README.md','docs/checkpoints/evidence/m7-blueprint-grammar-human-approval.md','docs/checkpoints/evidence/m7-blueprint-family-human-approval.md')
}

function Get-RepositoryRelativePath([string]$Path) {
    $rootUri = [Uri]::new(($RepoRoot.TrimEnd('\') + '\'))
    return [Uri]::UnescapeDataString($rootUri.MakeRelativeUri([Uri]::new($Path)).ToString()).Replace('\','/')
}
function Get-Sha256([string]$Path) { (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant() }
function Get-PngAlphaAudit([string]$Path) {
    $bitmap = [System.Drawing.Bitmap]::new($Path)
    try {
        $right = $bitmap.Width - 1
        $bottom = $bitmap.Height - 1
        return [ordered]@{
            width = $bitmap.Width
            height = $bitmap.Height
            alpha_corners = [ordered]@{
                top_left = [int]$bitmap.GetPixel(0, 0).A
                top_right = [int]$bitmap.GetPixel($right, 0).A
                bottom_left = [int]$bitmap.GetPixel(0, $bottom).A
                bottom_right = [int]$bitmap.GetPixel($right, $bottom).A
            }
        }
    } finally { $bitmap.Dispose() }
}
function Assert-Exact([object]$Actual, [object]$Expected, [string]$Message) { if ([string]$Actual -cne [string]$Expected) { throw "$Message (actual=$Actual expected=$Expected)" } }
function Assert-ExactArray([object[]]$Actual, [object[]]$Expected, [string]$Message) {
    if ($Actual.Count -ne $Expected.Count) { throw "$Message count mismatch" }
    for ($index = 0; $index -lt $Expected.Count; $index++) { Assert-Exact $Actual[$index] $Expected[$index] "$Message at $index" }
}
function Get-FamilyManifest {
    foreach ($record in $FamilyFiles.Values) {
        if (-not (Test-Path -LiteralPath $record.path -PathType Leaf)) { throw "Missing approved family artifact: $($record.path)" }
        Assert-Exact (Get-Sha256 $record.path) $record.sha256 "Approved family hash mismatch: $($record.path)"
    }
    $manifest = Get-Content -Raw -LiteralPath $FamilyFiles.manifest.path | ConvertFrom-Json
    Assert-Exact $manifest.schema 'printforge.creature-blueprints-family.v2' 'Family manifest schema mismatch'
    Assert-Exact $manifest.version 2 'Family manifest version mismatch'
    Assert-ExactArray @($manifest.catalog_order) $CatalogOrder 'Approved catalog order mismatch'
    if ($manifest.entries.Count -ne 24 -or @($manifest.entries.id | Select-Object -Unique).Count -ne 24) { throw 'Approved family manifest membership mismatch.' }
    return $manifest
}
function Get-ValidatedEntries {
    $family = Get-FamilyManifest
    $entries = @()
    for ($index = 0; $index -lt $CatalogOrder.Count; $index++) {
        $entry = $family.entries[$index]
        $id = $CatalogOrder[$index]
        Assert-Exact $entry.id $id 'Approved family entry ID mismatch'
        $sourcePath = Join-Path $RepoRoot ([string]$entry.source -replace '/', '\')
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) { throw "Missing selected source: $($entry.source)" }
        Assert-Exact (Get-Item -LiteralPath $sourcePath).Length $entry.bytes "Selected source byte mismatch: $id"
        Assert-Exact (Get-Sha256 $sourcePath) $entry.sha256 "Selected source hash mismatch: $id"
        $audit = Get-PngAlphaAudit $sourcePath
        Assert-Exact $audit.width $entry.dimensions[0] "Selected source width mismatch: $id"
        Assert-Exact $audit.height $entry.dimensions[1] "Selected source height mismatch: $id"
        Assert-Exact $audit.width 1254 "Selected source required width mismatch: $id"
        Assert-Exact $audit.height 1254 "Selected source required height mismatch: $id"
        foreach ($corner in @('top_left','top_right','bottom_left','bottom_right')) {
            Assert-Exact $audit.alpha_corners[$corner] $entry.alpha_corners.$corner "Selected source alpha corner mismatch: $id/$corner"
            if ($audit.alpha_corners[$corner] -gt 1) { throw "Selected source corner alpha exceeds approved tolerance: $id/$corner" }
        }
        Assert-Exact $entry.alpha_corner_validation.corner_alpha_max 1 "Selected source alpha tolerance mismatch: $id"
        if (-not [bool]$entry.alpha_corner_validation.passed) { throw "Selected source alpha validation is not approved: $id" }
        $runtimePath = Join-Path $RuntimeDir ($id + '_blueprint_ink_v2.png')
        $runtimeResource = 'res://assets/creatures/2d/blueprints/v2/' + $id + '_blueprint_ink_v2.png'
        $pilot = if ($PilotLinks.ContainsKey($id)) { $PilotLinks[$id] } else { $null }
        $entries += [ordered]@{ catalog_index = $index + 1; id = $id; name = [string]$entry.name; accepted_version = [string]$entry.accepted_version; source_path = [string]$entry.source; source_bytes = [int64]$entry.bytes; source_sha256 = [string]$entry.sha256; candidate_provenance = $entry.provenance; runtime_path = $runtimeResource; _source_full_path = $sourcePath; _runtime_full_path = $runtimePath; pilot_approval_links = $pilot }
    }
    return $entries
}
function Assert-LegacyInventoryRecords([object[]]$Records) {
    if ($Records.Count -ne $ExpectedLegacyRelativePaths.Count) { throw "Legacy inventory count mismatch (actual=$($Records.Count) expected=$($ExpectedLegacyRelativePaths.Count))" }
    $paths = @($Records | ForEach-Object { [string]$_.path } | Sort-Object)
    Assert-ExactArray $paths $ExpectedLegacyRelativePaths 'Legacy inventory paths mismatch'
    foreach ($record in $Records) {
        if ([string]::IsNullOrWhiteSpace([string]$record.name) -or [int64]$record.bytes -le 0 -or [string]$record.sha256 -notmatch '^[0-9A-F]{64}$') { throw "Legacy inventory record is missing required path/byte/hash evidence: $($record.path)" }
    }
}
function Assert-ExistingLegacyInventory {
    if (-not (Test-Path -LiteralPath $InventoryPath -PathType Leaf)) { return $false }
    $inventory = Get-Content -Raw -LiteralPath $InventoryPath | ConvertFrom-Json
    Assert-Exact $inventory.schema 'printforge.m7.legacy-blueprint-package-inventory.v1' 'Legacy inventory schema mismatch'
    Assert-LegacyInventoryRecords @($inventory.files)
    return $true
}
function Write-LegacyInventory {
    # This evidence records bytes that are intentionally retired from the runtime
    # package.  Once written, it is evidence—not a refreshed directory listing.
    if (Assert-ExistingLegacyInventory) { Write-Output 'M7 legacy inventory already validated and preserved.'; return }
    $legacyDir = Join-Path $RepoRoot 'assets\creatures\2d\blueprints'
    $files = @(Get-ChildItem -LiteralPath $legacyDir -File | Where-Object { $_.DirectoryName -eq $legacyDir } | Sort-Object Name)
    $currentPaths = @($files | ForEach-Object { Get-RepositoryRelativePath $_.FullName } | Sort-Object)
    Assert-ExactArray $currentPaths $ExpectedLegacyRelativePaths 'Legacy package shape required before first inventory creation'
    $inventory = [ordered]@{
        schema = 'printforge.m7.legacy-blueprint-package-inventory.v1'
        generated_utc = [DateTime]::UtcNow.ToString('o')
        scope = 'top-level legacy blueprint package inputs before M7 retirement; v2 subdirectory excluded'
        historical_docs_mapping = @('docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v1/provenance-v3.json','docs/archive/0.5-0.7/README.md')
        files = @($files | ForEach-Object { [ordered]@{ path = Get-RepositoryRelativePath $_.FullName; name = $_.Name; bytes = $_.Length; sha256 = Get-Sha256 $_.FullName; historical_docs = @('docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v1/provenance-v3.json','docs/archive/0.5-0.7/README.md') } })
    }
    [IO.File]::WriteAllText($InventoryPath, (($inventory | ConvertTo-Json -Depth 8) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
}
function Write-RuntimeManifest([object[]]$Entries) {
    $runtimeEntries = @($Entries | ForEach-Object {
        [ordered]@{ catalog_index = $_.catalog_index; id = $_.id; name = $_.name; accepted_version = $_.accepted_version; source_path = $_.source_path; source_bytes = $_.source_bytes; source_sha256 = $_.source_sha256; runtime_path = $_.runtime_path; runtime_bytes = (Get-Item -LiteralPath $_._runtime_full_path).Length; runtime_sha256 = Get-Sha256 $_._runtime_full_path; transform = 'byte-identical-copy'; candidate_provenance = $_.candidate_provenance; pilot_approval_links = $_.pilot_approval_links }
    })
    $manifest = [ordered]@{
        schema = 'printforge.runtime-blueprints.v2'
        version = 2
        generated_utc = [DateTime]::UtcNow.ToString('o')
        transform = 'byte-identical-copy'
        approval = [ordered]@{ record = 'docs/checkpoints/evidence/m7-blueprint-family-human-approval.md'; family_manifest_sha256 = $FamilyFiles.manifest.sha256; contact_sheet_sha256 = $FamilyFiles.contact_sheet.sha256; thumbnails_sha256 = $FamilyFiles.thumbnails.sha256 }
        catalog_order = $CatalogOrder
        entries = $runtimeEntries
    }
    [IO.File]::WriteAllText($RuntimeManifestPath, (($manifest | ConvertTo-Json -Depth 10) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
}
function Assert-RuntimeManifest([object[]]$Entries) {
    if (-not (Test-Path -LiteralPath $RuntimeManifestPath -PathType Leaf)) { throw 'Missing runtime v2 manifest.' }
    $manifest = Get-Content -Raw -LiteralPath $RuntimeManifestPath | ConvertFrom-Json
    Assert-Exact $manifest.schema 'printforge.runtime-blueprints.v2' 'Runtime manifest schema mismatch'
    Assert-Exact $manifest.version 2 'Runtime manifest version mismatch'
    Assert-Exact $manifest.approval.family_manifest_sha256 $FamilyFiles.manifest.sha256 'Runtime manifest family approval mismatch'
    Assert-ExactArray @($manifest.catalog_order) $CatalogOrder 'Runtime manifest catalog order mismatch'
    if ($manifest.entries.Count -ne 24 -or @($manifest.entries.id | Select-Object -Unique).Count -ne 24) { throw 'Runtime manifest membership mismatch.' }
    for ($index = 0; $index -lt $Entries.Count; $index++) {
        $expected, $actual = $Entries[$index], $manifest.entries[$index]
        foreach ($property in @('catalog_index','id','name','accepted_version','source_path','source_bytes','source_sha256','runtime_path','candidate_provenance')) { Assert-Exact $actual.$property $expected.$property "Runtime manifest $($expected.id) $property mismatch" }
        Assert-Exact $actual.transform 'byte-identical-copy' "Runtime manifest $($expected.id) transform mismatch"
        Assert-ExactArray @($actual.pilot_approval_links) @($expected.pilot_approval_links) "Runtime manifest $($expected.id) pilot links"
        if (-not (Test-Path -LiteralPath $expected._runtime_full_path -PathType Leaf)) { throw "Missing runtime asset: $($expected.id)" }
        Assert-Exact (Get-Item -LiteralPath $expected._runtime_full_path).Length $expected.source_bytes "Runtime byte mismatch: $($expected.id)"
        Assert-Exact (Get-Sha256 $expected._runtime_full_path) $expected.source_sha256 "Runtime byte identity mismatch: $($expected.id)"
        Assert-Exact $actual.runtime_bytes $expected.source_bytes "Runtime manifest byte mismatch: $($expected.id)"
        Assert-Exact $actual.runtime_sha256 $expected.source_sha256 "Runtime manifest hash mismatch: $($expected.id)"
    }
}

$entries = Get-ValidatedEntries
if ($ValidationSelfTest) {
    $badHash = $entries[0].source_sha256
    $entries[0].source_sha256 = '0' * 64
    $rejected = $false
    try { Assert-Exact (Get-Sha256 $entries[0]._source_full_path) $entries[0].source_sha256 'In-memory source mismatch' } catch { $rejected = $true }
    $entries[0].source_sha256 = $badHash
    if (-not $rejected) { throw 'Promotion self-test did not reject in-memory source mismatch.' }
	$inventory = Get-Content -Raw -LiteralPath $InventoryPath | ConvertFrom-Json
	$partialInventoryRejected = $false
	try { Assert-LegacyInventoryRecords @($inventory.files | Select-Object -First 50) } catch { $partialInventoryRejected = $true }
	if (-not $partialInventoryRejected) { throw 'Promotion self-test did not reject a partial legacy inventory.' }
    Write-Output 'Promotion self-test rejected in-memory source mismatch.'
	Write-Output 'Promotion self-test rejected partial legacy inventory.'
}
if (-not $ValidateOnly) {
    New-Item -ItemType Directory -Force -Path $RuntimeDir | Out-Null
    Write-LegacyInventory
    foreach ($entry in $entries) { Copy-Item -LiteralPath $entry._source_full_path -Destination $entry._runtime_full_path -Force }
    Write-RuntimeManifest $entries
}
Assert-ExistingLegacyInventory | Out-Null
Assert-RuntimeManifest $entries
Write-Output 'M7 runtime blueprint promotion validated: 24 byte-identical assets and manifest bindings.'
