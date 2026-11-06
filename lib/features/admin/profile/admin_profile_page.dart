import 'package:flutter/material.dart';

import '../../../features/shared/profile/profile_avatar.dart';
import '../../../services/auth_service.dart';
import 'admin_profile_controller.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  final controller = AdminProfileController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF5F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAF5F0),
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profil Admin',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF2F2318),
              ),
            ),
            Text(
              'Kelola akun dan akses administrasi Anda',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF8A7563),
                height: 1.2,
              ),
            ),
          ],
        ),
        titleSpacing: 16,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Hero Banner ─────────────────────────────────────────────────
            _AdminHeroBanner(
              controller: controller,
              onUploadSuccess: () => setState(() {}),
            ),
            const SizedBox(height: 20),

            // ── Quick Access ────────────────────────────────────────────────
            const Text(
              'Akses Cepat',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2F2318),
              ),
            ),
            const SizedBox(height: 10),
            const _QuickAccessGrid(),
            const SizedBox(height: 20),

            // ── Recent Activity ─────────────────────────────────────────────
            const Text(
              'Aktivitas Terakhir',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: Color(0xFF2F2318),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Lihat Semua'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8F4E1E),
                  backgroundColor: const Color(0xFFFFF3E5),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
                  shape: const StadiumBorder(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const _RecentActivityTable(),
            const SizedBox(height: 20),

            // ── Bottom Actions (Logout) ────────────────────────
            _BottomActionTile(
              icon: Icons.logout_rounded,
              iconColor: const Color(0xFFC74C4C),
              iconBg: const Color(0xFFFFEAEA),
              label: 'Logout',
              subtitle: 'Keluar dari akun admin secara aman',
              onTap: () async {
                await AuthService().clearSession();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Banner
// ─────────────────────────────────────────────────────────────────────────────

class _AdminHeroBanner extends StatelessWidget {
  final AdminProfileController controller;
  final VoidCallback? onUploadSuccess;

  const _AdminHeroBanner({required this.controller, this.onUploadSuccess});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6B1E00), Color(0xFFA83A00), Color(0xFFD15A10)],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB03A00).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(painter: _HeroDecorationPainter()),
                ),
                if (!isNarrow)
                  const Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: _HeroIllustration(),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 22,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ProfileAvatar(
                        imageUrl: controller.avatarUrl,
                        initials: controller.avatarInitials,
                        size: 72,
                        isEditable: true,
                        onUploadSuccess: onUploadSuccess,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text(
                                  controller.userName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.3,
                                  ),
                                ),
                                _RoleBadge(label: controller.roleLabel),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Kelola sistem, data, dan seluruh aktivitas aplikasi.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withValues(alpha: 0.85),
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 16,
                              runSpacing: 6,
                              children: [
                                _BannerMetaItem(
                                  icon: Icons.email_outlined,
                                  label: controller.email,
                                ),
                                _BannerMetaItem(
                                  icon: Icons.calendar_today_outlined,
                                  label: 'Bergabung sejak 12 Mei 2024',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final String label;
  const _RoleBadge({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.verified_user_rounded,
            size: 11,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _BannerMetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  const _BannerMetaItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.white.withValues(alpha: 0.75)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            color: Colors.white.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// Simple decorative painter (dots + wave)
class _HeroDecorationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;

    // Scattered dots
    final dots = [
      Offset(size.width * 0.1, size.height * 0.15),
      Offset(size.width * 0.2, size.height * 0.75),
      Offset(size.width * 0.35, size.height * 0.1),
      Offset(size.width * 0.45, size.height * 0.85),
      Offset(size.width * 0.6, size.height * 0.2),
    ];
    for (final d in dots) {
      canvas.drawCircle(d, 24, dotPaint);
    }

    // Wave arc at bottom
    final wavePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, size.height * 0.65)
      ..quadraticBezierTo(
        size.width * 0.3,
        size.height * 0.4,
        size.width * 0.6,
        size.height * 0.7,
      )
      ..quadraticBezierTo(
        size.width * 0.8,
        size.height * 0.9,
        size.width,
        size.height * 0.6,
      )
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Minimal house + chart line drawn with Canvas
class _HeroIllustration extends StatelessWidget {
  const _HeroIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: CustomPaint(painter: _IllustrationPainter()),
    );
  }
}

class _IllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final cx = size.width * 0.45;
    final cy = size.height * 0.42;
    final hw = 38.0;
    final hh = 30.0;

    // House body
    final body = Path()
      ..addRect(Rect.fromLTWH(cx - hw * 0.6, cy, hw * 1.2, hh));
    canvas.drawPath(body, paint);

    // Roof
    final roof = Path()
      ..moveTo(cx - hw * 0.75, cy)
      ..lineTo(cx, cy - hh * 0.7)
      ..lineTo(cx + hw * 0.75, cy);
    canvas.drawPath(roof, paint);

    // Door
    final door = Path()
      ..addRect(Rect.fromLTWH(cx - 8, cy + hh * 0.35, 16, hh * 0.65));
    canvas.drawPath(door, paint);

    // Window
    final win = Path()..addRect(Rect.fromLTWH(cx + 10, cy + 6, 12, 12));
    canvas.drawPath(win, paint);

    // Trend arrow (chart)
    final chartPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.20)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    final chart = Path()
      ..moveTo(cx - 20, cy + hh + 28)
      ..lineTo(cx - 5, cy + hh + 14)
      ..lineTo(cx + 10, cy + hh + 20)
      ..lineTo(cx + 30, cy + hh + 4);
    canvas.drawPath(chart, chartPaint);

    // Arrow tip
    final arrow = Path()
      ..moveTo(cx + 24, cy + hh)
      ..lineTo(cx + 30, cy + hh + 4)
      ..lineTo(cx + 26, cy + hh + 10);
    canvas.drawPath(arrow, chartPaint);

    // Clipboard icon (outline)
    final clipPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final bx = cx - 55.0;
    final by = cy - 20.0;
    final clipPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(bx, by, 28, 34),
          const Radius.circular(4),
        ),
      );
    canvas.drawPath(clipPath, clipPaint);

    // Lines on clipboard
    for (var i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(bx + 5, by + 12 + i * 7.0),
        Offset(bx + 23, by + 12 + i * 7.0),
        clipPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Access — horizontal scrollable row (5 cards)
// ─────────────────────────────────────────────────────────────────────────────

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid();

  static const _items = [
    _QuickItem(
      icon: Icons.apartment_rounded,
      iconColor: Color(0xFFCB7D2A),
      iconBg: Color(0xFFFFF0DC),
      label: 'Kelola Properti',
      subtitle: 'Tambah, edit, dan kelola data properti',
      route: '/admin/properties',
    ),
    _QuickItem(
      icon: Icons.receipt_long_rounded,
      iconColor: Color(0xFF2E9E6E),
      iconBg: Color(0xFFDFF5EC),
      label: 'Kelola Pemesanan',
      subtitle: 'Pantau dan kelola pemesanan properti',
      route: '/admin/reports/global',
    ),
    _QuickItem(
      icon: Icons.bar_chart_rounded,
      iconColor: Color(0xFF6E4EE0),
      iconBg: Color(0xFFEDE8FF),
      label: 'Laporan Penjualan',
      subtitle: 'Lihat laporan transaksi dan penjualan',
      route: '/admin/reports/sales',
    ),
    _QuickItem(
      icon: Icons.group_add_rounded,
      iconColor: Color(0xFFCB7D2A),
      iconBg: Color(0xFFFFF0DC),
      label: 'Kelola Staf',
      subtitle: 'Atur data dan role staf pemasaran',
      route: '/admin/staff',
    ),
    _QuickItem(
      icon: Icons.person_search_rounded,
      iconColor: Color(0xFF2563EB),
      iconBg: Color(0xFFDCEFFD),
      label: 'Kelola Pembeli',
      subtitle: 'Kelola data pembeli dan riwayat transaksi',
      route: '/admin/buyers',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        int crossAxisCount = 2;
        double childAspectRatio = 1.45;

        if (screenWidth > 900) {
          crossAxisCount = 5;
          childAspectRatio = 1.6;
        } else if (screenWidth > 600) {
          crossAxisCount = 3;
          childAspectRatio = 1.5;
        }

        final double spacing = 12.0;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: childAspectRatio,
          ),
          itemBuilder: (context, index) {
            return _QuickAccessCard(item: _items[index]);
          },
        );
      },
    );
  }
}

