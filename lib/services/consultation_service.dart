import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../models/consultation_request_model.dart';
import 'auth_service.dart';

class ConsultationService {
  static String get _apiBaseUrl =>
      '${AuthService.serverBaseUrl}/api/consultations';

  Future<ApiResponse> createConsultationRequest({
    int? propertyId,
    required String topic,
    required String preferredContactMethod,
    required String message,
  }) async {
    final token = _getToken();
    if (token == null) {
      return _unauthorizedResponse();
    }

    try {
      final response = await http.post(
        Uri.parse(_apiBaseUrl),
        headers: _headers(token),
        body: jsonEncode({
          'propertyId': propertyId,
          'topic': topic,
          'preferredContactMethod': preferredContactMethod,
          'message': message,
        }),
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> getMyConsultationRequests() async {
    final token = _getToken();
    if (token == null) {
      return _unauthorizedResponse();
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/my-requests'),
        headers: _headers(token),
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> getMyConsultationRoom() async {
    final token = _getToken();
    if (token == null) {
      return _unauthorizedResponse();
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/my-room'),
        headers: _headers(token),
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> getStaffConsultationRequests({String? status}) async {
    final token = _getToken(requireVerifiedSession: true);
    if (token == null) {
      return _unauthorizedResponse(requireVerifiedSession: true);
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl/requests').replace(
        queryParameters: status == null || status.trim().isEmpty
            ? null
            : {'status': status.trim()},
      );
      final response = await http.get(uri, headers: _headers(token));
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> getConsultationDetail(int consultationId) async {
    final token = _getToken();
    if (token == null) {
      return _unauthorizedResponse();
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/$consultationId'),
        headers: _headers(token),
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> getConsultationChats() async {
    final token = _getToken();
    if (token == null) {
      return _unauthorizedResponse();
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/chats'),
        headers: _headers(token),
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> updateConsultationStatus({
    required int consultationId,
    required String status,
    String? staffNotes,
  }) async {
    final token = _getToken(requireVerifiedSession: true);
    if (token == null) {
      return _unauthorizedResponse(requireVerifiedSession: true);
    }

    try {
      final response = await http.patch(
        Uri.parse('$_apiBaseUrl/$consultationId/status'),
        headers: _headers(token),
        body: jsonEncode({'status': status, 'staffNotes': staffNotes}),
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> getConsultationMessages(int consultationId) async {
    final token = _getToken();
    if (token == null) {
      return _unauthorizedResponse();
    }

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/$consultationId/messages'),
        headers: _headers(token),
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> sendConsultationMessage({
    required int consultationId,
    required String message,
  }) async {
    final token = _getToken();
    if (token == null) {
      return _unauthorizedResponse();
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/$consultationId/messages'),
        headers: _headers(token),
        body: jsonEncode({'message': message}),
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> sendConsultationMedia({
    required int consultationId,
    required XFile mediaFile,
    String? message,
  }) async {
    final token = _getToken();
    if (token == null) {
      return _unauthorizedResponse();
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl/$consultationId/messages/media');
      final file = kIsWeb
          ? http.MultipartFile.fromBytes(
              'media',
              await mediaFile.readAsBytes(),
              filename: mediaFile.name,
              contentType: _mimeTypeOf(mediaFile.name),
            )
          : await http.MultipartFile.fromPath(
              'media',
              mediaFile.path,
              filename: mediaFile.name,
              contentType: _mimeTypeOf(mediaFile.name),
            );
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['message'] = message ?? ''
        ..files.add(file);

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      return ApiResponse(statusCode: streamed.statusCode, body: body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> sendConsultationPickedFile({
    required int consultationId,
    required PlatformFile file,
    String? message,
  }) async {
    final token = _getToken();
    if (token == null) {
      return _unauthorizedResponse();
    }

    try {
      final uri = Uri.parse('$_apiBaseUrl/$consultationId/messages/media');
      final bytes = await file.readAsBytes();
      final multipart = http.MultipartFile.fromBytes(
        'media',
        bytes,
        filename: file.name,
        contentType: _mimeTypeOf(file.name),
      );
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['message'] = message ?? ''
        ..files.add(multipart);

      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      return ApiResponse(statusCode: streamed.statusCode, body: body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  List<ConsultationRequestModel> parseConsultations(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return const [];
    }

    final rawItems = decoded['consultations'];
    if (rawItems is! List) {
      return const [];
    }

    final consultations = <ConsultationRequestModel>[];
    for (final item in rawItems.whereType<Map>()) {
      try {
        consultations.add(
          ConsultationRequestModel.fromJson(Map<String, dynamic>.from(item)),
        );
      } on FormatException {
        continue;
      }
    }
    return consultations;
  }

  List<ConsultationRequestModel> parseChats(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return const [];
    }

    final rawItems = decoded['chats'];
    if (rawItems is! List) {
      return const [];
    }

    final chats = <ConsultationRequestModel>[];
    for (final item in rawItems.whereType<Map>()) {
      try {
        chats.add(
          ConsultationRequestModel.fromJson(Map<String, dynamic>.from(item)),
        );
      } on FormatException {
        continue;
      }
    }
    return chats;
  }

  ConsultationRequestModel parseConsultation(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic> || decoded['consultation'] is! Map) {
        throw const FormatException('Data konsultasi tidak valid');
      }

      return ConsultationRequestModel.fromJson(
        Map<String, dynamic>.from(decoded['consultation'] as Map),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Data konsultasi tidak valid');
    }
  }

  List<ConsultationChatMessageModel> parseMessages(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic> || decoded['messages'] is! List) {
      return const [];
    }

    final messages = <ConsultationChatMessageModel>[];
    for (final item in (decoded['messages'] as List).whereType<Map>()) {
      try {
        messages.add(
          ConsultationChatMessageModel.fromJson(
            Map<String, dynamic>.from(item),
          ),
        );
      } on FormatException {
        continue;
      }
    }
    return messages;
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

  String? _getToken({bool requireVerifiedSession = false}) {
    final session = AuthService().getSession();
    final state = (session?['sessionState'] ?? '').toString();
    if (requireVerifiedSession && state != SessionState.verified) {
      return null;
    }

    final token = (session?['token'] ?? '').toString();
    return token.isEmpty ? null : token;
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  MediaType _mimeTypeOf(String filename) {
    final ext = filename.toLowerCase();
    if (ext.endsWith('.png')) return MediaType('image', 'png');
    if (ext.endsWith('.webp')) return MediaType('image', 'webp');
    if (ext.endsWith('.mp3')) return MediaType('audio', 'mpeg');
    if (ext.endsWith('.m4a')) return MediaType('audio', 'mp4');
    if (ext.endsWith('.webm')) return MediaType('audio', 'webm');
    if (ext.endsWith('.wav')) return MediaType('audio', 'wav');
    if (ext.endsWith('.pdf')) return MediaType('application', 'pdf');
    return MediaType('image', 'jpeg');
  }

  ApiResponse _networkErrorResponse() => ApiResponse(
    statusCode: 500,
    body: jsonEncode({'message': 'Tidak dapat terhubung ke backend'}),
  );

  ApiResponse _unauthorizedResponse({bool requireVerifiedSession = false}) {
    final session = AuthService().getSession();
    final state = (session?['sessionState'] ?? '').toString();
    if (requireVerifiedSession && state == SessionState.cachedUnverified) {
      return AuthService().verificationRequiredResponse();
    }

    return ApiResponse(
      statusCode: 401,
      body: jsonEncode({'message': 'Sesi login tidak ditemukan'}),
    );
  }
}
