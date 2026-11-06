import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/admin_models.dart';
import '../models/buyer_record_model.dart';
import '../models/purchase_order_model.dart';
import 'auth_service.dart';

class AdminSalesReportResult {
  final double totalRevenue;
  final List<PurchaseOrderModel> transactions;
  final List<HistoricalSale> historicalSales;

  const AdminSalesReportResult({
    required this.totalRevenue,
    required this.transactions,
    this.historicalSales = const [],
  });
}

class AdminAvailabilityReportResult {
  final List<AdminAvailabilitySummaryModel> summary;
  final List<AdminPropertyModel> properties;

  const AdminAvailabilityReportResult({
    required this.summary,
    required this.properties,
  });
}

class AdminReportService {
  static String get _apiBaseUrl =>
      '${AuthService.serverBaseUrl}/api/admin/reports';

  Future<ApiResponse> getGlobalReport({
    DateTime? from,
    DateTime? to,
    int? month,
    int? year,
  }) =>
      _get(_reportUri('global', from: from, to: to, month: month, year: year));

  Future<ApiResponse> getSalesReport({
    DateTime? from,
    DateTime? to,
    int? month,
    int? year,
  }) => _get(_reportUri('sales', from: from, to: to, month: month, year: year));

  Future<ApiResponse> getAvailabilityReport({
    DateTime? from,
    DateTime? to,
    int? month,
    int? year,
  }) => _get(
    _reportUri('availability', from: from, to: to, month: month, year: year),
  );

  Future<ApiResponse> getTransactions({
    String? status,
    String? historicalStatus,
    DateTime? from,
    DateTime? to,
    int? month,
    int? year,
  }) => _get(
    _reportUri(
      'transactions',
      status: status,
      historicalStatus: historicalStatus,
      from: from,
      to: to,
      month: month,
      year: year,
    ),
    allowStaff: true,
  );

  AdminGlobalReportModel parseGlobalReport(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic> || decoded['report'] is! Map) {
      throw const FormatException('Data laporan global tidak valid');
    }
    return AdminGlobalReportModel.fromJson(
      Map<String, dynamic>.from(decoded['report'] as Map),
    );
  }

  AdminSalesReportResult parseSalesReport(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>)
      return const AdminSalesReportResult(
        totalRevenue: 0,
        transactions: [],
        historicalSales: [],
      );
    final raw = decoded['transactions'];
    final transactions = raw is List
        ? raw
              .whereType<Map>()
              .map(
                (item) => PurchaseOrderModel.fromJson(
                  Map<String, dynamic>.from(item),
                ),
              )
              .toList()
        : <PurchaseOrderModel>[];
    final rawHistoricalSales = decoded['historicalSales'];
    final historicalSales = rawHistoricalSales is List
        ? rawHistoricalSales
              .whereType<Map>()
              .map(
                (item) =>
                    HistoricalSale.fromJson(Map<String, dynamic>.from(item)),
              )
              .toList()
        : <HistoricalSale>[];
    return AdminSalesReportResult(
      totalRevenue: _toDouble(decoded['totalRevenue']),
      transactions: transactions,
      historicalSales: historicalSales,
    );
  }

  AdminAvailabilityReportResult parseAvailabilityReport(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic>) {
      return const AdminAvailabilityReportResult(summary: [], properties: []);
    }
    final rawSummary = decoded['summary'];
    final rawProperties = decoded['properties'];
    return AdminAvailabilityReportResult(
      summary: rawSummary is List
          ? rawSummary
                .whereType<Map>()
                .map(
                  (item) => AdminAvailabilitySummaryModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
      properties: rawProperties is List
          ? rawProperties
                .whereType<Map>()
                .map(
                  (item) => AdminPropertyModel.fromJson(
                    Map<String, dynamic>.from(item),
                  ),
                )
                .toList()
          : const [],
    );
  }

  List<PurchaseOrderModel> parseTransactions(String body) {
    final decoded = jsonDecode(body);
    if (decoded is! Map<String, dynamic> || decoded['transactions'] is! List)
      return const [];
    return (decoded['transactions'] as List)
        .whereType<Map>()
        .map(
          (item) =>
              PurchaseOrderModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  String parseMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic> && decoded['message'] != null)
        return decoded['message'].toString();
    } catch (_) {
      return 'Terjadi kesalahan';
    }
    return 'Terjadi kesalahan';
  }

  Future<ApiResponse> _get(Uri uri, {bool allowStaff = false}) async {
    final token = _token(allowStaff: allowStaff);
    if (token == null) {
      return ApiResponse(
        statusCode: 401,
        body: jsonEncode({'message': 'Sesi admin tidak ditemukan'}),
      );
    }

    try {
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );
      return ApiResponse(statusCode: response.statusCode, body: response.body);
    } catch (_) {
      return ApiResponse(
        statusCode: 500,
        body: jsonEncode({'message': 'Tidak dapat terhubung ke backend'}),
      );
    }
  }

  String? _token({bool allowStaff = false}) {
    final session = AuthService().getSession();
    if ((session?['sessionState'] ?? '').toString() != SessionState.verified) {
      return null;
    }
    final role = (session?['role'] ?? '').toString();
    if (role != UserRoles.admin && (!allowStaff || role != UserRoles.staf)) {
      return null;
    }
    final token = (session?['token'] ?? '').toString();
    return token.isEmpty ? null : token;
  }

  String _date(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  Uri _reportUri(
    String path, {
    String? status,
    String? historicalStatus,
    DateTime? from,
    DateTime? to,
    int? month,
    int? year,
  }) {
    final params = <String, String>{};
    if (status?.trim().isNotEmpty ?? false) params['status'] = status!.trim();
    if (historicalStatus?.trim().isNotEmpty ?? false) {
      params['historicalStatus'] = historicalStatus!.trim();
    }
    if (from != null) params['from'] = _date(from);
    if (to != null) params['to'] = _date(to);
    if (month != null) params['month'] = month.toString();
    if (year != null) params['year'] = year.toString();
    return Uri.parse(
      '$_apiBaseUrl/$path',
    ).replace(queryParameters: params.isEmpty ? null : params);
  }

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }
}
