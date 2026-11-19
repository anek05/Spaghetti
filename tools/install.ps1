param(
    [string]$AddOnsPath = 'D:\World of Warcraft\_forever_\Interface\AddOns',
    [switch]$Update
)
$ErrorActionPreference = 'Stop'
$sourcePath = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\Spaghetti'))
$addonRoot = (Resolve-Path -LiteralPath $AddOnsPath).Path
$destinationPath = Join-Path $addonRoot 'Spaghetti'
$expectedPath = [IO.Path]::GetFullPath((Join-Path $addonRoot 'Spaghetti'))
if ([IO.Path]::GetFullPath($destinationPath) -ne $expectedPath) {
    throw 'Installation target is outside the selected AddOns directory.'
}
$version = ((Get-Content -LiteralPath (Join-Path $sourcePath 'Spaghetti.toc') | Select-String '^## Version: (.+)$').Matches.Groups[1].Value)
if (Test-Path -LiteralPath $destinationPath) {
    if (-not $Update) { throw "Spaghetti already exists at $destinationPath. Use -Update to back up and update this addon. No files were changed." }
    $existing = Get-Item -LiteralPath $destinationPath
    if ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw 'Refusing to update a linked addon directory.' }
    $tocPath = Join-Path $destinationPath 'Spaghetti.toc'
    if (-not (Test-Path -LiteralPath $tocPath) -or -not (Test-Path -LiteralPath (Join-Path $destinationPath 'Core.lua'))) { throw 'Existing directory is not a recognized Spaghetti installation.' }
    if (-not (Get-Content -LiteralPath $tocPath | Select-String '^## Title: Spaghetti$')) { throw 'Existing TOC does not identify Spaghetti. No files were changed.' }
    $backupRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\.backups'))
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    $backupPath = Join-Path $backupRoot ('Spaghetti-before-' + $version + '-' + (Get-Date -Format 'yyyyMMdd-HHmmssfff') + '.zip')
    Compress-Archive -LiteralPath $destinationPath -DestinationPath $backupPath
    Get-ChildItem -LiteralPath $sourcePath -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $destinationPath -Recurse -Force
    }
    Write-Output "Previous addon backed up to $backupPath"
} else {
    Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Recurse
}
Write-Output "Installed Spaghetti $version to $destinationPath; no SavedVariables files were changed."
Write-Output 'Restart WoW Forever, enable Spaghetti, and enter /spaghetti.'
