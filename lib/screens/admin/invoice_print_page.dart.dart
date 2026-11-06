import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/purchase_order_model.dart';

class InvoicePrintPage extends StatelessWidget {
  final PurchaseOrderModel transaction;

  const InvoicePrintPage({super.key, required this.transaction});

  static const _brown = Color(0xFF7A3B1E);
  static const _brownLight = Color(0xFFF5E0C8);
  static const _border = Color(0xFFE7CCAE);
  static const _bg = Color(0xFFFFF8F0);

  String get _invoiceNumber {
    final year = DateTime.now().year;
    return 'INV/$year/${transaction.id.toString().padLeft(4, '0')}';
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
      if (withTime) {
        return '${DateFormat('dd MMM yyyy', 'id_ID').format(dt)}, '
            '${DateFormat('HH:mm').format(dt)} WIB';
      }
      return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Invoice',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Pratinjau dan bagikan faktur transaksi',
              style: TextStyle(fontSize: 11, height: 1.2),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Bagikan',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fitur bagikan belum tersedia')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded),
            tooltip: 'Download PDF',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fitur download PDF belum tersedia'),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
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
              // Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: _brown,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.home_work_rounded,
                      color: Colors.white,
                      size: 36,
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
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _invoiceNumber,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
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
                        const SizedBox(height: 4),
                        _StatusBadge(status: tx.status),
                      ],
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Buyer & Property Info side by side
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _Section(
                            title: 'Kepada',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tx.buyerNameSnapshot,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                if (tx.buyerPhoneSnapshot != null)
                                  _InfoLine(
                                    icon: Icons.phone_rounded,
                                    text: tx.buyerPhoneSnapshot!,
                                  ),
                                if (tx.buyerAddress != null)
                                  _InfoLine(
                                    icon: Icons.location_on_rounded,
                                    text: tx.buyerAddress!,
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: _Section(
                            title: 'Detail Pembayaran',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InvoiceRow(
                                  label: 'Metode',
                                  value: tx.paymentMethod,
                                ),
                                if (tx.bankName != null)
                                  _InvoiceRow(
                                    label: 'Bank',
                                    value: tx.bankName!,
                                  ),
                                if (tx.bankAccountNumber != null)
                                  _InvoiceRow(
                                    label: 'No. Rekening',
                                    value: tx.bankAccountNumber!,
                                  ),
                                if (tx.bankAccountName != null)
                                  _InvoiceRow(
                                    label: 'Atas Nama',
                                    value: tx.bankAccountName!,
                                  ),
                                if (tx.paymentDueAt != null)
                                  _InvoiceRow(
                                    label: 'Jatuh Tempo',
                                    value: _formatDate(tx.paymentDueAt),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(color: _border),
                    const SizedBox(height: 16),

                    // Property table
                    const Text(
                      'Rincian Properti',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: _brown,
                      ),
                    ),
                    const SizedBox(height: 12),
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
                          children: const [
                            _TableHeader('Properti'),
                            _TableHeader('Qty'),
                            _TableHeader('Harga', align: TextAlign.right),
                          ],
                        ),
                        TableRow(
                          children: [
                            _TableCell(
                              child: Column(
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
                            const _TableCell(
                              child: Text('1', style: TextStyle(fontSize: 13)),
                            ),
                            _TableCell(
                              align: Alignment.centerRight,
                              child: Text(
                                _formatCurrency(tx.propertyPrice),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Total
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
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
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _formatCurrency(tx.payableAmount),
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

                    const SizedBox(height: 24),
                    const Divider(color: _border),
                    const SizedBox(height: 12),

                    // Notes
                    if (tx.notes != null) ...[
                      const Text(
                        'Catatan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _brown,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tx.notes!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Footer timestamps
                    Row(
                      children: [
                        Expanded(
                          child: _InvoiceRow(
                            label: 'Dibuat',
                            value: _formatDate(tx.createdAt, withTime: true),
                          ),
                        ),
                        if (tx.confirmedAt != null)
                          Expanded(
                            child: _InvoiceRow(
                              label: 'Dikonfirmasi',
                              value: _formatDate(
                                tx.confirmedAt,
                                withTime: true,
                              ),
                            ),
                          ),
                        if (tx.verifiedBy != null)
                          Expanded(
                            child: _InvoiceRow(
                              label: 'Diverifikasi Oleh',
                              value: tx.verifiedBy!,
                            ),
                          ),
                      ],
                    ),

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
                              size: 16,
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
                  ],
                ),
              ),

              // Footer bar
              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 24,
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
}

// ── Small helper widgets ─────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  static const _labels = {
    'confirmed': 'Terjual',
    'pending_payment': 'Pending',
    'payment_uploaded': 'Pembayaran Diunggah',
    'payment_review': 'Diverifikasi',
    'rejected': 'Ditolak',
    'cancelled': 'Dibatalkan',
  };

  static const _colors = {
    'confirmed': Colors.green,
    'pending_payment': Colors.orange,
    'payment_uploaded': Colors.blue,
    'payment_review': Colors.indigo,
    'rejected': Colors.red,
    'cancelled': Colors.grey,
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

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
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
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  final String label;
  final String value;
  const _InvoiceRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
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
}

class _TableHeader extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _TableHeader(this.text, {this.align = TextAlign.left});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 12,
          color: Color(0xFF7A3B1E),
        ),
      ),
    );
  }
}

class _TableCell extends StatelessWidget {
  final Widget child;
  final Alignment align;
  const _TableCell({required this.child, this.align = Alignment.centerLeft});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Align(alignment: align, child: child),
    );
  }
}
