import 'dart:convert';
import 'package:http/http.dart' as http;

import '../models/buyer_record_model.dart';
import 'auth_service.dart';

class AdminBuyerRecordService {
  static String get _base =>
      '${AuthService.serverBaseUrl}/api/admin/buyer-records';

  // ─── Buyer Records ─────────────────────────────────────────────────────────

  Future<ApiResponse> getBuyerRecords({
    String? search,
    String? dataSource,
    String? verificationStatus,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
    if (dataSource != null) params['dataSource'] = dataSource;
    if (verificationStatus != null) params['verificationStatus'] = verificationStatus;
    final uri = Uri.parse(_base).replace(queryParameters: params);
    return _request('GET', uri);

  }

  Future<ApiResponse> getBuyerRecord(int id) =>
      _request('GET', Uri.parse('$_base/$id'));

  Future<ApiResponse> getBuyerRecordActivity(int id) =>
      _request('GET', Uri.parse('$_base/$id/activity'));

  Future<ApiResponse> createBuyerRecord({
    required String fullName,
    String? phone,
    String? email,
    String? address,
    String? notes,
    required String dataSource,
    String? dataLabel,
    int? linkedUserId,
  }) =>
      _request('POST', Uri.parse(_base), body: {
        'fullName': fullName,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (email != null && email.isNotEmpty) 'email': email,
        if (address != null && address.isNotEmpty) 'address': address,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        'dataSource': dataSource,
        if (dataLabel != null && dataLabel.isNotEmpty) 'dataLabel': dataLabel,
        if (linkedUserId != null) 'linkedUserId': linkedUserId,
      });

  Future<ApiResponse> updateBuyerRecord({
    required int id,
    required String fullName,
    String? phone,
    String? email,
    String? address,
    String? notes,
    required String dataSource,
    String? dataLabel,
    int? linkedUserId,
  }) =>
      _request('PATCH', Uri.parse('$_base/$id'), body: {
        'fullName': fullName,
        'phone': phone ?? '',
        'email': email ?? '',
        'address': address ?? '',
        'notes': notes ?? '',
        'dataSource': dataSource,
        'dataLabel': dataLabel ?? '',
        if (linkedUserId != null) 'linkedUserId': linkedUserId,
      });

  Future<ApiResponse> verifyBuyerRecord({
    required int id,
    required String verificationStatus,
  }) =>
      _request('PATCH', Uri.parse('$_base/$id/verify'), body: {
        'verificationStatus': verificationStatus,
      });

  Future<ApiResponse> deleteBuyerRecord(int id) =>
      _request('DELETE', Uri.parse('$_base/$id'));

  // ─── Historical Sales ───────────────────────────────────────────────────────

  Future<ApiResponse> getHistoricalSales({
    int? buyerRecordId,
    int? propertyId,
    String? status,
    int page = 1,
    int limit = 50,
  }) {
    final params = <String, String>{
      'page': '$page',
      'limit': '$limit',
    };
    if (buyerRecordId != null) params['buyerRecordId'] = '$buyerRecordId';
    if (propertyId != null) params['propertyId'] = '$propertyId';
    if (status != null) params['status'] = status;
    final uri = Uri.parse('$_base/historical-sales/list')
        .replace(queryParameters: params);
    return _request('GET', uri);
  }

  Future<ApiResponse> createHistoricalSale({
    required int buyerRecordId,
    int? propertyId,
    required String propertyNameSnapshot,
    String? transactionDate,
    int? transactionValue,
    String? paymentMethod,
    String status = 'completed',
    String? notes,
    String? dataLabel,
  }) =>
      _request('POST', Uri.parse('$_base/historical-sales'), body: {
        'buyerRecordId': buyerRecordId,
        if (propertyId != null) 'propertyId': propertyId,
        'propertyNameSnapshot': propertyNameSnapshot,
        if (transactionDate != null) 'transactionDate': transactionDate,
        if (transactionValue != null) 'transactionValue': transactionValue,
        if (paymentMethod != null && paymentMethod.isNotEmpty) 'paymentMethod': paymentMethod,
        'status': status,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
        if (dataLabel != null && dataLabel.isNotEmpty) 'dataLabel': dataLabel,
      });

  Future<ApiResponse> updateHistoricalSale({
    required int id,
    int? propertyId,
    required String propertyNameSnapshot,
    String? transactionDate,
    int? transactionValue,
    String? paymentMethod,
    String status = 'completed',
    String? notes,
    String? dataLabel,
  }) =>
      _request('PATCH', Uri.parse('$_base/historical-sales/$id'), body: {
        if (propertyId != null) 'propertyId': propertyId,
        'propertyNameSnapshot': propertyNameSnapshot,
        'transactionDate': transactionDate ?? '',
        'transactionValue': transactionValue,
        'paymentMethod': paymentMethod ?? '',
        'status': status,
        'notes': notes ?? '',
        'dataLabel': dataLabel ?? '',
      });

  Future<ApiResponse> deleteHistoricalSale(int id) =>
      _request('DELETE', Uri.parse('$_base/historical-sales/$id'));

  // ─── Parse helpers ──────────────────────────────────────────────────────────

  List<BuyerRecord> parseBuyerRecords(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return const [];
    final list = decoded['buyerRecords'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => BuyerRecord.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  BuyerRecord? parseBuyerRecord(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;
    final d = decoded['buyerRecord'];
    if (d is! Map) return null;
    return BuyerRecord.fromJson(Map<String, dynamic>.from(d));
  }

  BuyerRecordActivity? parseBuyerRecordActivity(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return null;
    return BuyerRecordActivity.fromJson(decoded);
  }

  List<HistoricalSale> parseHistoricalSales(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return const [];
    final list = decoded['historicalSales'];
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => HistoricalSale.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  int parseTotalCount(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) return 0;
    return (decoded['total'] as num?)?.toInt() ?? 0;
  }

  String parseMessage(String body) {
    try {
      final d = jsonDecode(body);
      if (d is Map<String, dynamic> && d['message'] != null) {
        return d['message'].toString();
      }
    } catch (_) {}
    return 'Terjadi kesalahan';
  }

  // ─── Internal request helper ────────────────────────────────────────────────

  Future<ApiResponse> _request(String method, Uri uri,
      {Map<String, dynamic>? body}) async {
    final token = _token(adminOnly: method != 'GET');
    if (token == null) {
      return ApiResponse(
        statusCode: 401,
        body: jsonEncode({'message': 'Sesi admin tidak ditemukan'}),
      );
    }
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final encoded = body == null ? null : jsonEncode(body);
    try {
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

  String? _token({bool adminOnly = true}) {
    final session = AuthService().getSession();
    if ((session?['sessionState'] ?? '').toString() != SessionState.verified) {
      return null;
    }
    final role = (session?['role'] ?? '').toString();
    if (role != UserRoles.admin &&
        (adminOnly || role != UserRoles.staf)) {
      return null;
    }
    final token = (session?['token'] ?? '').toString();
    return token.isEmpty ? null : token;
  }
}
