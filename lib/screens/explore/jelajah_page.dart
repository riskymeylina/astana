import 'package:flutter/material.dart';

import '../../models/property_model.dart';
import '../../services/property_service.dart';

class JelajahPage extends StatefulWidget {
  const JelajahPage({super.key});

  @override
  State<JelajahPage> createState() => _JelajahPageState();
}

class _JelajahPageState extends State<JelajahPage> {
  final PropertyService _svc = PropertyService();

  bool _isLoading = true;
  String? _error;
  List<PropertyModel> _props = const [];
  int _selectedCategory = 0;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Semua', 'icon': Icons.home_rounded},
    {'label': 'Rumah', 'icon': Icons.house_outlined},
    {'label': 'Kos', 'icon': Icons.apartment_outlined},
    {'label': 'Ruko', 'icon': Icons.store_outlined},
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final r = await _svc.getProperties();
      if (r.statusCode >= 200 && r.statusCode < 300) {
        setState(() => _props = _svc.parseProperties(r.body));
      } else {
        setState(() => _error = _svc.parseMessage(r.body));
      }
    } catch (e) {
      setState(() => _error = 'Gagal memuat data');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openDetail(int id) {
    Navigator.pushNamed(context, '/property-detail', arguments: id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F3EE),
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 14, 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFF5C1E04), Color(0xFF8F4E1E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5C1E04).withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Jelajah',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              height: 1.15,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Temukan properti yang sesuai dengan kebutuhan Anda.',
                            style: TextStyle(
                              color: Color(0xD9FFFFFF),
                              fontSize: 11.5,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.explore_rounded,
                      size: 48,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ],
                ),
              ),
            ),

            // ── Search bar ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 4, 18, 14),
              child: Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.search_rounded, color: Color(0xFF9E9E9E)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Cari lokasi, nama properti, atau kata kunci...',
                        style: TextStyle(
                          color: Color(0xFF9E9E9E),
                          fontSize: 13.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Category chips ──────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_categories.length, (i) {
                    final isSelected = i == _selectedCategory;
                    return Padding(
                      padding: EdgeInsets.only(
                        right: i < _categories.length - 1 ? 8 : 0,
                      ),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedCategory = i),
                        child: _CategoryChip(
                          label: _categories[i]['label'] as String,
                          icon: _categories[i]['icon'] as IconData,
                          selected: isSelected,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // ── List ────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF8E4E16),
                      ),
                    )
                  : _error != null
                  ? RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF8E4E16),
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: const Color(0xFF8E4E16),
                      child: CustomScrollView(
                        slivers: [
                          // ── Promo Banner ──────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
                              child: _PromoBanner(),
                            ),
                          ),

                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(18, 0, 18, 14),
                              child: Row(
                                children: [
                                  const Text(
                                    'Properti Unggulan',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF1A1A1A),
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: const Color(0xFFE9DCCF),
                                      ),
                                    ),
                                    child: Row(
                                      children: const [
                                        Text(
                                          'Terbaru',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1A1A1A),
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 18,
                                          color: Color(0xFF1A1A1A),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // ── Property cards ────────────────
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 120),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate((
                                context,
                                i,
                              ) {
                                final p = _props[i];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 14),
                                  child: _PropertyListCard(
                                    property: p,
                                    onOpen: () => _openDetail(p.id),
                                  ),
                                );
                              }, childCount: _props.length),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Category Chip ────────────────────────────────────────────────────────────

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.icon,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF7B3300) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? const Color(0xFF7B3300) : const Color(0xFFE9DCCF),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: selected ? Colors.white : const Color(0xFF6B5A4B),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : const Color(0xFF6B5A4B),
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Promo Banner ─────────────────────────────────────────────────────────────

class _PromoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF0DC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -10,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFDFB0).withOpacity(0.4),
              ),
            ),
          ),
          Positioned(
            right: 60,
            bottom: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFDFB0).withOpacity(0.3),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 130, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF8C42).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFFE07B1A),
                        size: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Promo Spesial',
                      style: TextStyle(
                        color: Color(0xFFE07B1A),
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Temukan hunian impian\ndengan harga terbaik!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF1A1A1A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(
                      Icons.access_time_rounded,
                      size: 13,
                      color: Color(0xFFE07B1A),
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Berakhir dalam 12 hari',
                      style: TextStyle(
                        color: Color(0xFFE07B1A),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Gift box illustration (using icon as placeholder)
          Positioned(
            right: 14,
            top: 0,
            bottom: 0,
            child: Center(
              child: Container(width: 90, height: 90, child: _GiftBoxWidget()),
            ),
          ),
        ],
      ),
    );
  }
}

// Gift box drawn with Flutter widgets
class _GiftBoxWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _GiftBoxPainter());
  }
}

