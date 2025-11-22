@echo off
echo Getting SHA-1 fingerprint for Google Maps API...
echo.

cd android
call gradlew signingReport

echo.
echo ========================================
echo Copy the SHA-1 from "Variant: debug" section above
echo Then add it to Google Cloud Console:
echo 1. Go to APIs & Services > Credentials
echo 2. Click on your API Key
echo 3. Under "Application restrictions" > "Android apps"
echo 4. Add package name: com.example.food_delivery_fbase
echo 5. Add SHA-1 fingerprint
echo ========================================
pause
































