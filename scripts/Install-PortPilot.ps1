Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$packageRoot = $PSScriptRoot
$manifestPath = Join-Path $packageRoot "AppxManifest.xml"

if (-not (Test-Path $manifestPath)) {
    throw "AppxManifest.xml was not found next to Install-PortPilot.ps1. Extract the full release archive before running the installer."
}

$developerMode = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -ErrorAction SilentlyContinue
if ($developerMode -ne 1) {
    throw "Developer Mode must be enabled before installing PortPilot. Open Settings > System > For developers and turn Developer Mode on."
}

$runningProcessIds = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq "PortPilot" } | ForEach-Object { $_.Id })
foreach ($processId in $runningProcessIds) {
    Stop-Process -Id $processId
}

$existingPackage = Get-AppxPackage -Name "PortPilot" -ErrorAction SilentlyContinue
if ($existingPackage) {
    Write-Host "Removing existing PortPilot package..." -ForegroundColor Yellow
    Remove-AppxPackage $existingPackage.PackageFullName
}

Write-Host "Registering PortPilot from $packageRoot..." -ForegroundColor Cyan
Add-AppxPackage -Register $manifestPath

Write-Host ""
Write-Host "PortPilot installed successfully." -ForegroundColor Green
Write-Host "Open Command Palette, run 'Reload Command Palette extensions', then search for 'PortPilot'."
