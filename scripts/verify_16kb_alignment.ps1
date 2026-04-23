# Script to verify 16 KB page size alignment in AAB/APK
# Usage: .\scripts\verify_16kb_alignment.ps1

param(
    [string]$AabPath = "build\app\outputs\bundle\release\app-release.aab",
    [string]$BundletoolPath = ""
)

Write-Host "=== 16 KB Page Size Alignment Verification ===" -ForegroundColor Cyan
Write-Host ""

# Check if AAB exists
if (-not (Test-Path $AabPath)) {
    Write-Host "ERROR: AAB file not found at: $AabPath" -ForegroundColor Red
    Write-Host "Error: AAB file not found at: $AabPath" -ForegroundColor Red
}

Write-Host "AAB found: $AabPath" -ForegroundColor Green
Write-Host "  File size: $([math]::Round((Get-Item $AabPath).Length / 1MB, 2)) MB" -ForegroundColor Gray
Write-Host ""

# Check for bundletool
$bundletoolFound = $false
if ($BundletoolPath -and (Test-Path $BundletoolPath)) {
    $bundletoolFound = $true
    Write-Host "Using bundletool: $BundletoolPath" -ForegroundColor Green
} else {
    # Try to find bundletool in common locations
    $possiblePaths = @(
        "$env:USERPROFILE\.android\bundletool.jar",
        "$env:LOCALAPPDATA\Android\Sdk\bundletool.jar",
        ".\bundletool.jar"
    )

    foreach ($path in $possiblePaths) {
        if (Test-Path $path) {
            $BundletoolPath = $path
            $bundletoolFound = $true
            Write-Host "Found bundletool: $BundletoolPath" -ForegroundColor Green
            break
        }
    }
}

if (-not $bundletoolFound) {
    Write-Host "WARNING: bundletool not found. To verify alignment manually:" -ForegroundColor Yellow
    Write-Host "  1) Download bundletool: https://github.com/google/bundletool/releases" -ForegroundColor Gray
    Write-Host "  2) Use Android Studio > Build > Analyze APK... and inspect the lib/ folder alignment" -ForegroundColor Gray
    Write-Host "Alternatively, build an APK and use zipalign:" -ForegroundColor Yellow
    Write-Host "  flutter build apk --release" -ForegroundColor Gray
    Write-Host "  zipalign -c -P 16 -v 4 build\app\outputs\flutter-apk\app-release.apk" -ForegroundColor Gray
    Write-Host ""
} else {
    Write-Host "Extracting APK from AAB for verification..." -ForegroundColor Cyan
    $tempDir = Join-Path $env:TEMP ("aab_verification_{0}" -f (Get-Random))
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        $apksPath = Join-Path $tempDir "app.apks"
        # Build APK set from AAB (universal)
        & java -jar $BundletoolPath build-apks --bundle=$AabPath --output=$apksPath --mode=universal 2>&1 | Out-Null

        if (Test-Path $apksPath) {
            Write-Host "APK set created: $apksPath" -ForegroundColor Green

Write-Host "✓ AAB file found: $AabPath" -ForegroundColor Green
            Expand-Archive -Path $apksPath -DestinationPath $extractDir -Force

            $universalApk = Get-ChildItem -Path $extractDir -Filter "universal.apk" -Recurse -ErrorAction SilentlyContinue | Select-Object -First 1

            if ($universalApk) {
                Write-Host "Universal APK extracted: $($universalApk.FullName)" -ForegroundColor Green
                Write-Host "Checking zip alignment..." -ForegroundColor Cyan

    Write-Host "✓ Using bundletool: $BundletoolPath" -ForegroundColor Green
                $sdkPath = $env:ANDROID_HOME
                if (-not $sdkPath) { $sdkPath = "$env:LOCALAPPDATA\Android\Sdk" }

                $zipalignPath = Join-Path $sdkPath "build-tools\35.0.0\zipalign.exe"
                if (-not (Test-Path $zipalignPath)) {
                    $buildToolsDirs = Get-ChildItem -Path (Join-Path $sdkPath 'build-tools') -Directory -ErrorAction SilentlyContinue | Sort-Object Name -Descending
                    if ($buildToolsDirs) { $zipalignPath = Join-Path $buildToolsDirs[0].FullName 'zipalign.exe' }


                if (Test-Path $zipalignPath) {
                    Write-Host "Using zipalign: $zipalignPath" -ForegroundColor Gray
                    $result = & $zipalignPath -c -P 16 -v 4 $universalApk.FullName 2>&1
            Write-Host "✓ Found bundletool: $BundletoolPath" -ForegroundColor Green

                    if ($result -match "Verification successful") {
                        Write-Host "16 KB ALIGNMENT VERIFICATION SUCCESSFUL" -ForegroundColor Green
                    } elseif ($result -match "Verification FAILED") {
                        Write-Host "ALIGNMENT VERIFICATION FAILED" -ForegroundColor Red
                    } else {
    Write-Host "⚠ Bundletool not found. To verify alignment:" -ForegroundColor Yellow
    Write-Host "  1. Download bundletool from: https://github.com/google/bundletool/releases" -ForegroundColor Gray
    Write-Host "  2. Use Android Studio's APK Analyzer (Build > Analyze APK...)" -ForegroundColor Gray
    Write-Host "  3. Check the Alignment column for any warnings" -ForegroundColor Gray
    Write-Host ""
                    Write-Host "WARNING: zipalign not found. Inspect the APK using Android Studio APK Analyzer." -ForegroundColor Yellow
                }
            } else {
                Write-Host "ERROR: Universal APK not found inside apks set." -ForegroundColor Red

    $tempDir = "$env:TEMP\aab_verification_$(Get-Random)"
    # Extract APK from AAB using bundletool
        } else {
        # Build APK set from AAB
        $apksPath = "$tempDir\app.apks"
        java -jar $BundletoolPath build-apks --bundle=$AabPath --output=$apksPath --mode=universal 2>&1 | Out-Null

        Remove-Item -Path $tempDir -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "✓ APK set created" -ForegroundColor Green

            # Extract universal APK
            $extractDir = "$tempDir\extracted"
Write-Host ""

            $universalApk = Get-ChildItem -Path $extractDir -Filter "universal.apk" -Recurse | Select-Object -First 1

                Write-Host "✓ Universal APK extracted" -ForegroundColor Green
                Write-Host ""
                Write-Host "Checking alignment..." -ForegroundColor Cyan

                # Check for zipalign
