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

# Ensure dotnet is available
$dotnetPath = "$env:LOCALAPPDATA\Microsoft\dotnet\dotnet.exe"
if (-not (Test-Path $dotnetPath)) {
    $dotnetPath = "dotnet"
}

# Build as self-contained
if (-not $SkipBuild) {
    # Stop any running PortPilot process first (locks build output files)
    $existing = Get-AppxPackage -Name "PortPilot" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Removing existing PortPilot package..." -ForegroundColor Yellow
        Remove-AppxPackage $existing.PackageFullName
        Start-Sleep -Seconds 2
    }
    Get-Process | Where-Object { $_.ProcessName -eq "PortPilot" } | ForEach-Object {
        [System.Diagnostics.Process]::GetProcessById($_.Id).Kill()
    }
    Start-Sleep -Seconds 1

    Write-Host "Building PortPilot (self-contained)..." -ForegroundColor Cyan
    & $dotnetPath publish "$projDir\PortPilot.csproj" -c Debug -r win-x64 --self-contained true -o $pubDir
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed."
        exit 1
    }
}

# Copy manifest and assets to output
Write-Host "Preparing deployment files..." -ForegroundColor Cyan
$manifest = Get-Content (Join-Path $projDir "Package.appxmanifest") -Raw
$manifest = $manifest -replace '\$targetnametoken\$\.exe', 'PortPilot.exe'
$manifest = $manifest -replace '\$targetentrypoint\$', 'Windows.FullTrustApplication'
$manifest = $manifest -replace 'Square150x150Logo="Assets\\Square150x150Logo\.png"', 'Square150x150Logo="Assets\Square150x150Logo.scale-200.png"'
$manifest = $manifest -replace 'Square44x44Logo="Assets\\Square44x44Logo\.png"', 'Square44x44Logo="Assets\Square44x44Logo.scale-200.png"'
$manifest = $manifest -replace 'Wide310x150Logo="Assets\\Wide310x150Logo\.png"', 'Wide310x150Logo="Assets\Wide310x150Logo.scale-200.png"'
$manifest = $manifest -replace 'Image="Assets\\SplashScreen\.png"', 'Image="Assets\SplashScreen.scale-200.png"'
$manifest = $manifest -replace '<Resource Language="x-generate"/>', '<Resource Language="en-us"/>'
Set-Content (Join-Path $pubDir "AppxManifest.xml") $manifest -Encoding UTF8

$assetsOut = Join-Path $pubDir "Assets"
if (-not (Test-Path $assetsOut)) { New-Item -ItemType Directory -Path $assetsOut | Out-Null }
Copy-Item (Join-Path $projDir "Assets\*") $assetsOut -Force

# Register the loose-file package
Write-Host "Registering PortPilot extension..." -ForegroundColor Cyan
$manifestPath = Join-Path $pubDir "AppxManifest.xml"
Add-AppxPackage -Register $manifestPath

Write-Host ""
Write-Host "PortPilot deployed successfully!" -ForegroundColor Green
Write-Host "Open Command Palette and type 'Reload' to discover the extension."
Write-Host "Then search for 'PortPilot' to use it."
