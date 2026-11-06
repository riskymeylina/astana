import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../../models/property_model.dart';
import '../../../../services/property_service.dart';
import '../../../../services/notification_service.dart';
import '../../../../services/staff_todo_service.dart';
import 'widgets/dashboard_summary_card.dart';

class StaffDashboardMainView extends StatefulWidget {
  final String userName;
  final String userRole;

  const StaffDashboardMainView({
    super.key,
    required this.userName,
    required this.userRole,
  });

  @override
  State<StaffDashboardMainView> createState() => _StaffDashboardMainViewState();
}

Widget _buildSeeAllButton({required VoidCallback onPressed}) {
  return TextButton(
    onPressed: onPressed,
    style: TextButton.styleFrom(
      foregroundColor: const Color(0xFF8F4E1E),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Lihat Semua',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
        SizedBox(width: 4),
        Icon(Icons.arrow_forward_rounded, size: 16),
      ],
    ),
  );
}

class _StaffDashboardMainViewState extends State<StaffDashboardMainView> {
  final PropertyService _propertyService = PropertyService();
  final NotificationService _notificationService = NotificationService();
  final StaffTodoService _todoService = StaffTodoService();

  List<PropertyModel> _properties = [];
  int _unreadNotifications = 0;

  List<Map<String, dynamic>> _todoList = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final propRes = await _propertyService.getProperties();
      final notifRes = await _notificationService.getNotifications();

      if (propRes.statusCode >= 200 && propRes.statusCode < 300) {
        setState(() {
          _properties = _propertyService.parseProperties(propRes.body);
        });
      }

      if (notifRes.statusCode >= 200 && notifRes.statusCode < 300) {
        final notifications = _notificationService.parseNotifications(
          notifRes.body,
        );
        setState(() {
          _unreadNotifications = notifications.where((n) => !n.isRead).length;
        });
      }

