class BuyerRecord {
  final int id;
  final int? linkedUserId;
  final String fullName;
  final String? phone;
  final String? email;
  final String? address;
  final String? notes;
  final String dataSource;
  final String? dataLabel;
  final String verificationStatus;
  final int? verifiedByUserId;
  final DateTime? verifiedAt;
  final int recordedByUserId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Joined fields
  final String? linkedUserName;
  final String? linkedUserEmail;
  final String? linkedUserPhone;
  final String? recordedByName;
  final String? verifiedByName;

  const BuyerRecord({
    required this.id,
    this.linkedUserId,
    required this.fullName,
    this.phone,
    this.email,
    this.address,
    this.notes,
    required this.dataSource,
    this.dataLabel,
    required this.verificationStatus,
    this.verifiedByUserId,
    this.verifiedAt,
    required this.recordedByUserId,
    this.createdAt,
    this.updatedAt,
    this.linkedUserName,
    this.linkedUserEmail,
    this.linkedUserPhone,
    this.recordedByName,
    this.verifiedByName,
  });

  factory BuyerRecord.fromJson(Map<String, dynamic> json) {
    return BuyerRecord(
      id: _toInt(json['id']) ?? 0,
      linkedUserId: _toInt(json['linkedUserId']),
      fullName: json['fullName']?.toString() ?? '',
      phone: _toOptionalText(json['phone']),
      email: _toOptionalText(json['email']),
      address: _toOptionalText(json['address']),
      notes: _toOptionalText(json['notes']),
      dataSource: json['dataSource']?.toString() ?? 'manual_admin',
      dataLabel: _toOptionalText(json['dataLabel']),
      verificationStatus: json['verificationStatus']?.toString() ?? 'unverified',
      verifiedByUserId: _toInt(json['verifiedByUserId']),
      verifiedAt: _toDateTime(json['verifiedAt']),
      recordedByUserId: _toInt(json['recordedByUserId']) ?? 0,
      createdAt: _toDateTime(json['createdAt']),
      updatedAt: _toDateTime(json['updatedAt']),
      linkedUserName: _toOptionalText(json['linkedUserName']),
      linkedUserEmail: _toOptionalText(json['linkedUserEmail']),
      linkedUserPhone: _toOptionalText(json['linkedUserPhone']),
      recordedByName: _toOptionalText(json['recordedByName']),
      verifiedByName: _toOptionalText(json['verifiedByName']),
    );
  }

  String get dataSourceLabel {
    switch (dataSource) {
      case 'app_registration':
        return 'Registrasi Mobile App';
      case 'historical_company':
        return 'Kantor Pemasaran (Direct)';
      case 'manual_admin':
      default:
        return 'Kantor Pemasaran (Direct)';
    }
  }

  String get verificationStatusLabel {
    switch (verificationStatus) {
      case 'verified':
        return 'Data Terverifikasi';
      case 'pending_verification':
        return 'Menunggu Verifikasi';
      case 'unverified':
      default:
        return 'Belum Diverifikasi';
    }
  }

  bool get isLinkedToApp => linkedUserId != null;
  bool get isVerified => verificationStatus == 'verified';
  bool get isSimulation => dataLabel?.toUpperCase() == 'SIMULASI';
}

class HistoricalSale {
  final int id;
  final int buyerRecordId;
  final int? propertyId;
  final String propertyNameSnapshot;
  final DateTime? transactionDate;
  final int? transactionValue;
  final String? paymentMethod;
  final String status;
  final String? notes;
  final String? dataLabel;
  final int recordedByUserId;
  final DateTime? recordedAt;
  final DateTime? updatedAt;
  // Joined fields
  final String? buyerFullName;
  final String? buyerPhone;
  final String? buyerDataSource;
  final String? recordedByName;
  final String? propertyTitleCurrent;
  final String? propertyLocation;
  final String? propertyStatusCurrent;
  final String? propertyThumbnailUrl;

