import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/purchase_order_model.dart';
import '../../widgets/braga_page_header.dart';
import '../../services/invoice_pdf_service.dart';

class TransactionDetailPage extends StatelessWidget {
  final PurchaseOrderModel transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  static const _brown = Color(0xFF7A3B1E);
  static const _border = Color(0xFFE7CCAE);
  static const _bg = Color(0xFFFFF8F0);

  String _formatCurrency(double amount) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);

  String _formatDate(String? raw, {bool withTime = false}) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      if (withTime) {
        return '${DateFormat('dd MMM yyyy', 'id_ID').format(dt)}, '
            '${DateFormat('HH:mm').format(dt)} WIB';
      }
      return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return raw;
    }
  }

  String get _invoiceNumber {
    try {
      final dt = DateTime.parse(transaction.createdAt ?? '').toLocal();
      final year = dt.year;
      final monthStr = dt.month.toString().padLeft(2, '0');
      final dayStr = dt.day.toString().padLeft(2, '0');
      final numStr = transaction.id.toString().padLeft(4, '0');
      return 'INV/$year/$monthStr$dayStr/$numStr';
    } catch (_) {
      return 'INV/${DateTime.now().year}/${transaction.id.toString().padLeft(4, '0')}';
    }
  }

  Map<String, String> get _statusLabels => const {
    'confirmed': 'Terjual',
    'pending_payment': 'Pending',
    'payment_uploaded': 'Dipesan',
    'payment_review': 'Dipesan',
    'rejected': 'Ditolak',
    'cancelled': 'Dibatalkan',
  };

  Map<String, Color> get _statusColors => const {
    'confirmed': Color(0xFF1B874B),
    'pending_payment': Color(0xFF1967D2),
    'payment_uploaded': Color(0xFFCB7D2A),
    'payment_review': Color(0xFFCB7D2A),
    'rejected': Color(0xFFC74C4C),
    'cancelled': Color(0xFF6C6C6C),
  };

  void _showProofFullScreen(BuildContext context, String url) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black.withOpacity(0.92),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Bukti Transfer',
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              tooltip: 'Tutup',
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
        body: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          boundaryMargin: const EdgeInsets.all(double.infinity),
          child: Center(
            child: Image.network(
              url,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : const Center(
                      child: CircularProgressIndicator(color: Colors.white70),
                    ),
              errorBuilder: (_, _, _) => const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.broken_image_rounded,
                    size: 56,
                    color: Colors.white54,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Gagal memuat bukti transfer',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final status = tx.status;
    final statusLabel = _statusLabels[status] ?? status;
    final statusColor = _statusColors[status] ?? Colors.grey;

    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          BragaPageHeader(
            title: 'Detail Transaksi',
            subtitle: 'Informasi pembayaran dan dokumen transaksi properti',
            onBack: () => Navigator.pop(context),
            actions: [
              OutlinedButton.icon(
                onPressed: () => InvoicePdfService().shareInvoice(tx),
                icon: const Icon(
                  Icons.download_rounded,
                  size: 15,
                  color: Colors.white,
                ),
                label: const Text(
                  'Download PDF',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => InvoicePdfService().printInvoice(tx),
                icon: const Icon(
                  Icons.print_rounded,
                  size: 15,
                  color: Colors.white,
                ),
                label: const Text(
                  'Cetak Invoice',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: _InfoCard(
                            title: 'Informasi Transaksi',
                            icon: Icons.receipt_long_rounded,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Nomor Invoice',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _invoiceNumber,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: _brown,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Status Transaksi',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    statusLabel,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _DetailRow(
                                  label: 'Tanggal Transaksi',
                                  value: _formatDate(
                                    tx.createdAt,
                                    withTime: true,
                                  ),
                                ),
                                _DetailRow(
                                  label: 'Tanggal Verifikasi',
                                  value: _formatDate(
                                    tx.confirmedAt,
                                    withTime: true,
                                  ),
                                ),
                                if (tx.verifiedBy != null)
                                  _DetailRow(
                                    label: 'Diverifikasi Oleh',
                                    value: tx.verifiedBy!,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: _InfoCard(
                            title: 'Informasi Pembeli',
                            icon: Icons.person_outline_rounded,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: const Color(0xFFF5E0C8),
                                      child: Text(
                                        tx.buyerNameSnapshot.isNotEmpty
                                            ? tx.buyerNameSnapshot[0]
                                                  .toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: _brown,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx.buyerNameSnapshot,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                            ),
                                          ),
                                          if (tx.buyerPhoneSnapshot != null)
                                            Text(
                                              tx.buyerPhoneSnapshot!,
                                              style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 13,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                if (tx.buyerEmail != null)
                                  _IconDetailRow(
                                    icon: Icons.email_rounded,
                                    value: tx.buyerEmail!,
                                  ),
                                if (tx.buyerAddress != null)
                                  _IconDetailRow(
                                    icon: Icons.location_on_rounded,
                                    value: tx.buyerAddress!,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: _InfoCard(
                            title: 'Informasi Properti',
                            icon: Icons.apartment_rounded,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5E0C8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: tx.propertyImageUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                          child: Image.network(
                                            tx.propertyImageUrl!,
                                            fit: BoxFit.cover,
                                            width: double.infinity,
                                          ),
                                        )
                                      : const Center(
                                          child: Icon(
                                            Icons.home_work_rounded,
                                            size: 40,
                                            color: _brown,
                                          ),
                                        ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  tx.propertyTitle,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                if (tx.propertyType != null)
                                  Text(
                                    tx.propertyType!,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                if (tx.propertyLandArea != null)
                                  _DetailRow(
                                    label: 'Luas Tanah',
                                    value: '${tx.propertyLandArea} m²',
                                  ),
                                if (tx.propertyBuildingArea != null)
                                  _DetailRow(
                                    label: 'Luas Bangunan',
                                    value: '${tx.propertyBuildingArea} m²',
                                  ),
                                if (tx.propertyLocation.isNotEmpty)
                                  _DetailRow(
                                    label: 'Lokasi',
                                    value: tx.propertyLocation,
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatCurrency(
                                    (tx.totalPrice ?? 0).toDouble(),
                                  ),
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: _brown,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          child: _InfoCard(
                            title: 'Informasi Pembayaran',
                            icon: Icons.account_balance_wallet_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _DetailRow(
                                  label: 'Metode Pembayaran',
                                  value: tx.paymentMethod,
                                ),
                                if (tx.bankName != null)
                                  _DetailRow(
                                    label: 'Bank Tujuan',
                                    value: tx.bankName!,
                                  ),
                                if (tx.bankAccountNumber != null)
                                  _DetailRow(
                                    label: 'Nomor Rekening',
                                    value: tx.bankAccountNumber!,
                                  ),
                                if (tx.bankAccountName != null)
                                  _DetailRow(
                                    label: 'Atas Nama',
                                    value: tx.bankAccountName!,
                                  ),
                                const Divider(height: 20),
                                _DetailRow(
                                  label: 'Nominal Transfer',
                                  value: _formatCurrency(
                                    (tx.totalPrice ?? 0).toDouble(),
                                  ),
                                ),
                                if (tx.referenceNumber != null)
                                  _DetailRow(
                                    label: 'No. Referensi',
                                    value: tx.referenceNumber!,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 2,
                          child: _InfoCard(
                            title: 'Bukti Transfer',
                            icon: Icons.image_outlined,
                            child:
                                tx.paymentProofUrl != null &&
                                    tx.paymentProofUrl!.isNotEmpty
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Material(
                                        color: const Color(0xFFF5E0C8),
                                        borderRadius: BorderRadius.circular(8),
                                        clipBehavior: Clip.antiAlias,
                                        child: InkWell(
                                          onTap: () => _showProofFullScreen(
                                            context,
                                            tx.paymentProofUrl!,
                                          ),
                                          child: Container(
                                            height: 170,
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                color: _border,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Image.network(
                                              tx.paymentProofUrl!,
                                              fit: BoxFit.cover,
                                              loadingBuilder:
                                                  (
                                                    context,
                                                    child,
                                                    progress,
                                                  ) => progress == null
                                                  ? child
                                                  : const Center(
                                                      child:
                                                          CircularProgressIndicator(),
                                                    ),
                                              errorBuilder: (_, _, _) =>
                                                  const Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.image_rounded,
                                                        size: 40,
                                                        color: _brown,
                                                      ),
                                                      SizedBox(height: 6),
                                                      Text(
                                                        'Ketuk untuk melihat',
                                                        style: TextStyle(
                                                          fontSize: 11,
                                                          color: _brown,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (tx.paymentProofFilename != null)
                                        Text(
                                          tx.paymentProofFilename!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      if (tx.paymentProofUploadedAt != null)
                                        Text(
                                          _formatDate(
                                            tx.paymentProofUploadedAt,
                                            withTime: true,
                                          ),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      const SizedBox(height: 10),
                                      OutlinedButton.icon(
                                        onPressed: () => _showProofFullScreen(
                                          context,
                                          tx.paymentProofUrl!,
                                        ),
                                        icon: const Icon(
                                          Icons.open_in_new_rounded,
                                          size: 14,
                                        ),
                                        label: const Text('Lihat Bukti'),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: _brown,
                                          side: const BorderSide(color: _brown),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : const Center(
                                    child: Padding(
                                      padding: EdgeInsets.all(20),
                                      child: Column(
                                        children: [
                                          Icon(
                                            Icons.image_not_supported,
                                            color: Colors.grey,
                                            size: 32,
                                          ),
                                          SizedBox(height: 8),
                                          Text(
                                            'Belum ada bukti transfer',
                                            style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(width: 16),

                        Expanded(
                          flex: 3,
                          child: _InfoCard(
                            title: 'Riwayat Transaksi',
                            icon: Icons.history_toggle_off_rounded,
                            child: Column(children: _buildHistoryTimeline(tx)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('Kembali ke Laporan'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _brown,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
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

  List<Widget> _buildHistoryTimeline(PurchaseOrderModel tx) {
    final steps = <Map<String, String?>>[];

    if (tx.createdAt != null) {
      steps.add({
        'label': 'Pemesanan Dibuat',
        'time': _formatDate(tx.createdAt, withTime: true),
        'done': 'true',
      });
    }
    if (tx.paymentProofUploadedAt != null) {
      steps.add({
        'label': 'Bukti Pembayaran Diupload',
        'time': _formatDate(tx.paymentProofUploadedAt, withTime: true),
        'done': 'true',
      });
    }
    if (tx.reviewedAt != null) {
      steps.add({
        'label': 'Diverifikasi Staf',
        'time': _formatDate(tx.reviewedAt, withTime: true),
        'done': 'true',
      });
    }
    if (tx.confirmedAt != null) {
      steps.add({
        'label': 'Disetujui',
        'time': _formatDate(tx.confirmedAt, withTime: true),
        'done': 'true',
      });
    }
    if (tx.status == 'confirmed') {
      steps.add({
        'label': 'Properti Terjual',
        'time': _formatDate(tx.confirmedAt, withTime: true),
        'done': 'true',
      });
    }
    if (tx.status == 'rejected') {
      steps.add({
        'label': 'Ditolak',
        'time': _formatDate(tx.rejectedAt, withTime: true),
        'done': 'false',
        'isRejected': 'true',
      });
    }

    if (steps.isEmpty) {
      return [
        const Text(
          'Tidak ada riwayat tersedia.',
          style: TextStyle(color: Colors.grey),
        ),
      ];
    }

    return steps.asMap().entries.map((entry) {
      final i = entry.key;
      final step = entry.value;
      final isDone = step['done'] == 'true';
      final isRejected = step['isRejected'] == 'true';
      final isLast = i == steps.length - 1;

      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isRejected
                      ? Colors.red
                      : isDone
                      ? Colors.green
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isRejected
                      ? Icons.close_rounded
                      : isDone
                      ? Icons.check_rounded
                      : Icons.radio_button_unchecked,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 36,
                  color: isDone ? Colors.green.shade200 : Colors.grey.shade200,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['label'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: isRejected ? Colors.red : Colors.black87,
                    ),
                  ),
                  if (step['time'] != null && step['time']!.isNotEmpty)
                    Text(
                      step['time']!,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    }).toList();
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  final IconData? icon;

  const _InfoCard({required this.title, required this.child, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFE6DD), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x084A1F09),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: const Color(0xFF8B3E0F)),
                const SizedBox(width: 8),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF5C1E04),
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF7F0EB)),
          const SizedBox(height: 14),
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
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _IconDetailRow extends StatelessWidget {
  final IconData icon;
  final String value;

  const _IconDetailRow({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: Colors.grey),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class InvoicePrintPage extends StatelessWidget {
  final PurchaseOrderModel transaction;
  const InvoicePrintPage({super.key, required this.transaction});

  static const _brown = Color(0xFF7A3B1E);
  static const _brownLight = Color(0xFFF5E0C8);
  static const _border = Color(0xFFE7CCAE);
  static const _bg = Color(0xFFFFF8F0);

  String get _invoiceNumber {
    try {
      final dt = DateTime.parse(transaction.createdAt ?? '').toLocal();
      final year = dt.year;
      final monthStr = dt.month.toString().padLeft(2, '0');
      final dayStr = dt.day.toString().padLeft(2, '0');
      final numStr = transaction.id.toString().padLeft(4, '0');
      return 'INV/$year/$monthStr$dayStr/$numStr';
    } catch (_) {
      return 'INV/${DateTime.now().year}/${transaction.id.toString().padLeft(4, '0')}';
    }
  }

  String _formatCurrency(double amount) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);

  String _formatDate(String? raw, {bool withTime = false}) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      return withTime
          ? '${DateFormat('dd MMM yyyy', 'id_ID').format(dt)}, ${DateFormat('HH:mm').format(dt)} WIB'
          : DateFormat('dd MMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _brown,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              _invoiceNumber,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download PDF',
            onPressed: () => InvoicePdfService().shareInvoice(transaction),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: _brown,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.home_work_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'INVOICE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          Text(
                            _invoiceNumber,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatDate(tx.createdAt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _InvoiceStatusBadge(status: tx.status),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Body ──
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Buyer + Payment
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _InvoiceSection(
                            title: 'Kepada',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.buyerNameSnapshot,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                if (tx.buyerPhoneSnapshot != null)
                                  _InvoiceInfoLine(
                                    icon: Icons.phone_rounded,
                                    text: tx.buyerPhoneSnapshot!,
                                  ),
                                if (tx.buyerAddress != null)
                                  _InvoiceInfoLine(
                                    icon: Icons.location_on_rounded,
                                    text: tx.buyerAddress!,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: _InvoiceSection(
                            title: 'Pembayaran',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InvoiceKV('Metode', tx.paymentMethod),
                                if (tx.bankName != null)
                                  _InvoiceKV('Bank', tx.bankName!),
                                if (tx.bankAccountNumber != null)
                                  _InvoiceKV('No. Rek', tx.bankAccountNumber!),
                                if (tx.bankAccountName != null)
                                  _InvoiceKV('Atas Nama', tx.bankAccountName!),
                                if (tx.paymentDueAt != null)
                                  _InvoiceKV(
                                    'Jatuh Tempo',
                                    _formatDate(tx.paymentDueAt),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),
                    const Divider(color: _border),
                    const SizedBox(height: 12),

                    // Property table
                    const Text(
                      'Rincian Properti',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _brown,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Table(
                      border: TableBorder.all(
                        color: _border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      columnWidths: const {
                        0: FlexColumnWidth(3),
                        1: FlexColumnWidth(1),
                        2: FlexColumnWidth(2),
                      },
                      children: [
                        TableRow(
                          decoration: const BoxDecoration(color: _brownLight),
                          children: [
                            _th('Properti'),
                            _th('Qty'),
                            _th('Harga', right: true),
                          ],
                        ),
                        TableRow(
                          children: [
                            _td(
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.propertyTitle,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    tx.propertyLocation,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _td(
                              const Text('1', style: TextStyle(fontSize: 13)),
                            ),
                            _td(
                              Text(
                                _formatCurrency(tx.propertyPrice),
                                style: const TextStyle(fontSize: 13),
                              ),
                              right: true,
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _brownLight,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Total: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatCurrency(tx.payableAmount),
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: _brown,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (tx.notes != null) ...[
                      const SizedBox(height: 16),
                      const Divider(color: _border),
                      const SizedBox(height: 8),
                      const Text(
                        'Catatan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _brown,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(tx.notes!, style: const TextStyle(fontSize: 12)),
                    ],

                    if (tx.rejectionReason != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.cancel_rounded,
                              color: Colors.red,
                              size: 15,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Alasan Penolakan: ${tx.rejectionReason}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    const Divider(color: _border),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _InvoiceKV(
                            'Dibuat',
                            _formatDate(tx.createdAt, withTime: true),
                          ),
                        ),
                        if (tx.confirmedAt != null)
                          Expanded(
                            child: _InvoiceKV(
                              'Dikonfirmasi',
                              _formatDate(tx.confirmedAt, withTime: true),
                            ),
                          ),
                        if (tx.verifiedBy != null)
                          Expanded(
                            child: _InvoiceKV(
                              'Diverifikasi Oleh',
                              tx.verifiedBy!,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Footer ──
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 20,
                ),
                decoration: const BoxDecoration(
                  color: _brownLight,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
                child: Center(
                  child: Text(
                    'Dokumen ini diterbitkan secara otomatis oleh sistem.',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _th(String text, {bool right = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Text(
      text,
      textAlign: right ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 12,
        color: _brown,
      ),
    ),
  );

  static Widget _td(Widget child, {bool right = false}) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    child: right
        ? Align(alignment: Alignment.centerRight, child: child)
        : child,
  );
}

class _InvoiceStatusBadge extends StatelessWidget {
  final String status;
  const _InvoiceStatusBadge({required this.status});

  static const _labels = {
    'confirmed': 'Terjual',
    'pending_payment': 'Pending',
    'payment_uploaded': 'Dipesan',
    'payment_review': 'Dipesan',
    'rejected': 'Ditolak',
    'cancelled': 'Dibatalkan',
  };
  static const _colors = {
    'confirmed': Color(0xFF1B874B),
    'pending_payment': Color(0xFF1967D2),
    'payment_uploaded': Color(0xFFCB7D2A),
    'payment_review': Color(0xFFCB7D2A),
    'rejected': Color(0xFFC74C4C),
    'cancelled': Color(0xFF6C6C6C),
  };

  @override
  Widget build(BuildContext context) {
    final label = _labels[status] ?? status;
    final color = _colors[status] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _InvoiceSection extends StatelessWidget {
  final String title;
  final Widget child;
  const _InvoiceSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          color: Colors.grey,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      const SizedBox(height: 6),
      child,
    ],
  );
}

class _InvoiceInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InvoiceInfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: Colors.grey),
        const SizedBox(width: 4),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 12))),
      ],
    ),
  );
}

class _InvoiceKV extends StatelessWidget {
  final String label;
  final String value;
  const _InvoiceKV(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    ),
  );
}
