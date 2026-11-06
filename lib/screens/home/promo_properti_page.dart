import 'package:flutter/material.dart';

import '../../models/property_model.dart';
import '../../services/property_service.dart';

class PromoPropertiPage extends StatefulWidget {
  const PromoPropertiPage({super.key});

  @override
  State<PromoPropertiPage> createState() => _PromoPropertiPageState();
}

class _PromoPropertiPageState extends State<PromoPropertiPage> {
  final PropertyService _propertyService = PropertyService();

  bool _isLoading = true;
  String? _errorMessage;
  List<PropertyModel> _properties = const [];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _propertyService.getProperties();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      setState(() {
        _errorMessage = _propertyService.parseMessage(response.body);
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _properties = _propertyService.parseProperties(response.body);
      _isLoading = false;
    });
  }

  List<PropertyModel> get _orderedProperties => _properties;

  PropertyModel? get _heroProperty {
    if (_orderedProperties.isEmpty) return null;
    return _orderedProperties.first;
  }

  List<PropertyModel> get _galleryProperties {
    if (_orderedProperties.length <= 1) return const [];
    return _orderedProperties.sublist(1);
  }

  void _openPropertyDetail(PropertyModel property) {
    Navigator.pushNamed(context, '/property-detail', arguments: property.id);
  }

  @override
  Widget build(BuildContext context) {
    final heroProperty = _heroProperty;

    return Scaffold(
      backgroundColor: const Color(0xFFF3E8DA),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8E4E16)),
            )
          : _errorMessage != null
          ? _PromoStateMessage(
              message: _errorMessage!,
              onPressed: _loadProperties,
            )
          : heroProperty == null
          ? _PromoStateMessage(
              message: 'Belum ada properti promo tersedia',
              onPressed: _loadProperties,
            )
          : Column(
              children: [
                // ── Top bar (outside scroll) ──────────────────────────────
                _PromoTopBar(
                  totalCount: _orderedProperties.length,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
                // ── Scrollable body ───────────────────────────────────────
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadProperties,
                    color: const Color(0xFF8E4E16),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _PromoHeroSection(property: heroProperty),
                          Container(
                              width: double.infinity,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFFBF6),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Title + pills + quick cards + button
                                    _PromoTitleBlock(
                                      property: heroProperty,
                                      propertyService: _propertyService,
                                      onOpenDetail: () =>
                                          _openPropertyDetail(heroProperty),
                                    ),
                                    const SizedBox(height: 22),

                                    // ── Fasilitas ──────────────────────────
                                    _PromoSectionHeader(
                                      title: 'Fasilitas',
                                      subtitle:
                                          'Sorotan cepat untuk unit promo ini',
                                    ),
                                    const SizedBox(height: 12),
                                    _PromoFacilityRow(
                                      property: heroProperty,
                                    ),
                                    const SizedBox(height: 18),

                                    // ── Promo Banner ───────────────────────
                                    _PromoBannerCard(property: heroProperty),
                                    const SizedBox(height: 22),

                                    // ── Galeri Properti ────────────────────
                                    _PromoSectionHeader(
                                      title: 'Galeri Properti',
                                      subtitle:
                                          'Foto lengkap unit dan lingkungan',
                                    ),
                                    const SizedBox(height: 12),
                                    _PromoGalleryRow(property: heroProperty),
                                    const SizedBox(height: 22),

                                    // ── Promo Lainnya ──────────────────────
                                    _PromoSectionHeader(
                                      title: 'Promo lainnya',
                                      subtitle:
                                          'Pilihan properti serupa di katalog',
                                    ),
                                    const SizedBox(height: 12),
                                    if (_galleryProperties.isEmpty)
                                      _PromoEmptyGallery(
                                        onRetry: _loadProperties,
                                      )
                                    else
                                      GridView.builder(
                                        itemCount: _galleryProperties.length,
                                        shrinkWrap: true,
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        gridDelegate:
                                            const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 2,
                                          mainAxisSpacing: 12,
                                          crossAxisSpacing: 12,
                                          childAspectRatio: 0.82,
                                        ),
                                        itemBuilder: (context, index) {
                                          final property =
                                              _galleryProperties[index];
                                          return _PromoGalleryCard(
                                            property: property,
                                            propertyService: _propertyService,
                                            onTap: () =>
                                                _openPropertyDetail(property),
                                          );
                                        },
                                      ),
                                  ],
                                ),
                              ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── Bottom Nav ────────────────────────────────────────────
                const _BottomNavBar(),
              ],
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TOP BAR  (back button + title + promo count pill)
// ─────────────────────────────────────────────────────────────────────────────
class _PromoTopBar extends StatelessWidget {
  const _PromoTopBar({required this.totalCount, required this.onBack});

