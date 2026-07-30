param(
    [string]$GameDirectory
)

$ErrorActionPreference = "Stop"

$autoloadPattern = '(?m)^[ \t]*UnboundBootstrap[ \t]*=[^\r\n]*(?:\r?\n)?'


function Stop-Uninstaller {
    param(
        [string]$Message
    )

    Write-Host ""
    Write-Host "Uninstallation failed: $Message"
    exit 1
}


function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}


Write-Host ""
Write-Host "Worldbuilt: Unbound Uninstaller"
Write-Host ""

if ([string]::IsNullOrWhiteSpace($GameDirectory)) {
    $GameDirectory = Read-Host "Enter the folder containing WorldbuiltAlpha.exe"
}

$GameDirectory = $GameDirectory.Trim().Trim('"')

if (-not (Test-Path -LiteralPath $GameDirectory -PathType Container)) {
    Stop-Uninstaller "The selected game folder does not exist."
}

$resolvedGameDirectory = (Resolve-Path -LiteralPath $GameDirectory).Path

$addonPath = Join-Path $resolvedGameDirectory "addons\worldbuilt_unbound"
$overridePath = Join-Path $resolvedGameDirectory "override.cfg"
$installMarkerPath = Join-Path $resolvedGameDirectory "worldbuilt_unbound.install.json"
$modsDirectory = Join-Path $resolvedGameDirectory "mods"

$overrideCreatedByInstaller = $false

if (Test-Path -LiteralPath $installMarkerPath -PathType Leaf) {
    try {
        $markerContent = [System.IO.File]::ReadAllText($installMarkerPath)
        $marker = $markerContent | ConvertFrom-Json

        if ($null -ne $marker.override_created_by_installer) {
            $overrideCreatedByInstaller = [bool]$marker.override_created_by_installer
        }
    }
    catch {
        Write-Host "Warning: Could not read the installation marker."
    }
}

if (Test-Path -LiteralPath $addonPath -PathType Container) {
    Remove-Item -LiteralPath $addonPath -Recurse -Force
    Write-Host "Removed addons\worldbuilt_unbound"
}
else {
    Write-Host "Addon folder was already absent."
}

if (Test-Path -LiteralPath $overridePath -PathType Leaf) {
    $overrideContent = [System.IO.File]::ReadAllText($overridePath)
    $updatedContent = [regex]::Replace($overrideContent, $autoloadPattern, "")

    if ($overrideCreatedByInstaller -and $updatedContent -match '^\s*\[autoload\]\s*$') {
        Remove-Item -LiteralPath $overridePath -Force
        Write-Host "Removed installer-created override.cfg"
    }
    else {
        Write-Utf8File -Path $overridePath -Content $updatedContent
        Write-Host "Removed the Unbound autoload from override.cfg"
    }
}

if (Test-Path -LiteralPath $installMarkerPath -PathType Leaf) {
    Remove-Item -LiteralPath $installMarkerPath -Force
    Write-Host "Removed installation marker"
}

Write-Host ""
Write-Host "Worldbuilt: Unbound uninstalled successfully."
Write-Host ""

if (Test-Path -LiteralPath $modsDirectory -PathType Container) {
    Write-Host "The mods folder was preserved:"
    Write-Host "  $modsDirectory"
}