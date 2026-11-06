import '../services/app_config.dart';

class PropertyModel {
  final int id;
  final String title;
  final String category;
  final String location;
  final int price;
  final String status;
  final String statusLabel;
  final List<PropertyGalleryItem> gallery;
  final String? updatedAt;

  const PropertyModel({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.price,
    required this.status,
    required this.statusLabel,
    required this.gallery,
    this.updatedAt,
  });

  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    final id = _toInt(json['id'] ?? json['id_property']);
    final price = _toInt(json['price']);

    if (id == null || price == null) {
      throw const FormatException('Data properti tidak valid');
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

    return PropertyModel(
      id: id,
      title: _toText(json['title']),
      category: _toText(json['category']),
      location: _toText(json['location']),
      price: price,
      status: mappedStatus,
      statusLabel:
          _toOptionalText(json['statusLabel']) ??
          _defaultStatusLabel(_toText(json['status'])),
      gallery: _parseGallery(json['gallery']),
      updatedAt: _toOptionalText(json['updatedAt']),
    );
  }

  static String _defaultStatusLabel(String status) {
    final s = status.trim();
    if (s.toLowerCase() == 'booking' || s == 'Sedang Dibooking') {
      return 'Sedang Dibooking';
    }
    if (s.toLowerCase() == 'sold' || s == 'Terjual') {
      return 'Terjual';
    }
    if (s.toLowerCase() == 'archived' || s == 'Diarsipkan') {
      return 'Diarsipkan';
    }
    return 'Tersedia';
  }

  static List<PropertyGalleryItem> _parseGallery(dynamic value) {
    if (value is! List) {
      return const [];
    }

    final items = <PropertyGalleryItem>[];
    for (final item in value.whereType<Map>()) {
      try {
        items.add(
          PropertyGalleryItem.fromJson(Map<String, dynamic>.from(item)),
        );
      } on FormatException {
        continue;
      }
    }
    return items;
  }

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
    if (text == null || text.isEmpty) {
      return null;
    }
    return text;
  }
}

class PropertyGalleryItem {
  final int id;
  final String imageUrl;
  final String title;
  final String subtitle;
  final List<String> details;

  const PropertyGalleryItem({
    required this.id,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.details,
  });

  factory PropertyGalleryItem.fromJson(Map<String, dynamic> json) {
    String rawUrl = (json['imageUrl'] ?? '').toString().trim();
    if (rawUrl.startsWith('/uploads')) {
      rawUrl = '${AppConfig.serverBaseUrl}$rawUrl';
    }
    // Encode spaces in URL if any
    if (rawUrl.contains(' ')) {
      rawUrl = Uri.encodeFull(rawUrl);
    }

    return PropertyGalleryItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      imageUrl: rawUrl,
      title: (json['title'] ?? '').toString(),
      subtitle: (json['subtitle'] ?? '').toString(),
      details: _parseDetails(json['details']),
    );
  }

  static List<String> _parseDetails(dynamic value) {
    if (value is! List) {
      return const [];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
