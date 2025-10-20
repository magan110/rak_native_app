@echo off
echo ========================================
echo Flutter App Clean and Restart Script
echo ========================================
echo.

echo Step 1: Stopping any running Flutter processes...
taskkill /F /IM dart.exe /T 2>nul
taskkill /F /IM flutter.exe /T 2>nul
timeout /t 2 /nobreak >nul

echo Step 2: Removing build directory...
if exist "build" (
    rmdir /s /q "build" 2>nul
    timeout /t 1 /nobreak >nul
)

echo Step 3: Running flutter clean...
flutter clean

echo Step 4: Getting dependencies...
flutter pub get

echo Step 5: Starting Flutter app...
echo.
echo ========================================
echo App is starting...
echo ========================================
echo.
flutter run

pause
