[CmdletBinding()]
param(
    [ValidateSet("Debug", "Release")]
    [string]$Configuration = "Release",

    [string[]]$RuntimeIdentifiers = @("win-x64", "win-arm64"),

    [string]$PackageVersion,

    [string]$ArtifactsDir
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "PortPilot.Packaging.ps1")

function Get-PortPilotPlatform {
    param(
        [Parameter(Mandatory)]
        [string]$RuntimeIdentifier
    )

    switch -Regex ($RuntimeIdentifier) {
        'arm64$' { return 'ARM64' }
        'x64$' { return 'x64' }
        default { throw "Unsupported RuntimeIdentifier '$RuntimeIdentifier' for PortPilot release packaging." }
    }
}

$projectDir = Join-Path $root "PortPilot"
$artifactsDir = if ($ArtifactsDir) { $ArtifactsDir } else { Join-Path $root "artifacts\release" }

if (Test-Path $artifactsDir) {
    Remove-Item $artifactsDir -Recurse -Force
}

New-Item -ItemType Directory -Path $artifactsDir | Out-Null

$dotnetPath = Get-PortPilotDotnetCommand
$createdArchives = [System.Collections.Generic.List[string]]::new()

foreach ($runtimeIdentifier in $RuntimeIdentifiers) {
    $stagingDir = Join-Path $artifactsDir "PortPilot-$runtimeIdentifier"
    $platform = Get-PortPilotPlatform -RuntimeIdentifier $runtimeIdentifier

    New-Item -ItemType Directory -Path $stagingDir | Out-Null

    Write-Host "Publishing PortPilot for $runtimeIdentifier ($platform)..." -ForegroundColor Cyan
    & $dotnetPath publish "$projectDir\PortPilot.csproj" -c $Configuration -r $runtimeIdentifier -p:Platform=$platform --self-contained true -o $stagingDir
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet publish failed for $runtimeIdentifier."
    }

    $resolvedVersion = Initialize-PortPilotLooseFilePackage -ProjectDir $projectDir -PackageDir $stagingDir -PackageVersion $PackageVersion
    Copy-Item (Join-Path $PSScriptRoot "Install-PortPilot.ps1") (Join-Path $stagingDir "Install-PortPilot.ps1") -Force
    Copy-Item (Join-Path $root "LICENSE") (Join-Path $stagingDir "LICENSE") -Force

    $zipPath = Join-Path $artifactsDir "PortPilot-$resolvedVersion-$runtimeIdentifier.zip"
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }

    Compress-Archive -Path (Join-Path $stagingDir '*') -DestinationPath $zipPath -CompressionLevel Optimal
    $createdArchives.Add($zipPath)
    Write-Host "Created $zipPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "Release packages ready:" -ForegroundColor Green
$createdArchives | ForEach-Object { Write-Host " - $_" }
