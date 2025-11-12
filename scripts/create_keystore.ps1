<#
create_keystore.ps1

Usage:
  # Normal (won't overwrite existing keystore)
  .\scripts\create_keystore.ps1

  # Force overwrite existing keystore
  .\scripts\create_keystore.ps1 -Force

  # Provide a custom subject DN
  .\scripts\create_keystore.ps1 -DName "CN=Your Name, OU=Dev, O=Company, L=City, S=State, C=US"

This script reads `key.properties` from the repository root and runs `keytool` to
generate the keystore at the path specified by the `storeFile` property.

WARNING: This will expose the passwords stored in `key.properties` to the local
command execution. Only run this script on your own machine, never in CI with
public logs.
#>

param(
    [switch]$Force,
    [string]$DName = "CN=rak_app, OU=Dev, O=birlawhite, L=jodhpur, S=Rajasthan, C=IN"
)

Set-StrictMode -Version Latest

$root = Split-Path -Parent $PSCommandPath
if (-not $root) { $root = Get-Location }

$propFile = Join-Path $root "..\key.properties"
if (-not (Test-Path $propFile)) {
    Write-Error "key.properties not found at project root ($propFile). Create it first and re-run."
    exit 1
}

# Diagnostics: create a small log file next to project root
$logFile = Join-Path $root "..\keystore_create.log"
"=== create_keystore.ps1 run at $(Get-Date -Format o) ===" | Out-File -FilePath $logFile -Encoding utf8
"Using key.properties at: $propFile" | Out-File -FilePath $logFile -Append -Encoding utf8

# Parse simple key=value properties (ignores comments and blank lines)
$props = @{}
Get-Content $propFile | ForEach-Object {
    $line = $_.Trim()
    if ([string]::IsNullOrWhiteSpace($line) -or $line -match '^#') { return }
    $parts = $line -split '=', 2
    if ($parts.Length -eq 2) {
        $k = $parts[0].Trim()
        $v = $parts[1].Trim()
        $props[$k] = $v
    }
}

"Parsed properties keys: $($props.Keys -join ', ')" | Out-File -FilePath $logFile -Append -Encoding utf8

$required = @('storeFile','keyAlias','storePassword','keyPassword')
foreach ($r in $required) {
    if (-not $props.ContainsKey($r)) {
        Write-Error "Missing required property '$r' in key.properties"
        exit 1
    }
}

$storeFile = $props['storeFile']
$alias = $props['keyAlias']
$storePass = $props['storePassword']
$keyPass = $props['keyPassword']

$absStorePath = Join-Path $root "..\$storeFile"
$absStoreDir = Split-Path $absStorePath -Parent
if (-not (Test-Path $absStoreDir)) {
    Write-Host "Creating keystore directory: $absStoreDir"
    New-Item -ItemType Directory -Path $absStoreDir -Force | Out-Null
}

if (Test-Path $absStorePath) {
    if (-not $Force) {
        Write-Host "Keystore already exists at: $absStorePath"
        Write-Host "Re-run with -Force to overwrite. Aborting."
        "Keystore already exists at: $absStorePath (aborting without -Force)" | Out-File -FilePath $logFile -Append -Encoding utf8
        exit 1
    }
    else {
        Write-Host "Overwriting existing keystore at: $absStorePath"
        "Overwriting existing keystore at: $absStorePath" | Out-File -FilePath $logFile -Append -Encoding utf8
        Remove-Item $absStorePath -Force
    }
}

# Ensure keytool is available
if (-not (Get-Command keytool -ErrorAction SilentlyContinue)) {
    Write-Error "keytool not found in PATH. Install a JDK and ensure 'keytool' is available in PATH."
    "keytool not found in PATH" | Out-File -FilePath $logFile -Append -Encoding utf8
    exit 1
}

Write-Host "Generating keystore at: $absStorePath"
"Attempting to generate keystore at: $absStorePath" | Out-File -FilePath $logFile -Append -Encoding utf8

$argList = @(
    '-genkeypair',
    '-v',
    '-keystore', $absStorePath,
    '-alias', $alias,
    '-keyalg', 'RSA',
    '-keysize', '2048',
    '-validity', '10000',
    '-storepass', $storePass,
    '-keypass', $keyPass,
    '-dname', $DName
)

Write-Host "Running: keytool with non-interactive options..."
"keytool command args (passwords masked): -genkeypair -v -keystore $absStorePath -alias $alias -keyalg RSA -keysize 2048 -validity 10000 -storepass ***** -keypass ***** -dname $DName" | Out-File -FilePath $logFile -Append -Encoding utf8
try {
    $proc = Start-Process -FilePath 'keytool' -ArgumentList $argList -NoNewWindow -Wait -PassThru -WindowStyle Hidden
    if ($proc.ExitCode -eq 0) {
        Write-Host "Keystore created successfully: $absStorePath"
        "keytool exit code 0; keystore created" | Out-File -FilePath $logFile -Append -Encoding utf8
    }
    else {
        Write-Error "keytool exited with code $($proc.ExitCode)"
        "keytool exited with code $($proc.ExitCode)" | Out-File -FilePath $logFile -Append -Encoding utf8
        exit $proc.ExitCode
    }
}
catch {
    Write-Error "Failed to run keytool: $_"
    "Exception running keytool: $_" | Out-File -FilePath $logFile -Append -Encoding utf8
    exit 1
}

Write-Host "Done. Keep a secure backup of the keystore and passwords."
"Finished run at $(Get-Date -Format o)" | Out-File -FilePath $logFile -Append -Encoding utf8
