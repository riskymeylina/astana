import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../services/admin_report_service.dart';
import '../../../../../models/recap_transaction_model.dart';

class DashboardChartSection extends StatefulWidget {
  const DashboardChartSection({super.key});

  @override
  State<DashboardChartSection> createState() => _DashboardChartSectionState();
}

class _DashboardChartSectionState extends State<DashboardChartSection> {
  final AdminReportService _reportService = AdminReportService();
  bool _isLoading = true;
  String _selectedPeriod = '6 Bulan';
  List<RecapTransaction> _transactions = [];

  final List<String> _periods = ['1 Bulan', '3 Bulan', '6 Bulan', '1 Tahun', 'Semua Waktu'];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    DateTime? from;
    final now = DateTime.now();
    
    if (_selectedPeriod == '1 Bulan') {
      from = DateTime(now.year, now.month - 1, now.day);
    } else if (_selectedPeriod == '3 Bulan') {
      from = DateTime(now.year, now.month - 3, now.day);
    } else if (_selectedPeriod == '6 Bulan') {
      from = DateTime(now.year, now.month - 6, now.day);
    } else if (_selectedPeriod == '1 Tahun') {
      from = DateTime(now.year - 1, now.month, now.day);
    }

    try {
      final response = await _reportService.getTransactions(from: from, to: now);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final result = _reportService.parseSalesReport(response.body);
        setState(() {
          _transactions = RecapTransaction.combine(
            orders: result.transactions,
            historicalSales: result.historicalSales,
          ).where((t) => t.isConfirmed).toList();
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  Map<String, double> _getMonthlyData() {
    final Map<String, double> data = {};
    for (var t in _transactions) {
      if (t.date != null) {
        final dt = t.date!.toLocal();
        final monthStr = DateFormat('MMM yy', 'id_ID').format(dt);
        data[monthStr] = (data[monthStr] ?? 0) + t.amount;
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final data = _getMonthlyData();
    final labels = data.keys.toList();
    labels.sort((a, b) {
      try {
        final dta = DateFormat('MMM yy', 'id_ID').parse(a);
        final dtb = DateFormat('MMM yy', 'id_ID').parse(b);
        return dta.compareTo(dtb);
      } catch (_) {
        return 0;
      }
    });

    final values = labels.map((l) => data[l]!).toList();
    if (labels.isEmpty) {
      labels.add(DateFormat('MMM yy', 'id_ID').format(DateTime.now()));
      values.add(0);
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Grafik Penjualan',
                style: TextStyle(
                  color: Color(0xFF1A1A1A),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedPeriod,
                    isDense: true,
                    icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedPeriod = newValue;
                        });
                        _loadData();
                      }
                    },
                    items: _periods.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : CustomPaint(
                    size: const Size(double.infinity, double.infinity),
                    painter: _RealLineChartPainter(values: values),
                  ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels.map((l) => Text(l, style: const TextStyle(color: Colors.grey, fontSize: 12))).toList(),
          ),
        ],
      ),
    );
  }
}

class _RealLineChartPainter extends CustomPainter {
  final List<double> values;

  _RealLineChartPainter({required this.values});

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFFCC7A2E)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFCC7A2E).withOpacity(0.3),
          const Color(0xFFCC7A2E).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    double maxVal = values.reduce((curr, next) => curr > next ? curr : next);
    if (maxVal == 0) maxVal = 1; // Prevent division by zero

    final path = Path();
    final points = <Offset>[];

    for (int i = 0; i < values.length; i++) {
      double x = values.length == 1 ? size.width / 2 : (i / (values.length - 1)) * size.width;
      double y = size.height - ((values[i] / maxVal) * size.height * 0.8); // Leave 20% padding at top
      points.add(Offset(x, y));
    }

    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(points.last.dx, size.height)
      ..lineTo(points.first.dx, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final dotPaint = Paint()
      ..color = const Color(0xFFCC7A2E)
      ..style = PaintingStyle.fill;

    for (var point in points) {
      canvas.drawCircle(point, 5, dotPaint);
      canvas.drawCircle(point, 3, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
