// ════════════════════════════════════════════════════════════════════════════
// MANAGE CONSULTATIONS PAGE  (Staff)
// Uses the same ConsultationService / ConsultationRequestModel as the
// buyer-side and main staff consultation module. No dummy data.
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../models/consultation_request_model.dart';
import '../../services/consultation_service.dart';
import '../../widgets/braga_page_header.dart';

class ManageConsultationsPage extends StatefulWidget {
  const ManageConsultationsPage({super.key});

  @override
  State<ManageConsultationsPage> createState() =>
      _ManageConsultationsPageState();
}

class _ManageConsultationsPageState extends State<ManageConsultationsPage> {
  final ConsultationService _consultationService = ConsultationService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isLocaleReady = false;
  bool _isSubmitting = false;
  String _selectedTab = 'all';
  String _searchQuery = '';
  String? _errorMessage;
  List<ConsultationRequestModel> _consultations = const [];

  // ── colours ───────────────────────────────────────────────────────────────
  static const _brown = Color(0xFF632B0A);
  static const _brownMid = Color(0xFF964B1A);
  static const _brownLight = Color(0xFFFFF0E0);
  static const _textDark = Color(0xFF2F2318);
  static const _textMid = Color(0xFF5A4535);
  static const _textLight = Color(0xFF8A7563);
  static const _border = Color(0xFFF0E1CF);
  static const _bg = Color(0xFFFDFBF9);

  // ── lifecycle ─────────────────────────────────────────────────────────────
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

    _searchController.addListener(() {
      if (!mounted) return;
      setState(
        () => _searchQuery = _searchController.text.trim().toLowerCase(),
      );
    });

