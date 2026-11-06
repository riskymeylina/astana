import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/admin_report_service.dart';
import '../../../models/admin_models.dart';
import '../../../widgets/braga_page_header.dart';

class GlobalReportPage extends StatefulWidget {
  const GlobalReportPage({super.key});

  @override
  State<GlobalReportPage> createState() => _GlobalReportPageState();
}

class _GlobalReportPageState extends State<GlobalReportPage> {
  final AdminReportService _service = AdminReportService();

  AdminGlobalReportModel? _report;
  bool _loading = true;
  String? _error;

  static const _border = Color(0xFFE7CCAE);
  static const _brown = Color(0xFF7A4F2D);

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _service.getGlobalReport();
      if (res.statusCode == 200) {
        setState(() {
          _report = _service.parseGlobalReport(res.body);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      body: Column(
        children: [
          BragaPageHeader(
            title: 'Laporan Global',
            subtitle: 'Lihat laporan penjualan dan pemesanan.',
            decorativeIcon: Icons.public_rounded,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: _loadReport,
              ),
            ],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? _buildError()
                : _buildContent(),
          ),
        ],
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
              onPressed: _loadReport,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: FilledButton.styleFrom(backgroundColor: _brown),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_report == null) return const SizedBox.shrink();
    final r = _report!;
    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            title: 'Ringkasan Sistem',
            border: _border,
            children: [
              _StatRow(label: 'Pembeli', value: '${r.uniqueTransactingBuyers}'),
              _StatRow(label: 'Properti', value: '${r.totalProperties}'),
              _StatRow(label: 'Transaksi', value: '${r.totalTransactions}'),
            ],
          ),
          const SizedBox(height: 14),
          _SectionCard(
            title: 'Aktivitas Transaksi',
            border: _border,
            children: [
              _StatRow(
                label: 'Pembeli Bertransaksi',
                value: '${r.uniqueTransactingBuyers}',
              ),
              _StatRow(label: 'Transaksi Terjual', value: '${r.soldUnits}'),
              _StatRow(
                label: 'Pesanan Terkonfirmasi',
                value: '${r.confirmedTransactions}',
              ),
              _StatRow(
                label: 'Penjualan Historis Selesai',
                value: '${r.completedHistoricalTransactions}',
              ),
              _StatRow(
                label: 'Total Pendapatan',
                value: _formatCurrency(r.totalRevenue),
                highlight: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(amount);
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  final Color border;

  const _SectionCard({
    required this.title,
    required this.children,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color(0xFF7A4F2D),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFFF0E1CF)),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;

  const _StatRow({
    required this.label,
    required this.value,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.black87)),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: highlight ? const Color(0xFF7A4F2D) : Colors.black87,
              fontSize: highlight ? 15 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
