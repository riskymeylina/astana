import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/braga_page_header.dart';

// ─── Date helpers ─────────────────────────────────────────────────────────────
String formatNotificationDate(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return '-';
  try {
    return DateFormat('d MMMM y, HH:mm', 'id_ID').format(DateTime.parse(raw));
  } catch (_) {
    return raw;
  }
}

String _shortDate(String? value) {
  final raw = value?.trim();
  if (raw == null || raw.isEmpty) return '-';
  try {
    final dt = DateTime.parse(raw).toLocal();
    final now = DateTime.now();
    final diff = DateTime(now.year, now.month, now.day)
        .difference(DateTime(dt.year, dt.month, dt.day))
        .inDays;
    if (diff == 0) return DateFormat('HH:mm').format(dt);
    if (diff == 1) return 'Kemarin ${DateFormat('HH:mm').format(dt)}';
    return DateFormat('d MMM').format(dt);
  } catch (_) {
    return raw;
  }
}

/// Groups notifications into: Hari ini / Kemarin / Minggu ini / Lebih lama
Map<String, List<NotificationModel>> _groupByDay(
    List<NotificationModel> items) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));
  final weekAgo = today.subtract(const Duration(days: 7));

  final groups = <String, List<NotificationModel>>{};

  for (final item in items) {
    DateTime? dt;
    try {
      dt = DateTime.parse(item.createdAt ?? '').toLocal();
    } catch (_) {}

    final String key;
    if (dt == null) {
      key = 'Lebih lama';
    } else {
      final day = DateTime(dt.year, dt.month, dt.day);
      if (!day.isBefore(today)) {
        key = 'Hari ini';
      } else if (!day.isBefore(yesterday)) {
        key = 'Kemarin';
      } else if (!day.isBefore(weekAgo)) {
        key = 'Minggu ini';
      } else {
        key = 'Lebih lama';
      }
    }

    groups.putIfAbsent(key, () => []).add(item);
  }

  // Preserve order
  const order = ['Hari ini', 'Kemarin', 'Minggu ini', 'Lebih lama'];
  return {
    for (final k in order)
      if (groups.containsKey(k)) k: groups[k]!,
  };
}

// ─── Colour palette (matches app brown/cream theme) ───────────────────────────
const _kBrown      = Color(0xFF6E340B);
const _kCreamBg    = Color(0xFFFFF6EC);
const _kCreamCard  = Color(0xFFFFF1DD);
const _kBorder     = Color(0xFFE7D9C8);
const _kInk        = Color(0xFF1F1A15);
const _kMuted      = Color(0xFF6A5948);
const _kRed        = Color(0xFFE96868);

