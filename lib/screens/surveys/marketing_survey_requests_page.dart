import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../models/survey_request_model.dart';
import '../../services/survey_service.dart';
import '../../widgets/braga_page_header.dart';

class MarketingSurveyRequestsPage extends StatefulWidget {
  const MarketingSurveyRequestsPage({super.key});

  @override
  State<MarketingSurveyRequestsPage> createState() =>
      _MarketingSurveyRequestsPageState();
}

class _MarketingSurveyRequestsPageState
    extends State<MarketingSurveyRequestsPage> {
  final SurveyService _surveyService = SurveyService();

  bool _isLoading = true;
  bool _isFetching = false;
  bool _isLocaleReady = false;
  bool _isSubmitting = false;
  bool _hasLoadedSurveys = false;
  String _selectedStatus = 'all';
  int _loadRequestId = 0;
  String? _errorMessage;
  List<SurveyRequestModel> _surveys = const [];

  @override
  void initState() {
    super.initState();
    _preparePage();
  }

  Future<void> _preparePage() async {
    await initializeDateFormatting('id_ID');
    if (!mounted) {
      return;
    }

    setState(() {
      _isLocaleReady = true;
    });

    await _loadSurveys();
  }

  Future<void> _loadSurveys() async {
    final requestId = ++_loadRequestId;
    final isInitialLoad = !_hasLoadedSurveys;
    setState(() {
      if (isInitialLoad) _isLoading = true;
      _isFetching = true;
      _errorMessage = null;
    });

    try {
      final response = await _surveyService.getMarketingSurveyRequests(
        status: _selectedStatus == 'all' ? null : _selectedStatus,
      );
      if (!mounted || requestId != _loadRequestId) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        setState(() {
          _surveys = _surveyService.parseSurveys(response.body);
          _hasLoadedSurveys = true;
          _isLoading = false;
          _isFetching = false;
        });
        return;
      }

      final message = _surveyService.parseMessage(response.body);
      setState(() {
        _isLoading = false;
        _isFetching = false;
        if (!_hasLoadedSurveys) _errorMessage = message;
      });
      if (_hasLoadedSurveys) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } catch (error) {
      if (!mounted || requestId != _loadRequestId) return;
      final message = 'Gagal memuat permintaan survei: $error';
      setState(() {
        _isLoading = false;
        _isFetching = false;
        if (!_hasLoadedSurveys) _errorMessage = message;
      });
      if (_hasLoadedSurveys) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    }
  }

  String _formatDate(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return 'Belum Ditentukan';
    }

    try {
      return DateFormat('EEEE, d MMMM y', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _formatTime(String? value, [String? notes]) {
    if (notes != null && notes.isNotEmpty) {
      final match = RegExp(
        r'Rentang kedatangan:\s*([0-9]{2}:[0-9]{2})\s*[-–]\s*([0-9]{2}:[0-9]{2})',
      ).firstMatch(notes);
      if (match != null) {
        final start = match.group(1);
        final end = match.group(2);
        return '$start - $end WIB';
      }
    }

    final raw = value?.trim();
    if (raw == null || raw.isEmpty) {
      return 'Belum Ditentukan';
    }

    final normalized = raw.length == 5 ? '$raw:00' : raw;

    try {
      return '${DateFormat('HH:mm').format(DateFormat('HH:mm:ss').parseStrict(normalized))} WIB';
    } catch (_) {
      return '$raw WIB';
    }
  }

  Future<void> _approveSurvey(SurveyRequestModel survey) async {
    final today = DateUtils.dateOnly(DateTime.now());
    final lastAllowedDate = DateTime(today.year, today.month + 1, 0);
    final requestedDate = _parseSurveyDate(survey.requestedDate);
    DateTime selectedDate =
        requestedDate != null &&
            !DateUtils.dateOnly(requestedDate).isBefore(today) &&
            !DateUtils.dateOnly(requestedDate).isAfter(lastAllowedDate)
        ? DateUtils.dateOnly(requestedDate)
        : today;
    TimeOfDay selectedTime =
        _parseSurveyTime(survey.requestedTime) ??
        const TimeOfDay(hour: 10, minute: 0);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Setujui survei'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SchedulePickerTile(
                icon: Icons.calendar_month_rounded,
                label: 'Tanggal final',
                value: DateFormat(
                  'EEEE, d MMMM y',
                  'id_ID',
                ).format(selectedDate),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: dialogContext,
                    initialDate: selectedDate,
                    firstDate: today,
                    lastDate: lastAllowedDate,
                    helpText: 'Pilih tanggal final',
                    cancelText: 'Batal',
                    confirmText: 'Pilih',
                  );
                  if (picked == null) return;
                  setDialogState(() => selectedDate = picked);
                },
              ),
              const SizedBox(height: 12),
              _SchedulePickerTile(
                icon: Icons.access_time_rounded,
                label: 'Jam final',
                value: selectedTime.format(context),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: dialogContext,
                    initialTime: selectedTime,
                    helpText: 'Pilih jam final',
                    cancelText: 'Batal',
                    confirmText: 'Pilih',
                  );
                  if (picked == null) return;
                  setDialogState(() => selectedTime = picked);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _submitStatusUpdate(
      surveyId: survey.id,
      status: 'approved',
      approvedScheduleDate: DateFormat('yyyy-MM-dd').format(selectedDate),
      approvedScheduleTime: _formatTimeForApi(selectedTime),
    );
  }

  DateTime? _parseSurveyDate(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;

    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  TimeOfDay? _parseSurveyTime(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return null;

    final parts = raw.split(':');
    if (parts.length < 2) return null;

    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return null;
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTimeForApi(TimeOfDay value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$hour:$minute:00';
  }

  Future<void> _rejectSurvey(SurveyRequestModel survey) async {
    final reasonController = TextEditingController();
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Tolak survei'),
            content: TextField(
              controller: reasonController,
              maxLines: 3,
              maxLength: 500,
              onChanged: (_) => setDialogState(() {}),
              decoration: const InputDecoration(labelText: 'Alasan penolakan'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: reasonController.text.trim().isEmpty
                    ? null
                    : () => Navigator.pop(dialogContext, true),
                child: const Text('Simpan'),
              ),
            ],
          ),
        ),
      );

      if (confirmed == true && mounted) {
        await _submitStatusUpdate(
          surveyId: survey.id,
          status: 'rejected',
          rejectionReason: reasonController.text.trim(),
        );
      }
    } finally {
      reasonController.dispose();
    }
  }

  Future<void> _completeSurvey(SurveyRequestModel survey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selesaikan survei'),
        content: const Text(
          'Apakah Anda yakin ingin menandai survei ini sebagai selesai?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Selesai'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    await _submitStatusUpdate(surveyId: survey.id, status: 'completed');
  }

  Future<void> _submitStatusUpdate({
    required int surveyId,
    required String status,
    String? approvedScheduleDate,
    String? approvedScheduleTime,
    String? rejectionReason,
  }) async {
    setState(() => _isSubmitting = true);
    try {
      final response = await _surveyService.updateSurveyStatus(
        surveyId: surveyId,
        status: status,
        approvedScheduleDate: approvedScheduleDate,
        approvedScheduleTime: approvedScheduleTime,
        rejectionReason: rejectionReason,
      );
      if (!mounted) return;

      final message = _surveyService.parseMessage(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        await _loadSurveys();
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal memperbarui status survei: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  int _countByStatus(String status) {
    if (status == 'all') return _surveys.length;
    return _surveys.where((s) => s.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EC),
      body: Column(
        children: [
          const BragaPageHeader(
            title: 'Permintaan Jadwal Survei',
            subtitle: 'Kelola semua permintaan jadwal survei properti Anda',
            decorativeIcon: Icons.event_available_rounded,
          ),
          _buildFilterBar(),
          if (_isSubmitting || (_isFetching && _hasLoadedSurveys))
            const LinearProgressIndicator(
              minHeight: 2,
              color: Color(0xFF8F4E1E),
            ),
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFF8F4E1E),
              onRefresh: _loadSurveys,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    const filters = [
      ('all', 'Semua', Icons.grid_view_rounded),
      ('pending', 'Menunggu', Icons.hourglass_top_rounded),
      ('approved', 'Disetujui', Icons.check_circle_outline_rounded),
      ('completed', 'Selesai', Icons.task_alt_rounded),
      ('rejected', 'Ditolak', Icons.cancel_outlined),
      ('cancelled', 'Dibatalkan', Icons.cancel_presentation_rounded),
    ];

    return Container(
      color: const Color(0xFFF8F3EC),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: filters.map((f) {
            final value = f.$1;
            final label = f.$2;
            final icon = f.$3;
            final isActive = _selectedStatus == value;
            final count = _countByStatus(value);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  if (_selectedStatus == value) return;
                  setState(() => _selectedStatus = value);
                  _loadSurveys();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? const Color(0xFF8F4E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isActive
                          ? const Color(0xFF8F4E1E)
                          : const Color(0xFFE0CCBA),
                    ),
                    boxShadow: isActive
                        ? [
                            const BoxShadow(
                              color: Color(0x228F4E1E),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        icon,
                        size: 14,
                        color: isActive
                            ? Colors.white
                            : const Color(0xFF6C4A2F),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : const Color(0xFF5A3A22),
                        ),
                      ),
                      if (!_isLoading && count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: isActive
                                ? Colors.white.withValues(alpha: 0.25)
                                : const Color(0xFFE7CCAE),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isActive
                                  ? Colors.white
                                  : const Color(0xFF8F4E1E),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (!_isLocaleReady || _isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF8F4E1E)),
      );
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: _MarketingMessageCard(
              title: 'Gagal memuat permintaan survei',
              message: _errorMessage!,
              actionLabel: 'Coba lagi',
              onPressed: _loadSurveys,
            ),
          ),
        ],
      );
    }

    if (_surveys.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          Padding(
            padding: EdgeInsets.all(24),
            child: _MarketingEmptyCard(
              title: 'Belum ada permintaan survei',
              message: 'Pengajuan pembeli akan tampil di halaman ini.',
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: _surveys.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final survey = _surveys[index];
        final badge = _badgeStyle(survey.status);

        String shortDate(String? v) {
          final raw = v?.trim();
          if (raw == null || raw.isEmpty) return 'Belum Ditentukan';
          try {
            return DateFormat(
              'dd/MM/yyyy',
              'id_ID',
            ).format(DateTime.parse(raw));
          } catch (_) {
            return raw;
          }
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFECE2D8)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A3D2415),
                blurRadius: 16,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(2, 4, 8, 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        survey.propertyTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF342216),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            size: 14,
                            color: Color(0xFF8A6A48),
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              survey.propertyLocation,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.3,
                                color: Color(0xFF80664F),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _MidInfoCell(
                              icon: Icons.person_outline_rounded,
                              label: 'Pembeli',
                              value:
                                  (survey.buyerPhone != null &&
                                      survey.buyerPhone!.isNotEmpty)
                                  ? '${survey.buyerName}\n(${survey.buyerPhone})'
                                  : survey.buyerName,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MidInfoCell(
                              icon: Icons.calendar_today_outlined,
                              label: 'Tanggal',
                              value: _formatDate(
                                (survey.isApproved || survey.isCompleted)
                                    ? survey.approvedScheduleDate
                                    : survey.requestedDate,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MidInfoCell(
                              icon: Icons.access_time_outlined,
                              label: 'Jam',
                              value: _formatTime(
                                (survey.isApproved || survey.isCompleted)
                                    ? survey.approvedScheduleTime
                                    : survey.requestedTime,
                                survey.notes,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 170,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF0E2D2)),
                ),
                child: Padding(
                  padding: EdgeInsets.zero,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge status
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: badge.background,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                badge.icon,
                                size: 12,
                                color: badge.foreground,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                badge.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: badge.foreground,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // ID + Tanggal
                      Text(
                        '#SRV-${survey.id.toString().padLeft(6, '0')}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2A1A0E),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        shortDate(
                          (survey.isApproved || survey.isCompleted)
                              ? survey.approvedScheduleDate
                              : survey.requestedDate,
                        ),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A3728),
                        ),
                      ),
                      // Tombol aksi (hanya untuk pending)
                      if (survey.isPending) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _rejectSurvey(survey),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFC0392B),
                              side: const BorderSide(color: Color(0xFFE6A39C)),
                              minimumSize: const Size.fromHeight(34),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: const Text(
                              'Tolak',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _approveSurvey(survey),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF6B2B0A),
                              minimumSize: const Size.fromHeight(34),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: const Text(
                              'Setujui',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                      if (survey.isApproved) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                            onPressed: _isSubmitting
                                ? null
                                : () => _completeSurvey(survey),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF824316),
                              minimumSize: const Size.fromHeight(34),
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(9),
                              ),
                            ),
                            child: const Text(
                              'Selesai',
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MarketingMessageCard extends StatelessWidget {
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  const _MarketingMessageCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D7BF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6D5540)),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _MarketingEmptyCard extends StatelessWidget {
  final String title;
  final String message;

  const _MarketingEmptyCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D7BF)),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.event_available_rounded,
            size: 46,
            color: Color(0xFF8F4E1E),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14, color: Color(0xFF6D5540)),
          ),
        ],
      ),
    );
  }
}

