import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/consultation_request_model.dart';
import '../../services/auth_service.dart';
import '../../services/consultation_service.dart';

class ConsultationDetailPage extends StatefulWidget {
  final int consultationId;

  const ConsultationDetailPage({super.key, required this.consultationId});

  @override
  State<ConsultationDetailPage> createState() => _ConsultationDetailPageState();
}

class _ConsultationDetailPageState extends State<ConsultationDetailPage> {
  final ConsultationService _consultationService = ConsultationService();
  final TextEditingController _chatController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  bool _isLoading = true;
  bool _isLoadingMessages = true;
  bool _isSendingMessage = false;
  bool _isUploadingMedia = false;
  String? _errorMessage;
  String? _chatErrorMessage;
  ConsultationRequestModel? _consultation;
  List<ConsultationRequestModel> _buyerConsultations = const [];
  List<ConsultationChatMessageModel> _messages = const [];
  int? _currentUserId;
  String _currentUserRole = '';

  @override
  void initState() {
    super.initState();
    final session = AuthService().getSession();
    _currentUserId = _toInt(session?['id']);
    _currentUserRole = (session?['role'] ?? '').toString().toLowerCase();
    _loadConsultation();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _scheduleChatRefresh() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      _loadMessages(silent: true);
      _scheduleChatRefresh();
    });
  }

  Future<void> _loadConsultation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _consultationService.getConsultationDetail(
      widget.consultationId,
    );
    if (!mounted) return;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      setState(() {
        _errorMessage = _consultationService.parseMessage(response.body);
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _consultation = _consultationService.parseConsultation(response.body);
      _isLoading = false;
    });
    _loadMessages();
    _scheduleChatRefresh();
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (_consultation == null) return;
    if (!silent) {
      setState(() {
        _isLoadingMessages = true;
        _chatErrorMessage = null;
      });
    }

    final isStaff = _currentUserRole == 'staf' || _currentUserRole == 'admin';
    final listResponse = isStaff
        ? await _consultationService.getStaffConsultationRequests()
        : await _consultationService.getMyConsultationRequests();

    if (!mounted) return;

    if (listResponse.statusCode < 200 || listResponse.statusCode >= 300) {
      setState(() {
        _chatErrorMessage = _consultationService.parseMessage(
          listResponse.body,
        );
        _isLoadingMessages = false;
      });
      return;
    }

    final allCons = _consultationService.parseConsultations(listResponse.body);
    final targetBuyerUserId = _consultation!.buyerUserId;
    final filteredCons = allCons
        .where((c) => c.buyerUserId == targetBuyerUserId)
        .toList();

    _buyerConsultations = filteredCons;

    try {
      final futures = filteredCons
          .map((c) => _consultationService.getConsultationMessages(c.id))
          .toList();
      final responses = await Future.wait(futures);

      if (!mounted) return;

      final List<ConsultationChatMessageModel> allParsedMessages = [];

      for (int i = 0; i < filteredCons.length; i++) {
        final c = filteredCons[i];
        final resp = responses[i];

        if (resp.statusCode >= 200 && resp.statusCode < 300) {
          final parsed = _consultationService.parseMessages(resp.body);

          // Inject initial message if not empty
          if (c.message.isNotEmpty) {
            final isGeneralCS =
                c.propertyId == null && c.topic == 'Konsultasi umum';
            final initialMessage = isGeneralCS
                ? ConsultationChatMessageModel(
                    id: 0,
                    consultationId: c.id,
                    senderUserId: c.processedByUserId ?? 0,
                    senderName: c.processedByName ?? 'Staf Pemasaran',
                    senderRole: 'staf',
                    messageType: 'text',
                    message: c.message,
                    mediaUrl: null,
                    mediaName: null,
                    mediaMime: null,
                    createdAt: c.createdAt ?? '',
                    readAt: null,
                  )
                : ConsultationChatMessageModel(
                    id: 0,
                    consultationId: c.id,
                    senderUserId: c.buyerUserId,
                    senderName: c.buyerName,
                    senderRole: 'pembeli',
                    messageType: 'text',
                    message: c.message,
                    mediaUrl: null,
                    mediaName: null,
                    mediaMime: null,
                    createdAt: c.createdAt ?? '',
                    readAt: null,
                  );

            if (parsed.isEmpty || parsed.first.message != c.message) {
              allParsedMessages.add(initialMessage);
            }
          }
          allParsedMessages.addAll(parsed);
        }
      }

      // Sort chronologically by createdAt
      allParsedMessages.sort((a, b) {
        final timeA =
            DateTime.tryParse(a.createdAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final timeB =
            DateTime.tryParse(b.createdAt ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return timeA.compareTo(timeB);
      });

      setState(() {
        _messages = allParsedMessages;
        _isLoadingMessages = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chatErrorMessage = 'Terjadi kesalahan saat memuat pesan chat';
        _isLoadingMessages = false;
      });
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_isUploadingMedia) return;
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    await _showImagePreviewAndSend(picked);
  }

  Future<void> _pickAndSendFile({FileType type = FileType.any}) async {
    if (_isUploadingMedia) return;
    final files = await FilePickerPlatform.instance.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
    );
    final file = files.isNotEmpty ? files.first : null;
    if (file == null || !mounted) return;

    await _showFilePreviewAndSend(file);
  }

  void _showAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _AttachmentAction(
                icon: Icons.image_rounded,
                label: 'Gambar',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendImage();
                },
              ),
              _AttachmentAction(
                icon: Icons.attach_file_rounded,
                label: 'File',
                onTap: () {
                  Navigator.pop(context);
                  _pickAndSendFile(type: FileType.custom);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showImagePreviewAndSend(XFile picked) async {
    final file = File(picked.path);
    final size = await file.length();
    const maxSize = 10 * 1024 * 1024; // 10 MB
    if (size > maxSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran gambar melebihi 10MB.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.file(file, fit: BoxFit.contain),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Kirim'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUploadingMedia = true);
    final response = await _consultationService.sendConsultationMedia(
      consultationId: _activeSendConsultationId,
      mediaFile: picked,
      message: _chatController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isUploadingMedia = false);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_consultationService.parseMessage(response.body)),
        ),
      );
      return;
    }

    _chatController.clear();
    await _loadMessages();
  }

  Future<void> _showFilePreviewAndSend(PlatformFile file) async {
    final size = file.lengthSync() ?? await file.length();
    const maxSize = 10 * 1024 * 1024; // 10 MB
    if (size > maxSize) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ukuran file melebihi 10MB.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                file.name,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text('${(size / 1024).toStringAsFixed(1)} KB'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Kirim'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true) return;

    setState(() => _isUploadingMedia = true);
    final response = await _consultationService.sendConsultationPickedFile(
      consultationId: _activeSendConsultationId,
      file: file,
      message: _chatController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _isUploadingMedia = false);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_consultationService.parseMessage(response.body)),
        ),
      );
      return;
    }

    _chatController.clear();
    await _loadMessages();
  }

  Future<void> _sendMessage() async {
    final text = _chatController.text.trim();
    if (text.isEmpty || _isSendingMessage) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Kirim Pesan?'),
        content: const Text(
          'Pesan akan dikirim ke lawan percakapan. Lanjutkan?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isSendingMessage = true);
    final response = await _consultationService.sendConsultationMessage(
      consultationId: _activeSendConsultationId,
      message: text,
    );
    if (!mounted) return;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      setState(() => _isSendingMessage = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_consultationService.parseMessage(response.body)),
        ),
      );
      return;
    }

    _chatController.clear();
    setState(() => _isSendingMessage = false);
    await _loadMessages();
  }

  Future<void> _openWhatsApp(ConsultationRequestModel consultation) async {
    final rawPhone =
        consultation.buyerWhatsapp ?? consultation.buyerPhone ?? '';
    final phone = rawPhone.replaceAll(RegExp(r'[^0-9+]'), '');
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nomor WhatsApp buyer belum tersedia.')),
      );
      return;
    }

    final normalized = phone.startsWith('+')
        ? phone.substring(1)
        : phone.startsWith('0')
        ? '62${phone.substring(1)}'
        : phone;
    final text = Uri.encodeComponent(
      'Halo ${consultation.buyerName}, saya ingin menindaklanjuti konsultasi "${consultation.topic}".',
    );
    final uri = Uri.parse('https://wa.me/$normalized?text=$text');
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat membuka WhatsApp.')),
      );
    }
  }

  // video/call features removed: chat focuses on messaging only

  String _formatDate(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed == null) return '-';
    return _dateFormat.format(parsed.toLocal());
  }

  int? _toInt(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  int get _activeSendConsultationId {
    if (_buyerConsultations.isEmpty) return widget.consultationId;

    final active = _buyerConsultations
        .where((c) => c.status != 'resolved' && c.status != 'rejected')
        .toList();
    if (active.isNotEmpty) {
      active.sort((a, b) => b.id.compareTo(a.id));
      return active.first.id;
    }

    final sorted = List<ConsultationRequestModel>.from(_buyerConsultations);
    sorted.sort((a, b) => b.id.compareTo(a.id));
    return sorted.first.id;
  }

  Future<void> _showStatusUpdateDialog(
    ConsultationRequestModel consultation,
  ) async {
    final notesController = TextEditingController(
      text: consultation.staffNotes ?? '',
    );
    String selectedStatus = consultation.status;

    if (selectedStatus != 'pending' && selectedStatus != 'contacted') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konsultasi ini sudah selesai diproses.')),
      );
      return;
    }

    final isStaff = _currentUserRole == 'staf' || _currentUserRole == 'admin';
    if (!isStaff) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFF7ED),
              title: const Text(
                'Tindak Lanjut Konsultasi',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF5E3210),
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ubah Status:',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF4E3B2C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<String>(
                      value: selectedStatus,
                      dropdownColor: const Color(0xFFFFF7ED),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                      ),
                      items: [
                        if (consultation.status == 'pending') ...[
                          const DropdownMenuItem(
                            value: 'pending',
                            child: Text('Menunggu Persetujuan'),
                          ),
                          const DropdownMenuItem(
                            value: 'contacted',
                            child: Text('Setujui & Hubungi'),
                          ),
                          const DropdownMenuItem(
                            value: 'rejected',
                            child: Text('Tolak'),
                          ),
                        ],
                        if (consultation.status == 'contacted') ...[
                          const DropdownMenuItem(
                            value: 'contacted',
                            child: Text('Aktif (Sedang Dihubungi)'),
                          ),
                          const DropdownMenuItem(
                            value: 'resolved',
                            child: Text('Tandai Selesai'),
                          ),
                        ],
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedStatus = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Catatan Tindak Lanjut Staf:',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: Color(0xFF4E3B2C),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: notesController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Tulis catatan atau alasan di sini...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'Batal',
                    style: TextStyle(color: Color(0xFF8F4E1E)),
                  ),
                ),
                FilledButton(
                  onPressed: () async {
                    final notes = notesController.text.trim();
                    if (selectedStatus == 'rejected' && notes.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Catatan wajib diisi jika konsultasi ditolak.',
                          ),
                        ),
                      );
                      return;
                    }

                    Navigator.pop(context);

                    setState(() {
                      _isLoading = true;
                    });

                    final res = await _consultationService
                        .updateConsultationStatus(
                          consultationId: consultation.id,
                          status: selectedStatus,
                          staffNotes: notes.isEmpty ? null : notes,
                        );

                    if (!mounted) return;

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          _consultationService.parseMessage(res.body),
                        ),
                        backgroundColor: res.statusCode < 300
                            ? const Color(0xFF8F4E1E)
                            : const Color(0xFFC74C4C),
                      ),
                    );

                    _loadConsultation();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8F4E1E),
                  ),
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final consultation = _consultation;
    final chatEnabled =
        consultation != null &&
        (consultation.isContacted || consultation.isResolved);

    return Scaffold(
      backgroundColor: const Color(0xFFF5E3CF),
      appBar: chatEnabled
          ? null
          : AppBar(
              title: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Detail Konsultasi', style: TextStyle(fontSize: 16)),
                  Text(
                    'Informasi percakapan konsultasi properti',
                    style: TextStyle(fontSize: 11, height: 1.2),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFFF5E3CF),
            ),
      body: chatEnabled
          ? _buildChatRoom(consultation)
          : RefreshIndicator(onRefresh: _loadConsultation, child: _buildBody()),
    );
  }

  String _chatPeerName(ConsultationRequestModel consultation) {
    if (_currentUserRole == UserRoles.pembeli) {
      return consultation.processedByName?.trim().isNotEmpty == true
          ? consultation.processedByName!
          : 'Staf Pemasaran';
    }
    return consultation.buyerName.trim().isNotEmpty
        ? consultation.buyerName
        : 'Konsumen';
  }

  Widget _buildChatRoom(ConsultationRequestModel consultation) {
    return SafeArea(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB16B33), Color(0xFF8F4E1E)],
          ),
        ),
        child: Column(
          children: [
            _ChatHeader(
              name: _chatPeerName(consultation),
              subtitle: _currentUserRole == UserRoles.pembeli
                  ? 'Customer Service'
                  : 'Calon Pembeli',
              onBack: () => Navigator.maybePop(context),
              trailing:
                  (_currentUserRole == 'staf' || _currentUserRole == 'admin') &&
                      consultation.status != 'resolved' &&
                      consultation.status != 'rejected'
                  ? IconButton(
                      icon: const Icon(
                        Icons.done_all_rounded,
                        color: Color(0xFFFFF7ED),
                      ),
                      tooltip: 'Tandai Selesai / Edit Catatan',
                      onPressed: () => _showStatusUpdateDialog(consultation),
                    )
                  : null,
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadMessages,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                  children: [
                    if (_isLoadingMessages)
                      const Padding(
                        padding: EdgeInsets.only(top: 80),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFF7ED),
                          ),
                        ),
                      )
                    else if (_chatErrorMessage != null)
                      _MessageState(
                        title: 'Gagal memuat chat',
                        message: _chatErrorMessage!,
                        onRetry: _loadMessages,
                      )
                    else if (_messages.isEmpty)
                      const _ChatEmptyState()
                    else
                      ..._buildMessageTimeline(),
                  ],
                ),
              ),
            ),
            _ChatInputBar(
              controller: _chatController,
              isSending: _isSendingMessage,
              isUploading: _isUploadingMedia,
              onAttach: _showAttachmentSheet,
              onCamera: _pickAndSendImage,
              onSend: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return _MessageState(
        title: 'Gagal memuat konsultasi',
        message: _errorMessage!,
        onRetry: _loadConsultation,
      );
    }

    final consultation = _consultation;
    if (consultation == null) {
      return const _MessageState(
        title: 'Data tidak ditemukan',
        message: 'Detail konsultasi tidak tersedia.',
      );
    }

    final badge = _statusBadge(consultation.status);
    final chatEnabled =
        consultation.status == 'contacted' || consultation.status == 'resolved';
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      consultation.topic,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  _StatusChip(
                    label: badge.label,
                    background: badge.background,
                    foreground: badge.foreground,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                consultation.message,
                style: const TextStyle(height: 1.45, color: Color(0xFF4E3B2C)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Informasi Konsultasi',
          child: Column(
            children: [
              _DetailRow(label: 'Buyer', value: consultation.buyerName),
              _DetailRow(
                label: 'WhatsApp',
                value:
                    consultation.buyerWhatsapp ??
                    consultation.buyerPhone ??
                    '-',
              ),
              _DetailRow(
                label: 'Metode kontak',
                value: consultation.preferredContactMethod,
              ),
              _DetailRow(
                label: 'Properti',
                value: consultation.propertyTitle ?? '-',
              ),
              _DetailRow(
                label: 'Lokasi properti',
                value: consultation.propertyLocation ?? '-',
              ),
              _DetailRow(
                label: 'Diajukan',
                value: _formatDate(consultation.createdAt),
              ),
              _DetailRow(
                label: 'Diperbarui',
                value: _formatDate(consultation.updatedAt),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _openWhatsApp(consultation),
          icon: const Icon(Icons.chat_rounded),
          label: const Text('Chat via WhatsApp'),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: 'Tindak Lanjut Staf',
          trailing:
              ((_currentUserRole == 'staf' || _currentUserRole == 'admin') &&
                  consultation.status != 'resolved' &&
                  consultation.status != 'rejected')
              ? IconButton(
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    color: Color(0xFF8F4E1E),
                  ),
                  tooltip: 'Perbarui Catatan / Status',
                  onPressed: () => _showStatusUpdateDialog(consultation),
                )
              : null,
          child: Column(
            children: [
              _DetailRow(
                label: 'Catatan staf',
                value: consultation.staffNotes ?? '-',
              ),
              _DetailRow(
                label: 'Diproses oleh',
                value: consultation.processedByName ?? '-',
              ),
              _DetailRow(
                label: 'Tanggal proses',
                value: _formatDate(consultation.processedAt),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        _SectionCard(
          title: chatEnabled ? 'Chat Konsultasi' : 'Status Konsultasi',
          child: chatEnabled
              ? Column(
                  children: [
                    if (_isLoadingMessages)
                      const Padding(
                        padding: EdgeInsets.all(18),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_chatErrorMessage != null)
                      Column(
                        children: [
                          Text(_chatErrorMessage!),
                          TextButton(
                            onPressed: _loadMessages,
                            child: const Text('Muat ulang chat'),
                          ),
                        ],
                      )
                    else if (_messages.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          'Room chat aktif. Mulai percakapan di sini.',
                        ),
                      )
                    else
                      ..._buildMessageTimeline(),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Tulis pesan chat...',
                              filled: true,
                              fillColor: const Color(0xFFFFF7ED),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: _isUploadingMedia
                              ? null
                              : _showAttachmentSheet,
                          icon: _isUploadingMedia
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.image_rounded),
                        ),
                        const SizedBox(width: 6),
                        FilledButton(
                          onPressed: _isSendingMessage ? null : _sendMessage,
                          child: _isSendingMessage
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.send_rounded),
                        ),
                      ],
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      consultation.status == 'rejected'
                          ? 'Konsultasi ditolak'
                          : 'Menunggu persetujuan staf',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      consultation.status == 'rejected'
                          ? (consultation.staffNotes ??
                                'Silakan ajukan ulang konsultasi.')
                          : 'Permintaan Anda sudah masuk. Room chat akan aktif setelah staf menyetujui konsultasi.',
                      style: const TextStyle(
                        color: Color(0xFF6D5540),
                        height: 1.4,
                      ),
                    ),
                    if (consultation.status == 'rejected') ...[
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/consultation-form'),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Ajukan Ulang'),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  List<Widget> _buildMessageTimeline() {
    final widgets = <Widget>[];
    String? lastGroup;

    for (final message in _messages) {
      final group = _chatDateGroup(message.createdAt);
      if (group != lastGroup) {
        widgets.add(_ChatDateDivider(label: group));
        lastGroup = group;
      }

      widgets.add(
        _ChatBubble(
          message: message,
          mine: message.senderUserId == _currentUserId,
          formatTime: _formatChatTime,
        ),
      );
    }

    return widgets;
  }

  String _chatDateGroup(String? value) {
    final parsed = DateTime.tryParse(value ?? '')?.toLocal();
    if (parsed == null) return 'Tanggal tidak diketahui';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(parsed.year, parsed.month, parsed.day);
    final diff = today.difference(date).inDays;
    if (diff == 0) return 'Hari ini';
    if (diff == 1) return 'Kemarin';
    return DateFormat('dd MMM yyyy', 'id_ID').format(parsed);
  }

  String _formatChatTime(String? value) {
    final parsed = DateTime.tryParse(value ?? '')?.toLocal();
    if (parsed == null) return '-';
    return DateFormat('HH:mm', 'id_ID').format(parsed);
  }
}

class _ChatDateDivider extends StatelessWidget {
  final String label;

  const _ChatDateDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 8, bottom: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xFFFFF7ED),
            fontSize: 8,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback onBack;
  final Widget? trailing;

  const _ChatHeader({
    required this.name,
    required this.subtitle,
    required this.onBack,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              padding: EdgeInsets.zero,
              iconSize: 20,
              color: const Color(0xFFFFF7ED),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFE0A05D),
              child: Text(
                name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFF7ED),
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: const Color(0xFFFFF7ED).withValues(alpha: 0.65),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.forum_rounded, size: 30, color: Color(0xFFFFF7ED)),
          SizedBox(height: 6),
          Text(
            'Room chat aktif',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: Color(0xFFFFF7ED),
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Mulai percakapan dengan mengirim pesan pertama.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFFFFF1DE), fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final bool isUploading;
  final VoidCallback onAttach;
  final VoidCallback onCamera;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.isSending,
    required this.isUploading,
    required this.onAttach,
    required this.onCamera,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.fromLTRB(10, 6, 6, 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        children: [
          // Attachment (file)
          InkWell(
            onTap: isUploading ? null : onAttach,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFD9C5AF)),
              ),
              child: isUploading
                  ? const Center(
                      child: SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Color(0xFF8F4E1E),
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.attach_file_rounded,
                      color: Color(0xFF8F4E1E),
                      size: 18,
                    ),
            ),
          ),
          const SizedBox(width: 8),

          // Message input
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.newline,
              style: const TextStyle(color: Color(0xFF4E3B2C), fontSize: 14),
              cursorColor: const Color(0xFF8F4E1E),
              decoration: InputDecoration(
                hintText: 'Tulis pesan... ',
                hintStyle: TextStyle(
                  color: const Color(0xFF8F4E1E).withOpacity(0.45),
                  fontSize: 14,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                border: InputBorder.none,
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Camera
          InkWell(
            onTap: isUploading ? null : onCamera,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Color(0xFF8F4E1E),
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Send
          InkWell(
            onTap: isSending ? null : onSend,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF8F4E1E),
                shape: BoxShape.circle,
              ),
              child: isSending
                  ? const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _AttachmentAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: 104,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9D7BF)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF8F4E1E)),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  final ConsultationChatMessageModel message;
  final bool mine;
  final String Function(String?) formatTime;

  const _ChatBubble({
    required this.message,
    required this.mine,
    required this.formatTime,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width > 420
              ? 190
              : MediaQuery.sizeOf(context).width * 0.58,
        ),
        margin: const EdgeInsets.only(top: 7),
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
        decoration: BoxDecoration(
          color: mine
              ? const Color(0xFFFFF7ED)
              : Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(13),
            topRight: const Radius.circular(13),
            bottomLeft: mine ? const Radius.circular(13) : Radius.zero,
            bottomRight: mine ? Radius.zero : const Radius.circular(13),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.message,
              style: TextStyle(
                color: mine ? const Color(0xFF4E3B2C) : const Color(0xFFFFF7ED),
                height: 1.3,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            if ((message.mediaUrl ?? '').isNotEmpty) ...[
              const SizedBox(height: 8),
              _ChatMediaPreview(message: message),
            ],
            const SizedBox(height: 5),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  formatTime(message.createdAt),
                  style: TextStyle(
                    color: mine
                        ? const Color(0xFF9E8263)
                        : const Color(0xFFFFF7ED).withValues(alpha: 0.65),
                    fontSize: 8,
                  ),
                ),
                if (mine) ...[
                  const SizedBox(width: 4),
                  Icon(
                    message.readAt == null
                        ? Icons.done_rounded
                        : Icons.done_all_rounded,
                    size: 14,
                    color: message.readAt == null
                        ? const Color(0xFFBBA080)
                        : const Color(0xFF5AA87A),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMediaPreview extends StatelessWidget {
  final ConsultationChatMessageModel message;

  const _ChatMediaPreview({required this.message});

  String get _url {
    final url = message.mediaUrl ?? '';
    if (url.startsWith('http')) return url;
    return '${AuthService.serverBaseUrl}$url';
  }

  @override
  Widget build(BuildContext context) {
    if (message.messageType == 'image') {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          _url,
          width: 220,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const _MediaFallback(
            icon: Icons.broken_image_rounded,
            label: 'Gambar gagal dimuat',
          ),
        ),
      );
    }

    return InkWell(
      onTap: () =>
          launchUrl(Uri.parse(_url), mode: LaunchMode.externalApplication),
      borderRadius: BorderRadius.circular(12),
      child: _MediaFallback(
        icon: message.messageType == 'audio'
            ? Icons.keyboard_voice_rounded
            : Icons.insert_drive_file_rounded,
        label: message.mediaName ?? 'Lampiran',
      ),
    );
  }
}

class _MediaFallback extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MediaFallback({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String? title;
  final Widget child;
  final Widget? trailing;

  const _SectionCard({this.title, required this.child, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE9D7BF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
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
            value.trim().isEmpty ? '-' : value,
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

class _MessageState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;

  const _MessageState({
    required this.title,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        _SectionCard(
          child: Column(
            children: [
              const Icon(
                Icons.forum_rounded,
                size: 44,
                color: Color(0xFF8F4E1E),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF7A6552)),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: onRetry,
                  child: const Text('Coba lagi'),
                ),
              ],
            ],
          ),
        ),
      ],
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
