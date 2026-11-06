class SurveyRequestModel {
  final int id;
  final int buyerUserId;
  final String buyerName;
  final String? buyerPhone;
  final String? buyerEmail;
  final int propertyId;
  final String propertyTitle;
  final String propertyLocation;
  final String propertyImageUrl;
  final String requestedDate;
  final String? requestedTime;
  final String? notes;
  final String status;
  final String? approvedScheduleDate;
  final String? approvedScheduleTime;
  final String? rejectionReason;
  final int? processedByUserId;
  final String? processedByName;
  final String? processedByPhone;
  final String? processedAt;
  final String? createdAt;
  final String? updatedAt;

  const SurveyRequestModel({
    required this.id,
    required this.buyerUserId,
    required this.buyerName,
    this.buyerPhone,
    this.buyerEmail,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyLocation,
    required this.propertyImageUrl,
    required this.requestedDate,
    required this.requestedTime,
    required this.notes,
    required this.status,
    required this.approvedScheduleDate,
    required this.approvedScheduleTime,
    required this.rejectionReason,
    required this.processedByUserId,
    required this.processedByName,
    this.processedByPhone,
    required this.processedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory SurveyRequestModel.fromJson(Map<String, dynamic> json) {
    final id = _toInt(json['id']) ?? _toInt(json['id_survey']) ?? _toInt(json['idSurvei']) ?? _toInt(json['idSurvey']);
    final buyerUserId = _toInt(json['buyerUserId']);
    final propertyId = _toInt(json['propertyId']);

    if (id == null || buyerUserId == null || propertyId == null) {
      throw const FormatException('Data survei tidak valid');
    }

    return SurveyRequestModel(
      id: id,
      buyerUserId: buyerUserId,
      buyerName: _toText(json['buyerName']),
      buyerPhone: _toOptionalText(json['buyerPhone'] ?? json['buyer_phone']),
      buyerEmail: _toOptionalText(json['buyerEmail'] ?? json['buyer_email']),
      propertyId: propertyId,
      propertyTitle: _toText(json['propertyTitle']),
      propertyLocation: _toText(json['propertyLocation']),
      propertyImageUrl: _toText(json['propertyImageUrl']),
      requestedDate: _toText(json['requestedDate']),
      requestedTime: _toOptionalText(json['requestedTime']),
      notes: _toOptionalText(json['notes']),
      status: _toText(json['status']),
      approvedScheduleDate: _toOptionalText(json['approvedScheduleDate']),
      approvedScheduleTime: _toOptionalText(json['approvedScheduleTime']),
      rejectionReason: _toOptionalText(json['rejectionReason']),
      processedByUserId: _toInt(json['processedByUserId']),
      processedByName: _toOptionalText(json['processedByName']),
      processedByPhone: _toOptionalText(json['processedByPhone'] ?? json['processed_by_phone']),
      processedAt: _toOptionalText(json['processedAt']),
      createdAt: _toOptionalText(json['createdAt']),
      updatedAt: _toOptionalText(json['updatedAt']),
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isCompleted => status == 'completed';
  bool get isRejected => status == 'rejected';
  bool get isCancelled => status == 'cancelled';

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      final normalized = value.trim();
      if (normalized.isEmpty) {
        return null;
      }
      return int.tryParse(normalized);
    }

    return null;
  }

  static String _toText(dynamic value) => value?.toString() ?? '';

  static String? _toOptionalText(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text.toLowerCase() == 'null') {
      return null;
    }
    return text;
  }
}
