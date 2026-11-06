import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';

enum UserRole { staf, admin, pembeli }

extension UserRoleValue on UserRole {
  String get value => name;

  String get label {
    switch (this) {
      case UserRole.staf:
        return 'Staf Pemasaran';
      case UserRole.admin:
        return 'Administrasi';
      case UserRole.pembeli:
        return 'Calon Pembeli';
    }
  }
}

class UserRoles {
  static const String staf = 'staf';
  static const String admin = 'admin';
  static const String pembeli = 'pembeli';

  static UserRole parse(String? rawRole) {
    switch ((rawRole ?? '').toLowerCase().trim()) {
      case staf:
        return UserRole.staf;
      case admin:
        return UserRole.admin;
      case pembeli:
      default:
        return UserRole.pembeli;
    }
  }

  static String normalize(String? rawRole) => parse(rawRole).value;

  static String label(String role) => parse(role).label;
}

class SessionState {
  static const String verified = 'verified';
  static const String cachedUnverified = 'cached_unverified';
  static const String invalid = 'invalid';
}

class ApiResponse {
  final int statusCode;
  final String body;

  const ApiResponse({required this.statusCode, required this.body});
}

class AuthService {
  static const String _sessionStorageKey = 'auth_session';
  static const String _tokenStorageKey = 'auth_token';
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();
  static const Duration _requestTimeout = Duration(seconds: 15);

  static String get _apiBaseUrl => AppConfig.authApiBaseUrl;
  static String get _serverBaseUrl => AppConfig.serverBaseUrl;
  static String get serverBaseUrl => _serverBaseUrl;

  static Map<String, dynamic>? _session;