class _SchedulePickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _SchedulePickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFFFF8EF),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9D7BF)),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFF8F4E1E)),
              const SizedBox(width: 12),
              Expanded(
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
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF3A2B1F),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF8A6A48)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BadgeStyle {
  final String label;
  final Color background;
  final Color foreground;
  final IconData icon;

  const _BadgeStyle({
    required this.label,
    required this.background,
    required this.foreground,
    required this.icon,
  });
}

_BadgeStyle _badgeStyle(String status) {
  switch (status) {
    case 'approved':
      return const _BadgeStyle(
        label: 'Disetujui',
        background: Color(0xFFE6F6EC),
        foreground: Color(0xFF1F7A45),
        icon: Icons.check_circle_outline_rounded,
      );
    case 'completed':
      return const _BadgeStyle(
        label: 'Selesai',
        background: Color(0xFFE7F7ED),
        foreground: Color(0xFF1F7A3D),
        icon: Icons.task_alt_rounded,
      );
    case 'rejected':
      return const _BadgeStyle(
        label: 'Ditolak',
        background: Color(0xFFFCE8E6),
        foreground: Color(0xFFC0392B),
        icon: Icons.cancel_outlined,
      );
    case 'cancelled':
      return const _BadgeStyle(
        label: 'Dibatalkan',
        background: Color(0xFFECEFF1),
        foreground: Color(0xFF455A64),
        icon: Icons.cancel_presentation_rounded,
      );
    default:
      return const _BadgeStyle(
        label: 'Menunggu',
        background: Color(0xFFFFF3D9),
        foreground: Color(0xFF9A6700),
        icon: Icons.hourglass_top_rounded,
      );
  }
}

class _MidInfoCell extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MidInfoCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: const Color(0xFF9A8070)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9A8070),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2A1A0E),
          ),
          maxLines: 5,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}