  const HistoricalSale({
    required this.id,
    required this.buyerRecordId,
    this.propertyId,
    required this.propertyNameSnapshot,
    this.transactionDate,
    this.transactionValue,
    this.paymentMethod,
    required this.status,
    this.notes,
    this.dataLabel,
    required this.recordedByUserId,
    this.recordedAt,
    this.updatedAt,
    this.buyerFullName,
    this.buyerPhone,
    this.buyerDataSource,
    this.recordedByName,
    this.propertyTitleCurrent,
    this.propertyLocation,
    this.propertyStatusCurrent,
    this.propertyThumbnailUrl,
  });

  factory HistoricalSale.fromJson(Map<String, dynamic> json) {
    return HistoricalSale(
      id: _toInt(json['id']) ?? 0,
      buyerRecordId: _toInt(json['buyerRecordId']) ?? 0,
      propertyId: _toInt(json['propertyId']),
      propertyNameSnapshot: json['propertyNameSnapshot']?.toString() ?? '',
      transactionDate: _toDate(json['transactionDate']),
      transactionValue: _toInt(json['transactionValue']),
      paymentMethod: _toOptionalText(json['paymentMethod']),
      status: json['status']?.toString() ?? 'completed',
      notes: _toOptionalText(json['notes']),
      dataLabel: _toOptionalText(json['dataLabel']),
      recordedByUserId: _toInt(json['recordedByUserId']) ?? 0,
      recordedAt: _toDateTime(json['recordedAt']),
      updatedAt: _toDateTime(json['updatedAt']),
      buyerFullName: _toOptionalText(json['buyerFullName']),
      buyerPhone: _toOptionalText(json['buyerPhone']),
      buyerDataSource: _toOptionalText(json['buyerDataSource']),
      recordedByName: _toOptionalText(json['recordedByName']),
      propertyTitleCurrent: _toOptionalText(json['propertyTitleCurrent']),
      propertyLocation: _toOptionalText(json['propertyLocation']),
      propertyStatusCurrent: _toOptionalText(json['propertyStatusCurrent']),
      propertyThumbnailUrl: _toOptionalText(json['propertyThumbnailUrl']),
    );
  }

  String get statusLabel {
    switch (status) {
      case 'completed':
        return 'Selesai';
      case 'pending':
        return 'Dalam Proses';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  bool get isSimulation => dataLabel?.toUpperCase() == 'SIMULASI';
}

class BuyerRecordActivity {
  final BuyerRecord buyerRecord;
  final List<HistoricalSale> historicalSales;
  final List<Map<String, dynamic>> onlinePurchases;
  final List<Map<String, dynamic>> surveys;

  const BuyerRecordActivity({
    required this.buyerRecord,
    required this.historicalSales,
    required this.onlinePurchases,
    required this.surveys,
  });

  factory BuyerRecordActivity.fromJson(Map<String, dynamic> json) {
    return BuyerRecordActivity(
      buyerRecord: BuyerRecord.fromJson(json['buyerRecord'] as Map<String, dynamic>),
      historicalSales: (json['historicalSales'] as List? ?? [])
          .whereType<Map>()
          .map((e) => HistoricalSale.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      onlinePurchases: (json['onlinePurchases'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
      surveys: (json['surveys'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(),
    );
  }

  int get totalTransactions => historicalSales.length + onlinePurchases.length;
  int get confirmedOnlinePurchases =>
      onlinePurchases.where((p) => p['status'] == 'confirmed').length;
  int get completedHistoricalSales =>
      historicalSales.where((s) => s.status == 'completed').length;
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

int? _toInt(dynamic v) {
  if (v == null) return null;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim());
}

String? _toOptionalText(dynamic v) {
  final t = v?.toString().trim();
  if (t == null || t.isEmpty || t.toLowerCase() == 'null') return null;
  return t;
}

DateTime? _toDateTime(dynamic v) {
  if (v == null) return null;
  try {
    return DateTime.parse(v.toString());
  } catch (_) {
    return null;
  }
}

DateTime? _toDate(dynamic v) {
  if (v == null) return null;
  try {
    final s = v.toString().split('T').first;
    return DateTime.parse(s);
  } catch (_) {
    return null;
  }
}
