# =============================================================
#  setup-debug.ps1  –  Astanakarya Debug Setup untuk HP Fisik
#  Jalankan dengan: klik kanan → "Run with PowerShell" (Admin)
# =============================================================

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "     ASTANAKARYA - Setup Debug HP Fisik" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ── Cek apakah berjalan sebagai Administrator ──────────────────
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")

if (-not $isAdmin) {
    Write-Host "[!] Script ini harus dijalankan sebagai Administrator!" -ForegroundColor Red
    Write-Host "    Klik kanan file ini → 'Run with PowerShell'" -ForegroundColor Yellow
    Write-Host "    atau klik kanan → 'Run as Administrator'" -ForegroundColor Yellow
    pause
    exit 1
}

# ── Buka Firewall untuk port 3000 ──────────────────────────────
Write-Host "[1/3] Mengatur Windows Firewall untuk port 3000..." -ForegroundColor Yellow

$ruleName = "Astanakarya Backend Port 3000"
$existingRule = netsh advfirewall firewall show rule name="$ruleName" 2>$null

if ($existingRule -match "No rules match") {
    netsh advfirewall firewall add rule name="$ruleName" dir=in action=allow protocol=TCP localport=3000 | Out-Null
    Write-Host "    ✅ Rule firewall berhasil ditambahkan!" -ForegroundColor Green
} else {
    Write-Host "    ✅ Rule firewall sudah ada, skip." -ForegroundColor Green
}

# ── Tampilkan IP yang aktif ────────────────────────────────────
Write-Host ""
Write-Host "[2/3] IP Address yang tersedia di komputer ini:" -ForegroundColor Yellow

$ips = Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.PrefixOrigin -ne "WellKnown" -and $_.IPAddress -ne "127.0.0.1" }

if ($ips.Count -eq 0) {
    Write-Host "    [!] Tidak ada IP jaringan aktif ditemukan!" -ForegroundColor Red
    Write-Host "    Pastikan komputer terhubung ke WiFi." -ForegroundColor Yellow
} else {
    foreach ($ip in $ips) {
        Write-Host "    📶 $($ip.IPAddress)  ($($ip.InterfaceAlias))" -ForegroundColor Green
    }
}

# ── Update app_config.dart jika IP berubah ────────────────────
Write-Host ""
Write-Host "[3/3] Cek konfigurasi app_config.dart..." -ForegroundColor Yellow

$configFile = Join-Path $PSScriptRoot "lib\services\app_config.dart"
$currentContent = Get-Content $configFile -Raw

# Ambil IP WiFi utama (bukan VPN/VMware)
$wifiIp = $ips | Where-Object { $_.InterfaceAlias -notlike "*VMware*" -and $_.InterfaceAlias -notlike "*VirtualBox*" -and $_.InterfaceAlias -notlike "*Loopback*" } | Select-Object -First 1

if ($wifiIp) {
    $newIpUrl = "http://$($wifiIp.IPAddress):3000"
    if ($currentContent -match "http://192\.168\.100\.187:3000") {
        $oldIpUrl = "http://192.168.100.187:3000"
        if ($newIpUrl -ne $oldIpUrl) {
            Write-Host "    [!] IP berubah dari $oldIpUrl ke $newIpUrl" -ForegroundColor Yellow
            Write-Host "    Update file app_config.dart secara manual jika diperlukan." -ForegroundColor Yellow
        } else {
            Write-Host "    ✅ IP di app_config.dart sudah sesuai: $newIpUrl" -ForegroundColor Green
        }
    }
}

# ── Panduan debugging ──────────────────────────────────────────
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  📱 CARA DEBUG DI HP FISIK:" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  1. Pastikan HP & PC terhubung ke WiFi yang SAMA" -ForegroundColor White
Write-Host "  2. Di terminal pertama, jalankan backend:" -ForegroundColor White
Write-Host "     cd backend && npm run dev" -ForegroundColor Yellow
Write-Host ""
Write-Host "  3. Perhatikan output server, cari baris 'Network:'" -ForegroundColor White
Write-Host "     Contoh: http://192.168.100.187:3000" -ForegroundColor Yellow
Write-Host ""
Write-Host "  4. Di terminal kedua, jalankan Flutter dengan IP server:" -ForegroundColor White
Write-Host "     flutter run --dart-define=PUIMEY_API_BASE_URL=http://192.168.100.187:3000" -ForegroundColor Yellow
Write-Host ""
Write-Host "  ATAU gunakan auto-detect (tanpa dart-define):" -ForegroundColor White
Write-Host "     flutter run" -ForegroundColor Yellow
Write-Host "     (App akan otomatis scan jaringan untuk server)" -ForegroundColor Gray
Write-Host ""
Write-Host "  5. Untuk enable USB debugging di HP Android:" -ForegroundColor White
Write-Host "     Settings → About Phone → ketuk Build Number 7x" -ForegroundColor Gray
Write-Host "     Settings → Developer Options → USB Debugging ON" -ForegroundColor Gray
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "  ✅ Setup selesai! Firewall port 3000 sudah terbuka." -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

pause
