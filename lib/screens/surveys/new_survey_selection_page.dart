import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/property_model.dart';
import '../../services/property_service.dart';
import '../../widgets/braga_page_header.dart';

class NewSurveySelectionPage extends StatefulWidget {
  const NewSurveySelectionPage({super.key});

  @override
  State<NewSurveySelectionPage> createState() => _NewSurveySelectionPageState();
}

class _NewSurveySelectionPageState extends State<NewSurveySelectionPage> {
  final PropertyService _propertyService = PropertyService();

  bool _isLoading = true;
  String? _errorMessage;
  List<PropertyModel> _eligibleProperties = [];

  @override
  void initState() {
    super.initState();
    _loadEligibleProperties();
  }

  Future<void> _loadEligibleProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _propertyService.getProperties();
    if (!mounted) return;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      setState(() {
        _errorMessage = _propertyService.parseMessage(response.body);
        _isLoading = false;
      });
      return;
    }

    final allProperties = _propertyService.parseProperties(response.body);
    // Filter to show properties with status 'available' or 'booking'
    final eligible = allProperties.where((p) {
      final s = p.status.toLowerCase();
      return s == 'available' || s == 'booking' || s == 'tersedia' || s == 'sedang dibooking';
    }).toList();

    setState(() {
      _eligibleProperties = eligible;
      _isLoading = false;
    });
  }

  void _selectProperty(PropertyModel property) {
    Navigator.pushNamed(
      context,
      '/survey-form',
      arguments: {
        'propertyId': property.id,
        'propertyTitle': property.title,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: Column(
        children: [
          const BragaPageHeader(
            title: 'Pilih Properti',
            subtitle: 'Pilih properti untuk survei.',
            decorativeIcon: Icons.home_work_outlined,
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Color(0xFF8F4E1E)),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat data',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6D5540)),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _loadEligibleProperties,
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_eligibleProperties.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.home_work_outlined, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'Belum ada properti',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                'Tidak ada properti yang tersedia untuk diajukan survei saat ini.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF6D5540)),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _eligibleProperties.length,
      itemBuilder: (context, index) {
        final property = _eligibleProperties[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _PropertyCard(
            property: property,
            onTap: () => _selectProperty(property),
          ),
        );
      },
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final PropertyModel property;
  final VoidCallback onTap;

  const _PropertyCard({
    required this.property,
    required this.onTap,
  });

  String _formatPrice(double price) {
    return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ').format(price);
  }

  Widget _buildStatusBadge() {
    Color bgColor;
    Color textColor;
    String text;

    final s = property.status.toLowerCase();
    if (s == 'available' || s == 'tersedia') {
      bgColor = const Color(0xFFE8F5E9);
      textColor = const Color(0xFF2E7D32);
      text = 'Tersedia';
    } else if (s == 'booking' || s == 'sedang dibooking') {
      bgColor = const Color(0xFFFFF3E0);
      textColor = const Color(0xFFE65100);
      text = 'Sedang Dibooking';
    } else {
      bgColor = const Color(0xFFECEFF1);
      textColor = const Color(0xFF37474F);
      text = property.statusLabel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = property.gallery.isNotEmpty ? property.gallery.first.imageUrl : '';
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 100,
                          height: 100,
                          color: const Color(0xFFFFF7ED),
                          child: const Icon(Icons.image_not_supported),
                        ),
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        color: const Color(0xFFFFF7ED),
                        child: const Icon(Icons.apartment_rounded),
                      ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF33241A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      property.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6D5540),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatPrice(property.price.toDouble()),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF8F4E1E),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _buildStatusBadge(),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
