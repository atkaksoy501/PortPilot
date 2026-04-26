function Get-PortPilotDotnetCommand {
    $localDotnet = Join-Path $env:LOCALAPPDATA "Microsoft\dotnet\dotnet.exe"
    if (Test-Path $localDotnet) {
        return $localDotnet
    }

    $pathDotnet = Get-Command dotnet -ErrorAction SilentlyContinue
    if ($pathDotnet) {
        return $pathDotnet.Source
    }

    throw ".NET SDK not found. Install the .NET 9 SDK or add dotnet to PATH."
}

function Get-PortPilotPackageVersion {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectDir,

        [string]$RequestedVersion
    )

    if (-not [string]::IsNullOrWhiteSpace($RequestedVersion)) {
        $normalizedVersion = $RequestedVersion.Trim().TrimStart('v', 'V')
        if ($normalizedVersion -notmatch '^\d+\.\d+\.\d+(?:\.\d+)?$') {
            throw "PackageVersion must use major.minor.patch or major.minor.patch.revision format."
        }

        if (($normalizedVersion -split '\.').Count -eq 3) {
            return "$normalizedVersion.0"
        }

        return $normalizedVersion
    }

    $manifestPath = Join-Path $ProjectDir "Package.appxmanifest"
    $manifest = Get-Content $manifestPath -Raw
    $match = [regex]::Match($manifest, '(?s)<Identity\b[^>]*\bVersion="([^"]+)"')

    if (-not $match.Success) {
        throw "Unable to read package version from $manifestPath."
    }

    return $match.Groups[1].Value
}

function Initialize-PortPilotLooseFilePackage {
    param(
        [Parameter(Mandatory)]
        [string]$ProjectDir,

        [Parameter(Mandatory)]
        [string]$PackageDir,

        [string]$PackageVersion
    )

    if (-not (Test-Path $PackageDir)) {
        throw "Package directory not found: $PackageDir"
    }

    $executablePath = Join-Path $PackageDir "PortPilot.exe"
    if (-not (Test-Path $executablePath)) {
        throw "Expected published executable was not found at $executablePath."
    }

    $manifestVersion = Get-PortPilotPackageVersion -ProjectDir $ProjectDir -RequestedVersion $PackageVersion
    $manifestPath = Join-Path $ProjectDir "Package.appxmanifest"
    $manifest = Get-Content $manifestPath -Raw
    $manifest = $manifest -replace '\$targetnametoken\$\.exe', 'PortPilot.exe'
    $manifest = $manifest -replace '\$targetentrypoint\$', 'Windows.FullTrustApplication'
    $manifest = $manifest -replace 'Square150x150Logo="Assets\\Square150x150Logo\.png"', 'Square150x150Logo="Assets\Square150x150Logo.scale-200.png"'
    $manifest = $manifest -replace 'Square44x44Logo="Assets\\Square44x44Logo\.png"', 'Square44x44Logo="Assets\Square44x44Logo.scale-200.png"'
    $manifest = $manifest -replace 'Wide310x150Logo="Assets\\Wide310x150Logo\.png"', 'Wide310x150Logo="Assets\Wide310x150Logo.scale-200.png"'
    $manifest = $manifest -replace 'Image="Assets\\SplashScreen\.png"', 'Image="Assets\SplashScreen.scale-200.png"'
    $manifest = $manifest -replace '<Resource Language="x-generate"/>', '<Resource Language="en-us"/>'

    $identityVersionPattern = [regex]::new('(<Identity\b[^>]*\bVersion=")[^"]+(")')
    $manifest = $identityVersionPattern.Replace(
        $manifest,
        [System.Text.RegularExpressions.MatchEvaluator]{
            param($match)
            "{0}{1}{2}" -f $match.Groups[1].Value, $manifestVersion, $match.Groups[2].Value
        },
        1
    )

    Set-Content (Join-Path $PackageDir "AppxManifest.xml") $manifest -Encoding UTF8

    $assetsOut = Join-Path $PackageDir "Assets"
    if (-not (Test-Path $assetsOut)) {
        New-Item -ItemType Directory -Path $assetsOut | Out-Null
    }

    Copy-Item (Join-Path $ProjectDir "Assets\*") $assetsOut -Force

    $publicOut = Join-Path $PackageDir "Public"
    if (-not (Test-Path $publicOut)) {
        New-Item -ItemType Directory -Path $publicOut | Out-Null
    }

    return $manifestVersion
}
