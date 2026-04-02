@echo off
echo ==========================================
echo Firebase Emulator Başlatılıyor...
echo ==========================================

REM Functions'ları derle
echo [1/4] TypeScript kodları derleniyor...
cd functions
call npm run build
if errorlevel 1 (
    echo ❌ Build hatası! Lütfen hataları kontrol edin.
    pause
    exit /b 1
)

echo ✅ Build tamamlandı!
cd ..

REM Firebase projesi ayarlarını kontrol et
echo [2/4] Firebase projesi kontrol ediliyor...
firebase use device-streaming-70d2d53c
if errorlevel 1 (
    echo ❌ Firebase projesi ayarlanamadı!
    pause
    exit /b 1
)

echo ✅ Firebase projesi ayarlandı!

REM Emulator'ı başlat
echo [3/4] Firebase emulator başlatılıyor...
echo.
echo 🚀 Emulator UI: http://localhost:4000
echo 🔧 Functions: http://localhost:5002
echo 💾 Storage: http://localhost:9199
echo.
echo ⚠️  Emulator'ı durdurmak için Ctrl+C tuşuna basın
echo.

REM Emulator'ı inspect mode ile başlat
firebase emulators:start --only functions,storage --inspect-functions

echo [4/4] Emulator durduruldu.
pause
