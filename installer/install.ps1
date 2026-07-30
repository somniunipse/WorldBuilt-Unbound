param(
    [string]$GameDirectory
)

$ErrorActionPreference = "Stop"

$loaderVersion = "0.1.0"
$autoloadLine = 'UnboundBootstrap="*res://addons/worldbuilt_unbound/core/bootstrap.gd"'

$repoRoot = Split-Path -Parent $PSScriptRoot
$payloadRoot = Join-Path $repoRoot "payload"
$sourceAddon = Join-Path $payloadRoot "addons\worldbuilt_unbound"
$sourceOverride = Join-Path $payloadRoot "override.cfg"


function Stop-Installer {
    param(
        [string]$Message
    )

    Write-Host ""
    Write-Host "Installation failed: $Message"
    exit 1
}


function Write-Utf8File {
    param(
        [string]$Path,
        [string]$Content
    )

    $encoding = New-Object System.Text.UTF8Encoding($false)

    [System.IO.File]::WriteAllText(
        $Path,
        $Content,
        $encoding
    )
}


Write-Host ""
Write-Host "Worldbuilt: Unbound Installer"
Write-Host "Version $loaderVersion"
Write-Host ""

if ([string]::IsNullOrWhiteSpace($GameDirectory)) {
    $GameDirectory = Read-Host "Enter the folder containing WorldbuiltAlpha.exe"
}

$GameDirectory = $GameDirectory.Trim().Trim('"')

if (-not (Test-Path -LiteralPath $GameDirectory -PathType Container)) {
    Stop-Installer "The selected game folder does not exist."
}

$resolvedGameDirectory = (Resolve-Path -LiteralPath $GameDirectory).Path

$gameExecutable = Get-ChildItem -LiteralPath $resolvedGameDirectory -Filter "*.exe" -File |
    Where-Object { $_.BaseName -like "Worldbuilt*" } |
    Select-Object -First 1

if ($null -eq $gameExecutable) {
    Stop-Installer "No Worldbuilt executable was found in the selected folder."
}

if (-not (Test-Path -LiteralPath $sourceAddon -PathType Container)) {
    Stop-Installer "The Worldbuilt: Unbound addon payload is missing."
}

if (-not (Test-Path -LiteralPath $sourceOverride -PathType Leaf)) {
    Stop-Installer "The payload override.cfg file is missing."
}

Write-Host "Game executable:"
Write-Host "  $($gameExecutable.FullName)"
Write-Host ""

$destinationAddons = Join-Path $resolvedGameDirectory "addons"
$destinationAddon = Join-Path $destinationAddons "worldbuilt_unbound"
$modsDirectory = Join-Path $resolvedGameDirectory "mods"
$overridePath = Join-Path $resolvedGameDirectory "override.cfg"
$installMarkerPath = Join-Path $resolvedGameDirectory "worldbuilt_unbound.install.json"

New-Item -ItemType Directory -Path $destinationAddons -Force | Out-Null
New-Item -ItemType Directory -Path $modsDirectory -Force | Out-Null

if (Test-Path -LiteralPath $destinationAddon) {
    Remove-Item -LiteralPath $destinationAddon -Recurse -Force
}

Copy-Item -LiteralPath $sourceAddon -Destination $destinationAddons -Recurse -Force

$overrideCreatedByInstaller = $false

if (Test-Path -LiteralPath $overridePath -PathType Leaf) {
    $overrideContent = [System.IO.File]::ReadAllText($overridePath)

    if ($overrideContent -notmatch '(?m)^\s*UnboundBootstrap\s*=') {
        $autoloadPattern = '(?m)^\s*\[autoload\]\s*$'
        $autoloadRegex = New-Object System.Text.RegularExpressions.Regex($autoloadPattern)

        if ($autoloadRegex.IsMatch($overrideContent)) {
            $replacement = "[autoload]`r`n`r`n$autoloadLine"
            $overrideContent = $autoloadRegex.Replace($overrideContent, $replacement, 1)
        }
        else {
            if ($overrideContent.Length -gt 0 -and -not $overrideContent.EndsWith("`n")) {
                $overrideContent += "`r`n"
            }

            $overrideContent += "`r`n[autoload]`r`n`r`n$autoloadLine`r`n"
        }

        Write-Utf8File -Path $overridePath -Content $overrideContent
    }
}
else {
    Copy-Item -LiteralPath $sourceOverride -Destination $overridePath -Force
    $overrideCreatedByInstaller = $true
}

$installMarker = [ordered]@{
    loader_version = $loaderVersion
    installed_at = (Get-Date).ToString("o")
    game_executable = $gameExecutable.Name
    override_created_by_installer = $overrideCreatedByInstaller
}

$installMarkerJson = $installMarker | ConvertTo-Json

Write-Utf8File -Path $installMarkerPath -Content $installMarkerJson

Write-Host ""
Write-Host "Worldbuilt: Unbound installed successfully."
Write-Host ""
Write-Host "Installed:"
Write-Host "  addons\worldbuilt_unbound"
Write-Host "  override.cfg autoload"
Write-Host "  mods folder"
Write-Host ""
Write-Host "Existing mods were not deleted."