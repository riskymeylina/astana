import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../services/survey_service.dart';
import '../../services/purchase_service.dart';
import '../../services/property_service.dart';
import '../../models/purchase_order_model.dart';
import '../../models/property_model.dart';
import '../../widgets/braga_page_header.dart';
import 'survey_shared.dart';

// ─── Colour aliases ────────────────────────────────────────────────────────────
const _brown = surveyBrown;
const _brownMid = surveyBrownMid;
const _brownDeep = surveyBrownDeep;
const _cream = surveyCream;
const _creamBg = surveyCreamBg;
const _creamCard = surveyCreamCard;
const _border = surveyBorder;
const _ink = surveyInk;
const _muted = surveyMuted;
const _light = surveyLight;

// ═════════════════════════════════════════════════════════════════════════════
//  SurveyFormPage
// ═════════════════════════════════════════════════════════════════════════════
class SurveyFormPage extends StatefulWidget {
  const SurveyFormPage({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    this.initialSurveyId,
    this.initialRequestedDate,
    this.initialRequestedTime,
    this.initialNotes,
  });

  final int propertyId;
  final String propertyTitle;

  // Optional initial values when opened to edit / resubmit an existing request
  final int? initialSurveyId;
  final String? initialRequestedDate; // yyyy-MM-dd
  final String? initialRequestedTime; // HH:mm or HH:mm:ss
  final String? initialNotes;

  @override
  State<SurveyFormPage> createState() => _SurveyFormPageState();
}

class _SurveyFormPageState extends State<SurveyFormPage> {
  final SurveyService _surveyService = SurveyService();
  final PurchaseService _purchaseService = PurchaseService();
  final PropertyService _propertyService = PropertyService();

  PurchaseOrderModel? _order;
  PropertyModel? _property;

  DateTime? _selectedDate;
  TimeOfDay _fromTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _toTime = const TimeOfDay(hour: 0, minute: 0);

  int _visitors = 2;
  bool _isSubmitting = false;
  bool _localeReady = false;
  String? _dateError;

  DateTime _calMonth = DateTime.now();

  final TextEditingController _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _boot();
    _loadData();
    if (widget.initialRequestedDate != null) {
      try {
        _selectedDate = DateTime.parse(widget.initialRequestedDate!);
      } catch (_) {}
    }

    // Set fallback/default for _toTime
    final defaultMins = _fromTime.hour * 60 + _fromTime.minute + 90;
    _toTime = TimeOfDay(hour: (defaultMins ~/ 60) % 24, minute: defaultMins % 60);

    if (widget.initialRequestedTime != null) {
      try {
        final parts = widget.initialRequestedTime!.split(':');
        final h = int.tryParse(parts[0]) ?? 10;
        final m = int.tryParse(parts[1]) ?? 0;
        _fromTime = TimeOfDay(hour: h, minute: m);

        final mins = h * 60 + m + 90;
        _toTime = TimeOfDay(hour: (mins ~/ 60) % 24, minute: mins % 60);
      } catch (_) {}
    }

