[CmdletBinding()]
param(
    [switch]$ValidateOnly,
    [switch]$ValidationSelfTest
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

Add-Type -AssemblyName System.Drawing

$ToolVersion = '1.0.0'
$RepoRoot = Split-Path -Parent $PSScriptRoot
$FamilyRelative = 'docs/art/printforge-physical-ui-spike-20260830/creature-blueprints-v2/family-v2'
$FamilyDir = Join-Path $RepoRoot ($FamilyRelative -replace '/', '\')
$ManifestPath = Join-Path $FamilyDir 'family-manifest-v2.json'
$SumsPath = Join-Path $FamilyDir 'SHA256SUMS-v2.txt'
$ContactPath = Join-Path $FamilyDir 'family-contact-sheet-v2.png'
$ThumbsPath = Join-Path $FamilyDir 'family-thumbnails-160-v2.png'

function Get-RepositoryRelativePath([string]$Path) {
    $rootUri = [Uri]::new(($RepoRoot.TrimEnd('\') + '\'))
    $pathUri = [Uri]::new($Path)
    return [Uri]::UnescapeDataString($rootUri.MakeRelativeUri($pathUri).ToString()).Replace('\', '/')
}

function Get-Sha256([string]$Path) {
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

function Get-AlphaCorners([System.Drawing.Bitmap]$Bitmap) {
    return [ordered]@{
        top_left = $Bitmap.GetPixel(0, 0).A
        top_right = $Bitmap.GetPixel($Bitmap.Width - 1, 0).A
        bottom_left = $Bitmap.GetPixel(0, $Bitmap.Height - 1).A
        bottom_right = $Bitmap.GetPixel($Bitmap.Width - 1, $Bitmap.Height - 1).A
    }
}

function New-Entry([int]$Index, [string]$Id, [string]$Name, [string]$Version, [string]$Source, [AllowNull()][string]$Provenance) {
    return [ordered]@{
        catalog_index = $Index
        id = $Id
        name = $Name
        accepted_version = $Version
        source = $Source
        provenance = $Provenance
    }
}

# Explicit allowlist only. Existing rejected/draft candidates remain untouched and
# cannot become inputs merely because they match an ID glob.
$Inputs = @(
    (New-Entry 1 'cinderpaw' 'Cinderpaw' 'pilot-v2' '../cinderpaw-orthographic-printplan-alpha-pilot-v2.png' $null),
    (New-Entry 2 'aquafin' 'Aquafin' 'paper-through-v2-calibration' 'aquafin_blueprint_ink_v2-paper-through-v2-calibration.png' 'aquafin_blueprint_ink_v2-paper-through-v2-calibration.json'),
    (New-Entry 3 'voltwig' 'Voltwig' 'candidate-v3' 'voltwig_blueprint_ink_v2-candidate-v3.png' 'voltwig_blueprint_ink_v2-candidate-v3.json'),
    (New-Entry 4 'mossmunk' 'Mossmunk' 'candidate-v1' 'mossmunk_blueprint_ink_v2-candidate-v1.png' 'mossmunk_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 5 'frostling' 'Frostling' 'candidate-v1' 'frostling_blueprint_ink_v2-candidate-v1.png' 'frostling_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 6 'stoneback' 'Stoneback' 'candidate-v1' 'stoneback_blueprint_ink_v2-candidate-v1.png' 'stoneback_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 7 'galehopper' 'Galehopper' 'candidate-v1' 'galehopper_blueprint_ink_v2-candidate-v1.png' 'galehopper_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 8 'sparkotter' 'Sparkotter' 'candidate-v1' 'sparkotter_blueprint_ink_v2-candidate-v1.png' 'sparkotter_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 9 'glassdrake' 'Glassdrake' 'candidate-v1' 'glassdrake_blueprint_ink_v2-candidate-v1.png' 'glassdrake_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 10 'coralisk' 'Coralisk' 'candidate-v1' 'coralisk_blueprint_ink_v2-candidate-v1.png' 'coralisk_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 11 'runestag' 'Runestag' 'candidate-v1' 'runestag_blueprint_ink_v2-candidate-v1.png' 'runestag_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 12 'brambleowl' 'Brambleowl' 'candidate-v1' 'brambleowl_blueprint_ink_v2-candidate-v1.png' 'brambleowl_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 13 'ironmaw' 'Ironmaw' 'candidate-v3' 'ironmaw_blueprint_ink_v2-candidate-v3.png' 'ironmaw_blueprint_ink_v2-candidate-v3.json'),
    (New-Entry 14 'aurorawing' 'Aurorawing' 'pilot-v1' '../aurorawing-orthographic-printplan-alpha-pilot-v1.png' $null),
    (New-Entry 15 'thunderelk' 'Thunderelk' 'candidate-v1' 'thunderelk_blueprint_ink_v2-candidate-v1.png' 'thunderelk_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 16 'coalgriffin' 'Coalgriffin' 'candidate-v1' 'coalgriffin_blueprint_ink_v2-candidate-v1.png' 'coalgriffin_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 17 'tidewhale' 'Tidewhale' 'candidate-v2' 'tidewhale_blueprint_ink_v2-candidate-v2.png' 'tidewhale_blueprint_ink_v2-candidate-v2.json'),
    (New-Entry 18 'skyforge' 'Skyforge' 'candidate-v1' 'skyforge_blueprint_ink_v2-candidate-v1.png' 'skyforge_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 19 'pyraxis' 'Pyraxis' 'candidate-v1' 'pyraxis_blueprint_ink_v2-candidate-v1.png' 'pyraxis_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 20 'verdantitan' 'Verdantitan' 'candidate-v2' 'verdantitan_blueprint_ink_v2-candidate-v2.png' 'verdantitan_blueprint_ink_v2-candidate-v2.json'),
    (New-Entry 21 'miragefox' 'Miragefox' 'candidate-v1' 'miragefox_blueprint_ink_v2-candidate-v1.png' 'miragefox_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 22 'voidmanta' 'Voidmanta' 'candidate-v1' 'voidmanta_blueprint_ink_v2-candidate-v1.png' 'voidmanta_blueprint_ink_v2-candidate-v1.json'),
    (New-Entry 23 'worldcoil' 'Worldcoil' 'pilot-v1' '../worldcoil-orthographic-printplan-alpha-pilot-v1.png' $null),
    (New-Entry 24 'starloom' 'Starloom' 'candidate-v2' 'starloom_blueprint_ink_v2-candidate-v2.png' 'starloom_blueprint_ink_v2-candidate-v2.json')
)

if ($Inputs.Count -ne 24 -or @($Inputs.id | Select-Object -Unique).Count -ne 24) {
    throw 'Family input contract requires exactly 24 unique catalog IDs.'
}
if (@($Inputs.catalog_index | Sort-Object) -join ',' -ne (1..24 -join ',')) {
    throw 'Family input contract catalog indices are not exactly 1..24.'
}

$Validated = @()
foreach ($entry in $Inputs) {
    $sourcePath = [IO.Path]::GetFullPath((Join-Path $FamilyDir $entry.source))
    if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
        throw "Missing accepted source for $($entry.id): $($entry.source)"
    }
    $provenancePath = $null
    if (-not [string]::IsNullOrWhiteSpace($entry.provenance)) {
        $provenancePath = [IO.Path]::GetFullPath((Join-Path $FamilyDir $entry.provenance))
        if (-not (Test-Path -LiteralPath $provenancePath -PathType Leaf)) {
            throw "Missing accepted provenance for $($entry.id): $($entry.provenance)"
        }
    }
    $bitmap = [System.Drawing.Bitmap]::new([string]$sourcePath)
    try {
        $corners = Get-AlphaCorners $bitmap
        $maxCorner = @($corners.Values | Measure-Object -Maximum).Maximum
        if ($bitmap.Width -ne 1254 -or $bitmap.Height -ne 1254) {
            throw "Accepted source for $($entry.id) is not 1254x1254: $($bitmap.Width)x$($bitmap.Height)"
        }
        if ($bitmap.PixelFormat -notmatch 'Argb') {
            throw "Accepted source for $($entry.id) is not ARGB/RGBA: $($bitmap.PixelFormat)"
        }
        if ($maxCorner -gt 1) {
            throw "Accepted source for $($entry.id) has nontransparent corner alpha >1: $maxCorner"
        }
        $Validated += [ordered]@{
            catalog_index = $entry.catalog_index
            id = $entry.id
            name = $entry.name
            accepted_version = $entry.accepted_version
            source = Get-RepositoryRelativePath $sourcePath
            bytes = (Get-Item -LiteralPath $sourcePath).Length
            sha256 = Get-Sha256 $sourcePath
            dimensions = @($bitmap.Width, $bitmap.Height)
            pixel_format = [string]$bitmap.PixelFormat
            alpha_corners = $corners
            alpha_corner_validation = [ordered]@{ corner_alpha_max = 1; passed = $true }
            review_status = 'accepted_for_preproduction_family_atlas'
            provenance = if ([string]::IsNullOrWhiteSpace($provenancePath)) { $null } else { Get-RepositoryRelativePath $provenancePath }
            _source_path = $sourcePath
        }
    }
    finally {
        $bitmap.Dispose()
    }
}

function New-EvidenceCanvas([int]$Width, [int]$Height) {
    $bitmap = [System.Drawing.Bitmap]::new($Width, $Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.Clear([System.Drawing.Color]::FromArgb(255, 231, 214, 175))
    $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceOver
    $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    return @($bitmap, $graphics)
}

function Draw-AspectFit([System.Drawing.Graphics]$Graphics, [System.Drawing.Image]$Image, [System.Drawing.RectangleF]$Bounds) {
    $scale = [Math]::Min($Bounds.Width / $Image.Width, $Bounds.Height / $Image.Height)
    $drawWidth = [Math]::Round($Image.Width * $scale, 4)
    $drawHeight = [Math]::Round($Image.Height * $scale, 4)
    $drawX = $Bounds.X + (($Bounds.Width - $drawWidth) / 2.0)
    $drawY = $Bounds.Y + (($Bounds.Height - $drawHeight) / 2.0)
    $Graphics.DrawImage($Image, [System.Drawing.RectangleF]::new($drawX, $drawY, $drawWidth, $drawHeight), [System.Drawing.RectangleF]::new(0, 0, $Image.Width, $Image.Height), [System.Drawing.GraphicsUnit]::Pixel)
}

function Save-ContactSheet {
    param([object[]]$Entries, [string]$Path)
    $columns, $rows, $cellWidth, $cellHeight = 4, 6, 360, 390
    $sheet = New-EvidenceCanvas ($columns * $cellWidth) ($rows * $cellHeight)
    $bitmap, $graphics = $sheet[0], $sheet[1]
    $border = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 139, 111, 69), 2)
    $font = [System.Drawing.Font]::new('Segoe UI', 15, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 52, 37, 25))
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    try {
        for ($i = 0; $i -lt $Entries.Count; $i++) {
            $entry = $Entries[$i]
            $column = $i % $columns
            $row = [Math]::Floor($i / $columns)
            $x = $column * $cellWidth
            $y = $row * $cellHeight
            $graphics.DrawRectangle($border, $x + 1, $y + 1, $cellWidth - 2, $cellHeight - 2)
            $image = [System.Drawing.Image]::FromFile([string]$entry._source_path)
            try { Draw-AspectFit $graphics $image ([System.Drawing.RectangleF]::new($x + 18, $y + 12, $cellWidth - 36, 316)) }
            finally { $image.Dispose() }
            $label = ('{0:D2} - {1}' -f $entry.catalog_index, $entry.name)
            $graphics.DrawString($label, $font, $brush, [System.Drawing.RectangleF]::new($x + 10, $y + 338, $cellWidth - 20, 38), $format)
        }
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $format.Dispose(); $brush.Dispose(); $font.Dispose(); $border.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
    }
}

function Save-ThumbnailSheet {
    param([object[]]$Entries, [string]$Path)
    $columns, $rows, $cellWidth, $cellHeight = 6, 4, 210, 216
    $sheet = New-EvidenceCanvas ($columns * $cellWidth) ($rows * $cellHeight)
    $bitmap, $graphics = $sheet[0], $sheet[1]
    $border = [System.Drawing.Pen]::new([System.Drawing.Color]::FromArgb(255, 139, 111, 69), 2)
    $font = [System.Drawing.Font]::new('Segoe UI', 14, [System.Drawing.FontStyle]::Bold, [System.Drawing.GraphicsUnit]::Pixel)
    $brush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(255, 52, 37, 25))
    $format = [System.Drawing.StringFormat]::new()
    $format.Alignment = [System.Drawing.StringAlignment]::Center
    $format.LineAlignment = [System.Drawing.StringAlignment]::Center
    try {
        for ($i = 0; $i -lt $Entries.Count; $i++) {
            $entry = $Entries[$i]
            $column = $i % $columns
            $row = [Math]::Floor($i / $columns)
            $x = $column * $cellWidth
            $y = $row * $cellHeight
            $graphics.DrawRectangle($border, $x + 1, $y + 1, $cellWidth - 2, $cellHeight - 2)
            $image = [System.Drawing.Image]::FromFile([string]$entry._source_path)
            try { Draw-AspectFit $graphics $image ([System.Drawing.RectangleF]::new($x + 25, $y + 8, 160, 160)) }
            finally { $image.Dispose() }
            $graphics.DrawString([string]$entry.name, $font, $brush, [System.Drawing.RectangleF]::new($x + 6, $y + 174, $cellWidth - 12, 32), $format)
        }
        $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $format.Dispose(); $brush.Dispose(); $font.Dispose(); $border.Dispose(); $graphics.Dispose(); $bitmap.Dispose()
    }
}

function Get-OutputDetails([string]$Path, [int[]]$Dimensions) {
    return [ordered]@{ path = Get-RepositoryRelativePath $Path; bytes = (Get-Item -LiteralPath $Path).Length; sha256 = Get-Sha256 $Path; dimensions = $Dimensions }
}

function Get-ExpectedChecksumLines([object[]]$Entries) {
    $paths = @($Entries | ForEach-Object { $_._source_path }) + @($ContactPath, $ThumbsPath, $ManifestPath)
    $relativePaths = @($paths | ForEach-Object { Get-RepositoryRelativePath $_ })
    if ($paths.Count -ne 27 -or @($relativePaths | Select-Object -Unique).Count -ne 27) {
        throw 'Checksum contract must contain 24 unique masters plus two sheets and manifest exactly once.'
    }
    return @($paths | Sort-Object { Get-RepositoryRelativePath $_ } | ForEach-Object { '{0}  {1}' -f (Get-Sha256 $_), (Get-RepositoryRelativePath $_) })
}

function Assert-ExactArray([object[]]$Actual, [object[]]$Expected, [string]$Label) {
    if ($Actual.Count -ne $Expected.Count) { throw "$Label count mismatch: actual $($Actual.Count), expected $($Expected.Count)." }
    for ($index = 0; $index -lt $Expected.Count; $index++) {
        if ([string]$Actual[$index] -cne [string]$Expected[$index]) {
            throw "$Label mismatch at index $index."
        }
    }
}

function Assert-ManifestEntry([object]$Actual, [object]$Expected) {
    $expectedPairs = [ordered]@{
        catalog_index = [string]$Expected.catalog_index
        id = [string]$Expected.id
        name = [string]$Expected.name
        accepted_version = [string]$Expected.accepted_version
        source = [string]$Expected.source
        bytes = [string]$Expected.bytes
        sha256 = [string]$Expected.sha256
        pixel_format = [string]$Expected.pixel_format
        review_status = [string]$Expected.review_status
        provenance = [string]$Expected.provenance
    }
    foreach ($pair in $expectedPairs.GetEnumerator()) {
        if ([string]$Actual.($pair.Key) -cne $pair.Value) { throw "Manifest entry $($Expected.id) $($pair.Key) mismatch." }
    }
    Assert-ExactArray @($Actual.dimensions) @($Expected.dimensions) "Manifest entry $($Expected.id) dimensions"
    foreach ($corner in @('top_left', 'top_right', 'bottom_left', 'bottom_right')) {
        if ([string]$Actual.alpha_corners.$corner -cne [string]$Expected.alpha_corners.$corner) { throw "Manifest entry $($Expected.id) alpha corner $corner mismatch." }
    }
    if ([string]$Actual.alpha_corner_validation.corner_alpha_max -cne [string]$Expected.alpha_corner_validation.corner_alpha_max -or -not [bool]$Actual.alpha_corner_validation.passed) {
        throw "Manifest entry $($Expected.id) alpha validation mismatch."
    }
}

function Write-ManifestAndSums([object[]]$Entries) {
    $manifestEntries = @($Entries | ForEach-Object {
        $copy = [ordered]@{}
        foreach ($property in $_.GetEnumerator()) {
            if ($property.Key -ne '_source_path') { $copy[$property.Key] = $property.Value }
        }
        [pscustomobject]$copy
    })
    $manifest = [ordered]@{
        schema = 'printforge.creature-blueprints-family.v2'
        version = 2
        generated_utc = [DateTime]::UtcNow.ToString('o')
        tool = [ordered]@{ path = 'tools/build_blueprint_family_v2.ps1'; version = $ToolVersion; implementation = 'System.Drawing + standard PowerShell/.NET'; candidate_selection_policy = 'explicit_allowlist_only' }
        catalog_order = @($Entries | ForEach-Object { $_.id })
        validation = [ordered]@{ expected_count = 24; unique_ids = 24; required_dimensions = @(1254, 1254); required_pixel_format = 'ARGB/RGBA'; corner_alpha_max = 1; unlisted_candidates_selected = $false }
        entries = $manifestEntries
        sheets = [ordered]@{
            contact_sheet = Get-OutputDetails $ContactPath @(1440, 2340)
            thumbnails_160 = Get-OutputDetails $ThumbsPath @(1260, 864)
        }
    }
    [IO.File]::WriteAllText($ManifestPath, (($manifest | ConvertTo-Json -Depth 10) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))

    $lines = Get-ExpectedChecksumLines $Entries
    [IO.File]::WriteAllText($SumsPath, (($lines -join [Environment]::NewLine) + [Environment]::NewLine), [Text.UTF8Encoding]::new($false))
}

function Assert-ExistingOutputs([object[]]$Entries) {
    foreach ($path in @($ManifestPath, $SumsPath, $ContactPath, $ThumbsPath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Missing family output: $path" }
    }
    $manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
    if ([string]$manifest.schema -cne 'printforge.creature-blueprints-family.v2' -or [int]$manifest.version -ne 2) { throw 'Manifest schema/version mismatch.' }
    if ($manifest.entries.Count -ne 24 -or $manifest.catalog_order.Count -ne 24 -or @($manifest.entries.id | Select-Object -Unique).Count -ne 24) { throw 'Manifest does not contain exactly 24 unique entries.' }
    Assert-ExactArray @($manifest.catalog_order) @($Entries | ForEach-Object { $_.id }) 'Manifest catalog order'
    for ($index = 0; $index -lt $Entries.Count; $index++) { Assert-ManifestEntry $manifest.entries[$index] $Entries[$index] }

    $contact = [System.Drawing.Bitmap]::new([string]$ContactPath)
    $thumbs = [System.Drawing.Bitmap]::new([string]$ThumbsPath)
    try {
        if ($contact.Width -ne 1440 -or $contact.Height -ne 2340) { throw 'Contact sheet dimensions are invalid.' }
        if ($thumbs.Width -ne 1260 -or $thumbs.Height -ne 864) { throw 'Thumbnail sheet dimensions are invalid.' }
    }
    finally { $contact.Dispose(); $thumbs.Dispose() }
    $expectedContact = Get-OutputDetails $ContactPath @(1440, 2340)
    $expectedThumbs = Get-OutputDetails $ThumbsPath @(1260, 864)
    foreach ($sheet in @(@($manifest.sheets.contact_sheet, $expectedContact, 'contact sheet'), @($manifest.sheets.thumbnails_160, $expectedThumbs, 'thumbnail sheet'))) {
        $actual, $expected, $label = $sheet[0], $sheet[1], $sheet[2]
        foreach ($property in @('path', 'bytes', 'sha256')) {
            if ([string]$actual.$property -cne [string]$expected.$property) { throw "Manifest $label $property mismatch." }
        }
        Assert-ExactArray @($actual.dimensions) @($expected.dimensions) "Manifest $label dimensions"
    }
    $actualSums = @([IO.File]::ReadAllLines($SumsPath))
    $expectedSums = Get-ExpectedChecksumLines $Entries
    if ($actualSums | Where-Object { $_ -match 'SHA256SUMS-v2\.txt' }) { throw 'SHA256SUMS must not include itself.' }
    Assert-ExactArray $actualSums $expectedSums 'SHA256SUMS'
}

if (-not $ValidateOnly) {
    Save-ContactSheet $Validated $ContactPath
    Save-ThumbnailSheet $Validated $ThumbsPath
    Write-ManifestAndSums $Validated
}
if ($ValidationSelfTest) {
    $expected = Get-ExpectedChecksumLines $Validated
    $tampered = @($expected)
    $tampered[0] = '0000000000000000000000000000000000000000000000000000000000000000  invalid/path.png'
    $mismatchRejected = $false
    try { Assert-ExactArray $tampered $expected 'Validation self-test' }
    catch { $mismatchRejected = $true }
    if (-not $mismatchRejected) { throw 'Validation self-test did not reject an in-memory checksum mismatch.' }
    Write-Output 'Validation self-test rejected in-memory checksum mismatch.'
}
Assert-ExistingOutputs $Validated
Write-Output ("Blueprint family v2 validated: 24 inputs, 27 SHA entries, contact 1440x2340, thumbnails 1260x864.")