class _QuickItem {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String subtitle;
  final String route;

  const _QuickItem({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.subtitle,
    required this.route,
  });
}

class _QuickAccessCard extends StatelessWidget {
  final _QuickItem item;
  final double? width;

  const _QuickAccessCard({required this.item}) : width = null;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        shadowColor: const Color(0xFF8E3A00).withValues(alpha: 0.04),
        elevation: 2,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, item.route),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEFE6DD)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: item.iconBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 18),
                    ),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 15,
                      color: Color(0xFFBEA48A),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        item.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2F2318),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF9E856C),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recent Activity Table
// ─────────────────────────────────────────────────────────────────────────────

class _ActivityEntry {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String description;
  final String date;
  final String time;

  const _ActivityEntry({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
  });
}

class _RecentActivityTable extends StatelessWidget {
  const _RecentActivityTable();

  static const _entries = [
    _ActivityEntry(
      icon: Icons.check_circle_outline_rounded,
      iconColor: Color(0xFF2E9E6E),
      iconBg: Color(0xFFDFF5EC),
      title: 'Menambahkan properti baru',
      description: 'Astana Residence Prambanan ditambahkan',
      date: '12 Juni 2026',
      time: '10:30 WIB',
    ),
    _ActivityEntry(
      icon: Icons.shopping_cart_outlined,
      iconColor: Color(0xFFCB7D2A),
      iconBg: Color(0xFFFFF0DC),
      title: 'Mengonfirmasi pemesanan',
      description: 'Pemesanan INV/2026/0612/0012 dikonfirmasi',
      date: '12 Juni 2026',
      time: '09:45 WIB',
    ),
    _ActivityEntry(
      icon: Icons.insert_drive_file_outlined,
      iconColor: Color(0xFF6E4EE0),
      iconBg: Color(0xFFEDE8FF),
      title: 'Mengunggah laporan penjualan',
      description: 'Laporan penjualan bulan Mei 2026 diunggah',
      date: '11 Juni 2026',
      time: '16:20 WIB',
    ),
    _ActivityEntry(
      icon: Icons.person_add_outlined,
      iconColor: Color(0xFF2563EB),
      iconBg: Color(0xFFDCEFFD),
      title: 'Menambahkan staf baru',
      description: 'Staf pemasaran baru ditambahkan',
      date: '10 Juni 2026',
      time: '14:10 WIB',
    ),
    _ActivityEntry(
      icon: Icons.delete_outline_rounded,
      iconColor: Color(0xFFC74C4C),
      iconBg: Color(0xFFFFEAEA),
      title: 'Menghapus data tidak aktif',
      description: 'Beberapa data nonaktif telah dihapus',
      date: '10 Juni 2026',
      time: '11:05 WIB',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECDDCC)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _entries.length,
        separatorBuilder: (_, _) =>
            const Divider(color: Color(0xFFF4EAE0), height: 1),
        itemBuilder: (context, index) {
          final entry = _entries[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: entry.iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(entry.icon, color: entry.iconColor, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        entry.title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2F2318),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        entry.description,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFF9E856C),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.access_time_rounded,
                            size: 11,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${entry.date} • ${entry.time}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Action Tile (Notifikasi / Logout)
// ─────────────────────────────────────────────────────────────────────────────

class _BottomActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _BottomActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFECDDCC)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF2F2318),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10.5,
                        color: Color(0xFF9E856C),
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFFBEA48A),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
