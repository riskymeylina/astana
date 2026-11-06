import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/purchase_order_model.dart';

class StaffPaymentSummaryCard extends StatelessWidget {
  const StaffPaymentSummaryCard({
    super.key,
    required this.order,
    required this.formatPrice,
    required this.formatDate,
    this.compact = false,
  });

  final PurchaseOrderModel order;
  final String Function(double) formatPrice;
  final String Function(String?) formatDate;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isQris = order.isQris;
    final isCash = order.isCash;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 12 : 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E1D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isQris
                    ? Icons.qr_code_scanner_rounded
                    : (isCash ? Icons.payments_rounded : Icons.account_balance_wallet_rounded),
                color: isQris
                    ? const Color(0xFF1E5FAF)
                    : (isCash ? const Color(0xFF1F7A45) : const Color(0xFF8E4E16)),
                size: 20,
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Informasi Pembayaran',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
              StaffStatusBadge(status: order.status, paymentMethod: order.paymentMethod),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isQris
                  ? const Color(0xFF1E5FAF)
                  : (isCash ? const Color(0xFF1F7A45) : const Color(0xFF1E2A5A)),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isQris
                      ? 'Total Pembayaran QRIS'
                      : (isCash ? 'Total Pembayaran Tunai' : 'Total Pembayaran'),
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFE5E8FF),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formatPrice(order.payableAmount),
                  style: TextStyle(
                    fontSize: compact ? 18 : 21,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _StaffPaymentRow(
            label: 'Metode Pembayaran',
            value: isQris ? 'QRIS' : (isCash ? 'Cash Payment (Tunai di Kasir)' : order.paymentMethod),
            icon: Icons.credit_card_rounded,
          ),
          if (isQris) ...[
            _StaffPaymentRow(
              label: 'Order ID Transaksi',
              value: order.midtransOrderId ?? 'Belum dibuat',
              icon: Icons.tag_rounded,
              trailing: (order.midtransOrderId ?? '').isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Salin Order ID',
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: order.midtransOrderId!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order ID disalin')),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                    ),
            ),
            _StaffPaymentRow(
              label: 'Status Pembayaran',
              value: order.isConfirmed
                  ? 'Lunas'
                  : (order.midtransPaymentStatus ?? 'Menunggu Scan'),
              icon: Icons.verified_user_rounded,
              valueColor: order.isConfirmed ? const Color(0xFF1F7A45) : const Color(0xFF1E5FAF),
            ),
          ] else ...[
            const _StaffPaymentRow(
              label: 'Lokasi Kasir',
              value: 'Kantor Pemasaran Astana Karya',
              icon: Icons.storefront_rounded,
            ),
          ],
          _StaffPaymentRow(
            label: 'Batas Pembayaran',
            value: formatDate(order.paymentDueAt),
            icon: Icons.schedule_rounded,
            valueColor: order.isCancelled
                ? const Color(0xFFC0392B)
                : const Color(0xFF9A6700),
          ),
          if ((order.paymentProofUrl ?? '').isNotEmpty) ...[
            const SizedBox(height: 12),
            _PaymentProofPreview(imageUrl: order.paymentProofUrl!),
          ],
        ],
      ),
    );
  }
}

class _PaymentProofPreview extends StatelessWidget {
  const _PaymentProofPreview({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showFullScreen(context),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE6D4BC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(
                  Icons.image_search_rounded,
                  size: 18,
                  color: Color(0xFF8E4E16),
                ),
                SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'Kwitansi / Bukti Pembayaran',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF3A2B1F),
                    ),
                  ),
                ),
                Icon(Icons.open_in_full_rounded, size: 16),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 92,
                  color: const Color(0xFFFFF3E7),
                  child: const Center(child: Text('Gagal memuat gambar')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreen(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Center(
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Text(
                    'Gagal memuat gambar',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                onPressed: () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffPaymentRow extends StatelessWidget {
  const _StaffPaymentRow({
    required this.label,
    required this.value,
    required this.icon,
    this.trailing,
    this.valueColor,
  });

  final String label;
  final String value;
  final IconData icon;
  final Widget? trailing;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF8E4E16)),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF8A735F),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.trim().isEmpty ? '-' : value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: valueColor ?? const Color(0xFF303030),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class StaffStatusBadge extends StatelessWidget {
  const StaffStatusBadge({super.key, required this.status, this.paymentMethod});

  final String status;
  final String? paymentMethod;

  @override
  Widget build(BuildContext context) {
    final style = staffStatusStyle(status, paymentMethod: paymentMethod);

    return Container(
      constraints: const BoxConstraints(maxWidth: 140),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        style.label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: style.foreground,
        ),
      ),
    );
  }
}

class StaffStatusStyle {
  const StaffStatusStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

StaffStatusStyle staffStatusStyle(String status, {String? paymentMethod}) {
  final isQris = (paymentMethod ?? '').toUpperCase().contains('QRIS');
  final isCash = (paymentMethod ?? '').toLowerCase().contains('cash') ||
      (paymentMethod ?? '').toLowerCase().contains('tunai');

  switch (status) {
    case 'confirmed':
      return const StaffStatusStyle(
        label: 'Dikonfirmasi',
        background: Color(0xFFE6F6EC),
        foreground: Color(0xFF1F7A45),
      );
    case 'rejected':
      return const StaffStatusStyle(
        label: 'Ditolak',
        background: Color(0xFFFCE8E6),
        foreground: Color(0xFFC0392B),
      );
    case 'cancelled':
      return const StaffStatusStyle(
        label: 'Dibatalkan',
        background: Color(0xFFF1F1F1),
        foreground: Color(0xFF6B7280),
      );
    case 'payment_uploaded':
      return const StaffStatusStyle(
        label: 'Bukti Diunggah',
        background: Color(0xFFE3EFFD),
        foreground: Color(0xFF1E5FAF),
      );
    case 'payment_review':
      return const StaffStatusStyle(
        label: 'Sedang Ditinjau',
        background: Color(0xFFEDE7F6),
        foreground: Color(0xFF5E35B1),
      );
    default:
      if (status == 'pending_payment') {
        if (isQris) {
          return const StaffStatusStyle(
            label: 'Menunggu QRIS',
            background: Color(0xFFE3EFFD),
            foreground: Color(0xFF1E5FAF),
          );
        }
        if (isCash) {
          return const StaffStatusStyle(
            label: 'Menunggu Kasir',
            background: Color(0xFFFFF3D9),
            foreground: Color(0xFF9A6700),
          );
        }
      }
      return const StaffStatusStyle(
        label: 'Menunggu Bayar',
        background: Color(0xFFFFF3D9),
        foreground: Color(0xFF9A6700),
      );
  }
}
