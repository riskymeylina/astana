import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../models/admin_models.dart';
import '../../../../services/admin_property_service.dart';
import '../../../../services/admin_report_service.dart';
import '../../../../services/notification_service.dart';

import 'widgets/dashboard_summary_card.dart';
import 'widgets/dashboard_chart_section.dart';
import 'widgets/dashboard_donut_chart.dart';
import 'widgets/dashboard_list_section.dart';

class DashboardMainView extends StatefulWidget {
  final String userName;
  final String userRole;

  const DashboardMainView({
    super.key,
    required this.userName,
    required this.userRole,
  });

  @override
  State<DashboardMainView> createState() => _DashboardMainViewState();
}

class _DashboardMainViewState extends State<DashboardMainView> {
  final AdminPropertyService _propertyService = AdminPropertyService();
  final AdminReportService _reportService = AdminReportService();
  final NotificationService _notificationService = NotificationService();

  List<AdminPropertyModel> _properties = [];
  AdminGlobalReportModel? _globalReport;
  int _unreadNotifications = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        _propertyService.getProperties(),
        _reportService.getGlobalReport(),
        _notificationService.getNotifications(),
      ]);

      final propRes = results[0];
      final reportRes = results[1];
      final notifRes = results[2];

      if (propRes.statusCode >= 200 && propRes.statusCode < 300) {
        final List<dynamic> data =
            _propertyService.parseProperties(propRes.body) as List<dynamic>;
        setState(() {
          _properties = data.cast<AdminPropertyModel>();
        });
      }

      if (reportRes.statusCode >= 200 && reportRes.statusCode < 300) {
        setState(() {
          _globalReport = _reportService.parseGlobalReport(reportRes.body);
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
    } catch (e) {
      debugPrint('DashboardMainView _loadData error: $e');
    }
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
              constraints: const BoxConstraints.tightFor(
                width: 40,
                height: 40,
              ),
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
    final today = DateFormat('dd MMMM yyyy', 'id_ID').format(DateTime.now());

    // Statistik dari Global Report API
    final int totalProperti =
        _globalReport?.totalProperties ?? _properties.length;
    final int totalTersedia =
        _globalReport?.availableProperties ??
        _properties
            .where(
              (p) =>
                  p.status.toLowerCase() == 'available' ||
                  p.status.toLowerCase() == 'tersedia',
            )
            .length;
    final int totalBooking =
        _globalReport?.bookingProperties ??
        _properties
            .where(
              (p) =>
                  p.status.toLowerCase() == 'booking' ||
                  p.status.toLowerCase().contains('booking'),
            )
            .length;
    final int totalTerjual =
        _globalReport?.soldUnits ??
        _properties
            .where(
              (p) =>
                  p.status.toLowerCase() == 'sold' ||
                  p.status.toLowerCase() == 'terjual',
            )
            .length;
    final int totalPembeli =
        _globalReport?.uniqueTransactingBuyers ??
        _globalReport?.totalBuyers ??
        0;
    final int totalTransaksi =
        _globalReport?.soldUnits ??
        _globalReport?.confirmedTransactions ??
        0;
    final double totalPendapatan = _globalReport?.totalRevenue ?? 0;

    List<DashboardPropertyListItem> recentProperties = [];

    if (_properties.isNotEmpty) {
      final sortedProps = List<AdminPropertyModel>.from(_properties);
      sortedProps.sort((a, b) => b.id.compareTo(a.id));
      final recent = sortedProps.take(4).toList();
      recentProperties = recent.map((p) {
        Color statusColor = const Color(0xFF4CAF50);
        String statusLabel = 'Tersedia';
        if (p.status.toLowerCase() == 'booking') {
          statusColor = const Color(0xFFFFC107);
          statusLabel = 'Booking';
        } else if (p.status.toLowerCase() == 'sold') {
          statusColor = const Color(0xFFF44336);
          statusLabel = 'Terjual';
        } else if (p.status.toLowerCase() == 'archived') {
          statusColor = Colors.grey;
          statusLabel = 'Arsip';
        }

        return DashboardPropertyListItem(
          imageUrl: p.imageUrl ?? '',
          title: p.title,
          subtitle:
              '${p.category} • Rp ${NumberFormat('#,###', 'id_ID').format(p.price)}',
          status: statusLabel,
          statusColor: statusColor,
          onTap: () {
            Navigator.pushNamed(context, '/property-detail', arguments: p.id);
          },
        );
      }).toList();
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
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
                          const SizedBox(height: 4),
                          const Text(
                            'Berikut adalah ringkasan aktivitas penjualan properti hari ini.',
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
                          // Tanggal — read-only (non-clickable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  today,
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
                  const SizedBox(height: 32),

                  // Summary Cards Row 1: Properti
                  Row(
                    children: [
                      Expanded(
                        child: DashboardSummaryCard(
                          title: 'Total Properti',
                          value: '$totalProperti',
                          badge: 'Portofolio',
                          badgeColor: const Color(0xFF6F3212),
                          subtitle: 'Semua unit terdaftar',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardSummaryCard(
                          title: 'Tersedia',
                          value: '$totalTersedia',
                          badge: 'Siap Huni',
                          badgeColor: const Color(0xFF16794C),
                          subtitle: '$totalTersedia dari $totalProperti unit',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardSummaryCard(
                          title: 'Booking',
                          value: '$totalBooking',
                          badge: 'Proses',
                          badgeColor: const Color(0xFFC78928),
                          subtitle: '$totalBooking dalam verifikasi',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardSummaryCard(
                          title: 'Terjual',
                          value: '$totalTerjual',
                          badge: 'Sah BAST',
                          badgeColor: const Color(0xFFB03A2E),
                          subtitle: '$totalTerjual unit terjual',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Summary Cards Row 2: Bisnis
                  Row(
                    children: [
                      Expanded(
                        child: DashboardSummaryCard(
                          title: 'Pembeli Bertransaksi',
                          value: '$totalPembeli',
                          badge: 'Pembeli',
                          subtitle: 'Pembeli dengan transaksi',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DashboardSummaryCard(
                          title: 'Transaksi Terjual',
                          value: '$totalTransaksi',
                          badge: 'Selesai',
                          subtitle: 'Transaksi sukses',
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 2,
                        child: DashboardSummaryCard(
                          title: 'Total Pendapatan',
                          value:
                              'Rp ${NumberFormat('#,###', 'id_ID').format(totalPendapatan)}',
                          badge: 'Omzet Lunas',
                          subtitle: 'Akumulasi transaksi offline & online sah',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Middle Row: Chart & Recent Properties
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 320,
                          child: DashboardChartSection(),
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 1,
                        child: SizedBox(
                          height: 320,
                          child: DashboardListSection(
                            title: 'Properti Terbaru',
                            onSeeAll: () {
                              Navigator.pushNamed(context, '/admin/properties');
                            },
                            items: recentProperties.isEmpty
                                ? const [
                                    Center(
                                      child: Padding(
                                        padding: EdgeInsets.all(16.0),
                                        child: Text('Belum ada properti'),
                                      ),
                                    ),
                                  ]
                                : recentProperties,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Statistics Donut (Activities removed)
                  Center(
                    child: SizedBox(
                      height: 360,
                      child: DashboardDonutChart(properties: _properties),
                    ),
                  ),
                ],
        ),
      ),
    );
  }
}
