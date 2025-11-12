<#
verify_playstore_ready.ps1

Quick local checks to validate Play Store readiness.
Run from repository root in PowerShell.
#>

Set-StrictMode -Version Latest

function Fail([string]$msg) {
    Write-Error $msg
    exit 1
}

if (-not (Test-Path .\android\app\build.gradle.kts)) {
    Fail "android/app/build.gradle.kts not found"
}

# Check applicationId
$buildGradle = Get-Content .\android\app\build.gradle.kts -Raw
$appIdMatch = [regex]::Match($buildGradle, 'applicationId\s*=\s*"([^"]+)"')
if ($appIdMatch.Success) {
    $appId = $appIdMatch.Groups[1].Value
    Write-Host "applicationId: $appId"
    if ($appId -like 'com.example*') {
        Write-Warning "applicationId is a com.example value. Please set to your Play Console package name."
    }
}
else {
    Write-Warning "Could not find applicationId in build.gradle.kts. Please verify the Android config."
}

# Check key.properties
if (-not (Test-Path .\key.properties)) {
    Write-Warning "key.properties not found at project root. Create it with storeFile, storePassword, keyAlias and keyPassword."
}
else {
    Write-Host "Found key.properties"
}

# Check keystore file
$storeFile = $null
if (Test-Path .\key.properties) {
    $lines = Get-Content .\key.properties | ForEach-Object { $_.Trim() }
    foreach ($l in $lines) {
        if ($l -match '^storeFile\s*=\s*(.+)$') { $storeFile = $Matches[1].Trim() }
    }
}

if ($storeFile) {
    $storePath = Join-Path (Get-Location) $storeFile
    if (Test-Path $storePath) { Write-Host "Keystore exists: $storePath" }
    else { Write-Warning "Keystore not found at $storePath" }
}

# Check pubspec version
if (Test-Path .\pubspec.yaml) {
    $pub = Get-Content .\pubspec.yaml | Select-String '^version:\s*(.+)$' -First 1
    if ($pub) { Write-Host "pubspec version: $($pub.Matches[0].Groups[1].Value.Trim())" }
    else { Write-Warning "No version entry found in pubspec.yaml" }
}

Write-Host "Verification complete. Address any WARNINGS before uploading to Play Store."