    setState(() => _isLocaleReady = true);
    await _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _consultationService.getStaffConsultationRequests();
    if (!mounted) return;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      setState(() {
        _consultations = _consultationService.parseConsultations(response.body);
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _errorMessage = _consultationService.parseMessage(response.body);
      _isLoading = false;
    });
  }

  Future<void> _markResolved(ConsultationRequestModel consultation) async {
    setState(() => _isSubmitting = true);
    final response = await _consultationService.updateConsultationStatus(
      consultationId: consultation.id,
      status: 'resolved',
      staffNotes: consultation.staffNotes ?? 'Konsultasi diselesaikan staf.',
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_consultationService.parseMessage(response.body)),
        backgroundColor: response.statusCode < 300
            ? _brown
            : const Color(0xFFC74C4C),
      ),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await _loadConsultations();
    }
  }

  // ── safe navigation to the shared detail page ─────────────────────────────
  void _openDetail(int id) {
    if (!mounted) return;
    Navigator.pushNamed(context, '/consultation-detail', arguments: id).then((
      _,
    ) {
      if (mounted) _loadConsultations();
    });
  }

  // ── status tabs + search ──────────────────────────────────────────────────
  List<ConsultationRequestModel> get _visible {
    final filtered = _consultations.where((c) {
      final matchesTab = switch (_selectedTab) {
        'unread' => c.unreadCount > 0,
        'read' => c.unreadCount == 0,
        'resolved' => c.status == 'resolved',
        _ => true,
      };
      if (!matchesTab) return false;
      if (_searchQuery.isEmpty) return true;

      final searchable = [
        c.buyerName,
        c.buyerPhone,
        c.buyerEmail,
        c.propertyTitle ?? '',
        c.propertyLocation ?? '',
        c.topic,
        c.message,
        c.lastMessage ?? '',
      ].join(' ').toLowerCase();
      return searchable.contains(_searchQuery);
    }).toList();

    filtered.sort((a, b) => _sortDate(b).compareTo(_sortDate(a)));

    final Map<int, ConsultationRequestModel> grouped = {};
    for (final c in filtered) {
      if (!grouped.containsKey(c.buyerUserId)) {
        grouped[c.buyerUserId] = c;
      } else {
        final existing = grouped[c.buyerUserId]!;
        grouped[c.buyerUserId] = ConsultationRequestModel(
          id: existing.id,
          buyerUserId: existing.buyerUserId,
          buyerName: existing.buyerName,
          buyerPhone: existing.buyerPhone,
          buyerEmail: existing.buyerEmail,
          buyerWhatsapp: existing.buyerWhatsapp,
          propertyId: existing.propertyId,
          propertyTitle: existing.propertyTitle,
          propertyLocation: existing.propertyLocation,
          topic: existing.topic,
          preferredContactMethod: existing.preferredContactMethod,
          message: existing.message,
          status: existing.status,
          staffNotes: existing.staffNotes,
          processedByUserId: existing.processedByUserId,
          processedByName: existing.processedByName,
          processedAt: existing.processedAt,
          createdAt: existing.createdAt,
          updatedAt: existing.updatedAt,
          lastMessage: existing.lastMessage ?? existing.message,
          lastMessageAt: existing.lastMessageAt ?? existing.createdAt,
          lastMessageSenderUserId: existing.lastMessageSenderUserId,
          lastMessageReadAt: existing.lastMessageReadAt,
          unreadCount: existing.unreadCount + c.unreadCount,
          surveyId: existing.surveyId,
          surveyStatus: existing.surveyStatus,
          surveyDate: existing.surveyDate,
          surveyTime: existing.surveyTime,
        );
      }
    }

    return grouped.values.toList();
  }

  DateTime _sortDate(ConsultationRequestModel c) =>
      DateTime.tryParse(
        c.lastMessageAt ?? c.updatedAt ?? c.createdAt ?? '',
      )?.toLocal() ??
      DateTime.fromMillisecondsSinceEpoch(0);

  // ── time helper ───────────────────────────────────────────────────────────
  String _compactTime(String? value) {
    final parsed = DateTime.tryParse(value ?? '')?.toLocal();
    if (parsed == null) return '-';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(parsed.year, parsed.month, parsed.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return DateFormat('HH:mm', 'id_ID').format(parsed);
    if (diff == 1) return 'Kemarin';
    return DateFormat('dd/MM/yy', 'id_ID').format(parsed);
  }

  int get _unreadCount => _consultations.where((c) => c.unreadCount > 0).length;

  // ════════════════════════════════════════════════════════════════════════
  // BUILD
  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BragaPageHeader(
            title: 'Chat Konsultasi Konsumen',
            subtitle: 'Kelola semua percakapan konsultasi dengan konsumen Anda',
            decorativeIcon: Icons.forum_rounded,
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: _buildSearchBar(),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: _buildStatusTabs(),
          ),

          if (_isSubmitting)
            const LinearProgressIndicator(
              minHeight: 2,
              color: _brownMid,
              backgroundColor: _brownLight,
            ),

          Expanded(
            child: RefreshIndicator(
              color: _brown,
              onRefresh: _loadConsultations,
              child: _buildBody(),
            ),
          ),

          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 13, color: _textDark),
        decoration: InputDecoration(
          hintText: 'Cari nama, properti, topik, atau pesan…',
          hintStyle: const TextStyle(color: Color(0xFFB0A090), fontSize: 13),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _textLight,
            size: 18,
          ),
          suffixIcon: _searchQuery.isEmpty
              ? null
              : IconButton(
                  onPressed: _searchController.clear,
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _textLight,
                    size: 18,
                  ),
                ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ── Status tabs ───────────────────────────────────────────────────────────
  Widget _buildStatusTabs() {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 10,
        runSpacing: 8,
        children: [
          _chip(value: 'all', label: 'Semua'),
          _chip(
            value: 'unread',
            label: 'Belum dibaca',
            badgeCount: _unreadCount > 0 ? _unreadCount : null,
          ),
          _chip(value: 'read', label: 'Sudah dibaca'),
          _chip(
            value: 'resolved',
            label: 'Selesai',
            showDot: true,
            dotColor: _textLight,
          ),
        ],
      ),
    );
  }

  Widget _chip({
    required String value,
    required String label,
    int? badgeCount,
    bool showDot = false,
    Color? dotColor,
  }) {
    final isSelected = _selectedTab == value;
    return InkWell(
      onTap: () => setState(() => _selectedTab = value),
      borderRadius: BorderRadius.circular(100),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? _brown : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? Colors.transparent : const Color(0xFFFAF0E6),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot && dotColor != null) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? Colors.white : _textMid,
              ),
            ),
            if (badgeCount != null) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: Color(0xFFE28A43),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Bottom Bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final visible = _visible.length;
    final total = _consultations.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
      decoration: const BoxDecoration(
        color: _bg,
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Menampilkan $visible dari $total percakapan',
            style: const TextStyle(fontSize: 12, color: _textLight),
          ),
          ElevatedButton.icon(
            onPressed: _isLoading ? null : _loadConsultations,
            style: ElevatedButton.styleFrom(
              backgroundColor: _brown,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: const Text(
              'Muat ulang',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (!_isLocaleReady || _isLoading) {
      return const Center(child: CircularProgressIndicator(color: _brownMid));
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _InfoCard(
            icon: Icons.error_outline_rounded,
            iconColor: const Color(0xFFC74C4C),
            title: 'Gagal memuat chat konsultasi',
            message: _errorMessage!,
            actionLabel: 'Coba lagi',
            onPressed: _loadConsultations,
          ),
        ],
      );
    }

    final list = _visible;
    if (list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: const [
          _InfoCard(
            icon: Icons.forum_rounded,
            iconColor: _brownMid,
            title: 'Chat tidak ditemukan',
            message:
                'Tidak ada pengajuan konsultasi dari konsumen saat ini. '
                'Coba ubah kata kunci pencarian.',
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox.shrink(),
      itemBuilder: (context, index) {
        final c = list[index];
        return _ConsultationTile(
          consultation: c,
          compactTime: _compactTime,
          onOpenDetail: () => _openDetail(c.id),
          onMarkResolved: () => _markResolved(c),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// CONSULTATION TILE
// ════════════════════════════════════════════════════════════════════════════
class _ConsultationTile extends StatelessWidget {
  final ConsultationRequestModel consultation;
  final String Function(String?) compactTime;
  final VoidCallback onOpenDetail;
  final VoidCallback onMarkResolved;

  const _ConsultationTile({
    required this.consultation,
    required this.compactTime,
    required this.onOpenDetail,
    required this.onMarkResolved,
  });

  static const _avatarColors = [
    Color(0xFFE28A43),
    Color(0xFF7C5CBF),
    Color(0xFF3B82F6),
    Color(0xFF3DAA6E),
    Color(0xFFCB4D4D),
    Color(0xFF0891B2),
  ];

  Color get _avatarColor =>
      _avatarColors[consultation.buyerUserId % _avatarColors.length];

  @override
  Widget build(BuildContext context) {
    final name = consultation.buyerName.trim().isEmpty
        ? 'Konsumen'
        : consultation.buyerName.trim();
    final topic = consultation.propertyTitle ?? consultation.topic;
    final preview = (consultation.lastMessage ?? consultation.message).trim();
    final hasUnread = consultation.unreadCount > 0;
    final isResolved = consultation.status == 'resolved';
    final lastTime =
        consultation.lastMessageAt ??
        consultation.updatedAt ??
        consultation.createdAt;

    return Padding(
      padding: const EdgeInsets.only(bottom: 1),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: Color(0xFFF5E6D3))),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── Avatar ───────────────────────────────────────────────
              CircleAvatar(
                radius: 22,
                backgroundColor: _avatarColor,
                child: Text(
                  name[0].toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // ── Name + topic + preview ────────────────────────────────
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F2318),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAF0E6),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.assignment_outlined,
                            size: 11,
                            color: Color(0xFF8A7563),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              topic,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF8A7563),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: hasUnread
                              ? const Color(0xFF8A7563)
                              : const Color(0xFF3B82F6),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            preview.isEmpty ? 'Belum ada pesan.' : preview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF5A4535),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      compactTime(lastTime),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFFB0A090),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Unread badge ──────────────────────────────────────────
              Expanded(
                flex: 2,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: hasUnread
                          ? const Color(0xFFFFF0E5)
                          : const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      hasUnread ? 'BELUM DIBACA' : 'SUDAH DIBACA',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: hasUnread
                            ? const Color(0xFFE28A43)
                            : const Color(0xFF627D98),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // ── Date + status ─────────────────────────────────────────
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      compactTime(lastTime),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8A7563),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isResolved
                            ? const Color(0xFFF0F0F0)
                            : const Color(0xFFE6F7EE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isResolved
                                  ? const Color(0xFF8A7563)
                                  : const Color(0xFF3DAA6E),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isResolved ? 'Selesai' : 'Aktif',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isResolved
                                  ? const Color(0xFF8A7563)
                                  : const Color(0xFF3DAA6E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // ── Actions ───────────────────────────────────────────────
              Expanded(
                flex: 2,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onOpenDetail,
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF964B1A)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                      ),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 12,
                        color: Color(0xFF964B1A),
                      ),
                      label: const Text(
                        'Lihat Chat',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF964B1A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    PopupMenuButton<String>(
                      onSelected: (v) {
                        if (v == 'resolve') onMarkResolved();
                        if (v == 'detail') onOpenDetail();
                      },
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Color(0xFF8A7563),
                        size: 18,
                      ),
                      itemBuilder: (_) => [
                        if (!isResolved)
                          const PopupMenuItem(
                            value: 'resolve',
                            child: Text('Tandai Selesai'),
                          ),
                        const PopupMenuItem(
                          value: 'detail',
                          child: Text('Lihat Detail'),
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

// ════════════════════════════════════════════════════════════════════════════
// INFO CARD (error / empty state)
// ════════════════════════════════════════════════════════════════════════════
class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onPressed;

  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0E1CF)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 44, color: iconColor),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Color(0xFF2F2318),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8A7563),
              height: 1.5,
            ),
          ),
          if (actionLabel != null && onPressed != null) ...[
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF632B0A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: Text(
                actionLabel!,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
