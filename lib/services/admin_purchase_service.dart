import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/purchase_order_model.dart';
import 'auth_service.dart';

class AdminPurchaseService {
  static const String _baseUrl = '/api/purchases/orders';

  final String _serverBaseUrl = AuthService.serverBaseUrl;

  Future<http.Response> getBookings({
    String? status,
    String? from,
    String? to,
  }) async {
    try {
      final token = _getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (from != null && from.isNotEmpty) queryParams['from'] = from;
      if (to != null && to.isNotEmpty) queryParams['to'] = to;

      final uri = Uri.parse('$_serverBaseUrl$_baseUrl')
          .replace(queryParameters: queryParams);

      return await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  Future<http.Response> getBookingDetail(int bookingId) async {
    try {
      final token = _getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      return await http
          .get(
            Uri.parse('$_serverBaseUrl$_baseUrl/$bookingId'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  Future<http.Response> confirmBooking(int bookingId) async {
    try {
      final token = _getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      return await http
          .patch(
            Uri.parse('$_serverBaseUrl$_baseUrl/$bookingId/status'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'status': 'confirmed'}),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  Future<http.Response> rejectBooking(int bookingId, String reason) async {
    try {
      final token = _getToken();
      if (token == null) throw Exception('Token tidak ditemukan');

      return await http
          .patch(
            Uri.parse('$_serverBaseUrl$_baseUrl/$bookingId/status'),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'status': 'rejected',
              'rejectionReason': reason,
            }),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      return http.Response(jsonEncode({'error': e.toString()}), 500);
    }
  }

  List<PurchaseOrderModel> parseBookings(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final purchases = json['purchases'] as List<dynamic>? ?? [];
      return purchases
          .map((p) => PurchaseOrderModel.fromJson(p as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  PurchaseOrderModel? parseBookingDetail(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      final purchase = json['purchase'] as Map<String, dynamic>?;
      if (purchase == null) return null;
      return PurchaseOrderModel.fromJson(purchase);
    } catch (_) {
      return null;
    }
  }

  String parseMessage(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['message'] as String? ?? 'Operasi gagal';
    } catch (_) {
      return 'Terjadi kesalahan';
    }
  }

  String? _getToken() {
    final session = AuthService().getSession();
    final token = (session?['token'] ?? '').toString();
    return token.isEmpty ? null : token;
  }
}
