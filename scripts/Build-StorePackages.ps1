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
        default { throw "Unsupported RuntimeIdentifier '$RuntimeIdentifier' for Store packaging." }
    }
}

function Get-PortPilotPackageArchitecture {
    param(
        [Parameter(Mandatory)]
        [string]$RuntimeIdentifier
    )

    switch -Regex ($RuntimeIdentifier) {
        'arm64$' { return 'arm64' }
        'x64$' { return 'x64' }
        default { throw "Unsupported RuntimeIdentifier '$RuntimeIdentifier' for package architecture." }
    }
}

function Get-WindowsSdkTool {
    param(
        [Parameter(Mandatory)]
        [string]$ToolName
    )

    $kitsRoot = "${env:ProgramFiles(x86)}\Windows Kits\10\bin"
    if (-not (Test-Path $kitsRoot)) {
        throw "Windows SDK tools not found. Install Windows 10/11 SDK."
    }

    $tool = Get-ChildItem $kitsRoot -Recurse -Filter $ToolName -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -match '\\x64\\' } |
        Sort-Object FullName -Descending |
        Select-Object -First 1

    if (-not $tool) {
        throw "$ToolName not found under $kitsRoot."
    }

    return $tool.FullName
}

$projectDir = Join-Path $root "PortPilot"
$artifactsDir = if ($ArtifactsDir) { $ArtifactsDir } else { Join-Path $root "artifacts\store" }

if (Test-Path $artifactsDir) {
    Remove-Item $artifactsDir -Recurse -Force
}

New-Item -ItemType Directory -Path $artifactsDir | Out-Null

$dotnetPath = Get-PortPilotDotnetCommand
$makeAppxPath = Get-WindowsSdkTool -ToolName "makeappx.exe"
$createdPackages = [System.Collections.Generic.List[string]]::new()

foreach ($runtimeIdentifier in $RuntimeIdentifiers) {
    $stagingDir = Join-Path $artifactsDir "PortPilot-$runtimeIdentifier"
    $platform = Get-PortPilotPlatform -RuntimeIdentifier $runtimeIdentifier
    $packageArchitecture = Get-PortPilotPackageArchitecture -RuntimeIdentifier $runtimeIdentifier

    New-Item -ItemType Directory -Path $stagingDir | Out-Null

    Write-Host "Publishing PortPilot for $runtimeIdentifier ($platform)..." -ForegroundColor Cyan
    & $dotnetPath publish "$projectDir\PortPilot.csproj" -c $Configuration -r $runtimeIdentifier -p:Platform=$platform --self-contained true -o $stagingDir
    if ($LASTEXITCODE -ne 0) {
        throw "dotnet publish failed for $runtimeIdentifier."
    }

    $resolvedVersion = Initialize-PortPilotLooseFilePackage `
        -ProjectDir $projectDir `
        -PackageDir $stagingDir `
        -PackageVersion $PackageVersion `
        -PackageArchitecture $packageArchitecture

    $msixPath = Join-Path $artifactsDir "PortPilot-$resolvedVersion-$runtimeIdentifier.msix"
    if (Test-Path $msixPath) {
        Remove-Item $msixPath -Force
    }

    Write-Host "Packing $msixPath..." -ForegroundColor Cyan
    & $makeAppxPath pack /d $stagingDir /p $msixPath /o
    if ($LASTEXITCODE -ne 0) {
        throw "makeappx failed for $runtimeIdentifier."
    }

    $createdPackages.Add($msixPath)
    Write-Host "Created $msixPath" -ForegroundColor Green
}

Write-Host ""
Write-Host "Store packages ready:" -ForegroundColor Green
$createdPackages | ForEach-Object { Write-Host " - $_" }
