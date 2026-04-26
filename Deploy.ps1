<#
.SYNOPSIS
    Deploy PortPilot extension to PowerToys Command Palette.
.DESCRIPTION
    Builds the project as self-contained and registers it as a loose-file MSIX package.
    Requires Developer Mode enabled in Windows Settings.
#>
param(
    [switch]$SkipBuild
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$projDir = Join-Path $root "PortPilot"
$pubDir = Join-Path $projDir "bin\Publish"
. (Join-Path $root "scripts\PortPilot.Packaging.ps1")

# Ensure dotnet is available
$dotnetPath = Get-PortPilotDotnetCommand

$developerMode = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" -Name "AllowDevelopmentWithoutDevLicense" -ErrorAction SilentlyContinue
if ($developerMode -ne 1) {
    throw "Developer Mode must be enabled before deploying PortPilot. Open Settings > System > For developers and turn Developer Mode on."
}

# Validate the existing publish output before unregistering the current package.
if ($SkipBuild -and -not (Test-Path (Join-Path $pubDir "PortPilot.exe"))) {
    throw "No existing publish output was found at $pubDir. Run .\Deploy.ps1 without -SkipBuild first."
}

# Stop any running PortPilot process first (locks build output files).
$runningProcessIds = @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -eq "PortPilot" } | ForEach-Object { $_.Id })
foreach ($processId in $runningProcessIds) {
    Stop-Process -Id $processId -Force
}

if ($runningProcessIds.Count -gt 0) {
    Start-Sleep -Seconds 1
}

# Build as self-contained
if (-not $SkipBuild) {
    Write-Host "Building PortPilot (self-contained)..." -ForegroundColor Cyan
    & $dotnetPath publish "$projDir\PortPilot.csproj" -c Debug -r win-x64 --self-contained true -o $pubDir
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed."
        exit 1
    }
}

# Copy manifest and assets to output
Write-Host "Preparing deployment files..." -ForegroundColor Cyan
Initialize-PortPilotLooseFilePackage -ProjectDir $projDir -PackageDir $pubDir | Out-Null

$existing = Get-AppxPackage -Name "PortPilot" -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Removing existing PortPilot package..." -ForegroundColor Yellow
    Remove-AppxPackage $existing.PackageFullName
    Start-Sleep -Seconds 2
}

# Register the loose-file package
Write-Host "Registering PortPilot extension..." -ForegroundColor Cyan
$manifestPath = Join-Path $pubDir "AppxManifest.xml"
Add-AppxPackage -Register $manifestPath

Write-Host ""
Write-Host "PortPilot deployed successfully!" -ForegroundColor Green
Write-Host "Open Command Palette and type 'Reload' to discover the extension."
Write-Host "Then search for 'PortPilot' to use it."