  Future<ApiResponse> loginUser(String email, String password) async {
    debugPrint('[AUTH_DEBUG] loginUser dipanggil dengan email: $email');
    if (email.trim().isEmpty || password.isEmpty) {
      debugPrint('[AUTH_DEBUG] loginUser gagal: email atau password kosong');
      return ApiResponse(
        statusCode: 400,
        body: jsonEncode({'message': 'Email dan kata sandi wajib diisi'}),
      );
    }

    try {
      final url = '$_apiBaseUrl/login';
      debugPrint('[AUTH_DEBUG] Mengirim POST request ke $url');
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'password': password}),
          )
          .timeout(_requestTimeout);

      debugPrint('[AUTH_DEBUG] Response POST $url: Status ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _decodeJsonObject(response.body);
        await saveSession(data, sessionState: SessionState.verified);
      }

      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (e, stack) {
      debugPrint('[AUTH_DEBUG] Exception pada loginUser: $e\n$stack');
      return ApiResponse(
        statusCode: 500,
        body: jsonEncode({'message': 'Tidak dapat terhubung ke backend'}),
      );
    }
  }

  Future<ApiResponse> socialLoginUser({
    required String provider,
    required String email,
    required String name,
    String? providerId,
    String? photoUrl,
  }) async {
    debugPrint('[AUTH_DEBUG] socialLoginUser dipanggil provider: $provider, email: $email');
    if (email.trim().isEmpty || name.trim().isEmpty) {
      return ApiResponse(
        statusCode: 400,
        body: jsonEncode({'message': 'Data akun sosial tidak lengkap'}),
      );
    }

    try {
      final url = '$_apiBaseUrl/social-login';
      debugPrint('[AUTH_DEBUG] Mengirim POST request ke $url');
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'provider': provider,
              'email': email.trim(),
              'name': name.trim(),
              if (providerId != null) 'providerId': providerId,
              if (photoUrl != null) 'photoUrl': photoUrl,
            }),
          )
          .timeout(_requestTimeout);

      debugPrint('[AUTH_DEBUG] Response POST $url: Status ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _decodeJsonObject(response.body);
        await saveSession(data, sessionState: SessionState.verified);
      }

      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (e, stack) {
      debugPrint('[AUTH_DEBUG] Exception pada socialLoginUser: $e\n$stack');
      return ApiResponse(
        statusCode: 500,
        body: jsonEncode({'message': 'Tidak dapat terhubung ke backend'}),
      );
    }
  }

  Future<ApiResponse> registerUser(
    String name,
    String email,
    String phone,
    String password, {
    String role = 'pembeli',
  }) async {
    debugPrint('[AUTH_DEBUG] registerUser dipanggil untuk: $email (role: $role)');
    if (name.trim().isEmpty ||
        email.trim().isEmpty ||
        phone.trim().isEmpty ||
        password.isEmpty) {
      debugPrint('[AUTH_DEBUG] registerUser gagal: ada field kosong');
      return ApiResponse(
        statusCode: 400,
        body: jsonEncode({'message': 'Semua field wajib diisi'}),
      );
    }

    try {
      final url = '$_apiBaseUrl/register';
      debugPrint('[AUTH_DEBUG] Mengirim POST request ke $url');
      final response = await http
          .post(
            Uri.parse(url),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': name.trim(),
              'email': email.trim(),
              'phone': phone.trim(),
              'password': password,
              'role': role,
            }),
          )
          .timeout(_requestTimeout);

      debugPrint('[AUTH_DEBUG] Response POST $url: Status ${response.statusCode}');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _decodeJsonObject(response.body);
        await saveSession(data, sessionState: SessionState.verified);
      }

      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (e, stack) {
      debugPrint('[AUTH_DEBUG] Exception pada registerUser: $e\n$stack');
      return ApiResponse(
        statusCode: 500,
        body: jsonEncode({'message': 'Tidak dapat terhubung ke backend'}),
      );
    }
  }

  Future<ApiResponse> forgotPassword(String email) async {
    if (email.trim().isEmpty) {
      return ApiResponse(
        statusCode: 400,
        body: jsonEncode({'message': 'Email wajib diisi'}),
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/forgot-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim()}),
          )
          .timeout(_requestTimeout);

      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return ApiResponse(
        statusCode: 500,
        body: jsonEncode({'message': 'Tidak dapat terhubung ke backend'}),
      );
    }
  }

  Future<ApiResponse> verifyResetCode(String email, String code) async {
    if (email.trim().isEmpty || code.trim().isEmpty) {
      return ApiResponse(
        statusCode: 400,
        body: jsonEncode({'message': 'Email dan kode verifikasi wajib diisi'}),
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/verify-reset-code'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email.trim(), 'code': code.trim()}),
          )
          .timeout(_requestTimeout);

      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return ApiResponse(
        statusCode: 500,
        body: jsonEncode({'message': 'Tidak dapat terhubung ke backend'}),
      );
    }
  }

  Future<ApiResponse> resetPassword(
    String email,
    String resetToken,
    String newPassword,
  ) async {
    if (email.trim().isEmpty ||
        resetToken.trim().isEmpty ||
        newPassword.isEmpty) {
      return ApiResponse(
        statusCode: 400,
        body: jsonEncode({'message': 'Data reset password belum lengkap'}),
      );
    }

    try {
      final response = await http
          .post(
            Uri.parse('$_apiBaseUrl/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'resetToken': resetToken.trim(),
              'newPassword': newPassword,
            }),
          )
          .timeout(_requestTimeout);

      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return ApiResponse(
        statusCode: 500,
        body: jsonEncode({'message': 'Tidak dapat terhubung ke backend'}),
      );
    }
  }

  Future<ApiResponse> uploadProfilePhoto(XFile photo) async {
    if (!hasVerifiedSession) {
      return _verificationRequiredResponse();
    }

    final token = await _readToken();
    if (token.isEmpty) {
      return _unauthorizedResponse();
    }

    try {
      final bytes = await photo.readAsBytes();
      final filename = _resolveUploadFilename(photo);

      final request =
          http.MultipartRequest('POST', Uri.parse('$_apiBaseUrl/profile-photo'))
            ..headers['Authorization'] = 'Bearer $token'
            ..files.add(
              http.MultipartFile.fromBytes(
                'photo',
                bytes,
                filename: filename,
                contentType: _resolveContentType(filename),
              ),
            );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = _decodeJsonObject(response.body);
        await updateSessionUser(
          data['user'],
          sessionState: SessionState.verified,
        );
      }

      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return ApiResponse(
        statusCode: 500,
        body: jsonEncode({'message': 'Gagal mengunggah foto profil'}),
      );
    }
  }

  Future<Map<String, dynamic>?> restoreSession() async {
    debugPrint('[AUTH_DEBUG] restoreSession dipanggil. Sesi in-memory: ${_session != null ? "Ada" : "Null"}');
    if (_session != null) {
      debugPrint('[AUTH_DEBUG] Menggunakan sesi in-memory yang sudah ada');
      return _session;
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionStorageKey);
    final token = await _readToken();
    debugPrint('[AUTH_DEBUG] Storage token ditemukan: ${token.isNotEmpty ? "YA" : "TIDAK"}');
    if ((raw == null || raw.isEmpty) && token.isEmpty) {
      debugPrint('[AUTH_DEBUG] Tidak ada sesi atau token di storage');
      return null;
    }

    try {
      final decoded = raw == null || raw.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        debugPrint('[AUTH_DEBUG] Format sesi di storage tidak valid, membersihkan sesi');
        await clearSession();
        return null;
      }

      _session = {
        ...Map<String, dynamic>.from(decoded),
        'token': token,
        'sessionState': token.isEmpty
            ? SessionState.invalid
            : SessionState.cachedUnverified,
      };

      if (token.isEmpty) {
        debugPrint('[AUTH_DEBUG] Token kosong saat restore, membersihkan sesi');
        await clearSession();
        return null;
      }

      debugPrint('[AUTH_DEBUG] Memulai verifikasi sesi dari storage');
      return await verifySession();
    } catch (e, stack) {
      debugPrint('[AUTH_DEBUG] Exception saat restoreSession: $e\n$stack');
      await clearSession();
      return null;
    }
  }

  Future<Map<String, dynamic>?> verifySession() async {
    debugPrint('[AUTH_DEBUG] verifySession dipanggil');
    String token = (_session?['token'] ?? '').toString();
    if (token.isEmpty) {
      token = await _readToken();
    }

    if (token.isEmpty) {
      debugPrint('[AUTH_DEBUG] verifySession gagal: token kosong');
      await clearSession();
      return null;
    }

    _session = {
      ...?_session,
      'token': token,
      'sessionState':
          (_session?['sessionState'] ?? SessionState.cachedUnverified)
              .toString(),
    };

    try {
      final url = '$_apiBaseUrl/me';
      debugPrint('[AUTH_DEBUG] Mengirim GET request verifikasi sesi ke $url');
      final response = await http
          .get(
            Uri.parse(url),
            headers: {'Authorization': 'Bearer $token'},
          )
          .timeout(_requestTimeout);

      debugPrint('[AUTH_DEBUG] Response GET $url: Status ${response.statusCode}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        debugPrint('[AUTH_DEBUG] Token kedaluwarsa atau tidak valid, membersihkan sesi');
        await clearSession();
        return null;
      }

      if (response.statusCode < 200 || response.statusCode >= 300) {
        debugPrint('[AUTH_DEBUG] Gagal verifikasi sesi (offline/server error), menggunakan sesi cache');
        _session = {
          ...?_session,
          'token': token,
          'sessionState': SessionState.cachedUnverified,
        };
        await _persistSession();
        return getSession();
      }

      final data = _decodeJsonObject(response.body);
      debugPrint('[AUTH_DEBUG] Sesi berhasil diverifikasi oleh server');
      await updateSessionUser(
        data['user'],
        sessionState: SessionState.verified,
      );
      return getSession();
    } catch (e, stack) {
      debugPrint('[AUTH_DEBUG] Exception saat verifySession: $e\n$stack');
      debugPrint('[AUTH_DEBUG] Menggunakan sesi cache (offline)');
      _session = {
        ...?_session,
        'token': token,
        'sessionState': SessionState.cachedUnverified,
      };
      await _persistSession();
      return getSession();
    }
  }

  Future<void> saveSession(
    Map<String, dynamic> data, {
    String? fallbackName,
    String? fallbackEmail,
    String sessionState = SessionState.verified,
  }) async {
    final user = _normalizeUser(data['user']);
    final resolvedRole = UserRoles.normalize(user['role']?.toString());
    final token = (data['token'] ?? '').toString();

    debugPrint('[AUTH_DEBUG] saveSession dipanggil. Token disimpan: ${token.isNotEmpty ? "YA" : "TIDAK"} (Role: $resolvedRole)');

    _session = {
      'token': token,
      'id': user['id'],
      'name': (user['name'] ?? fallbackName ?? 'Pengguna').toString(),
      'email': (user['email'] ?? fallbackEmail ?? '').toString(),
      'phone': (user['phone'] ?? '').toString(),
      'role': resolvedRole,
      'profilePhotoPath': _normalizeProfilePhotoPath(
        user['profilePhotoPath']?.toString(),
      ),
      'sessionState': sessionState,
    };

    await _persistSession();
  }

  Future<void> updateSessionUser(
    dynamic rawUser, {
    String? sessionState,
  }) async {
    if (_session == null) {
      return;
    }

    final user = _normalizeUser(rawUser);

    _session = {
      ...?_session,
      'id': user['id'] ?? _session?['id'],
      'name': (user['name'] ?? _session?['name'] ?? 'Pengguna').toString(),
      'email': (user['email'] ?? _session?['email'] ?? '').toString(),
      'phone': (user['phone'] ?? _session?['phone'] ?? '').toString(),
      'role': UserRoles.normalize(
        user['role']?.toString() ?? _session?['role']?.toString(),
      ),
      'profilePhotoPath': _normalizeProfilePhotoPath(
        user['profilePhotoPath']?.toString() ??
            _session?['profilePhotoPath']?.toString(),
      ),
      'sessionState':
          sessionState ??
          _session?['sessionState'] ??
          SessionState.cachedUnverified,
    };

    await _persistSession();
  }

  Map<String, dynamic>? getSession() =>
      _session == null ? null : Map<String, dynamic>.from(_session!);

  bool get hasSession {
    final token = (_session?['token'] ?? '').toString();
    return token.isNotEmpty;
  }

  bool get hasVerifiedSession =>
      (_session?['sessionState'] ?? '').toString() == SessionState.verified;

  bool get hasCachedUnverifiedSession =>
      (_session?['sessionState'] ?? '').toString() ==
      SessionState.cachedUnverified;

  ApiResponse verificationRequiredResponse([
    String message =
        'Perlu tersambung ke server untuk memverifikasi sesi Anda.',
  ]) => ApiResponse(statusCode: 403, body: jsonEncode({'message': message}));

  String? resolveProfilePhotoUrl(String? profilePhotoPath) {
    final normalized = _normalizeProfilePhotoPath(profilePhotoPath);
    if (normalized == null) {
      return null;
    }

    return '$_serverBaseUrl$normalized';
  }

  Future<void> clearSession() async {
    debugPrint('[AUTH_DEBUG] clearSession dipanggil (Logout)');
    _session = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionStorageKey);
    if (kIsWeb) {
      await prefs.remove(_tokenStorageKey);
    } else {
      await _secureStorage.delete(key: _tokenStorageKey);
    }
    debugPrint('[AUTH_DEBUG] Sesi dan storage berhasil dibersihkan');
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = (_session?['token'] ?? '').toString();
    final sessionForPrefs = <String, dynamic>{...?_session}..remove('token');

    if (kIsWeb) {
      if (token.isEmpty) {
        await prefs.remove(_tokenStorageKey);
      } else {
        await prefs.setString(_tokenStorageKey, token);
      }
    } else {
      if (token.isEmpty) {
        await _secureStorage.delete(key: _tokenStorageKey);
      } else {
        await _secureStorage.write(key: _tokenStorageKey, value: token);
      }
    }

    await prefs.setString(_sessionStorageKey, jsonEncode(sessionForPrefs));
  }

  Future<String> _readToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return (prefs.getString(_tokenStorageKey) ?? '').trim();
    }
    return (await _secureStorage.read(key: _tokenStorageKey) ?? '').trim();
  }

  Map<String, dynamic> _decodeJsonObject(String body) {
    final decoded = jsonDecode(body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    return <String, dynamic>{};
  }

  Map<String, dynamic> _normalizeUser(dynamic rawUser) {
    if (rawUser is Map<String, dynamic>) {
      return rawUser;
    }
    if (rawUser is Map) {
      return Map<String, dynamic>.from(rawUser);
    }
    return <String, dynamic>{};
  }

  String _resolveUploadFilename(XFile photo) {
    final name = photo.name.trim();
    if (name.isNotEmpty) {
      return name;
    }

    final path = photo.path.trim();
    if (path.isNotEmpty) {
      final normalized = path.replaceAll('\\', '/');
      final parts = normalized.split('/');
      final last = parts.isNotEmpty ? parts.last.trim() : '';
      if (last.isNotEmpty) {
        return last;
      }
    }

    return 'profile-photo.jpg';
  }

  MediaType _resolveContentType(String filename) {
    final normalized = filename.toLowerCase();

    if (normalized.endsWith('.png')) {
      return MediaType('image', 'png');
    }
    if (normalized.endsWith('.webp')) {
      return MediaType('image', 'webp');
    }

    return MediaType('image', 'jpeg');
  }

  String? _normalizeProfilePhotoPath(String? profilePhotoPath) {
    final value = (profilePhotoPath ?? '').trim();
    return value.isEmpty ? null : value;
  }

  ApiResponse _unauthorizedResponse() => ApiResponse(
    statusCode: 401,
    body: jsonEncode({'message': 'Sesi login tidak ditemukan'}),
  );

  ApiResponse _verificationRequiredResponse() => verificationRequiredResponse();
}
