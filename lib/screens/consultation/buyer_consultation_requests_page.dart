import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../models/consultation_request_model.dart';
import '../../services/consultation_service.dart';
import '../../widgets/bottom_nav_section.dart';
import '../../widgets/braga_page_header.dart';

class BuyerConsultationRequestsPage extends StatefulWidget {
  const BuyerConsultationRequestsPage({super.key});

  @override
  State<BuyerConsultationRequestsPage> createState() =>
      _BuyerConsultationRequestsPageState();
}

class _BuyerConsultationRequestsPageState
    extends State<BuyerConsultationRequestsPage> {
  final ConsultationService _consultationService = ConsultationService();

  bool _isLoading = true;
  bool _isLocaleReady = false;
  String? _errorMessage;
  List<ConsultationRequestModel> _consultations = const [];

  @override
  void initState() {
    super.initState();
    _preparePage();
  }

  Future<void> _preparePage() async {
    await initializeDateFormatting('id_ID');
    if (!mounted) return;

    setState(() {
      _isLocaleReady = true;
    });

    await _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _consultationService.getMyConsultationRequests();
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

  String _formatDate(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return '-';

    try {
      return DateFormat('d MMMM y, HH:mm', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  void _handleBottomNavTap(int index) {
    if (index == 3) return;

    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: {'selectedIndex': index},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EC),
      bottomNavigationBar: BottomNavSection(
        currentIndex: 3,
        onTap: _handleBottomNavTap,
      ),
      body: Column(
        children: [
          const BragaPageHeader(
            title: 'Chat Konsultasi',
            subtitle: 'Riwayat dan status konsultasi Anda.',
            decorativeIcon: Icons.forum_rounded,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadConsultations,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_isLocaleReady || _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: _MessageCard(
              title: 'Gagal memuat konsultasi',
              message: _errorMessage!,
              actionLabel: 'Coba lagi',
              onPressed: _loadConsultations,
            ),
          ),
        ],
      );
    }

    if (_consultations.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: _MessageCard(
              title: 'Belum ada chat konsultasi',
              message:
                  'Room chat Anda akan dibuat otomatis saat membuka menu konsultasi.',
              actionLabel: 'Muat ulang',
              onPressed: _loadConsultations,
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 92),
      itemCount: _consultations.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) => _ConsultationCard(
        consultation: _consultations[index],
        formatDate: _formatDate,
        onOpenDetail: () => Navigator.pushNamed(
          context,
          '/consultation-detail',
          arguments: _consultations[index].id,
        ),
      ),
    );
  }
}

class _ConsultationCard extends StatelessWidget {
  final ConsultationRequestModel consultation;
  final String Function(String?) formatDate;
  final VoidCallback onOpenDetail;

  const _ConsultationCard({
    required this.consultation,
    required this.formatDate,
    required this.onOpenDetail,
  });

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(consultation.status);
    final propertyTitle = consultation.propertyTitle ?? 'Konsultasi umum';
    final preview = consultation.lastMessage ?? consultation.message;
    final lastTime = consultation.lastMessageAt ?? consultation.createdAt;

    return InkWell(
      onTap: onOpenDetail,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE9D7BF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        propertyTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF3A2B1F),
                        ),
                      ),
                      if ((consultation.propertyLocation ?? '').isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          consultation.propertyLocation!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF7A6552),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      _compactTime(lastTime),
                      style: const TextStyle(
                        color: Color(0xFF7A6552),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _StatusChip(
                      label: badge.label,
                      background: badge.background,
                      foreground: badge.foreground,
                    ),
                    if (consultation.unreadCount > 0) ...[
                      const SizedBox(height: 6),
                      _UnreadBadge(count: consultation.unreadCount),
                    ],
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.chat_bubble_outline_rounded,
                  size: 16,
                  color: Color(0xFF8F4E1E),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    preview,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: consultation.unreadCount > 0
                          ? const Color(0xFF2F2318)
                          : const Color(0xFF7A6552),
                      fontWeight: consultation.unreadCount > 0
                          ? FontWeight.w900
                          : FontWeight.w600,
                    ),
                  ),
                ),
                if (consultation.lastMessageSenderUserId != null) ...[
                  const SizedBox(width: 6),
                  Icon(
                    consultation.lastMessageReadAt == null
                        ? Icons.done_rounded
                        : Icons.done_all_rounded,
                    size: 16,
                    color: consultation.lastMessageReadAt == null
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF0284C7),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            _DetailRow(label: 'Topik', value: consultation.topic),
            _DetailRow(
              label: 'Metode kontak',
              value: consultation.preferredContactMethod,
            ),
            _DetailRow(label: 'Pesan', value: consultation.message),
            _DetailRow(
              label: 'Diajukan',
              value: formatDate(consultation.createdAt),
            ),
            if ((consultation.staffNotes ?? '').isNotEmpty)
              _DetailRow(
                label: 'Catatan staf',
                value: consultation.staffNotes!,
              ),
            if (consultation.isResolved && consultation.propertyId != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/survey-form',
                      arguments: {
                        'propertyId': consultation.propertyId!,
                        'propertyTitle': propertyTitle,
                      },
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: const Text(
                    'Ajukan Survei',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

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
}

class _UnreadBadge extends StatelessWidget {
  final int count;

  const _UnreadBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFF25D366),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8A6A48),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF4E3B2C),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusChip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: foreground,
        ),
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _MessageCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9D7BF)),
      ),
      child: Column(
        children: [
          const Icon(Icons.forum_rounded, size: 42, color: Color(0xFF8F4E1E)),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF3A2B1F),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF7A6552), height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _StatusBadgeData {
  final String label;
  final Color background;
  final Color foreground;

  const _StatusBadgeData(this.label, this.background, this.foreground);
}

_StatusBadgeData _statusBadge(String status) {
  switch (status) {
    case 'contacted':
      return const _StatusBadgeData(
        'Disetujui',
        Color(0xFFE8F0FF),
        Color(0xFF1E4E8C),
      );
    case 'resolved':
      return const _StatusBadgeData(
        'Selesai',
        Color(0xFFE7F7ED),
        Color(0xFF1F7A3D),
      );
    case 'rejected':
      return const _StatusBadgeData(
        'Ditolak',
        Color(0xFFFFE7E7),
        Color(0xFFB42318),
      );
    default:
      return const _StatusBadgeData(
        'Pending',
        Color(0xFFFFF2D8),
        Color(0xFF9A5A00),
      );
  }
}
