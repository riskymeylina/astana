import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../models/admin_models.dart';
import '../../../../services/admin_property_service.dart';

class ClusterReportData {
  final String clusterName;
  int totalUnit = 0;
  int tersedia = 0;
  int booking = 0;
  int terjual = 0;
  int arsip = 0;
  double totalNilai = 0;

  ClusterReportData(this.clusterName);
}

class AdminAvailabilityReportPage extends StatefulWidget {
  const AdminAvailabilityReportPage({super.key});

  @override
  State<AdminAvailabilityReportPage> createState() => _AdminAvailabilityReportPageState();
}

class _AdminAvailabilityReportPageState extends State<AdminAvailabilityReportPage> {
  final AdminPropertyService _propertyService = AdminPropertyService();
  bool _isLoading = true;
  List<AdminPropertyModel> _properties = [];
  List<ClusterReportData> _clusters = [];
  
  // Summary Stats
  int _totalUnit = 0;
  int _totalTersedia = 0;
  int _totalBooking = 0;
  int _totalTerjual = 0;
  double _totalNilaiAll = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final response = await _propertyService.getProperties();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final List<dynamic> data = _propertyService.parseProperties(response.body) as List<dynamic>;
        _properties = data.cast<AdminPropertyModel>();
        _processClusterData();
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _processClusterData() {
    final Map<String, ClusterReportData> map = {};
    _totalUnit = _properties.length;
    _totalTersedia = 0;
    _totalBooking = 0;
    _totalTerjual = 0;
    _totalNilaiAll = 0;

    for (var p in _properties) {
      final cName = p.location.isNotEmpty ? p.location : 'Lainnya';
      if (!map.containsKey(cName)) {
        map[cName] = ClusterReportData(cName);
      }
      
      final c = map[cName]!;
      c.totalUnit++;
      c.totalNilai += p.price;
      _totalNilaiAll += p.price;

      final st = p.status.toLowerCase();
      if (st == 'available') {
        c.tersedia++;
        _totalTersedia++;
      } else if (st == 'booking') {
        c.booking++;
        _totalBooking++;
      } else if (st == 'sold') {
        c.terjual++;
        _totalTerjual++;
      } else {
        c.arsip++;
      }
    }

    _clusters = map.values.toList();
    _clusters.sort((a, b) => b.totalUnit.compareTo(a.totalUnit)); // Sort by size
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(child: CircularProgressIndicator(color: Color(0xFF8B3E0F))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildFilterSection(),
            const SizedBox(height: 32),
            _buildSummaryCards(),
            const SizedBox(height: 32),
            _buildChartsSection(),
            const SizedBox(height: 32),
            _buildClusterTable(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF8B3E0F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Laporan Ketersediaan Properti',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Pantau ketersediaan unit properti secara real-time dan akurat per cluster/perumahan.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.analytics_rounded,
              size: 48,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Laporan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDropdown('Semua Bulan')),
              const SizedBox(width: 16),
              Expanded(child: _buildDropdown('Semua Tahun')),
              const SizedBox(width: 16),
              Expanded(child: _buildDropdown('Semua Cluster')),
              const SizedBox(width: 24),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.filter_list_rounded, size: 18),
                label: const Text('Terapkan'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B3E0F),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String hint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          hint: Text(hint, style: const TextStyle(fontSize: 14)),
          items: const [],
          onChanged: (val) {},
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Unit', '$_totalUnit', Icons.domain_rounded, const Color(0xFF6F3212), badge: 'Portofolio')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Tersedia', '$_totalTersedia', Icons.check_circle_rounded, const Color(0xFF16794C), badge: 'Siap Jual')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Booking', '$_totalBooking', Icons.pending_actions_rounded, const Color(0xFFC78928), badge: 'Proses')),
        const SizedBox(width: 16),
        Expanded(child: _buildStatCard('Terjual', '$_totalTerjual', Icons.sell_rounded, const Color(0xFFB03A2E), badge: 'Sah BAST')),
        const SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: _buildStatCard(
            'Total Nilai Properti',
            'Rp ${NumberFormat('#,###', 'id_ID').format(_totalNilaiAll)}',
            Icons.payments_rounded,
            const Color(0xFF16794C),
            badge: 'Akumulasi Nilai',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, {String? badge}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEE5DC), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A7568),
                    letterSpacing: 0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: value.length > 14 ? 15 : (value.length > 9 ? 18 : 24),
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF2A1508),
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 1,
          child: _buildDonutChart(),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 2,
          child: _buildBarChart(),
        ),
      ],
    );
  }

  Widget _buildDonutChart() {
    int t = _totalUnit == 0 ? 1 : _totalUnit;
    return Container(
      height: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Ringkasan Ketersediaan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 32),
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 60,
                    sections: [
                      PieChartSectionData(color: const Color(0xFF4CAF50), value: (_totalTersedia/t)*100, title: '', radius: 30),
                      PieChartSectionData(color: const Color(0xFFFFC107), value: (_totalBooking/t)*100, title: '', radius: 30),
                      PieChartSectionData(color: const Color(0xFFF44336), value: (_totalTerjual/t)*100, title: '', radius: 30),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$_totalUnit', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
                    const Text('Total Unit', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final topClusters = _clusters.take(5).toList();
    
    return Container(
      height: 360,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Top 5 Cluster (Berdasarkan Total Unit)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 24),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: topClusters.isEmpty ? 10 : topClusters.first.totalUnit.toDouble() * 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (val, meta) {
                        int idx = val.toInt();
                        if (idx < 0 || idx >= topClusters.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            topClusters[idx].clusterName.length > 10 
                              ? '${topClusters[idx].clusterName.substring(0, 10)}...' 
                              : topClusters[idx].clusterName,
                            style: const TextStyle(fontSize: 10),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(topClusters.length, (index) {
                  final c = topClusters[index];
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(toY: c.tersedia.toDouble(), color: const Color(0xFF4CAF50), width: 16),
                      BarChartRodData(toY: c.booking.toDouble(), color: const Color(0xFFFFC107), width: 16),
                      BarChartRodData(toY: c.terjual.toDouble(), color: const Color(0xFFF44336), width: 16),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Tersedia', const Color(0xFF4CAF50)),
              const SizedBox(width: 16),
              _buildLegend('Booking', const Color(0xFFFFC107)),
              const SizedBox(width: 16),
              _buildLegend('Terjual', const Color(0xFFF44336)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildClusterTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: const Text('Rincian per Cluster', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          ),
          const Divider(height: 1),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey, fontSize: 13),
              dataTextStyle: const TextStyle(fontSize: 14, color: Color(0xFF1A1A1A)),
              columns: const [
                DataColumn(label: Text('NAMA CLUSTER')),
                DataColumn(label: Text('TOTAL UNIT')),
                DataColumn(label: Text('TERSEDIA')),
                DataColumn(label: Text('BOOKING')),
                DataColumn(label: Text('TERJUAL')),
                DataColumn(label: Text('KETERSEDIAAN')),
                DataColumn(label: Text('NILAI ASET')),
              ],
              rows: _clusters.map((c) {
                double pct = c.totalUnit == 0 ? 0 : c.tersedia / c.totalUnit;
                return DataRow(
                  cells: [
                    DataCell(Text(c.clusterName, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text('${c.totalUnit}')),
                    DataCell(Text('${c.tersedia}', style: const TextStyle(color: Color(0xFF4CAF50), fontWeight: FontWeight.bold))),
                    DataCell(Text('${c.booking}', style: const TextStyle(color: Color(0xFFFFC107), fontWeight: FontWeight.bold))),
                    DataCell(Text('${c.terjual}', style: const TextStyle(color: Color(0xFFF44336), fontWeight: FontWeight.bold))),
                    DataCell(
                      SizedBox(
                        width: 140,
                        child: Row(
                          children: [
                            Expanded(
                              child: LinearProgressIndicator(
                                value: pct,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  pct > 0.5 ? const Color(0xFF4CAF50) : (pct > 0.2 ? const Color(0xFFFFC107) : const Color(0xFFF44336)),
                                ),
                                minHeight: 8,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text('${(pct * 100).toStringAsFixed(0)}%'),
                          ],
                        ),
                      ),
                    ),
                    DataCell(Text('Rp ${NumberFormat('#,###', 'id_ID').format(c.totalNilai)}')),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}
