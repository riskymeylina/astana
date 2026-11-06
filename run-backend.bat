@echo off
chcp 65001 > nul
title Astanakarya - Debug HP Fisik

echo.
echo ============================================================
echo     ASTANAKARYA - Menjalankan Backend Server
echo ============================================================
echo.

:: Dapatkan IP WiFi
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /i "IPv4"') do (
    set RAW_IP=%%a
    goto :found_ip
)
:found_ip
:: Hapus spasi di depan
for /f "tokens=1" %%b in ("%RAW_IP%") do set LOCAL_IP=%%b

echo [*] IP Lokal terdeteksi: %LOCAL_IP%
echo.
echo [*] Memulai backend server...
echo     Backend URL untuk HP: http://%LOCAL_IP%:3000
echo.
echo ============================================================
echo  Flutter run command (jalankan di terminal lain):
echo.
echo  flutter run --dart-define=PUIMEY_API_BASE_URL=http://%LOCAL_IP%:3000
echo.
echo  ATAU cukup: flutter run  (auto-detect aktif)
echo ============================================================
echo.

cd /d "%~dp0backend"
npm run dev