class _GiftBoxPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Box body
    final bodyPaint = Paint()..color = const Color(0xFFE8873A);
    final lidPaint = Paint()..color = const Color(0xFFD4712A);
    final ribbonPaint = Paint()..color = const Color(0xFFF5A855);
    final bowPaint = Paint()..color = const Color(0xFFF5A855);
    final shinePaint = Paint()..color = Colors.white.withOpacity(0.3);

    // Lid
    final lidRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.05, h * 0.3, w * 0.9, h * 0.14),
      const Radius.circular(6),
    );
    canvas.drawRRect(lidRect, lidPaint);

    // Box body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.43, w * 0.8, h * 0.5),
      const Radius.circular(6),
    );
    canvas.drawRRect(bodyRect, bodyPaint);

    // Vertical ribbon on body
    canvas.drawRect(
      Rect.fromLTWH(w * 0.44, h * 0.43, w * 0.12, h * 0.5),
      ribbonPaint,
    );

    // Horizontal ribbon on lid
    canvas.drawRRect(lidRect, ribbonPaint..color = const Color(0xFFF5A855));

    // Bow left loop
    final bowPath = Path();
    bowPath.moveTo(w * 0.5, h * 0.28);
    bowPath.cubicTo(w * 0.2, h * 0.05, w * 0.1, h * 0.3, w * 0.38, h * 0.3);
    canvas.drawPath(
      bowPath,
      bowPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // Bow right loop
    final bowPath2 = Path();
    bowPath2.moveTo(w * 0.5, h * 0.28);
    bowPath2.cubicTo(w * 0.8, h * 0.05, w * 0.9, h * 0.3, w * 0.62, h * 0.3);
    canvas.drawPath(
      bowPath2,
      bowPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // Center knot
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.29),
      w * 0.06,
      Paint()..color = const Color(0xFFE8873A),
    );

    // Shine on body
    canvas.drawOval(
      Rect.fromLTWH(w * 0.15, h * 0.48, w * 0.2, h * 0.12),
      shinePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Property List Card ───────────────────────────────────────────────────────

class _PropertyListCard extends StatelessWidget {
  const _PropertyListCard({required this.property, required this.onOpen});

  final PropertyModel property;
  final VoidCallback onOpen;

  String get _categoryLabel {
    final title = property.title.toLowerCase();
    if (title.contains('ruko')) return 'Ruko';
    if (title.contains('kos')) return 'Kos';
    return 'Rumah';
  }

  /// Bangun daftar spesifikasi dari PropertyModel.
  List<String> _buildSpecs() {
    final specs = <String>[];
    // Sesuaikan dengan field PropertyModel Anda:
    // if (property.bedroomCount != null) specs.add('${property.bedroomCount} KT');
    // if (property.bathroomCount != null) specs.add('${property.bathroomCount} KM');
    // if (property.area != null) specs.add('${property.area} m²');
    return specs;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Image ──────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(18),
            ),
            child: SizedBox(
              width: 140,
              height: 200,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    property.gallery.isNotEmpty
                        ? property.gallery.first.imageUrl
                        : '',
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) =>
                        Container(color: const Color(0xFFF0DCC0)),
                  ),
                  // Category badge
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _categoryLabel,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Right: Info ──────────────────────────────────────────
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Featured badge
                  Row(
                    children: const [
                      Icon(
                        Icons.star_rounded,
                        size: 13,
                        color: Color(0xFFF5A623),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Unggulan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFF5A623),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    property.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                  const SizedBox(height: 6),

                  // Location
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: Color(0xFF6B5A4B),
                      ),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          property.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFF6B5A4B),
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Specs
                  _SpecsRow(specs: _buildSpecs()),
                  if (_buildSpecs().isNotEmpty) const SizedBox(height: 8),

                  // Price
                  Text(
                    PropertyService().formatPrice(property.price),
                    style: const TextStyle(
                      color: Color(0xFF8E4E16),
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onOpen,
                      icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                      label: const Text(
                        'Lihat Detail',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF6B5A4B),
                        side: const BorderSide(color: Color(0xFFE9DCCF)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Specs Row ────────────────────────────────────────────────────────────────
// Adjust the specs list based on your actual PropertyModel fields.
// Example: property.bedroomCount, property.bathroomCount, property.area

class _SpecsRow extends StatelessWidget {
  const _SpecsRow({required this.specs});
  final List<String> specs;

  @override
  Widget build(BuildContext context) {
    if (specs.isEmpty) return const SizedBox.shrink();
    return Row(
      children: specs.asMap().entries.expand((entry) {
        final widgets = <Widget>[
          Text(
            entry.value,
            style: const TextStyle(color: Color(0xFF6B5A4B), fontSize: 13),
          ),
        ];
        if (entry.key < specs.length - 1) {
          widgets.add(
            const Text(
              ' • ',
              style: TextStyle(color: Color(0xFF9E9E9E), fontSize: 13),
            ),
          );
        }
        return widgets;
      }).toList(),
    );
  }
}
