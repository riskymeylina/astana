import 'dart:math' as math;
import 'package:flutter/material.dart';

class BottomNavSection extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int notificationCount;

  const BottomNavSection({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.notificationCount = 0,
  });

  @override
  State<BottomNavSection> createState() => _BottomNavSectionState();
}

class _BottomNavSectionState extends State<BottomNavSection> {
  // ── Nav tab definitions ──────────────────────────────────────────────────
  // Index mapping: 0=Beranda, 1=Jelajah, FAB(center), 4=Notifikasi, 3=Profil
  static const _navItems = [
    _NavItem(tabIndex: 0, unselected: Icons.home_outlined,              selected: Icons.home_rounded,               label: 'Beranda'),
    _NavItem(tabIndex: 1, unselected: Icons.explore_outlined,           selected: Icons.explore_rounded,            label: 'Jelajah'),
    _NavItem(tabIndex: 4, unselected: Icons.notifications_none_rounded, selected: Icons.notifications_rounded,      label: 'Notifikasi'),
    _NavItem(tabIndex: 3, unselected: Icons.person_outline_rounded,     selected: Icons.person_rounded,             label: 'Profil'),
  ];

  // ── Bar sizing ───────────────────────────────────────────────────────────
  static const double _barHeight   = 72.0;
  static const double _fabSize     = 62.0;
  static const double _fabRingPad  = 8.0;
  static const double _fabOverhang = 34.0;
  static const double _totalHeight = _barHeight + _fabOverhang;

  // ── State ────────────────────────────────────────────────────────────────
  final GlobalKey _fabKey = GlobalKey();
  bool _isMenuOpen = false;
  OverlayEntry? _menuOverlay;

  // ── FAB menu ─────────────────────────────────────────────────────────────

  void _toggleFabMenu() =>
      _isMenuOpen ? _closeFabMenu() : _openFabMenu();

  void _openFabMenu() {
    final box = _fabKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final fabCenter = box.localToGlobal(Offset.zero) +
        Offset(box.size.width / 2, box.size.height / 2);

    setState(() => _isMenuOpen = true);

    _menuOverlay = OverlayEntry(
      builder: (_) => _FabMenuOverlay(
        fabCenter:      fabCenter,
        onDismiss:      _closeFabMenu,
        onConsultation: () {
          _closeFabMenu();
          Navigator.pushNamed(context, '/consultation');
        },
        onSurvey: () {
          _closeFabMenu();
          Navigator.pushNamed(context, '/survey/new');
        },
      ),
    );
    Overlay.of(context).insert(_menuOverlay!);
  }

  void _closeFabMenu() {
    _menuOverlay?.remove();
    _menuOverlay = null;
    if (mounted) setState(() => _isMenuOpen = false);
  }

