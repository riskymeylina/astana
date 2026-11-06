import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Konfigurasi global aplikasi yang cerdas dan otomatis mendeteksi server backend.
/// Dapat bekerja di:
/// 1. Flutter Web (localhost:3000)
/// 2. HP Fisik via USB/Kabel (adb reverse localhost:3000)
/// 3. HP Fisik via Wi-Fi sama (IP LAN 192.168.100.187:3000 atau subnet lokal lainnya)
/// 4. HP Fisik di Wi-Fi Beda / Kuota Data / Semua Jaringan (Cloud Public Tunnel)
/// 5. Custom URL yang tersimpan di memori HP jika user ingin mengubahnya manual
class AppConfig {
  AppConfig._();

  static const String _prefServerUrlKey = 'custom_backend_server_url';
  static const String _buildServerUrl = String.fromEnvironment(
    'PUIMEY_API_BASE_URL',
    defaultValue: '',
  );

  // Daftar kandidat endpoint backend yang dicek secara otomatis secara paralel/berurutan
  static const List<String> _candidateUrls = [
    'http://localhost:3000', // USB ADB Reverse & Web & Emulator
    'http://10.0.2.2:3000', // Android Studio Emulator standard loopback
    'http://192.168.100.187:3000', // IP Wi-Fi PC saat ini
    'https://cool-groups-hammer.loca.lt', // Public Cloud Tunnel (akses dari semua wifi/seluler)
  ];

  static String _serverBaseUrl = 'http://localhost:3000';

  /// Inisialisasi konfigurasi. Dipanggil sekali di [main].
  static Future<void> initialize() async {
    if (_buildServerUrl.trim().isNotEmpty) {
      _serverBaseUrl = _cleanUrl(_buildServerUrl);
      debugPrint('[AppConfig] Menggunakan backend dari build: $_serverBaseUrl');
      return;
    }

    if (kIsWeb) {
      _serverBaseUrl = 'http://localhost:3000';
      debugPrint(
        '[AppConfig] Flutter Web mode: serverBaseUrl = $_serverBaseUrl',
      );
      return;
    }

    // 1. Cek apakah ada custom URL yang tersimpan di SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString(_prefServerUrlKey);
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        final healthy = await _testHealth(savedUrl.trim());
        if (healthy) {
          _serverBaseUrl = _cleanUrl(savedUrl);
          debugPrint('[AppConfig] Menggunakan Saved URL: $_serverBaseUrl');
          return;
        }
      }
    } catch (_) {}

    // 2. Deteksi otomatis secara paralel ke semua kandidat URL
    final activeUrl = await _detectActiveServerUrl();
    if (activeUrl != null) {
      _serverBaseUrl = _cleanUrl(activeUrl);
      debugPrint(
        '[AppConfig] Server aktif terdeteksi otomatis: $_serverBaseUrl',
      );
    } else {
      // Fallback default: localhost (didukung oleh adb reverse di HP fisik)
      _serverBaseUrl = 'http://localhost:3000';
      debugPrint(
        '[AppConfig] Tidak ada server merespons cepat, fallback ke $_serverBaseUrl',
      );
    }
  }

  /// Tes konektivitas /api/health ke suatu base URL dengan timeout singkat
  static Future<bool> _testHealth(String baseUrl) async {
    try {
      final uri = Uri.parse('${_cleanUrl(baseUrl)}/api/health');
      final res = await http
          .get(uri, headers: {'bypass-tunnel-reminder': '1'})
          .timeout(const Duration(milliseconds: 1800));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Menemukan URL yang pertama kali merespons 200 OK
  static Future<String?> _detectActiveServerUrl() async {
    final completer = Completer<String?>();
    int pending = _candidateUrls.length;

    for (final url in _candidateUrls) {
      _testHealth(url)
          .then((isHealthy) {
            if (!completer.isCompleted) {
              if (isHealthy) {
                completer.complete(url);
              } else {
                pending--;
                if (pending <= 0) {
                  completer.complete(null);
                }
              }
            }
          })
          .catchError((_) {
            if (!completer.isCompleted) {
              pending--;
              if (pending <= 0) {
                completer.complete(null);
              }
            }
          });
    }

    // Maksimal tunggu 2.5 detik untuk pendeteksian otomatis
    return completer.future.timeout(
      const Duration(milliseconds: 2500),
      onTimeout: () => null,
    );
  }

  /// Bersihkan slash di akhir URL
  static String _cleanUrl(String url) {
    var trimmed = url.trim();
    while (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  /// Mengizinkan pengubahan server URL secara manual jika diinginkan pengguna
  static Future<void> setCustomServerUrl(String newUrl) async {
    _serverBaseUrl = _cleanUrl(newUrl);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefServerUrlKey, _serverBaseUrl);
    } catch (_) {}
    debugPrint('[AppConfig] Server URL diubah ke: $_serverBaseUrl');
  }

  /// URL dasar server backend, contoh: http://localhost:3000 atau https://cool-groups-hammer.loca.lt
  static String get serverBaseUrl => _serverBaseUrl;

  /// URL dasar API autentikasi, contoh: [serverBaseUrl]/api/auth
  static String get authApiBaseUrl => '$_serverBaseUrl/api/auth';

  /// URL dasar API umum, contoh: [serverBaseUrl]/api
  static String get apiBaseUrl => '$_serverBaseUrl/api';
}