    if (widget.initialNotes != null) {
      final rawNotes = widget.initialNotes!;
      final lines = rawNotes.split('\n');
      int? parsedVisitors;
      TimeOfDay? parsedFromTime;
      TimeOfDay? parsedToTime;
      final customNotesLines = <String>[];

      for (var line in lines) {
        final trimmedLine = line.trim();
        if (trimmedLine.startsWith('Jumlah pengunjung:')) {
          final val = trimmedLine.replaceFirst('Jumlah pengunjung:', '').trim();
          parsedVisitors = int.tryParse(val);
        } else if (trimmedLine.startsWith('Rentang kedatangan:')) {
          final val = trimmedLine
              .replaceFirst('Rentang kedatangan:', '')
              .replaceAll('WIB', '')
              .trim();
          final parts = val.split(RegExp(r'[-–]'));
          if (parts.length == 2) {
            final fromParts = parts[0].trim().split(':');
            final toParts = parts[1].trim().split(':');
            if (fromParts.length == 2) {
              final h = int.tryParse(fromParts[0]);
              final m = int.tryParse(fromParts[1]);
              if (h != null && m != null) {
                parsedFromTime = TimeOfDay(hour: h, minute: m);
              }
            }
            if (toParts.length == 2) {
              final h = int.tryParse(toParts[0]);
              final m = int.tryParse(toParts[1]);
              if (h != null && m != null) {
                parsedToTime = TimeOfDay(hour: h, minute: m);
              }
            }
          }
        } else {
          customNotesLines.add(line);
        }
      }

      if (parsedVisitors != null) {
        _visitors = parsedVisitors;
      }
      if (parsedFromTime != null) {
        _fromTime = parsedFromTime;
      }
      if (parsedToTime != null) {
        _toTime = parsedToTime;
      }
      _notesCtrl.text = customNotesLines.join('\n').trim();
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _boot() async {
    await initializeDateFormatting('id_ID');
    if (!mounted) return;
    setState(() => _localeReady = true);
  }

  Future<void> _loadData() async {
    try {
      final pr = await _propertyService.getPropertyDetail(widget.propertyId);
      if (pr.statusCode >= 200 && pr.statusCode < 300 && mounted) {
        setState(
          () => _property = _propertyService.parsePropertyDetail(pr.body),
        );
      }
    } catch (_) {}

    try {
      final r = await _purchaseService.getMyOrders();
      if (r.statusCode >= 200 && r.statusCode < 300 && mounted) {
        final orders = _purchaseService.parseOrders(r.body);
        final match = orders.where((o) => o.propertyId == widget.propertyId);
        if (match.isNotEmpty) {
          setState(() => _order = match.first);
        }
      }
    } catch (_) {}
  }

  int _minutesOfDay(TimeOfDay time) {
    return time.hour * 60 + time.minute;
  }

  // String _formatTime24(TimeOfDay time) {
  //   final hour = time.hour.toString().padLeft(2, '0');
  //   final minute = time.minute.toString().padLeft(2, '0');

  //   return '$hour:$minute';
  // }

  void _showTimeError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ── Time Picker ───────────────────────────────────────────────────────────
  Future<void> _pickTime({required bool isFrom}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isFrom ? _fromTime : _toTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    final pickedMinutes = _minutesOfDay(picked);
    final fromMinutes = _minutesOfDay(_fromTime);
    final toMinutes = _minutesOfDay(_toTime);

    if (isFrom) {
      if (pickedMinutes >= toMinutes) {
        _showTimeError(
          'Waktu Dari tidak boleh sama atau lebih besar dari waktu Sampai.',
        );
        return;
      }

      setState(() {
        _fromTime = picked;
      });
    } else {
      if (pickedMinutes <= fromMinutes) {
        _showTimeError('Waktu Sampai harus lebih besar dari waktu Dari.');
        return;
      }

      setState(() {
        _toTime = picked;
      });
    }
  }

  Future<void> _submit() async {
    final now = DateTime.now();

    // Validation: date required
    if (_selectedDate == null) {
      setState(() => _dateError = 'Pilih tanggal survei terlebih dahulu');
      return;
    }

    // Validation: date not in the past
    final selectedDay = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    if (selectedDay.isBefore(today)) {
      setState(
        () =>
            _dateError = 'Tanggal survei tidak boleh tanggal yang sudah lewat',
      );
      return;
    }

    // Validation: time not in the past if today is selected
    if (selectedDay.isAtSameMomentAs(today)) {
      final selectedMinutes = _fromTime.hour * 60 + _fromTime.minute;
      final nowMinutes = now.hour * 60 + now.minute;
      if (selectedMinutes <= nowMinutes) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Jam survei tidak boleh waktu yang sudah lewat untuk hari ini',
            ),
            backgroundColor: Color(0xFFB84040),
          ),
        );
        return;
      }
    }

    setState(() => _isSubmitting = true);

    final timeStr =
        '${_fromTime.hour.toString().padLeft(2, '0')}:${_fromTime.minute.toString().padLeft(2, '0')}';

    final notesParts = [
      'Jumlah pengunjung: $_visitors',
      'Rentang kedatangan: ${_fmtTime(_fromTime)} – ${_fmtTime(_toTime)} WIB',
    ];
    if (_notesCtrl.text.trim().isNotEmpty)
      notesParts.add(_notesCtrl.text.trim());

    dynamic resp;
    if (widget.initialSurveyId != null) {
      resp = await _surveyService.updateSurveyRequest(
        surveyId: widget.initialSurveyId!,
        requestedDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        requestedTime: timeStr,
        notes: notesParts.join('\n'),
      );
    } else {
      resp = await _surveyService.createSurveyRequest(
        propertyId: widget.propertyId,
        requestedDate: DateFormat('yyyy-MM-dd').format(_selectedDate!),
        requestedTime: timeStr,
        notes: notesParts.join('\n'),
      );
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      await _showSuccess();
      if (mounted)
        Navigator.pushReplacementNamed(context, '/buyer-survey-requests');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_surveyService.parseMessage(resp.body)),
          backgroundColor: const Color(0xFFB84040),
        ),
      );
    }
  }

  Future<void> _showSuccess() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: _creamBg,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: _cream.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 42,
                  color: _brown,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Pengajuan Berhasil!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Jadwal survei Anda berhasil diajukan.\nTim kami akan segera meninjau pengajuan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _muted, height: 1.5),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0D6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Status: Menunggu Konfirmasi',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8D5A2B),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Lihat Daftar Survei',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String get _propTitle =>
      _property?.title ?? _order?.propertyTitle ?? widget.propertyTitle;
  String get _propLocation =>
      _property?.location ?? _order?.propertyLocation ?? '';
  double get _propPrice => _property != null
      ? _property!.price.toDouble()
      : (_order?.propertyPrice ?? 0);
  String get _propThumb =>
      (_property?.gallery.isNotEmpty == true
          ? _property!.gallery.first.imageUrl
          : null) ??
      _order?.propertyThumbnailUrl ??
      '';

  String _fmtPrice(double v) {
    try {
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(v);
    } catch (_) {
      return 'Rp ${v.toInt()}';
    }
  }

  String _fmtTime(TimeOfDay t) {
    return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }

  String _fmtShort(DateTime? v) {
    if (v == null) return '-';
    if (!_localeReady) return DateFormat('d MMM y').format(v);
    return DateFormat('d MMM y', 'id_ID').format(v);
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final isWide = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: _creamBg,
      body: Column(
        children: [
          const BragaPageHeader(
            title: 'Ajukan Jadwal Survei',
            subtitle: 'Pilih tanggal dan jam kunjungan survei properti Anda',
            decorativeIcon: Icons.edit_calendar_outlined,
          ),
          // ── Scrollable form ────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1 · Property card
                  _PropertyCard(
                    title: _propTitle,
                    location: _propLocation,
                    price: _propPrice,
                    thumbnail: _propThumb,
                    fmtPrice: _fmtPrice,
                  ),
                  const SizedBox(height: 14),

                  // 2 · Calendar + Time range
                  isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              flex: 5,
                              child: _SectionCard(
                                icon: Icons.calendar_month_rounded,
                                title: 'Pilih Tanggal Survei',
                                child: _CompactCalendar(
                                  focusedMonth: _calMonth,
                                  selectedDate: _selectedDate,
                                  firstDate: tomorrow,
                                  lastDate: DateTime(
                                    now.year,
                                    now.month + 6,
                                    now.day,
                                  ),
                                  onDaySelected: (d) => setState(() {
                                    _selectedDate = d;
                                    _dateError = null;
                                  }),
                                  onMonthChanged: (m) =>
                                      setState(() => _calMonth = m),
                                  errorText: _dateError,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 4,
                              child: _SectionCard(
                                icon: Icons.access_time_rounded,
                                title: 'Pilih Waktu Kedatangan',
                                child: _TimePickerFields(
                                  fromTime: _fromTime,
                                  toTime: _toTime,
                                  onFromTap: () => _pickTime(isFrom: true),
                                  onToTap: () => _pickTime(isFrom: false),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _SectionCard(
                              icon: Icons.calendar_month_rounded,
                              title: 'Pilih Tanggal Survei',
                              child: _CompactCalendar(
                                focusedMonth: _calMonth,
                                selectedDate: _selectedDate,
                                firstDate: tomorrow,
                                lastDate: DateTime(
                                  now.year,
                                  now.month + 6,
                                  now.day,
                                ),
                                onDaySelected: (d) => setState(() {
                                  _selectedDate = d;
                                  _dateError = null;
                                }),
                                onMonthChanged: (m) =>
                                    setState(() => _calMonth = m),
                                errorText: _dateError,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _SectionCard(
                              icon: Icons.access_time_rounded,
                              title: 'Pilih Waktu Kedatangan',
                              child: _TimePickerFields(
                                fromTime: _fromTime,
                                toTime: _toTime,
                                onFromTap: () => _pickTime(isFrom: true),
                                onToTap: () => _pickTime(isFrom: false),
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 12),

                  // 3 · Visitors + notes
                  _SectionCard(
                    icon: Icons.group_rounded,
                    title: 'Data Tambahan (Opsional)',
                    child: _DataTambahan(
                      visitors: _visitors,
                      notesCtrl: _notesCtrl,
                      onVisitors: (v) => setState(() => _visitors = v),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 4 · Summary card (muncul setelah tanggal dipilih)
                  if (_selectedDate != null) ...[
                    _SummaryCard(
                      propertyTitle: _propTitle,
                      date: _fmtShort(_selectedDate),
                      fromTime: '${_fmtTime(_fromTime)} WIB',
                      toTime: '${_fmtTime(_toTime)} WIB',
                      visitors: _visitors,
                    ),
                    const SizedBox(height: 12),
                  ],

                  // 5 · Submit
                  _SubmitBtn(isSubmitting: _isSubmitting, onPressed: _submit),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Property Card ─────────────────────────────────────────────────────────────
class _PropertyCard extends StatelessWidget {
  const _PropertyCard({
    required this.title,
    required this.location,
    required this.price,
    required this.thumbnail,
    required this.fmtPrice,
  });

  final String title;
  final String location;
  final double price;
  final String thumbnail;
  final String Function(double) fmtPrice;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thumbnail — mengisi penuh tinggi card
            SizedBox(
              width: 120,
              child: thumbnail.isNotEmpty
                  ? Image.network(
                      thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) =>
                          const _PropThumbPlaceholder(),
                    )
                  : const _PropThumbPlaceholder(),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5E6C8),
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: const Text(
                            'Detail Properti',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: _brownDeep,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: _ink,
                        height: 1.2,
                      ),
                    ),
                    if (location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: _muted,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: _muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (price > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        fmtPrice(price),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: _brownDeep,
                        ),
                      ),
                    ],
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

class _PropThumbPlaceholder extends StatelessWidget {
  const _PropThumbPlaceholder();

  @override
  Widget build(BuildContext context) => Container(
    color: const Color(0xFFEFE4D5),
    child: const Center(
      child: Icon(Icons.home_outlined, size: 34, color: Color(0xFFCCBBA8)),
    ),
  );
}

// ─── Time Picker Fields ───────────────────────────────────────────────────────
class _TimePickerFields extends StatelessWidget {
  const _TimePickerFields({
    required this.fromTime,
    required this.toTime,
    required this.onFromTap,
    required this.onToTap,
  });

  final TimeOfDay fromTime;
  final TimeOfDay toTime;
  final VoidCallback onFromTap;
  final VoidCallback onToTap;

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tap pada kolom waktu untuk membuka pemilih jam. Gunakan format 24 jam.',
          style: TextStyle(fontSize: 11.5, color: _muted, height: 1.4),
        ),
        const SizedBox(height: 14),

        // From / To tap fields
        Row(
          children: [
            Expanded(
              child: _TimeField(
                label: 'Dari',
                time: fromTime,
                onTap: onFromTap,
                fmt: _fmt,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 18, left: 10, right: 10),
              child: Container(
                width: 16,
                height: 2,
                decoration: BoxDecoration(
                  color: _muted.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            Expanded(
              child: _TimeField(
                label: 'Sampai',
                time: toTime,
                onTap: onToTap,
                fmt: _fmt,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Info hint
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _cream.withOpacity(0.28),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: _brownDeep,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tim survei akan tiba dalam rentang waktu yang Anda pilih. Mohon bersiap di lokasi pada waktu tersebut.',
                  style: TextStyle(fontSize: 11.5, color: _ink, height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.time,
    required this.onTap,
    required this.fmt,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  final String Function(TimeOfDay) fmt;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: _muted,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  fmt(time),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
                const Icon(Icons.access_time_rounded, size: 16, color: _muted),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Compact Inline Calendar ──────────────────────────────────────────────────
class _CompactCalendar extends StatelessWidget {
  const _CompactCalendar({
    required this.focusedMonth,
    required this.selectedDate,
    required this.firstDate,
    required this.lastDate,
    required this.onDaySelected,
    required this.onMonthChanged,
    this.errorText,
  });

  final DateTime focusedMonth;
  final DateTime? selectedDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime> onDaySelected;
  final ValueChanged<DateTime> onMonthChanged;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(
      focusedMonth.year,
      focusedMonth.month,
    );
    final offset =
        DateTime(focusedMonth.year, focusedMonth.month, 1).weekday - 1;
    final today = DateTime.now();

    return Column(
      children: [
        // Month nav
        Row(
          children: [
            _NavBtn(
              icon: Icons.chevron_left_rounded,
              onTap:
                  DateTime(
                    focusedMonth.year,
                    focusedMonth.month - 1,
                  ).isBefore(DateTime(firstDate.year, firstDate.month))
                  ? null
                  : () => onMonthChanged(
                      DateTime(focusedMonth.year, focusedMonth.month - 1),
                    ),
            ),
            Expanded(
              child: Text(
                DateFormat('MMMM y', 'id_ID').format(focusedMonth),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: _ink,
                ),
              ),
            ),
            _NavBtn(
              icon: Icons.chevron_right_rounded,
              onTap:
                  DateTime(
                    focusedMonth.year,
                    focusedMonth.month + 1,
                  ).isAfter(DateTime(lastDate.year, lastDate.month))
                  ? null
                  : () => onMonthChanged(
                      DateTime(focusedMonth.year, focusedMonth.month + 1),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Day-of-week header
        Row(
          children: ['M', 'S', 'S', 'R', 'K', 'J', 'M']
              .map(
                (d) => Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: _muted,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),

        // Day grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 2,
            crossAxisSpacing: 0,
            childAspectRatio: 1.1,
          ),
          itemCount: offset + daysInMonth,
          itemBuilder: (_, index) {
            if (index < offset) return const SizedBox.shrink();
            final day = DateTime(
              focusedMonth.year,
              focusedMonth.month,
              index - offset + 1,
            );
            final isSel =
                selectedDate != null && DateUtils.isSameDay(day, selectedDate!);
            final isToday = DateUtils.isSameDay(day, today);
            final isEnabled =
                !day.isBefore(firstDate) && !day.isAfter(lastDate);

            return GestureDetector(
              onTap: isEnabled ? () => onDaySelected(day) : null,
              child: Container(
                margin: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: isSel
                      ? _brown
                      : isToday
                      ? _cream.withOpacity(0.55)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSel || isToday
                          ? FontWeight.w900
                          : FontWeight.w600,
                      color: isSel
                          ? Colors.white
                          : isEnabled
                          ? _ink
                          : _light,
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        // Hanya error — chip & legend DIHAPUS
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 13,
                color: Color(0xFFC0392B),
              ),
              const SizedBox(width: 4),
              Text(
                errorText!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFC0392B),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: onTap != null ? _creamCard : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: onTap != null ? _border : Colors.transparent,
          ),
        ),
        child: Icon(icon, size: 18, color: onTap != null ? _brownDeep : _light),
      ),
    );
  }
}

// ─── Data Tambahan ─────────────────────────────────────────────────────────────
class _DataTambahan extends StatelessWidget {
  const _DataTambahan({
    required this.visitors,
    required this.notesCtrl,
    required this.onVisitors,
  });

  final int visitors;
  final TextEditingController notesCtrl;
  final ValueChanged<int> onVisitors;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          decoration: BoxDecoration(
            color: _creamCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: visitors,
              isExpanded: true,
              icon: const Icon(Icons.expand_more_rounded, color: _brownDeep),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
              items: List.generate(
                6,
                (i) => DropdownMenuItem(
                  value: i + 1,
                  child: Row(
                    children: [
                      const Icon(Icons.person_rounded, size: 16, color: _muted),
                      const SizedBox(width: 8),
                      Text('${i + 1} Orang'),
                    ],
                  ),
                ),
              ),
              onChanged: (v) {
                if (v != null) onVisitors(v);
              },
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: notesCtrl,
          minLines: 3,
          maxLines: 5,
          maxLength: 500,
          style: const TextStyle(fontSize: 13, color: _ink),
          decoration: InputDecoration(
            hintText: 'Catatan tambahan (opsional)...',
            hintStyle: const TextStyle(color: _light, fontSize: 13),
            filled: true,
            fillColor: Colors.white,
            counterStyle: const TextStyle(color: _light, fontSize: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _brownMid, width: 1.5),
            ),
            contentPadding: const EdgeInsets.all(14),
          ),
        ),
      ],
    );
  }
}

// ─── Summary Card ─────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.propertyTitle,
    required this.date,
    required this.fromTime,
    required this.toTime,
    required this.visitors,
  });

  final String propertyTitle;
  final String date;
  final String fromTime;
  final String toTime;
  final int visitors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4A2508), Color(0xFF9E5B1A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _brown.withOpacity(0.22),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.receipt_long_rounded,
                size: 15,
                color: Colors.white70,
              ),
              const SizedBox(width: 7),

              const Expanded(
                child: Text(
                  'Ringkasan Survei',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),

              const SizedBox(width: 8),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Menunggu Konfirmasi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 10),

          _SumRow(Icons.home_rounded, 'Properti', propertyTitle),
          _SumRow(Icons.calendar_today_rounded, 'Tanggal', date),
          _SumRow(Icons.access_time_rounded, 'Dari', fromTime),
          _SumRow(Icons.access_time_rounded, 'Sampai', toTime),
          _SumRow(
            Icons.group_rounded,
            'Peserta',
            '$visitors Orang',
            isLast: true,
          ),
        ],
      ),
    );
  }
}

class _SumRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLast;

  const _SumRow(this.icon, this.label, this.value, {this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.white70),

          const SizedBox(width: 8),

          SizedBox(
            width: 82,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: label == 'Properti' ? 2 : 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Card wrapper ─────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  final IconData icon;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: _cream.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 15, color: _brownDeep),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: _ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ─── Submit Button ─────────────────────────────────────────────────────────────
class _SubmitBtn extends StatelessWidget {
  const _SubmitBtn({required this.isSubmitting, required this.onPressed});
  final bool isSubmitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _brownDeep,
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFFB89070),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        child: isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Ajukan Survei',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
      ),
    );
  }
}