  @override
  void dispose() {
    _closeFabMenu();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final double w = constraints.maxWidth;

      // 5 slots: 2 left | FAB center | 2 right → equal spacing w/6 each
      //   slot centers: w/6, w/3, w/2, 2w/3, 5w/6
      final positions = [
        w / 6,       // Beranda   16.7 %
        w / 3,       // Jelajah   33.3 %
        // FAB:       w / 2       50.0 %
        w * 2 / 3,  // Notifikasi 66.7 %
        w * 5 / 6,  // Profil     83.3 %
      ];

      final double notchR = (_fabSize / 2) + _fabRingPad + 4;

      return SizedBox(
        height: _totalHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Bar background ──
            Positioned(
              left: 0, right: 0, bottom: 0, height: _barHeight,
              child: CustomPaint(
                painter: _NotchBarPainter(
                  notchCenterX: w / 2,
                  notchRadius:  notchR,
                ),
              ),
            ),

            // ── Nav icons (4 items) ──
            for (int i = 0; i < _navItems.length; i++)
              _buildNavIcon(
                cx:   positions[i],
                item: _navItems[i],
                badgeCount: _navItems[i].tabIndex == 4
                    ? widget.notificationCount
                    : 0,
              ),

            // ── Floating FAB ──
            Positioned(
              left: w / 2 - (_fabSize + _fabRingPad * 2) / 2,
              top:  0,
              child: _buildFab(),
            ),
          ],
        ),
      );
    });
  }

  // ── Nav icon ─────────────────────────────────────────────────────────────

  Widget _buildNavIcon({
    required double cx,
    required _NavItem item,
    int badgeCount = 0,
  }) {
    const double W = 64.0;
    final isActive = widget.currentIndex == item.tabIndex;
    final icon     = isActive ? item.selected : item.unselected;
    const active   = Color(0xFF8D4E18);
    const inactive = Color(0xFFC8B195);

    return Positioned(
      left:   cx - W / 2,
      bottom: 0,
      height: _barHeight,
      width:  W,
      child: GestureDetector(
        onTap: () => widget.onTap(item.tabIndex),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(icon, size: 29,
                      color: isActive ? active : inactive,
                      key: ValueKey(isActive)),
                ),
                // Notification badge
                if (badgeCount > 0)
                  Positioned(
                    right: -4, top: -4,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color:  isActive ? active : inactive,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width:  isActive ? 5 : 0,
              height: isActive ? 5 : 0,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0xFF8D4E18),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FAB ──────────────────────────────────────────────────────────────────

  Widget _buildFab() {
    final double outerSize = _fabSize + _fabRingPad * 2;
    return GestureDetector(
      key: _fabKey,
      onTap: _toggleFabMenu,
      child: Container(
        width:  outerSize,
        height: outerSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFFFAF3EC),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFB8824A).withOpacity(0.28),
              blurRadius: 18, spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(_fabRingPad),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: _isMenuOpen
                    ? [const Color(0xFF4A1A04), const Color(0xFF6E340B)]
                    : [const Color(0xFF8D4E18), const Color(0xFF6E340B)],
                begin: Alignment.topLeft,
                end:   Alignment.bottomRight,
              ),
            ),
            child: AnimatedRotation(
              turns:    _isMenuOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 220),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Fan Menu Overlay ────────────────────────────────────────────────────────

class _FabMenuOverlay extends StatefulWidget {
  final Offset fabCenter;
  final VoidCallback onDismiss;
  final VoidCallback onConsultation;
  final VoidCallback onSurvey;

  const _FabMenuOverlay({
    required this.fabCenter,
    required this.onDismiss,
    required this.onConsultation,
    required this.onSurvey,
  });

  @override
  State<_FabMenuOverlay> createState() => _FabMenuOverlayState();
}

class _FabMenuOverlayState extends State<_FabMenuOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  // Radius: bigger = icons float higher above FAB
  static const double _radius = 120.0;

  // 135° = upper-left  |  45° = upper-right  (from right-horizontal)
  static const double _leftAngle  = 135.0 * math.pi / 180;
  static const double _rightAngle =  45.0 * math.pi / 180;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      // Dim barrier
      GestureDetector(
        onTap: widget.onDismiss,
        behavior: HitTestBehavior.opaque,
        child: Container(color: Colors.black.withOpacity(0.30)),
      ),
      // Konsultasi (upper-left)
      _fanItem(angle: _leftAngle,  icon: Icons.chat_bubble_outline_rounded, label: 'Konsultasi', onTap: widget.onConsultation),
      // Survei (upper-right)
      _fanItem(angle: _rightAngle, icon: Icons.calendar_month_outlined,      label: 'Survei',      onTap: widget.onSurvey),
    ]);
  }

  Widget _fanItem({
    required double angle,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    const double itemR = 28.0;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, _) {
        final t  = _anim.value;
        final dx =  math.cos(angle) * _radius * t;
        final dy = -math.sin(angle) * _radius * t;
        return Positioned(
          left: widget.fabCenter.dx + dx - itemR,
          top:  widget.fabCenter.dy + dy - itemR,
          child: Opacity(
            opacity: t.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: t.clamp(0.0, 1.0),
              child: _ItemCircle(icon: icon, label: label, onTap: onTap),
            ),
          ),
        );
      },
    );
  }
}

// ─── Single menu icon circle ─────────────────────────────────────────────────

class _ItemCircle extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ItemCircle({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8D4E18).withOpacity(0.22),
                  blurRadius: 14, spreadRadius: 1,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: const Color(0xFF8D4E18), size: 26),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6)],
            ),
            child: Text(label,
              style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF6E340B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Nav Item Data ─────────────────────────────────────────────────────────────

class _NavItem {
  final int tabIndex;
  final IconData unselected;
  final IconData selected;
  final String label;
  const _NavItem({
    required this.tabIndex,
    required this.unselected,
    required this.selected,
    required this.label,
  });
}

// ─── Custom Painter ────────────────────────────────────────────────────────────

class _NotchBarPainter extends CustomPainter {
  final double notchCenterX;
  final double notchRadius;

  const _NotchBarPainter({required this.notchCenterX, required this.notchRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);
    canvas.drawShadow(path.shift(const Offset(0, -2)),
        Colors.black.withOpacity(0.09), 12, false);
    canvas.drawPath(path,
        Paint()..color = Colors.white..style = PaintingStyle.fill);
  }

  Path _buildPath(Size size) {
    const double cornerR = 30.0;
    const double smooth  = 14.0;
    final double cx = notchCenterX;
    final double nr = notchRadius;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, cornerR);
    path.quadraticBezierTo(0, 0, cornerR, 0);
    path.lineTo(cx - nr - smooth, 0);
    path.cubicTo(cx - nr, 0, cx - smooth, nr, cx, nr);
    path.cubicTo(cx + smooth, nr, cx + nr, 0, cx + nr + smooth, 0);
    path.lineTo(size.width - cornerR, 0);
    path.quadraticBezierTo(size.width, 0, size.width, cornerR);
    path.lineTo(size.width, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _NotchBarPainter old) =>
      old.notchCenterX != notchCenterX || old.notchRadius != notchRadius;
}
