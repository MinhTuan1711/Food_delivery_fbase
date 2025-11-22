@echo off
echo ========================================
echo Getting SHA-1 Certificate Fingerprint
echo ========================================
echo.

keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

echo.
echo ========================================
echo INSTRUCTIONS:
echo 1. Find the line "SHA1:" above
echo 2. Copy the SHA-1 value (format: AA:BB:CC:DD:...)
echo 3. Go to Google Cloud Console
echo 4. APIs & Services > Credentials
echo 5. Click on your API Key
echo 6. Under "Application restrictions" > "Android apps"
echo 7. Add package name: com.example.food_delivery_fbase
echo 8. Add the SHA-1 fingerprint you copied
echo 9. Click Save
echo ========================================
pause
































