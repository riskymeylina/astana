class AdminPropertyModel {
  final int id;
  final String title;
  final String category;
  final String location;
  final double price;
  final String status;
  final String? imageUrl;

  const AdminPropertyModel({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.price,
    required this.status,
    this.imageUrl,
  });

  factory AdminPropertyModel.fromJson(Map<String, dynamic> json) {
    String? img;
    if (json['imageUrl'] != null) {
      img = _toText(json['imageUrl']);
    } else if (json['gallery'] is List && (json['gallery'] as List).isNotEmpty) {
      final first = (json['gallery'] as List).first;
      if (first is Map && first['imageUrl'] != null) {
        img = _toText(first['imageUrl']);
      }
    }

    final rawStatus = _toText(json['status']).trim().toLowerCase();
    String mappedStatus = 'available';
    if (rawStatus == 'available' || rawStatus == 'tersedia') {
      mappedStatus = 'available';
    } else if (rawStatus == 'booking' || rawStatus == 'sedang dibooking') {
      mappedStatus = 'booking';
    } else if (rawStatus == 'sold' || rawStatus == 'terjual') {
      mappedStatus = 'sold';
    } else if (rawStatus == 'archived' || rawStatus == 'diarsipkan') {
      mappedStatus = 'archived';
    } else {
      mappedStatus = rawStatus.isNotEmpty ? rawStatus : 'available';
    }

    return AdminPropertyModel(
      id: _toInt(json['id'] ?? json['id_property']) ?? 0,
      title: _toText(json['title']),
      category: _toText(json['category']),
      location: _toText(json['location']),
      price: _toDouble(json['price']),
      status: mappedStatus,
      imageUrl: img,
    );
  }

  Map<String, dynamic> toJson() {
    String dbStatus = 'Tersedia';
    if (status == 'available') {
      dbStatus = 'Tersedia';
    } else if (status == 'booking') {
      dbStatus = 'Sedang Dibooking';
    } else if (status == 'sold') {
      dbStatus = 'Terjual';
    } else {
      dbStatus = status;
    }

    return {
      'id': id,
      'title': title,
      'category': category,
      'location': location,
      'price': price,
      'status': dbStatus,
      'imageUrl': imageUrl,
    };
  }
}

class AdminUserModel {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final bool isActive;
  final String? createdAt;

  const AdminUserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminUserModel.fromJson(Map<String, dynamic> json) {
    return AdminUserModel(
      id: _toInt(json['id'] ?? json['id_user']) ?? 0,
      name: _toText(json['name']),
      email: _toText(json['email']),
      phone: _toOptionalText(json['phone']),
      role: _toText(json['role']),
      isActive: json['isActive'] != false,
      createdAt: _toOptionalText(json['createdAt']),
    );
  }
}

class AdminGlobalReportModel {
  final int totalProperties;
  final int availableProperties;
  final int bookingProperties;
  final int soldProperties;
  final int totalBuyers;
  final int totalStaff;
  final int totalTransactions;
  final int confirmedTransactions;
  final int completedHistoricalTransactions;
  final int soldUnits;
  final int uniqueTransactingBuyers;
  final double totalRevenue;

  const AdminGlobalReportModel({
    required this.totalProperties,
    required this.availableProperties,
    required this.bookingProperties,
    required this.soldProperties,
    required this.totalBuyers,
    required this.totalStaff,
    required this.totalTransactions,
    required this.confirmedTransactions,
    required this.completedHistoricalTransactions,
    required this.soldUnits,
    required this.uniqueTransactingBuyers,
    required this.totalRevenue,
  });

  factory AdminGlobalReportModel.fromJson(Map<String, dynamic> json) {
    return AdminGlobalReportModel(
      totalProperties: _toInt(json['total_properties']) ?? 0,
      availableProperties: _toInt(json['available_properties']) ?? 0,
      bookingProperties: _toInt(json['booking_properties']) ?? 0,
      soldProperties: _toInt(json['sold_properties']) ?? 0,
      totalBuyers: _toInt(json['total_buyers']) ?? 0,
      totalStaff: _toInt(json['total_staff']) ?? 0,
      totalTransactions: _toInt(json['total_transactions']) ?? 0,
      confirmedTransactions: _toInt(json['confirmed_transactions']) ?? 0,
      completedHistoricalTransactions:
          _toInt(json['completed_historical_transactions']) ?? 0,
      soldUnits: _toInt(json['sold_units']) ?? 0,
      uniqueTransactingBuyers:
          _toInt(json['unique_transacting_buyers']) ?? 0,
      totalRevenue: _toDouble(json['total_revenue']),
    );
  }
}

class AdminAvailabilitySummaryModel {
  final String status;
  final int total;

  const AdminAvailabilitySummaryModel({
    required this.status,
    required this.total,
  });

  factory AdminAvailabilitySummaryModel.fromJson(Map<String, dynamic> json) {
    return AdminAvailabilitySummaryModel(
      status: _toText(json['status']),
      total: _toInt(json['total']) ?? 0,
    );
  }
}

int? _toInt(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString().trim());
}

double _toDouble(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().trim()) ?? 0;
}

String _toText(dynamic value) => value?.toString() ?? '';

String? _toOptionalText(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text.toLowerCase() == 'null') return null;
  return text;
}
