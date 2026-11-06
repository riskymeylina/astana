import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

import '../models/purchase_order_model.dart';
import 'auth_service.dart';

class PurchaseService {
  static String get _apiBaseUrl => '${AuthService.serverBaseUrl}/api/purchases';

  Future<ApiResponse> createPurchase({
    required int propertyId,
    required String paymentMethod,
    required String buyerName,
    String? buyerPhone,
    String? buyerAddress,
    String? notes,
  }) async {
    final token = _getToken();
    if (token == null) return _unauthorizedResponse();

    try {
      final response = await http.post(
        Uri.parse(_apiBaseUrl),
        headers: _headers(token),
        body: jsonEncode({
          'propertyId': propertyId,
          'paymentMethod': paymentMethod,
          'buyerName': buyerName,
          'buyerPhone': buyerPhone,
          'buyerAddress': buyerAddress,
          'notes': notes,
        }),
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> getMyOrders() async {
    final token = _getToken();
    if (token == null) return _unauthorizedResponse();

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/my-orders'),
        headers: _headers(token),
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> getAllOrders({
    String? status,
    String? search,
    DateTime? from,
    DateTime? to,
    int? month,
    int? year,
  }) async {
    // PERBAIKAN: requireVerifiedSession diubah menjadi false agar sesi tidak null otomatis
    final token = _getToken(requireVerifiedSession: false);
    if (token == null) {
      return _unauthorizedResponse(requireVerifiedSession: false);
    }

    try {
      final params = <String, String>{};
      if (status?.trim().isNotEmpty ?? false) params['status'] = status!.trim();
      if (search?.trim().isNotEmpty ?? false) params['search'] = search!.trim();
      if (from != null) params['from'] = _date(from);
      if (to != null) params['to'] = _date(to);
      if (month != null) params['month'] = month.toString();
      if (year != null) params['year'] = year.toString();
      final uri = Uri.parse(
        '$_apiBaseUrl/orders',
      ).replace(queryParameters: params.isEmpty ? null : params);
      final response = await http.get(uri, headers: _headers(token));
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> getOrderDetail(int purchaseId) async {
    final token = _getToken();
    if (token == null) return _unauthorizedResponse();

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/$purchaseId'),
        headers: _headers(token),
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> checkMidtransStatus(int purchaseId) async {
    final token = _getToken();
    if (token == null) return _unauthorizedResponse();

    try {
      final response = await http.get(
        Uri.parse('$_apiBaseUrl/$purchaseId/midtrans-status'),
        headers: _headers(token),
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> simulateMidtransPayment(int purchaseId) async {
    final token = _getToken();
    if (token == null) return _unauthorizedResponse();

    try {
      final response = await http.post(
        Uri.parse('$_apiBaseUrl/$purchaseId/simulate-payment'),
        headers: _headers(token),
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> uploadPaymentProof({
    required int purchaseId,
    required XFile imageFile,
  }) async {
    final token = _getToken();
    if (token == null) return _unauthorizedResponse();

    try {
      final uri = Uri.parse('$_apiBaseUrl/$purchaseId/payment-proof');
      final file = kIsWeb
          ? http.MultipartFile.fromBytes(
              'paymentProof',
              await imageFile.readAsBytes(),
              filename: imageFile.name,
              contentType: _mimeTypeOf(imageFile.name),
            )
          : await http.MultipartFile.fromPath(
              'paymentProof',
              imageFile.path,
              filename: imageFile.name,
              contentType: _mimeTypeOf(imageFile.name),
            );
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(file);

      final streamed = await request.send();
      final respBody = await streamed.stream.bytesToString();
      return ApiResponse(statusCode: streamed.statusCode, body: respBody);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  Future<ApiResponse> updateOrderStatus({
    required int purchaseId,
    required String status,
    String? rejectionReason,
  }) async {
    final token = _getToken(requireVerifiedSession: true);
    if (token == null) {
      return _unauthorizedResponse(requireVerifiedSession: true);
    }

    try {
      final response = await http.patch(
        Uri.parse('$_apiBaseUrl/$purchaseId/status'),
        headers: _headers(token),
        body: jsonEncode({
          'status': status,
          'rejectionReason': rejectionReason,
        }),
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return _networkErrorResponse();
    }
  }

  List<PurchaseOrderModel> parseOrders(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return const [];

    final raw = decoded['purchases'];
    if (raw is! List) return const [];

    final orders = <PurchaseOrderModel>[];
    for (final item in raw.whereType<Map>()) {
      try {
        orders.add(
          PurchaseOrderModel.fromJson(Map<String, dynamic>.from(item)),
        );
      } on FormatException {
        continue;
      }
    }
    return orders;
  }

  PurchaseOrderModel parseOrder(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is! Map<String, dynamic> || decoded['purchase'] is! Map) {
        throw const FormatException('Data pemesanan tidak valid');
      }
      return PurchaseOrderModel.fromJson(
        Map<String, dynamic>.from(decoded['purchase'] as Map),
      );
    } on FormatException {
      rethrow;
    } catch (_) {
      throw const FormatException('Data pemesanan tidak valid');
    }
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

  MediaType _mimeTypeOf(String filename) {
    final ext = filename.toLowerCase();
    if (ext.endsWith('.png')) return MediaType('image', 'png');
    if (ext.endsWith('.webp')) return MediaType('image', 'webp');
    return MediaType('image', 'jpeg');
  }

  String _date(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String? _getToken({bool requireVerifiedSession = false}) {
    final session = AuthService().getSession();
    final state = (session?['sessionState'] ?? '').toString();
    if (requireVerifiedSession && state != SessionState.verified) return null;
    final token = (session?['token'] ?? '').toString();
    return token.isEmpty ? null : token;
  }

  Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

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