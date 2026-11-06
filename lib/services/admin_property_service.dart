import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

import '../models/admin_models.dart';
import 'auth_service.dart';

class AdminPropertyService {
  static String get _apiBaseUrl =>
      '${AuthService.serverBaseUrl}/api/admin/properties';

  Future<ApiResponse> getProperties() async => _request('GET', _apiBaseUrl);

  Future<ApiResponse> createProperty(AdminPropertyModel property) async {
    return _request('POST', _apiBaseUrl, body: property.toJson());
  }

  Future<ApiResponse> updateProperty(AdminPropertyModel property) async {
    return _request(
      'PATCH',
      '$_apiBaseUrl/${property.id}',
      body: property.toJson(),
    );
  }

  Future<ApiResponse> deleteProperty(int id) async {
    return _request('DELETE', '$_apiBaseUrl/$id');
  }

  Future<ApiResponse> deleteImage(int imageId) async {
    return _request('DELETE', '$_apiBaseUrl/images/$imageId');
  }

  Future<ApiResponse> uploadPropertyImages(int propertyId, List<List<int>> filesData, List<String> fileNames) async {
    final token = _token();
    if (token == null) return _unauthorizedResponse();

    try {
      final uri = Uri.parse('$_apiBaseUrl/$propertyId/images');
      var request = http.MultipartRequest('POST', uri);
      request.headers['Authorization'] = 'Bearer $token';

      for (int i = 0; i < filesData.length; i++) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'images',
            filesData[i],
            filename: fileNames[i],
            contentType: _contentTypeFor(fileNames[i]),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return ApiResponse(
        statusCode: 500,
        body: jsonEncode({'message': 'Tidak dapat mengunggah gambar'}),
      );
    }
  }

  List<AdminPropertyModel> parseProperties(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic> || decoded['properties'] is! List)
      return const [];
    return (decoded['properties'] as List)
        .whereType<Map>()
        .map(
          (item) =>
              AdminPropertyModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  String parseMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['message'] != null) {
        return decoded['message'].toString();
      }
    } catch (_) {
      return 'Terjadi kesalahan';
    }
    return 'Terjadi kesalahan';
  }

  Future<ApiResponse> _request(
    String method,
    String url, {
    Map<String, dynamic>? body,
  }) async {
    final token = _token();
    if (token == null) return _unauthorizedResponse();

    try {
      final uri = Uri.parse(url);
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };
      final encoded = body == null ? null : jsonEncode(body);
      final response = switch (method) {
        'POST' => await http.post(uri, headers: headers, body: encoded),
        'PATCH' => await http.patch(uri, headers: headers, body: encoded),
        'DELETE' => await http.delete(uri, headers: headers),
        _ => await http.get(uri, headers: headers),
      };
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return ApiResponse(
        statusCode: 500,
        body: jsonEncode({'message': 'Tidak dapat terhubung ke backend'}),
      );
    }
  }

  String? _token() {
    final session = AuthService().getSession();
    if ((session?['sessionState'] ?? '').toString() != SessionState.verified) {
      return null;
    }
    if ((session?['role'] ?? '').toString() != UserRoles.admin) {
      return null;
    }
    final token = (session?['token'] ?? '').toString();
    return token.isEmpty ? null : token;
  }

  MediaType _contentTypeFor(String filename) {
    final ext = filename.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
        return MediaType('image', 'png');
      case 'webp':
        return MediaType('image', 'webp');
      default:
        return MediaType('image', 'jpeg');
    }
  }

  ApiResponse _unauthorizedResponse() => ApiResponse(
    statusCode: 401,
    body: jsonEncode({'message': 'Sesi tidak ditemukan'}),
  );
}
