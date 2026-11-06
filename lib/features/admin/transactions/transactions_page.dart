import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/admin_report_service.dart';
import '../../../models/purchase_order_model.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final AdminReportService _service = AdminReportService();

  List<PurchaseOrderModel> _transactions = [];
  bool _loading = true;
  String? _error;
  String _selectedStatus = '';

  static const _amber = Color(0xFFFDD096);
  static const _border = Color(0xFFE7CCAE);
  static const _brown = Color(0xFF7A4F2D);

  static const _statusOptions = [
    {'value': '', 'label': 'Semua'},
    {'value': 'pending', 'label': 'Menunggu'},
    {'value': 'completed', 'label': 'Selesai'},
    {'value': 'cancelled', 'label': 'Dibatalkan'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.getTransactions(
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
      );
      if (res.statusCode == 200) {
        setState(() {
          _transactions = _service.parseTransactions(res.body);
          _loading = false;
        });
      } else {
        setState(() {
          _error = _service.parseMessage(res.body);
          _loading = false;
        });
      }
    } catch (_) {
      setState(() {
        _error = 'Tidak dapat terhubung ke server';
        _loading = false;
      });
    }
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }

  String _formatDate(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: _amber,
        foregroundColor: _brown,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Semua Transaksi',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Pantau pembayaran dan status transaksi properti',
              style: TextStyle(fontSize: 11, height: 1.2),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadTransactions,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : _transactions.isEmpty
                        ? _buildEmpty()
                        : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusOptions.map((opt) {
            final isSelected = _selectedStatus == opt['value'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(opt['label']!),
                selected: isSelected,
                selectedColor: _brown,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : _brown,
                  fontWeight: FontWeight.w600,
                ),
                side: const BorderSide(color: _border),
                backgroundColor: const Color(0xFFFFF8F0),
                onSelected: (_) {
                  if (_selectedStatus != opt['value']) {
                    setState(() => _selectedStatus = opt['value']!);
                    _loadTransactions();
                  }
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _loadTransactions,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(backgroundColor: _brown),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_rounded, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text(
            'Belum ada data transaksi',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return RefreshIndicator(
      onRefresh: _loadTransactions,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _transactions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final tx = _transactions[i];
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        tx.propertyTitle,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _StatusChip(status: tx.status),
                  ],
                ),
                if (tx.buyerName != null && tx.buyerName!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Pembeli: ${tx.buyerName}',
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                ],
                if (tx.invoiceNumber != null && tx.invoiceNumber!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    tx.invoiceNumber!,
                    style: const TextStyle(fontSize: 12, color: Colors.grey, fontFamily: 'monospace'),
                  ),
                ],
                const Divider(height: 16, color: Color(0xFFF4EAE0)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatCurrency((tx.totalPrice ?? 0).toDouble()),
                      style: const TextStyle(
                        color: _brown,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(tx.createdAt),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color {
    return switch (status.toLowerCase()) {
      'selesai' || 'completed' || 'dikonfirmasi' => Colors.green,
      'menunggu' || 'pending' || 'sedang diverifikasi' => Colors.orange,
      'ditolak' || 'rejected' || 'cancelled' || 'dibatalkan' => Colors.red,
      _ => Colors.grey,
    };
  }

  String get _label {
    return switch (status.toLowerCase()) {
      'completed' || 'selesai' || 'dikonfirmasi' => 'Selesai',
      'pending' || 'menunggu' || 'sedang diverifikasi' => 'Menunggu',
      'cancelled' || 'dibatalkan' || 'rejected' || 'ditolak' => 'Batal',
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withOpacity(0.4)),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}