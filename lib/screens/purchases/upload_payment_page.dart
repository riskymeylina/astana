import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:async';

import '../../models/purchase_order_model.dart';
import '../../services/purchase_service.dart';
import 'widgets/purchase_theme.dart';
import 'widgets/upload_area.dart';
import 'widgets/payment_proof_preview.dart';
import '../../widgets/braga_page_header.dart';

class UploadPaymentPage extends StatefulWidget {
  const UploadPaymentPage({super.key, required this.order});

  final PurchaseOrderModel order;

  @override
  State<UploadPaymentPage> createState() => _UploadPaymentPageState();
}

class _UploadPaymentPageState extends State<UploadPaymentPage> {
  final PurchaseService _purchaseService = PurchaseService();
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  final ImagePicker _picker = ImagePicker();

  XFile? _selectedImage;
  bool _isUploading = false;
  bool _isLocaleReady = false;
  Duration _timeLeft = Duration.zero;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _preparePage();
  }

  Widget _buildTimeline() {
    final steps = ['Pesanan Dibuat', 'Menunggu Pembayaran', 'Upload Bukti Pembayaran', 'Verifikasi Marketing', 'Dikonfirmasi Admin'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: PurchaseTheme.cardBackground, borderRadius: BorderRadius.circular(PurchaseTheme.radiusXL), border: Border.all(color: PurchaseTheme.dividerColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: steps.map((s) => Expanded(child: Column(children: [const Icon(Icons.check_circle, color: Color(0xFF1F7A45)), const SizedBox(height: 6), Text(s, textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))],))).toList(),
      ),
    );
  }

  Widget _buildCountdownCard() {
    String two(int n) => n.toString().padLeft(2, '0');
    final hours = two(_timeLeft.inHours.remainder(100));
    final minutes = two(_timeLeft.inMinutes.remainder(60));
    final seconds = two(_timeLeft.inSeconds.remainder(60));
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(PurchaseTheme.spacing16),
      decoration: BoxDecoration(color: const Color(0xFFFFF7EF), borderRadius: BorderRadius.circular(PurchaseTheme.radiusLarge), border: Border.all(color: const Color(0xFFF1D9B9))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Selesaikan pembayaran sebelum waktu habis!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900)),
                SizedBox(height: 6),
                Text('Sisa waktu pembayaran:', style: TextStyle(fontSize: 12, color: Color(0xFF6D5540))),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFFFCF0E6), borderRadius: BorderRadius.circular(8)),
            child: Row(children: [Text(hours, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFC0392B))), const SizedBox(width: 6), Text(':', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(width: 6), Text(minutes, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFC0392B))), const SizedBox(width: 6), Text(':', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), const SizedBox(width: 6), Text(seconds, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFFC0392B)))],),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummaryDetailed() {
    return Container(
      decoration: PurchaseTheme.cardDecoration(),
      padding: const EdgeInsets.all(PurchaseTheme.spacing18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 100,
                height: 75,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade200,
                  image: widget.order.propertyThumbnailUrl != null
                      ? DecorationImage(
                          image: NetworkImage(widget.order.propertyThumbnailUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
              ),
              const SizedBox(width: PurchaseTheme.spacing16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.order.propertyTitle,
                      style: PurchaseTheme.heading2.copyWith(fontSize: 16),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.order.propertyLocation,
                      style: PurchaseTheme.bodySecondary.copyWith(fontSize: 13),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _buildInfoChip('Tipe 120'),
                        _buildInfoChip('2 Lantai'),
                        _buildInfoChip('120 m²'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEAD6C0)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No. Pemesanan', style: PurchaseTheme.hint.copyWith(fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    'INV/${widget.order.id.toString().padLeft(6, '0')}',
                    style: PurchaseTheme.body.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Tanggal Pemesanan', style: PurchaseTheme.hint.copyWith(fontSize: 11)),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(widget.order.createdAt),
                    style: PurchaseTheme.body,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF9F6F0),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAD6C0)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11, color: Color(0xFF5C4033)),
      ),
    );
  }

  Widget _buildPaymentInfo() {
    final isQris = widget.order.isQris;
    final isCash = widget.order.isCash;

    return Container(
      decoration: PurchaseTheme.cardDecoration(),
      padding: const EdgeInsets.all(PurchaseTheme.spacing18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Total yang harus dibayar', style: PurchaseTheme.hint),
          const SizedBox(height: PurchaseTheme.spacing8),
          Text(_formatPrice(widget.order.payableAmount), style: PurchaseTheme.priceStyle()),
          const SizedBox(height: PurchaseTheme.spacing12),
          Text('Metode Pembayaran', style: PurchaseTheme.hint),
          const SizedBox(height: PurchaseTheme.spacing6),
          Text(widget.order.paymentMethod, style: PurchaseTheme.body),
          const SizedBox(height: PurchaseTheme.spacing16),
          if (isQris) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(PurchaseTheme.spacing14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F6FD),
                borderRadius: BorderRadius.circular(PurchaseTheme.radiusMedium),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.qr_code_scanner_rounded, size: 20, color: Color(0xFF1E5FAF)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Pembayaran Otomatis QRIS',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E5FAF),
                            fontFamily: 'TomatoGrotesk',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Pembayaran dengan QRIS diverifikasi secara otomatis dan instan. Anda tidak perlu mengunggah bukti pembayaran secara manual.',
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.45,
                      color: Color(0xFF334155),
                      fontFamily: 'TomatoGrotesk',
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF1E5FAF),
                        side: const BorderSide(color: Color(0xFF1E5FAF)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      icon: const Icon(Icons.qr_code_rounded, size: 16),
                      label: const Text(
                        'Kembali ke Halaman Scan QRIS',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else if (isCash) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(PurchaseTheme.spacing12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF5F0),
                borderRadius: BorderRadius.circular(PurchaseTheme.radiusMedium),
                border: Border.all(color: const Color(0xFFC2E8CC)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.payments_rounded, size: 20, color: Color(0xFF1F7A45)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Instruksi Pembayaran Tunai (Cash)',
                          style: PurchaseTheme.body.copyWith(fontWeight: FontWeight.bold, color: const Color(0xFF1F7A45)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Silakan kunjungi kantor pemasaran resmi kami untuk melakukan pembayaran tunai secara langsung ke kasir/staf marketing.\n\nSetelah melakukan pembayaran tunai, Anda akan menerima kwitansi fisik. Foto dan unggah kwitansi tersebut di bawah ini sebagai bukti verifikasi sistem.',
                    style: PurchaseTheme.hint.copyWith(height: 1.45, color: const Color(0xFF2C5E3D)),
                  ),
                ],
              ),
            ),
          ] else ...[
            Text(widget.order.paymentAccountNumber ?? '-', style: PurchaseTheme.body),
          ],
        ],
      ),
    );
  }


  Future<void> _preparePage() async {
    await initializeDateFormatting('id_ID');
    if (!mounted) return;
    _startCountdown();
    setState(() => _isLocaleReady = true);
  }

  void _startCountdown() {
    final due = DateTime.tryParse(widget.order.paymentDueAt ?? '');
    if (due == null) return;
    _updateTimeLeft(due);
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateTimeLeft(due);
    });
  }

  void _updateTimeLeft(DateTime due) {
    final now = DateTime.now().toUtc();
    final left = due.toUtc().difference(now);
    setState(() => _timeLeft = left.isNegative ? Duration.zero : left);
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  String _formatDate(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed == null) return '-';
    return _dateFormat.format(parsed.toLocal());
  }

  Future<void> _upload() async {
    if (_selectedImage == null) {
      _showMessage(
        'Pilih gambar bukti pembayaran terlebih dahulu',
        isError: true,
      );
      return;
    }

    setState(() => _isUploading = true);

    final response = await _purchaseService.uploadPaymentProof(
      purchaseId: widget.order.id,
      imageFile: _selectedImage!,
    );

    if (!mounted) return;
    setState(() => _isUploading = false);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      await _showSuccessDialog();
    } else {
      _showMessage(_purchaseService.parseMessage(response.body), isError: true);
    }
  }

  Future<void> _showSuccessDialog() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PurchaseTheme.radiusRound)),
        backgroundColor: PurchaseTheme.lightCream,
        child: Padding(
          padding: const EdgeInsets.all(PurchaseTheme.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: PurchaseTheme.cream.withOpacity(0.35),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 42,
                  color: PurchaseTheme.success,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Bukti Terkirim!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: PurchaseTheme.darkBrown,
                  fontFamily: 'TomatoGrotesk',
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Bukti pembayaran Anda berhasil diunggah.\nTim kami akan segera meninjau pembayaran Anda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: PurchaseTheme.brownText,
                  height: 1.5,
                  fontFamily: 'TomatoGrotesk',
                ),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    Navigator.pushReplacementNamed(
                      context,
                      '/purchase-detail',
                      arguments: widget.order.id,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PurchaseTheme.brown,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(PurchaseTheme.radiusLarge),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Lihat Detail Pemesanan',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, fontFamily: 'TomatoGrotesk'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _replaceImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null && mounted) {
        setState(() => _selectedImage = image);
      }
    } catch (_) {
      _showMessage('Gagal mengambil gambar', isError: true);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_rounded,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError ? PurchaseTheme.error : PurchaseTheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PurchaseTheme.radiusMedium),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCash = widget.order.paymentMethod.toLowerCase().contains('cash') ||
        widget.order.paymentMethod.toLowerCase().contains('tunai');
    return Scaffold(
      backgroundColor: PurchaseTheme.background,
      body: Column(
        children: [
          const BragaPageHeader(
            title: 'Unggah Bukti',
            subtitle: 'Unggah bukti pembayaran Anda.',
            decorativeIcon: Icons.upload_file_rounded,
          ),
          Expanded(
            child: !_isLocaleReady
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(
                      PurchaseTheme.spacing16,
                      PurchaseTheme.spacing16,
                      PurchaseTheme.spacing16,
                      PurchaseTheme.spacing32,
                    ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeline(),
                  const SizedBox(height: PurchaseTheme.spacing16),
                  _buildCountdownCard(),
                  const SizedBox(height: PurchaseTheme.spacing20),
                  _buildOrderSummaryDetailed(),
                  const SizedBox(height: PurchaseTheme.spacing20),                  const SizedBox(height: PurchaseTheme.spacing20),
                  _buildPaymentInfo(),
                  const SizedBox(height: PurchaseTheme.spacing20),
                  Container(
                    decoration: PurchaseTheme.cardDecoration(),
                    padding: const EdgeInsets.all(PurchaseTheme.spacing18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCash ? 'Upload Kwitansi Pembayaran' : 'Upload Bukti Transfer',
                          style: PurchaseTheme.heading2,
                        ),
                        const SizedBox(height: PurchaseTheme.spacing8),
                        Text(
                          isCash
                              ? 'Foto kwitansi pembayaran resmi yang didapatkan dari kasir/marketing\nFormat JPG, JPEG, PNG, PDF (Maks. 5MB)'
                              : 'Klik untuk upload bukti pembayaran\nFormat JPG, JPEG, PNG, PDF (Maks. 5MB)',
                          style: PurchaseTheme.hint,
                        ),
                        const SizedBox(height: PurchaseTheme.spacing16),
                        if (_selectedImage != null)
                          PaymentProofPreview(
                            imageFile: _selectedImage!,
                            onRemove: () => setState(() => _selectedImage = null),
                            onReplace: () => _replaceImage(ImageSource.gallery),
                          )
                        else
                          UploadArea(
                            onImageSelected: (image) => setState(() => _selectedImage = image),
                            onImageRemoved: () => setState(() => _selectedImage = null),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: PurchaseTheme.spacing20),

                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7FF),
                      borderRadius: BorderRadius.circular(PurchaseTheme.radiusLarge),
                    ),
                    padding: const EdgeInsets.all(PurchaseTheme.spacing16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tips agar bukti pembayaran mudah diverifikasi', style: PurchaseTheme.subheading),
                        const SizedBox(height: PurchaseTheme.spacing8),
                        Text(
                          isCash
                              ? '\u2022 Pastikan foto kwitansi terlihat jelas, tegak, dan tidak buram'
                              : '\u2022 Pastikan bukti transfer terlihat jelas dan tidak buram',
                        ),
                        const SizedBox(height: PurchaseTheme.spacing4),
                        Text(
                          isCash
                              ? '\u2022 Pastikan nominal pembayaran, tanda tangan kasir, dan cap lunas terlihat jelas'
                              : '\u2022 Pastikan nominal transfer terlihat jelas',
                        ),
                        const SizedBox(height: PurchaseTheme.spacing4),
                        Text(
                          isCash
                              ? '\u2022 Pastikan tanggal penerbitan kwitansi tercantum dengan jelas'
                              : '\u2022 Pastikan tanggal dan waktu transfer terlihat jelas',
                        ),
                        const SizedBox(height: PurchaseTheme.spacing4),
                        const Text('\u2022 Jangan crop gambar bukti/kwitansi'),
                      ],
                    ),
                  ),

                  const SizedBox(height: PurchaseTheme.spacing20),

                  SizedBox(
                    width: double.infinity,
                    height: PurchaseTheme.buttonHeight,
                    child: ElevatedButton.icon(
                      onPressed: _isUploading ? null : _upload,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: Text(isCash ? 'Kirim Kwitansi Pembayaran' : 'Kirim Bukti Pembayaran'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PurchaseTheme.brown,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PurchaseTheme.radiusLarge)),
                        elevation: 2,
                      ),
                    ),
                  ),
                  const SizedBox(height: PurchaseTheme.spacing12),
                  SizedBox(
                    width: double.infinity,
                    height: PurchaseTheme.buttonHeight,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batalkan'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(PurchaseTheme.radiusLarge)),
                        side: const BorderSide(color: Color(0xFFEAD6C0)),
                      ),
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

}
