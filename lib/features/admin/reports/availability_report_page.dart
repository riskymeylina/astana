import 'package:flutter/material.dart';

import '../../../services/admin_report_service.dart';
import '../../../models/admin_models.dart';

class AvailabilityReportPage extends StatefulWidget {
  const AvailabilityReportPage({super.key});

  @override
  State<AvailabilityReportPage> createState() => _AvailabilityReportPageState();
}

class _AvailabilityReportPageState extends State<AvailabilityReportPage> {
  final AdminReportService _service = AdminReportService();

  AdminAvailabilityReportResult? _result;
  bool _loading = true;
  String? _error;

  static const _amber = Color(0xFFFDD096);
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
      final res = await _service.getAvailabilityReport();
      if (res.statusCode == 200) {
        setState(() {
          _result = _service.parseAvailabilityReport(res.body);
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
      appBar: AppBar(
        backgroundColor: _amber,
        foregroundColor: _brown,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Laporan Ketersediaan',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            Text(
              'Ringkasan unit properti berdasarkan status',
              style: TextStyle(fontSize: 11, height: 1.2),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadReport,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContent(),
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
    final result = _result!;

    if (result.summary.isEmpty && result.properties.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apartment_rounded, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'Belum ada data ketersediaan',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadReport,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (result.summary.isNotEmpty) ...[
            const Text(
              'Ringkasan Ketersediaan',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: _brown,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: result.summary
                    .map(
                      (s) => _SummaryTile(
                        summary: s,
                        border: _border,
                        brown: _brown,
                        isLast: s == result.summary.last,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 20),
          ],
          if (result.properties.isNotEmpty) ...[
            const Text(
              'Detail Properti',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: _brown,
              ),
            ),
            const SizedBox(height: 10),
            ...result.properties.map(
              (p) => _PropertyCard(
                property: p,
                border: _border,
                brown: _brown,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final AdminAvailabilitySummaryModel summary;
  final Color border;
  final Color brown;
  final bool isLast;

  const _SummaryTile({
    required this.summary,
    required this.border,
    required this.brown,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  summary.status,
                  style: const TextStyle(color: Colors.black87),
                ),
              ),
              Text(
                '${summary.total} unit', // Diperbaiki dari summary.count ke summary.total
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: brown,
                ),
              ),
            ],
          ),
        ),
        if (!isLast) const Divider(height: 1, color: Color(0xFFF0E1CF)),
      ],
    );
  }
}

class _PropertyCard extends StatelessWidget {
  final AdminPropertyModel property;
  final Color border;
  final Color brown;

  const _PropertyCard({
    required this.property,
    required this.border,
    required this.brown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0D6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: border),
            ),
            child: Icon(Icons.apartment_rounded, color: brown, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                if (property.category.isNotEmpty) // Diperbaiki dari property.type ke property.category
                  Text(
                    property.category,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
              ],
            ),
          ),
          _AvailabilityBadge(status: property.status.isNotEmpty ? property.status : '-'),
        ],
      ),
    );
  }
}

class _AvailabilityBadge extends StatelessWidget {
  final String status;
  const _AvailabilityBadge({required this.status});

  Color get _color {
    return switch (status.toLowerCase()) {
      'tersedia' || 'available' => Colors.green,
      'terjual' || 'sold' => Colors.red,
      'dipesan' || 'booking' || 'reserved' => Colors.orange, // Menambahkan case 'booking' agar selaras dengan data internal
      _ => Colors.grey,
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
        status,
        style: TextStyle(
          fontSize: 11,
          color: _color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}