  final int totalCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
        child: Row(
          children: [
            // Back button
            _RoundIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: onBack,
              backgroundColor: Colors.white,
              iconColor: const Color(0xFF2F2318),
              size: 40,
              borderColor: const Color(0xFFE8D1B4),
            ),
            const SizedBox(width: 12),
            // Title
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Promo Properti',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2F2318),
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Promo terbaik yang sedang berlangsung',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF7A5C3A),
                    ),
                  ),
                ],
              ),
            ),
            // Count pill
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: const Color(0xFFE8D1B4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.card_giftcard_rounded,
                    size: 15,
                    color: Color(0xFF8E4E16),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '$totalCount Promo',
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8E4E16),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HERO SECTION  (full-width image with overlay — no back btn, handled by TopBar)
// ─────────────────────────────────────────────────────────────────────────────
class _PromoHeroSection extends StatelessWidget {
  const _PromoHeroSection({required this.property});

  final PropertyModel property;

  String get _displayImageUrl {
    if (property.gallery.isNotEmpty &&
        property.gallery.first.imageUrl.isNotEmpty) {
      return property.gallery.first.imageUrl;
    }
    return '';
  }

  String get _heroSubtitle {
    final pieces = <String>[
      property.location,
      property.category,
      property.statusLabel,
    ];
    return pieces.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final heroHeight = (MediaQuery.of(context).size.height * 0.42)
        .clamp(280.0, 380.0)
        .toDouble();

    return SizedBox(
      height: heroHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image with rounded TOP corners (like a card)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            child: Image.network(
              _displayImageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: const Color(0xFFF0DCC0),
                child: const Center(
                  child: Icon(
                    Icons.image_not_supported_rounded,
                    color: Color(0xFF8E4E16),
                    size: 42,
                  ),
                ),
              ),
            ),
          ),
          // Gradient overlay (also clipped with rounded top)
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(28),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.68),
                  ],
                ),
              ),
            ),
          ),
          // Top-right: "Promo Saat Ini" pill
          Positioned(
            top: 14,
            right: 14,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text('🔥', style: TextStyle(fontSize: 13)),
                  SizedBox(width: 5),
                  Text(
                    'Promo Saat Ini',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF8E4E16),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom info
          Positioned(
            left: 16,
            right: 16,
            bottom: 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category pill
                _InfoPill(
                  label: property.category.toUpperCase(),
                  filled: true,
                ),
                const SizedBox(height: 10),
                Text(
                  property.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on_rounded,
                      color: Colors.white70,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        _heroSubtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Dot indicators
                Row(
                  children: [
                    _dot(active: true),
                    const SizedBox(width: 5),
                    _dot(),
                    const SizedBox(width: 5),
                    _dot(),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot({bool active = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: active ? 18 : 7,
      height: 7,
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.white38,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TITLE BLOCK  (name, desc, pills, quick cards, button)
// ─────────────────────────────────────────────────────────────────────────────
class _PromoTitleBlock extends StatelessWidget {
  const _PromoTitleBlock({
    required this.property,
    required this.propertyService,
    required this.onOpenDetail,
  });

  final PropertyModel property;
  final PropertyService propertyService;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          property.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: Color(0xFF2F2318),
            height: 1.1,
          ),
        ),
        const SizedBox(height: 14),
        // Pills row
        Wrap(
          spacing: 7,
          runSpacing: 7,
          children: [
            _PricePill(label: propertyService.formatPrice(property.price)),
            if (property.location.isNotEmpty)
              _IconLabelPill(
                icon: Icons.location_on_rounded,
                label: property.location,
              ),
          ],
        ),
        const SizedBox(height: 16),
        // Quick cards
        Row(
          children: [
            Expanded(
              child: _QuickFeatureCard(
                icon: Icons.verified_rounded,
                title: 'Status',
                value: property.statusLabel,
                valueColor: const Color(0xFF2BAC76),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickFeatureCard(
                icon: Icons.place_rounded,
                title: 'Lokasi',
                value: property.location,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Lihat Detail button – full width
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onOpenDetail,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF2B04B),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            icon: const Icon(Icons.visibility_rounded, size: 18),
            label: const Text(
              'Lihat Detail',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
          ),
        ),
      ],
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// FASILITAS ROW
// ─────────────────────────────────────────────────────────────────────────────
class _PromoFacilityRow extends StatelessWidget {
  const _PromoFacilityRow({required this.property});

  final PropertyModel property;

  @override
  Widget build(BuildContext context) {
    final facilities = <_FacilityItem>[

      _FacilityItem(
        icon: Icons.directions_car_rounded,
        label: 'Carport',
      ),

      _FacilityItem(
        icon: Icons.security_rounded,
        label: 'Security',
      ),

      _FacilityItem(
        icon: Icons.park_rounded,
        label: 'Taman',
      ),

      _FacilityItem(
        icon: Icons.water_drop_rounded,
        label: 'Air Bersih',
      ),

      _FacilityItem(
        icon: Icons.bolt_rounded,
        label: 'Listrik',
      ),

      _FacilityItem(
        icon: Icons.home_work_rounded,
        label: property.category,
      ),
    ];

    return SizedBox(
      height: 108,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: facilities.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final item = facilities[index];

          return _FacilityTile(
            icon: item.icon,
            label: item.label,
          );
        },
      ),
    );
  }
}

class _FacilityItem {
  const _FacilityItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}

class _FacilityTile extends StatelessWidget {
  const _FacilityTile({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 82,
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE7D4BD),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8CC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF8E4E16),
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B5744),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROMO BANNER CARD  (discount badge + text + countdown + gift emoji)
// ─────────────────────────────────────────────────────────────────────────────
class _PromoBannerCard extends StatelessWidget {
  const _PromoBannerCard({required this.property});

  final PropertyModel property;

  @override
  Widget build(BuildContext context) {
    final badgeText = 'Promo Spesial!';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF2C97A), width: 1.5),
      ),
      child: Row(
        children: [
          // Red discount badge
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Color(0xFFFF4444),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text(
                '%',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  badgeText,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F2318),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  'Dapatkan harga terbaik untuk unit terbatas.',
                  style: TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF6B5744),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                // Timer pill
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2B04B).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: const Color(0xFFF2B04B)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Color(0xFF8E4E16),
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Berakhir dalam 12 hari',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF8E4E16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Gift emoji
          const Text('🎁', style: TextStyle(fontSize: 46)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GALLERY ROW  (horizontal photo thumbnails from property.gallery)
// ─────────────────────────────────────────────────────────────────────────────
class _PromoGalleryRow extends StatelessWidget {
  const _PromoGalleryRow({required this.property});

  final PropertyModel property;

  @override
  Widget build(BuildContext context) {
    final images = property.gallery
        .where((g) => g.imageUrl.isNotEmpty)
        .map((g) => g.imageUrl)
        .toList();

    if (images.isEmpty) {
      images.add('');
    }

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.network(
              images[index],
              width: 110,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                width: 110,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3DDC2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.image_not_supported_rounded,
                  color: Color(0xFF8E4E16),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION HEADER  (title + subtitle + "Lihat semua →")
// ─────────────────────────────────────────────────────────────────────────────
class _PromoSectionHeader extends StatelessWidget {
  const _PromoSectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF2F2318),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12.5,
                  color: Color(0xFF7A6653),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GALLERY GRID CARD  (used in "Promo Lainnya" 2-column grid)
// ─────────────────────────────────────────────────────────────────────────────
class _PromoGalleryCard extends StatelessWidget {
  const _PromoGalleryCard({
    required this.property,
    required this.propertyService,
    required this.onTap,
  });

  final PropertyModel property;
  final PropertyService propertyService;
  final VoidCallback onTap;

  String get _displayImageUrl {
    if (property.gallery.isNotEmpty &&
        property.gallery.first.imageUrl.isNotEmpty) {
      return property.gallery.first.imageUrl;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 16,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(
                        _displayImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          color: const Color(0xFFF3DDC2),
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_rounded,
                              color: Color(0xFF8E4E16),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withValues(alpha: 0.40),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        bottom: 10,
                        child: const _InfoPill(
                          label: 'Promo',
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      property.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF2F2318),
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      property.location,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF786351),
                        fontWeight: FontWeight.w600,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            propertyService.formatPrice(property.price),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF8E4E16),
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 12,
                          color: Color(0xFFB08963),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BOTTOM NAV BAR
// ─────────────────────────────────────────────────────────────────────────────
class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8D1B4))),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: const [
              _NavItem(icon: Icons.home_outlined, label: 'Beranda'),
              _NavItem(icon: Icons.explore_outlined, label: 'Jelajah'),

              _NavItem(
                icon: Icons.chat_bubble_outline_rounded,
                label: 'Konsultasi',
              ),
              _NavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
  }) : isActive = false;

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final color =
        isActive ? const Color(0xFFF2B04B) : const Color(0xFFB08963);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED SMALL WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
class _QuickFeatureCard extends StatelessWidget {
  const _QuickFeatureCard({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFF3E0C7),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: const Color(0xFF8E4E16), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8B7158),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: valueColor ?? const Color(0xFF2E2218),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Translucent/filled pill — used on hero image (filled=true) and in content area
class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, this.filled = false});

  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: filled
            ? Colors.white.withValues(alpha: 0.18)
            : const Color(0xFFF4E3CC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: filled
              ? Colors.white.withValues(alpha: 0.28)
              : const Color(0xFFE0C6A5),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: filled ? Colors.white : const Color(0xFF7D4A1D),
        ),
      ),
    );
  }
}

/// Orange price pill
class _PricePill extends StatelessWidget {
  const _PricePill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF2A927),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// Small pill with leading icon
class _IconLabelPill extends StatelessWidget {
  const _IconLabelPill({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF4E3CC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE0C6A5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF7D4A1D)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7D4A1D),
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular icon button (used in TopBar)
class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    required this.backgroundColor,
    required this.iconColor,
    required this.size,
    this.borderColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  final Color iconColor;
  final double size;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      shape: CircleBorder(
        side: borderColor != null
            ? BorderSide(color: borderColor!)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Icon(icon, color: iconColor, size: size * 0.48),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY / ERROR STATES
// ─────────────────────────────────────────────────────────────────────────────
class _PromoEmptyGallery extends StatelessWidget {
  const _PromoEmptyGallery({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8EFE4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE6CFB4)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.photo_library_outlined,
            color: Color(0xFF8E4E16),
            size: 30,
          ),
          const SizedBox(height: 8),
          const Text(
            'Belum ada promo lain untuk ditampilkan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFF6B5744),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Muat ulang')),
        ],
      ),
    );
  }
}

class _PromoStateMessage extends StatelessWidget {
  const _PromoStateMessage({required this.message, required this.onPressed});

  final String message;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.home_work_rounded,
              size: 48,
              color: Color(0xFF8E4E16),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Color(0xFF574332),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8E4E16),
                foregroundColor: Colors.white,
              ),
              child: const Text('Muat Ulang'),
            ),
          ],
        ),
      ),
    );
  }
}