// ═════════════════════════════════════════════════════════════════════════════
//  NotificationsPage
// ═════════════════════════════════════════════════════════════════════════════
class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;
  bool _isLocaleReady = false;
  PermissionStatus? _notificationPermissionStatus;
  String? _errorMessage;
  List<NotificationModel> _notifications = const [];

  @override
  void initState() {
    super.initState();
    _preparePage();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _preparePage() async {
    await initializeDateFormatting('id_ID');
    if (!mounted) return;
    setState(() => _isLocaleReady = true);
    await _loadNotificationPermissionStatus();
    await _loadNotifications();
  }

  Future<void> _loadNotificationPermissionStatus() async {
    if (kIsWeb) {
      setState(() {
        _notificationPermissionStatus = PermissionStatus.granted;
      });
      return;
    }
    final status = await Permission.notification.status;
    if (!mounted) return;
    setState(() {
      _notificationPermissionStatus = status;
    });
  }

  Future<void> _loadNotifications({String? search}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    final response = await _notificationService.getNotifications(
      search: search,
    );
    if (!mounted) return;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      setState(() {
        _notifications =
            _notificationService.parseNotifications(response.body);
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _errorMessage = _notificationService.parseMessage(response.body);
      _isLoading = false;
    });
  }

  Future<void> _refreshPage() async {
    await _loadNotificationPermissionStatus();
    await _loadNotifications();
  }

  void _searchNotifications(String value) {
    _loadNotifications(search: value.trim().isEmpty ? null : value.trim());
  }

  Future<void> _deleteNotification(int index) async {
    final notification = _notifications[index];
    setState(() {
      _notifications = List<NotificationModel>.from(_notifications)
        ..removeAt(index);
    });
    final response =
        await _notificationService.deleteNotification(notification.id);
    if (!mounted) return;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${notification.title} dihapus')));
      return;
    }
    setState(() {
      _notifications = List<NotificationModel>.from(_notifications)
        ..insert(index, notification);
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_notificationService.parseMessage(response.body))));
  }

  Future<void> _openNotification(NotificationModel notification) async {
    // 1. Optimistic local update
    final updatedLocal = notification.copyWith(readAt: DateTime.now().toIso8601String());
    setState(() {
      _notifications = _notifications
          .map((item) => item.id == notification.id ? updatedLocal : item)
          .toList(growable: false);
    });

    // 2. Open detail immediately
    _showNotificationDetail(updatedLocal);

    // 3. Update backend in background
    try {
      final response = await _notificationService.markAsRead(notification.id);
      if (mounted && response.statusCode >= 200 && response.statusCode < 300) {
        final parsed = _notificationService.parseNotification(response.body);
        setState(() {
          _notifications = _notifications
              .map((item) => item.id == parsed.id ? parsed : item)
              .toList(growable: false);
        });
      }
    } catch (_) {}
  }

  Future<void> _requestNotificationPermission() async {
    if (kIsWeb) return;
    final status = await Permission.notification.request();
    if (!mounted) return;
    setState(() {
      _notificationPermissionStatus = status;
    });
    final messenger = ScaffoldMessenger.of(context);
    if (status.isGranted) {
      messenger
          .showSnackBar(const SnackBar(content: Text('Izin notifikasi aktif')));
      return;
    }
    if (status.isPermanentlyDenied) {
      messenger.showSnackBar(SnackBar(
        content: const Text(
            'Izin notifikasi diblokir. Buka pengaturan untuk mengaktifkan.'),
        action: SnackBarAction(label: 'Settings', onPressed: openAppSettings),
      ));
      return;
    }
    messenger.showSnackBar(
        const SnackBar(content: Text('Izin notifikasi belum diberikan')));
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'purchase':
        return Icons.shopping_bag_outlined;
      case 'survey':
        return Icons.calendar_month_outlined;
      case 'consultation':
        return Icons.support_agent_outlined;
      case 'promotion':
        return Icons.local_offer_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    // Return the same brown/orange color for all types to match the design
    return const Color(0xFFD06B22);
  }

  void _showNotificationDetail(NotificationModel notification) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDD0C2),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(
                      color: _colorForType(notification.type)
                          .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(_iconForType(notification.type),
                        color: _colorForType(notification.type), size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(notification.title,
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: _kInk)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(formatNotificationDate(notification.createdAt),
                  style: const TextStyle(
                      fontSize: 12.5,
                      color: _kMuted,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kCreamBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _kBorder),
                ),
                child: Text(notification.message,
                    style: const TextStyle(
                        fontSize: 14.5, height: 1.5, color: _kInk)),
              ),
              if (notification.actionUrl != null) ...[
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _handleActionUrl(notification.actionUrl!);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBrown,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: const Text('Lihat Detail',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _handleActionUrl(String actionUrl) {
    final role = (AuthService().getSession()?['role'] ?? '')
        .toString()
        .toLowerCase();
    final isStaffOrAdmin = role == 'staf' || role == 'admin' || role == 'marketing';

    String route = actionUrl;
    if (actionUrl == '/consultations') {
      route = '/consultation';
    } else if (actionUrl == '/surveys' || actionUrl == '/buyer-survey-requests') {
      route = isStaffOrAdmin ? '/marketing-survey-requests' : '/buyer-survey-requests';
    } else if (actionUrl == '/purchases' || actionUrl == '/purchase-status') {
      route = isStaffOrAdmin ? '/marketing-orders' : '/purchase-status';
    }

    const knownRoutes = {
      '/consultation',
      '/buyer-survey-requests',
      '/marketing-survey-requests',
      '/purchase-status',
      '/marketing-orders',
      '/home',
    };
    if (knownRoutes.contains(route)) {
      Navigator.pushNamed(context, route);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detail notifikasi sudah dibuka')));
  }

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 700;
    return isWide ? _buildWideLayout() : _buildNarrowLayout();
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  NARROW  (mobile)
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildNarrowLayout() {
    return Scaffold(
      backgroundColor: _kCreamBg,
      body: Column(
        children: [
          BragaPageHeader(
            title: 'Notifikasi',
            subtitle: 'Pembaruan terbaru terkait akun dan aktivitas Anda',
            actions: [
              _buildArchiveIcon(isWide: false),
              const SizedBox(width: 12),
              _buildBellAction(isWide: false),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPage,
              color: _kBrown,
              child: _isLocaleReady
                  ? _buildNarrowBody()
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNarrowBody() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      children: [
        _buildSearchField(),
        const SizedBox(height: 12),
        // Content
        if (_isLoading)
          const _LoadingCard()
        else if (_errorMessage != null)
          _EmptyState(
            icon: Icons.error_outline_rounded,
            title: 'Gagal memuat notifikasi',
            message: _errorMessage!,
            actionLabel: 'Coba lagi',
            onPressed: _loadNotifications,
          )
        else if (_notifications.isEmpty)
          const _EmptyState(
            icon: Icons.notifications_off_outlined,
            title: 'Belum ada notifikasi',
            message: 'Semua pembaruan dari sistem akan muncul di sini.',
          )
        else
          _buildGroupedList(),
      ],
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      textInputAction: TextInputAction.search,
      onSubmitted: _searchNotifications,
      decoration: InputDecoration(
        hintText: 'Cari notifikasi...',
        prefixIcon: const Icon(Icons.search_rounded, color: _kBrown),
        suffixIcon: IconButton(
          onPressed: () {
            _searchController.clear();
            _searchNotifications('');
          },
          icon: const Icon(Icons.close_rounded),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _kBorder),
        ),
      ),
    );
  }

  Widget _buildBellAction({bool isWide = false}) {
    final unread = _notifications.where((n) => !n.isRead).length;
    final iconColor = isWide ? _kBrown : Colors.white;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) {
            return StatefulBuilder(
              builder: (ctx, setSheetState) {
                final isGranted = _notificationPermissionStatus?.isGranted ?? false;
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40, height: 4,
                          margin: const EdgeInsets.only(bottom: 24),
                          decoration: BoxDecoration(
                            color: const Color(0xFFDDD0C2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(
                                color: _kCreamCard,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.notifications_active_rounded,
                                  color: _kBrown, size: 24),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Aktifkan notifikasi sekarang',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      color: _kInk,
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'Dapatkan pembaruan langsung dari platform',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: _kMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: isGranted,
                              activeColor: _kBrown,
                              onChanged: (bool value) async {
                                if (value) {
                                  await _requestNotificationPermission();
                                  setSheetState(() {});
                                  setState(() {});
                                } else {
                                  final result = await showDialog<bool>(
                                    context: context,
                                    builder: (c) => AlertDialog(
                                      title: const Text('Nonaktifkan Notifikasi'),
                                      content: const Text(
                                          'Untuk menonaktifkan notifikasi, Anda harus mengubahnya di pengaturan aplikasi.'),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(c, false),
                                          style: TextButton.styleFrom(foregroundColor: _kMuted),
                                          child: const Text('Batal'),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(c, true),
                                          style: TextButton.styleFrom(foregroundColor: _kBrown),
                                          child: const Text('Pengaturan', style: TextStyle(fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (result == true) {
                                    await openAppSettings();
                                    await _loadNotificationPermissionStatus();
                                  }
                                  setSheetState(() {});
                                  setState(() {});
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.notifications_outlined, color: iconColor, size: 28),
          if (unread > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0A23A),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$unread',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildArchiveIcon({bool isWide = false}) {
    final iconColor = isWide ? _kBrown : Colors.white;
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          backgroundColor: Colors.white,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          builder: (ctx) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDD0C2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      color: _kCreamCard,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inventory_2_outlined,
                        color: _kBrown, size: 36),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Arsip Notifikasi',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _kInk,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Semua notifikasi penting yang Anda simpan akan muncul di sini. Saat ini belum ada data.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: _kMuted,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBrown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Tutup',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      child: Icon(Icons.inventory_2_outlined, color: iconColor, size: 28),
    );
  }

  Widget _buildGroupedList() {
    final groups = _groupByDay(_notifications);
    final widgets = <Widget>[];

    int flatIndex = 0;
    for (final entry in groups.entries) {
      widgets.add(_DayHeader(label: entry.key));
      widgets.add(const SizedBox(height: 10));
      for (int i = 0; i < entry.value.length; i++) {
        final item = entry.value[i];
        final currentFlatIndex = flatIndex;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Dismissible(
              key: ValueKey(item.id),
              direction: DismissDirection.endToStart,
              background: _DismissBackground(),
              onDismissed: (_) => _deleteNotification(currentFlatIndex),
              child: _NotificationCard(
                notification: item,
                icon: _iconForType(item.type),
                iconColor: _colorForType(item.type),
                onTap: () => _openNotification(item),
              ),
            ),
          ),
        );
        flatIndex++;
      }
      widgets.add(const SizedBox(height: 6));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildWideLayout() {
    return Scaffold(
      backgroundColor: _kCreamBg,
      body: Column(
        children: [
          BragaPageHeader(
            title: 'Notifikasi',
            subtitle: 'Pembaruan terbaru terkait akun dan aktivitas Anda',
            actions: [
              _buildArchiveIcon(isWide: false),
              const SizedBox(width: 12),
              _buildBellAction(isWide: false),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refreshPage,
              color: _kBrown,
              child: _isLocaleReady
                  ? _buildWideBody()
                  : const Center(child: CircularProgressIndicator()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWideBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(32, 12, 32, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchField(),
          const SizedBox(height: 16),
          // Content
          if (_isLoading)
            const _LoadingCard()
          else if (_errorMessage != null)
            _EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Gagal memuat notifikasi',
              message: _errorMessage!,
              actionLabel: 'Coba lagi',
              onPressed: _loadNotifications,
            )
          else if (_notifications.isEmpty)
            const _EmptyState(
              icon: Icons.notifications_off_outlined,
              title: 'Belum ada notifikasi',
              message: 'Semua pembaruan dari sistem akan muncul di sini.',
            )
          else
            _buildWideGroupedList(),
        ],
      ),
    );
  }

  Widget _buildWideGroupedList() {
    final groups = _groupByDay(_notifications);
    final widgets = <Widget>[];

    int flatIndex = 0;
    for (final entry in groups.entries) {
      widgets.add(_DayHeader(label: entry.key, isWide: true));
      widgets.add(const SizedBox(height: 12));
      for (int i = 0; i < entry.value.length; i++) {
        final item = entry.value[i];
        final currentFlatIndex = flatIndex;
        widgets.add(
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Dismissible(
              key: ValueKey(item.id),
              direction: DismissDirection.endToStart,
              background: _DismissBackground(),
              onDismissed: (_) => _deleteNotification(currentFlatIndex),
              child: _NotificationCard(
                notification: item,
                icon: _iconForType(item.type),
                iconColor: _colorForType(item.type),
                onTap: () => _openNotification(item),
                isWide: true,
              ),
            ),
          ),
        );
        flatIndex++;
      }
      widgets.add(const SizedBox(height: 10));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}

// ─── Day Group Header ─────────────────────────────────────────────────────────
class _DayHeader extends StatelessWidget {
  final String label;
  final bool isWide;

  const _DayHeader({required this.label, this.isWide = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: isWide ? 0 : 4, bottom: 6),
      child: Row(
        children: [
          Text(label,
              style: TextStyle(
                fontSize: isWide ? 17 : 16,
                fontWeight: FontWeight.w900,
                color: _kInk,
              )),
          const SizedBox(width: 12),
          Container(
            width: 24,
            height: 2,
            color: const Color(0xFFF0A23A),
          ),
          Expanded(
            child: Container(
              height: 1, 
              color: const Color(0xFFEBE0D3),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Notification Card ────────────────────────────────────────────────────────
class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isWide;

  const _NotificationCard({
    required this.notification,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.isWide = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;

    return Material(
      color: isUnread ? const Color(0xFFFFFAF4) : Colors.white,
      borderRadius: BorderRadius.circular(isWide ? 16 : 18),
      child: InkWell(
        borderRadius: BorderRadius.circular(isWide ? 16 : 18),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(isWide ? 16 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isWide ? 16 : 18),
            border: Border.all(
              color: isUnread
                  ? const Color(0xFFF0C97A)
                  : _kBorder,
              width: isUnread ? 1.5 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar / icon
              Container(
                width: isWide ? 46 : 50,
                height: isWide ? 46 : 50,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isWide ? 12 : 14),
                ),
                child: _NotificationAvatar(
                  notification: notification,
                  icon: icon,
                  iconColor: iconColor,
                ),
              ),
              SizedBox(width: isWide ? 14 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(notification.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: isWide ? 14.5 : 15,
                          color: _kInk,
                        )),
                    const SizedBox(height: 4),
                    Text(notification.message,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: _kMuted,
                            fontWeight: FontWeight.w500)),
                    if (isWide) ...[
                      const SizedBox(height: 6),
                      Text(formatNotificationDate(notification.createdAt),
                          style: const TextStyle(
                              fontSize: 11.5,
                              color: _kMuted,
                              fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          color: isUnread ? const Color(0xFFF0A23A) : const Color(0xFFC4B5A5),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(_shortDate(notification.createdAt),
                          style: const TextStyle(
                              fontSize: 12,
                              color: _kMuted,
                              fontWeight: FontWeight.w500)),
                      const SizedBox(width: 6),
                      Icon(Icons.chevron_right_rounded,
                          color: _kMuted.withOpacity(0.8), size: 18),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationAvatar extends StatelessWidget {
  final NotificationModel notification;
  final IconData icon;
  final Color iconColor;

  const _NotificationAvatar({
    required this.notification,
    required this.icon,
    required this.iconColor,
  });

  String? _safeUrl(String? v) {
    final uri = Uri.tryParse(v ?? '');
    if (uri == null || !uri.hasScheme) return null;
    return (uri.scheme == 'http' || uri.scheme == 'https') ? v : null;
  }

  @override
  Widget build(BuildContext context) {
    final url = _safeUrl(notification.imageUrl);
    if (url != null && url.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(url,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) =>
                Icon(icon, color: iconColor, size: 22)),
      );
    }
    return Icon(icon, color: iconColor, size: 22);
  }
}

// ─── Dismiss background ───────────────────────────────────────────────────────
class _DismissBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          width: 80,
          decoration: BoxDecoration(
            color: _kRed,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Center(
            child: Icon(Icons.delete_outline_rounded, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

// ─── Loading card ─────────────────────────────────────────────────────────────
class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: const Center(
          child: CircularProgressIndicator(color: _kBrown)),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  const _EmptyState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: const Color(0xFFD4C4B0)),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _kInk)),
          const SizedBox(height: 8),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13.5, color: _kMuted)),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBrown,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                    horizontal: 28, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(actionLabel!,
                  style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ],
      ),
    );
  }
}