      await _loadTodos();
    } catch (e) {
      debugPrint('StaffDashboard _loadData error: $e');
    }
  }

  Future<void> _loadTodos() async {
    try {
      final res = await _todoService.getTodos();
      if (res.statusCode >= 200 && res.statusCode < 300) {
        final todos = _todoService.parseTodos(res.body);
        setState(() {
          _todoList = todos;
        });
      }
    } catch (e) {
      debugPrint('_loadTodos error: $e');
    }
  }

  Future<void> _toggleTodo(int index) async {
    final item = _todoList[index];
    final bool current = (item['status']?.toString() ?? '') == 'completed';
    final newStatus = current ? 'pending' : 'completed';
    try {
      final res = await _todoService.updateTodoStatus(item['id'], newStatus);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await _loadTodos();
      }
    } catch (e) {
      debugPrint('_toggleTodo error: $e');
    }
  }

  Future<void> _deleteTodo(int index) async {
    final item = _todoList[index];
    try {
      final res = await _todoService.deleteTodo(item['id']);
      if (res.statusCode >= 200 && res.statusCode < 300) {
        await _loadTodos();
      }
    } catch (e) {
      debugPrint('_deleteTodo error: $e');
    }
  }

  void _showAddTodoDialog() {
    final TextEditingController titleCtrl = TextEditingController();
    final TextEditingController descCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Tambah Tugas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Judul Tugas'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Deskripsi'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6F3212),
              ),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final res = await _todoService.createTodo(
                  titleCtrl.text.trim(),
                  descCtrl.text.trim(),
                  '',
                );
                if (res.statusCode >= 200 && res.statusCode < 300) {
                  await _loadTodos();
                  if (mounted) Navigator.pop(ctx);
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(_todoService.parseMessage(res.body)),
                      ),
                    );
                  }
                }
              },
              child: const Text(
                'Simpan',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationButton(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFEFE6DC)),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Center(
            child: IconButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/notifications',
                ).then((_) => _loadData());
              },
              tooltip: 'Notifikasi',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 40, height: 40),
              icon: const Icon(
                Icons.notifications_none_rounded,
                color: Color(0xFF3E1E09),
                size: 22,
              ),
            ),
          ),
          if (_unreadNotifications > 0)
            Positioned(
              top: 1,
              right: 0,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFD32F2F),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  _unreadNotifications > 99 ? '99+' : '$_unreadNotifications',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat(
      'd MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());

    // Statistik dari database
    final int totalProperti = _properties.length;
    final int tersedia = _properties
        .where(
          (p) =>
              p.status.toLowerCase() == 'available' ||
              p.status.toLowerCase() == 'tersedia',
        )
        .length;
    final int dipesan = _properties
        .where(
          (p) =>
              p.status.toLowerCase() == 'booking' ||
              p.status.toLowerCase().contains('booking'),
        )
        .length;
    final int tidakTersedia = _properties
        .where(
          (p) =>
              p.status.toLowerCase() == 'sold' ||
              p.status.toLowerCase() == 'terjual',
        )
        .length;

    final double totalF = totalProperti > 0 ? totalProperti.toDouble() : 1.0;
    final double tersediaPct = (tersedia / totalF) * 100;
    final double dipesanPct = (dipesan / totalF) * 100;
    final double tidakTersediaPct = (tidakTersedia / totalF) * 100;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selamat datang, ${widget.userName}',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3E1E09),
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Berikut ringkasan aktivitas dan informasi penting untuk Anda hari ini.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF6F5F53),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildNotificationButton(context),
                    const SizedBox(width: 16),
                    // Tanggal sistem — read-only
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFEFE6DC)),
                      ),
                      child: Row(
                        children: [
                          Text(
                            formattedDate,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF3E1E09),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 28),

            // ── Summary Cards: Properti ──────────────────────────
            Row(
              children: [
                Expanded(
                  child: DashboardSummaryCard(
                    title: 'Total Properti',
                    value: '$totalProperti',
                    badge: 'Portofolio',
                    badgeColor: const Color(0xFF6F3212),
                    subtitle: 'Semua unit terdata',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DashboardSummaryCard(
                    title: 'Tersedia',
                    value: '$tersedia',
                    badge: 'Siap Huni',
                    badgeColor: const Color(0xFF16794C),
                    subtitle: '$tersediaPct% dari total',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DashboardSummaryCard(
                    title: 'Booking',
                    value: '$dipesan',
                    badge: 'Proses',
                    badgeColor: const Color(0xFFC78928),
                    subtitle: '$dipesanPct% dari total',
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: DashboardSummaryCard(
                    title: 'Terjual',
                    value: '$tidakTersedia',
                    badge: 'Sah BAST',
                    badgeColor: const Color(0xFFB03A2E),
                    subtitle: '$tidakTersediaPct% dari total',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Responsive Content Columns
            LayoutBuilder(
              builder: (context, constraints) {
                final bool isWide = constraints.maxWidth > 900;
                return isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildTodoListCard(),
                                const SizedBox(height: 24),
                                const SizedBox.shrink(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPropertyAvailabilityCard(
                                  tersedia,
                                  tersediaPct,
                                  dipesan,
                                  dipesanPct,
                                  tidakTersedia,
                                  tidakTersediaPct,
                                  totalProperti,
                                ),
                                const SizedBox(height: 24),
                                _buildRecentPropertiesCard(),
                              ],
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTodoListCard(),
                          const SizedBox(height: 24),
                          _buildPropertyAvailabilityCard(
                            tersedia,
                            tersediaPct,
                            dipesan,
                            dipesanPct,
                            tidakTersedia,
                            tidakTersediaPct,
                            totalProperti,
                          ),
                          const SizedBox(height: 24),
                          const SizedBox.shrink(),
                          const SizedBox(height: 24),
                          _buildRecentPropertiesCard(),
                        ],
                      );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Card Builder: Todo List
  Widget _buildTodoListCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daftar Tugas',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3E1E09),
                ),
              ),
              _buildSeeAllButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Menampilkan semua daftar tugas Anda.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Checklist items
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _todoList.length,
            separatorBuilder: (context, index) =>
                Divider(color: Colors.grey.shade100, height: 1),
            itemBuilder: (context, index) {
              final item = _todoList[index];
              final bool isChecked =
                  (item['status']?.toString() ?? '') == 'completed';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: InkWell(
                        onTap: () => _toggleTodo(index),
                        borderRadius: BorderRadius.circular(4),
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: isChecked
                                ? const Color(0xFF5A2A0D)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: isChecked
                                  ? const Color(0xFF5A2A0D)
                                  : Colors.grey.shade400,
                              width: 1.5,
                            ),
                          ),
                          child: isChecked
                              ? const Icon(
                                  Icons.check,
                                  size: 11,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['title']?.toString() ?? '',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF3E1E09),
                              decoration: isChecked
                                  ? TextDecoration.lineThrough
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item['description']?.toString() ?? '',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      item['due_date']?.toString() ?? '',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isChecked) ...[
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _deleteTodo(index),
                        constraints: const BoxConstraints(),
                        padding: EdgeInsets.zero,
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Add Task Button
          InkWell(
            onTap: _showAddTodoDialog,
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF9F3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFFFFF0E0),
                  style: BorderStyle.solid,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Color(0xFFCC7A2E), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Tambah Tugas',
                    style: TextStyle(
                      color: Color(0xFFCC7A2E),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
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

  // Card Builder: Property Availability
  Widget _buildPropertyAvailabilityCard(
    int tersedia,
    double tersediaPct,
    int dipesan,
    double dipesanPct,
    int tidakTersedia,
    double tidakTersediaPct,
    int totalProperti,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Ketersediaan Properti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3E1E09),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildSeeAllButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/marketing-property-availability',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Donut Chart Row
          Row(
            children: [
              // Chart representation
              Expanded(
                flex: 4,
                child: SizedBox(
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 46,
                          sections: [
                            PieChartSectionData(
                              color: const Color(0xFF4CAF50),
                              value: tersediaPct,
                              title: '',
                              radius: 14,
                            ),
                            PieChartSectionData(
                              color: const Color(0xFFFFC107),
                              value: dipesanPct,
                              title: '',
                              radius: 14,
                            ),
                            PieChartSectionData(
                              color: const Color(0xFFF44336),
                              value: tidakTersediaPct,
                              title: '',
                              radius: 14,
                            ),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$totalProperti',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF3E1E09),
                            ),
                          ),
                          const Text(
                            'Total Properti',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              // Legend
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendRow(
                      'Tersedia',
                      const Color(0xFF4CAF50),
                      tersedia,
                      tersediaPct,
                    ),
                    const SizedBox(height: 12),
                    _buildLegendRow(
                      'Dipesan',
                      const Color(0xFFFFC107),
                      dipesan,
                      dipesanPct,
                    ),
                    const SizedBox(height: 12),
                    _buildLegendRow(
                      'Tidak Tersedia',
                      const Color(0xFFF44336),
                      tidakTersedia,
                      tidakTersediaPct,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          // Warning/Info banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF9F3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pastikan ketersediaan properti selalu diperbarui untuk informasi yang akurat.',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF7A4B16),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendRow(String label, Color color, int count, double pct) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Color(0xFF3E1E09),
              ),
            ),
          ],
        ),
        Text(
          '$count (${pct.toStringAsFixed(1)}%)',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Card Builder: Properti Terbaru
  Widget _buildRecentPropertiesCard() {
    final List<Map<String, dynamic>> displayProps = [];

    if (_properties.isNotEmpty) {
      final sortedProps = List<PropertyModel>.from(_properties);
      sortedProps.sort((a, b) => b.id.compareTo(a.id));
      final recent = sortedProps.take(4).toList();

      for (var p in recent) {
        String statusLabel = 'Tersedia';
        Color statusColor = const Color(0xFF4CAF50);
        if (p.status.toLowerCase() == 'booking') {
          statusLabel = 'Dipesan';
          statusColor = const Color(0xFFFFC107);
        } else if (p.status.toLowerCase() == 'sold') {
          statusLabel = 'Tidak Tersedia';
          statusColor = const Color(0xFFF44336);
        }

        displayProps.add({
          'id': p.id,
          'title': p.title,
          'subtitle': p.category,
          'price': 'Rp ${NumberFormat('#,###', 'id_ID').format(p.price)}',
          'status': statusLabel,
          'statusColor': statusColor,
          'image': p.gallery.isNotEmpty ? p.gallery.first.imageUrl : '',
        });
      }
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Properti Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF3E1E09),
                ),
              ),
              _buildSeeAllButton(
                onPressed: () => Navigator.pushNamed(
                  context,
                  '/marketing-property-availability',
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (displayProps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Belum ada properti',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayProps.length,
              separatorBuilder: (context, index) =>
                  Divider(color: Colors.grey.shade100, height: 1),
              itemBuilder: (context, index) {
                final p = displayProps[index];
                return InkWell(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/property-detail',
                      arguments: p['id'] ?? 1,
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 8,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child:
                              p['image'].toString().isNotEmpty &&
                                  p['image'].toString().startsWith('http')
                              ? Image.network(
                                  p['image'],
                                  width: 52,
                                  height: 52,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      _buildFallbackImage(),
                                )
                              : _buildFallbackImage(),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['title'],
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF3E1E09),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p['subtitle'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                p['price'],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFFCC7A2E),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: (p['statusColor'] as Color).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            p['status'],
                            style: TextStyle(
                              color: p['statusColor'],
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildFallbackImage() {
    return Container(
      width: 52,
      height: 52,
      color: const Color(0xFFFFF0E0),
      child: const Icon(
        Icons.home_work_rounded,
        color: Color(0xFFCC7A2E),
        size: 24,
      ),
    );
  }
}
