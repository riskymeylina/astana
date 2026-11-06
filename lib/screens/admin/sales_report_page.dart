import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:excel/excel.dart' hide Border;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../../../models/buyer_record_model.dart';
import '../../../../models/recap_transaction_model.dart';
import '../../../../services/admin_report_service.dart';
import '../../../../services/admin_buyer_record_service.dart';
import '../../../../models/purchase_order_model.dart';
import '../../../../widgets/braga_page_header.dart';
import 'transaction_detail_page.dart';
import '../purchases/purchase_detail_page.dart';
import '../../utils/file_saver.dart'; // Perbaikan: menggunakan path internal folder yang sama

class SalesReportPage extends StatefulWidget {
  const SalesReportPage({super.key});

  @override
  State<SalesReportPage> createState() => _SalesReportPageState();
}

class _SalesReportPageState extends State<SalesReportPage> {
  final AdminReportService _service = AdminReportService();
  final AdminBuyerRecordService _buyerRecordService = AdminBuyerRecordService();

  AdminSalesReportResult? _result;
  List<BuyerRecord> _buyerRecords = const [];
  bool _buyerRecordsLoading = true;
  String? _buyerRecordsError;
  bool _loading = true;
  String? _error;

  // Filter state
  DateTime? _fromDate;
  DateTime? _toDate;
  String? _selectedStatus;
  String? _selectedHistoricalStatus;
  String? _selectedPaymentMethod;
  String? _selectedProperty;

  // Pagination
  int _currentPage = 1;
  static const int _pageSize = 10;

  // Filtered/paged list
  List<PurchaseOrderModel> _filteredTransactions = [];
  List<HistoricalSale> _filteredHistoricalSales = [];

  static const _brown = Color(0xFF7A3B1E);
  static const _border = Color(0xFFE7CCAE);
  static const _bg = Color(0xFFFFF8F0);

  final List<String> _statusOptions = [
    'confirmed',
    'pending_payment',
    'payment_uploaded',
    'payment_review',
    'rejected',
    'cancelled',
  ];

  final List<String> _historicalStatusOptions = [
    'completed',
    'pending',
    'cancelled',
  ];

  final Map<String, String> _statusLabels = {
    'confirmed': 'Terjual',
    'pending_payment': 'Pending',
    'payment_uploaded': 'Dipesan',
    'payment_review': 'Dipesan',
    'rejected': 'Ditolak',
    'cancelled': 'Dibatalkan',
  };

  final Map<String, Color> _statusColors = {
    'confirmed': const Color(0xFF1B874B),
    'pending_payment': const Color(0xFF1967D2),
    'payment_uploaded': const Color(0xFFCB7D2A),
    'payment_review': const Color(0xFFCB7D2A),
    'rejected': const Color(0xFFC74C4C),
    'cancelled': const Color(0xFF6C6C6C),
  };

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
    final buyerRecordsFuture = _loadBuyerRecords();
    try {
      final res = await _service.getTransactions(
        status: _selectedStatus,
        historicalStatus: _selectedHistoricalStatus,
        from: _fromDate,
        to: _toDate,
      );
      if (!mounted) return;
      if (res.statusCode == 200) {
        final result = _service.parseSalesReport(res.body);
        setState(() {
          _result = result;
          _loading = false;
        });
        _applyFilters();
      } else {
        setState(() {
          _error = _service.parseMessage(res.body);
          _loading = false;
        });
      }
      await buyerRecordsFuture;
    } catch (_) {
      await buyerRecordsFuture;
      if (!mounted) return;
      setState(() {
        _error = 'Tidak dapat terhubung ke server';
        _loading = false;
      });
    }
  }

  Future<void> _loadBuyerRecords() async {
    if (mounted) {
      setState(() {
        _buyerRecordsLoading = true;
        _buyerRecordsError = null;
      });
    }

    try {
      final records = <BuyerRecord>[];
      var page = 1;
      var total = 0;
      do {
        final response = await _buyerRecordService.getBuyerRecords(
          page: page,
          limit: 100,
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw StateError(_buyerRecordService.parseMessage(response.body));
        }
        records.addAll(_buyerRecordService.parseBuyerRecords(response.body));
        total = _buyerRecordService.parseTotalCount(response.body);
        page++;
      } while (records.length < total);

      if (!mounted) return;
      setState(() {
        _buyerRecords = records;
        _buyerRecordsLoading = false;
      });
      if (_result != null) _applyFilters();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _buyerRecordsError = error.toString().replaceFirst('Bad state: ', '');
        _buyerRecordsLoading = false;
      });
    }
  }

  void _applyFilters() {
    if (_result == null) return;
    var list = List<PurchaseOrderModel>.from(_result!.transactions);
    var historicalSales = List<HistoricalSale>.from(_result!.historicalSales);

    if (_selectedStatus != null) {
      list = list.where((t) => t.status == _selectedStatus).toList();
    }
    if (_selectedHistoricalStatus != null) {
      historicalSales = historicalSales
          .where((sale) => sale.status == _selectedHistoricalStatus)
          .toList();
    }
    if (_selectedPaymentMethod != null) {
      list = list
          .where(
            (t) =>
                t.paymentMethod.toLowerCase() ==
                _selectedPaymentMethod!.toLowerCase(),
          )
          .toList();
      historicalSales = historicalSales
          .where(
            (sale) =>
                (sale.paymentMethod ?? '').toLowerCase() ==
                _selectedPaymentMethod!.toLowerCase(),
          )
          .toList();
    }
    if (_fromDate != null) {
      list = list.where((t) {
        if (t.createdAt == null) return false;
        return _matchesDateRange(DateTime.tryParse(t.createdAt!));
      }).toList();
      historicalSales = historicalSales
          .where((sale) => _matchesDateRange(sale.transactionDate))
          .toList();
    }
    if (_toDate != null) {
      list = list.where((t) {
        if (t.createdAt == null) return false;
        return _matchesDateRange(DateTime.tryParse(t.createdAt!));
      }).toList();
      historicalSales = historicalSales
          .where((sale) => _matchesDateRange(sale.transactionDate))
          .toList();
    }
    if (_selectedProperty != null) {
      list = list
          .where(
            (transaction) => transaction.propertyTitle == _selectedProperty,
          )
          .toList();
      historicalSales = historicalSales
          .where(
            (sale) =>
                (sale.propertyTitleCurrent ?? sale.propertyNameSnapshot) ==
                _selectedProperty,
          )
          .toList();
    }

    final canonicalTransactions = RecapTransaction.combine(
      orders: list,
      historicalSales: historicalSales,
      buyerRecords: _buyerRecords,
    );
    list = canonicalTransactions
        .where((transaction) => transaction.order != null)
        .map((transaction) => transaction.order!)
        .toList();
    historicalSales = canonicalTransactions
        .where((transaction) => transaction.historicalSale != null)
        .map((transaction) => transaction.historicalSale!)
        .toList();

    setState(() {
      _filteredTransactions = list;
      _filteredHistoricalSales = historicalSales;
      _currentPage = 1;
    });
  }

  bool _matchesDateRange(DateTime? date) {
    if (date == null) return false;
    final day = DateTime(date.year, date.month, date.day);
    if (_fromDate != null &&
        day.isBefore(
          DateTime(_fromDate!.year, _fromDate!.month, _fromDate!.day),
        )) {
      return false;
    }
    if (_toDate != null &&
        day.isAfter(DateTime(_toDate!.year, _toDate!.month, _toDate!.day))) {
      return false;
    }
    return true;
  }

  List<RecapTransaction> get _pagedCanonicalTransactions {
    final all = _canonicalTransactions;
    final start = (_currentPage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, all.length);
    if (start >= all.length) return [];
    return all.sublist(start, end);
  }

  int get _totalPages =>
      (_canonicalTransactions.length / _pageSize).ceil().clamp(1, 999);

  String _formatCurrency(double amount) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(amount);

  String _formatDate(String? raw, {bool withTime = false}) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final datePart = DateFormat('dd MMM yyyy', 'id_ID').format(dt);
      if (withTime) {
        return '$datePart, ${DateFormat('HH:mm').format(dt)} WIB';
      }
      return datePart;
    } catch (_) {
      return raw;
    }
  }

  // Summary stats
  List<RecapTransaction> get _canonicalTransactions => RecapTransaction.combine(
    orders: _filteredTransactions,
    historicalSales: _filteredHistoricalSales,
    buyerRecords: _buyerRecords,
  );

  int get _totalTransactions => _canonicalTransactions.length;

  double get _totalRevenue => _canonicalTransactions
      .where((transaction) => transaction.isConfirmed)
      .fold<double>(0, (sum, transaction) => sum + transaction.amount);

  int get _totalPropertiesSold => _canonicalTransactions
      .where((transaction) => transaction.isConfirmed)
      .length;

  int get _totalBuyers {
    return _canonicalTransactions
        .map((transaction) => transaction.buyerKey(_buyerRecords))
        .toSet()
        .length;
  }

  BuyerRecord? _buyerRecordForSale(HistoricalSale sale) {
    for (final buyer in _buyerRecords) {
      if (buyer.id == sale.buyerRecordId) return buyer;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          BragaPageHeader(
            title: 'Laporan Penjualan Properti',
            subtitle:
                'Pantau seluruh transaksi penjualan properti yang telah berhasil diproses.',
            decorativeIcon: Icons.bar_chart_rounded,
            actions: [
              _HeaderButton(
                icon: Icons.table_chart_rounded,
                label: 'Export Excel',
                color: const Color(0xFF1D6F42),
                onTap: _exportToExcel,
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                icon: Icons.picture_as_pdf_rounded,
                label: 'Export PDF',
                color: const Color(0xFFD93025),
                onTap: _exportToPdf,
              ),
              const SizedBox(width: 8),
              _HeaderButton(
                icon: Icons.print_rounded,
                label: 'Cetak Laporan',
                onTap: _printReport,
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
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _loadReport,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildFilterBar(),
            const SizedBox(height: 20),
            _buildSummaryCards(),
            const SizedBox(height: 20),
            _buildTransactionTable(),
            const SizedBox(height: 16),
            _buildPagination(),
            const SizedBox(height: 28),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _FilterField(
                  label: 'Tanggal Awal',
                  value: _fromDate != null
                      ? DateFormat('dd/MM/yyyy').format(_fromDate!)
                      : null,
                  placeholder: '01/05/2026',
                  icon: Icons.calendar_today_rounded,
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _fromDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (p != null) {
                      setState(() => _fromDate = p);
                      _applyFilters();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _FilterField(
                  label: 'Tanggal Akhir',
                  value: _toDate != null
                      ? DateFormat('dd/MM/yyyy').format(_toDate!)
                      : null,
                  placeholder: '12/06/2026',
                  icon: Icons.calendar_today_rounded,
                  onTap: () async {
                    final p = await showDatePicker(
                      context: context,
                      initialDate: _toDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (p != null) {
                      setState(() => _toDate = p);
                      _applyFilters();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownFilter<String>(
                  label: 'Status Transaksi',
                  value: _selectedStatus,
                  placeholder: 'Semua Status',
                  items: _statusOptions,
                  itemLabel: (s) => _statusLabels[s] ?? s,
                  onChanged: (v) {
                    setState(() => _selectedStatus = v);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownFilter<String>(
                  label: 'Metode Pembayaran',
                  value: _selectedPaymentMethod,
                  placeholder: 'Semua Metode',
                  items: const ['QRIS'],
                  itemLabel: (s) => s,
                  onChanged: (v) {
                    setState(() => _selectedPaymentMethod = v);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DropdownFilter<String>(
                  label: 'Properti',
                  value: _selectedProperty,
                  placeholder: 'Semua Properti',
                  items: {
                    ...?_result?.transactions
                        .map((t) => t.propertyTitle)
                        .where((title) => title.isNotEmpty),
                    ...?_result?.historicalSales.map(
                      (sale) =>
                          sale.propertyTitleCurrent ??
                          sale.propertyNameSnapshot,
                    ),
                  }.where((title) => title.isNotEmpty).toList(),
                  itemLabel: (s) => s,
                  onChanged: (v) {
                    setState(() => _selectedProperty = v);
                    _applyFilters();
                  },
                ),
              ),
              const SizedBox(width: 12),
              Column(
                children: [
                  const Text('  ', style: TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      FilledButton.icon(
                        onPressed: _loadReport,
                        icon: const Icon(Icons.tune_rounded, size: 16),
                        label: const Text('Terapkan'),
                        style: FilledButton.styleFrom(
                          backgroundColor: _brown,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _fromDate = null;
                            _toDate = null;
                            _selectedStatus = null;
                            _selectedHistoricalStatus = null;
                            _selectedPaymentMethod = null;
                            _selectedProperty = null;
                          });
                          _loadReport();
                        },
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: const Text('Reset'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 9,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: _DropdownFilter<String>(
                  label: 'Status Penjualan Historis',
                  value: _selectedHistoricalStatus,
                  placeholder: 'Semua Status Historis',
                  items: _historicalStatusOptions,
                  itemLabel: (status) => switch (status) {
                    'completed' => 'Selesai',
                    'pending' => 'Dalam Proses',
                    'cancelled' => 'Dibatalkan',
                    _ => status,
                  },
                  onChanged: (value) {
                    setState(() => _selectedHistoricalStatus = value);
                    _applyFilters();
                  },
                ),
              ),
              const Spacer(flex: 4),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _SummaryCard(
          icon: Icons.receipt_long_rounded,
          iconBg: const Color(0xFFE8F0FE),
          iconColor: const Color(0xFF1565C0),
          label: 'Total Penjualan',
          value: '$_totalTransactions',
          sub: 'Transaksi Sukses',
          badge: 'Tercatat',
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          icon: Icons.home_work_rounded,
          iconBg: const Color(0xFFFFF0E6),
          iconColor: const Color(0xFF6F3212),
          label: 'Unit Terjual',
          value: '$_totalPropertiesSold',
          sub: 'Transaksi selesai',
          badge: 'Terkonfirmasi',
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          icon: Icons.people_alt_rounded,
          iconBg: const Color(0xFFF5EEF8),
          iconColor: const Color(0xFF7B3FA0),
          label: 'Pembeli Bertransaksi',
          value: '$_totalBuyers',
          sub: 'Pembeli unik',
          badge: 'Tercatat',
        ),
        const SizedBox(width: 16),
        _SummaryCard(
          icon: Icons.payments_rounded,
          iconBg: const Color(0xFFEBF7F0),
          iconColor: const Color(0xFF16794C),
          label: 'Total Pendapatan',
          value: _formatCurrency(_totalRevenue),
          sub: 'Penerimaan Lunas',
          badge: 'Akumulasi Sah',
          large: true,
        ),
      ],
    );
  }

  Widget _buildTransactionTable() {
    final rows = _pagedCanonicalTransactions;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _brown,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: const [
                _TableHeader(label: 'Tanggal', flex: 2),
                _TableHeader(label: 'Invoice', flex: 2),
                _TableHeader(label: 'Pembeli', flex: 3),
                _TableHeader(label: 'Properti', flex: 3),
                _TableHeader(label: 'Metode Pembayaran', flex: 3),
                _TableHeader(label: 'Nilai', flex: 2),
                _TableHeader(label: 'Status', flex: 2),
                _TableHeader(label: 'Aksi', flex: 2),
              ],
            ),
          ),

          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: Text(
                  'Tidak ada data transaksi',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...rows.asMap().entries.map((entry) {
              return _RecapTransactionRow(
                transaction: entry.value,
                isEven: entry.key.isEven,
                statusLabels: _statusLabels,
                statusColors: _statusColors,
                formatCurrency: _formatCurrency,
                formatDate: _formatDate,
                onViewDetail: entry.value.order == null
                    ? () => _openHistoricalDetail(entry.value.historicalSale!)
                    : () => _openDetail(entry.value.order!),
              );
            }),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Text(
                  'Menampilkan '
                  'Menampilkan ${_canonicalTransactions.length} transaksi',
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoricalSalesTable() {
    final sales = _filteredHistoricalSales;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Penjualan Historis (Audit)',
          style: TextStyle(
            color: Color(0xFF2A1508),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Catatan historis ditampilkan di sini dan dihitung bersama transaksi '
          'aplikasi. Data duplikat pembeli dan properti hanya dihitung sekali.',
          style: TextStyle(color: Colors.black54, fontSize: 13),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF5C493D),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: const Row(
                  children: [
                    _TableHeader(label: 'Tanggal Transaksi', flex: 2),
                    _TableHeader(label: 'Pembeli', flex: 3),
                    _TableHeader(label: 'Properti (Snapshot)', flex: 3),
                    _TableHeader(label: 'Metode Pembayaran', flex: 2),
                    _TableHeader(label: 'Nilai Historis', flex: 2),
                    _TableHeader(label: 'Status', flex: 2),
                  ],
                ),
              ),
              if (sales.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Tidak ada catatan penjualan historis untuk filter ini.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...sales.asMap().entries.map((entry) {
                  final index = entry.key;
                  final sale = entry.value;
                  return Container(
                    color: index.isEven
                        ? Colors.white
                        : const Color(0xFFFFFBF6),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatDate(
                              sale.transactionDate?.toIso8601String(),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            _cleanBuyerName(sale.buyerFullName) ?? '-',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            sale.propertyNameSnapshot,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            sale.paymentMethod ?? '-',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _formatCurrency(
                              (sale.transactionValue ?? 0).toDouble(),
                            ),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        Expanded(
                          flex: 2,
                          child: Text(
                            sale.statusLabel,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${sales.length} catatan historis',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBuyerRecordsTable() {
    final transactionsByBuyer = <int, List<String>>{};
    for (final transaction in _canonicalTransactions) {
      final buyerKey = transaction.buyerKey(_buyerRecords);
      for (final buyer in _buyerRecords) {
        if (buyerKey != 'record:${buyer.id}') continue;
        final properties = transactionsByBuyer.putIfAbsent(buyer.id, () => []);
        if (!properties.contains(transaction.propertyName)) {
          properties.add(transaction.propertyName);
        }
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Data Pembeli',
                    style: TextStyle(
                      color: Color(0xFF2A1508),
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  _buyerRecordsLoading
                      ? 'Memuat...'
                      : '${_buyerRecords.length} pembeli',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
                IconButton(
                  tooltip: 'Muat ulang data pembeli',
                  onPressed: _buyerRecordsLoading ? null : _loadBuyerRecords,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          if (_buyerRecordsError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'Data pembeli gagal dimuat: $_buyerRecordsError',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            )
          else if (_buyerRecordsLoading)
            const LinearProgressIndicator(minHeight: 2)
          else if (_buyerRecords.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Text(
                'Belum ada data pembeli.',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            )
          else ...[
            Container(
              color: const Color(0xFFFAF7F4),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              child: const Row(
                children: [
                  _TableHeader(label: 'Nama Pembeli', flex: 4),
                  _TableHeader(label: 'Nomor Telepon', flex: 3),
                  _TableHeader(label: 'Kota', flex: 2),
                  _TableHeader(label: 'Properti', flex: 4),
                ],
              ),
            ),
            ..._buyerRecords.map((buyer) {
              final name = buyer.fullName
                  .trim()
                  .replaceFirst(
                    RegExp(r'^(?:(?:ibu|bapak)\s+)+', caseSensitive: false),
                    '',
                  )
                  .trim();
              final properties = transactionsByBuyer[buyer.id] ?? const [];
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF0EAE5))),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 4,
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(
                        buyer.phone ?? '—',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Text(
                        buyer.address ?? '—',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    Expanded(
                      flex: 4,
                      child: Text(
                        properties.isEmpty ? '—' : properties.join(', '),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  Widget _buildPagination() {
    if (_totalPages <= 1) return const SizedBox.shrink();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          onPressed: _currentPage > 1
              ? () => setState(() => _currentPage--)
              : null,
        ),
        ...List.generate(_totalPages.clamp(0, 7), (i) {
          final page = i + 1;
          final isActive = page == _currentPage;
          return GestureDetector(
            onTap: () => setState(() => _currentPage = page),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isActive ? _brown : Colors.white,
                border: Border.all(color: isActive ? _brown : _border),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Text(
                '$page',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        }),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          onPressed: _currentPage < _totalPages
              ? () => setState(() => _currentPage++)
              : null,
        ),
      ],
    );
  }

  void _openDetail(PurchaseOrderModel tx) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TransactionDetailPage(transaction: tx)),
    );
  }

  void _openHistoricalDetail(HistoricalSale sale) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PurchaseDetailPage(purchaseId: sale.id, historicalSale: sale),
      ),
    );
  }

  Future<void> _exportToExcel() async {
    if (_canonicalTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diexport')),
      );
      return;
    }

    try {
      var excelObj = Excel.createExcel();
      String sheetName = 'Laporan Penjualan';
      excelObj.rename('Sheet1', sheetName);
      var sheet = excelObj[sheetName];

      // Add Headers
      sheet.appendRow([
        TextCellValue('Tanggal'),
        TextCellValue('Nomor Invoice'),
        TextCellValue('Nama Pembeli'),
        TextCellValue('WhatsApp'),
        TextCellValue('Email'),
        TextCellValue('Alamat'),
        TextCellValue('Properti'),
        TextCellValue('Tipe'),
        TextCellValue('Metode Pembayaran'),
        TextCellValue('Nilai'),
        TextCellValue('Status'),
      ]);

      // Add Rows
      for (var tx in _filteredTransactions) {
        final invoiceNum = _getInvoiceNumber(tx);
        final statusLabel = _statusLabels[tx.status] ?? tx.status;
        sheet.appendRow([
          TextCellValue(_formatDate(tx.createdAt)),
          TextCellValue(invoiceNum),
          TextCellValue(_cleanBuyerName(tx.buyerNameSnapshot) ?? ''),
          TextCellValue(tx.buyerPhoneSnapshot ?? ''),
          TextCellValue(tx.buyerEmail ?? ''),
          TextCellValue(tx.buyerAddress ?? ''),
          TextCellValue(tx.propertyTitle),
          TextCellValue(tx.propertyType ?? ''),
          TextCellValue(tx.paymentMethod),
          DoubleCellValue((tx.totalPrice ?? 0.0).toDouble()),
          TextCellValue(statusLabel),
        ]);
      }
      for (final sale in _filteredHistoricalSales) {
        final buyer = _buyerRecordForSale(sale);
        sheet.appendRow([
          TextCellValue(_formatDate(sale.transactionDate?.toIso8601String())),
          TextCellValue('HIS-${sale.id}'),
          TextCellValue(
            _cleanBuyerName(sale.buyerFullName ?? buyer?.fullName) ?? '',
          ),
          TextCellValue(sale.buyerPhone ?? buyer?.phone ?? ''),
          TextCellValue(buyer?.email ?? ''),
          TextCellValue(buyer?.address ?? ''),
          TextCellValue(sale.propertyTitleCurrent ?? sale.propertyNameSnapshot),
          TextCellValue(''),
          TextCellValue(sale.paymentMethod ?? ''),
          DoubleCellValue((sale.transactionValue ?? 0).toDouble()),
          TextCellValue(sale.statusLabel),
        ]);
      }

      final bytes = excelObj.save();
      if (bytes != null) {
        await downloadFile(
          bytes: Uint8List.fromList(bytes),
          fileName:
              'Laporan_Penjualan_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx',
          mimeType:
              'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Laporan Excel berhasil diunduh')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal export Excel: $e')));
    }
  }

  Future<Uint8List> _generatePdfReport() async {
    final pdf = pw.Document(title: 'Laporan Penjualan Properti');

    final baseFont = await PdfGoogleFonts.robotoRegular();
    final boldFont = await PdfGoogleFonts.robotoBold();

    final totalRevenueText = _formatCurrency(_totalRevenue);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(24),
          theme: pw.ThemeData.withFont(base: baseFont, bold: boldFont),
        ),
        header: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(bottom: 20),
          child: pw.Text(
            'PT. ASTANA KARYA BANDAWASA - Laporan Penjualan',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 20),
          child: pw.Text(
            'Halaman ${context.pageNumber} dari ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey),
          ),
        ),
        build: (context) => [
          pw.Text(
            'Laporan Penjualan Properti',
            style: pw.TextStyle(
              fontSize: 20,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#7A3B1E'),
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Dicetak pada: ${DateFormat('dd MMMM yyyy, HH:mm').format(DateTime.now())} WIB',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey),
          ),
          pw.SizedBox(height: 16),

          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              _buildPdfSummaryCard(
                'Total Transaksi',
                '$_totalTransactions Transaksi',
              ),
              _buildPdfSummaryCard(
                'Unit Terjual',
                '$_totalPropertiesSold Unit',
              ),
              _buildPdfSummaryCard(
                'Pembeli Bertransaksi',
                '$_totalBuyers Orang',
              ),
              _buildPdfSummaryCard(
                'Total Pendapatan',
                totalRevenueText,
                isLarge: true,
              ),
            ],
          ),
          pw.SizedBox(height: 20),

          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: const {
              0: pw.FlexColumnWidth(2),
              1: pw.FlexColumnWidth(2.5),
              2: pw.FlexColumnWidth(3),
              3: pw.FlexColumnWidth(3),
              4: pw.FlexColumnWidth(2.5),
              5: pw.FlexColumnWidth(2.5),
              6: pw.FlexColumnWidth(2),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#7A3B1E'),
                ),
                children: [
                  _pdfTh('Tanggal'),
                  _pdfTh('Invoice'),
                  _pdfTh('Pembeli'),
                  _pdfTh('Properti'),
                  _pdfTh('Pembayaran'),
                  _pdfTh('Nilai'),
                  _pdfTh('Status'),
                ],
              ),
              ..._filteredTransactions.map((tx) {
                final invoiceNum =
                    'INV/${DateTime.now().year}/${tx.id.toString().padLeft(4, '0')}';
                final statusLabel = _statusLabels[tx.status] ?? tx.status;
                return pw.TableRow(
                  children: [
                    _pdfTd(_formatDate(tx.createdAt)),
                    _pdfTd(invoiceNum),
                    _pdfTd(_cleanBuyerName(tx.buyerNameSnapshot) ?? ''),
                    _pdfTd(tx.propertyTitle),
                    _pdfTd(tx.paymentMethod),
                    _pdfTd(_formatCurrency((tx.totalPrice ?? 0).toDouble())),
                    _pdfTd(statusLabel),
                  ],
                );
              }),
              ..._filteredHistoricalSales.map((sale) {
                final buyer = _buyerRecordForSale(sale);
                return pw.TableRow(
                  children: [
                    _pdfTd(
                      _formatDate(sale.transactionDate?.toIso8601String()),
                    ),
                    _pdfTd('HIS-${sale.id}'),
                    _pdfTd(
                      _cleanBuyerName(sale.buyerFullName ?? buyer?.fullName) ??
                          '',
                    ),
                    _pdfTd(
                      sale.propertyTitleCurrent ?? sale.propertyNameSnapshot,
                    ),
                    _pdfTd(sale.paymentMethod ?? ''),
                    _pdfTd(
                      _formatCurrency((sale.transactionValue ?? 0).toDouble()),
                    ),
                    _pdfTd(sale.statusLabel),
                  ],
                );
              }),
            ],
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildPdfSummaryCard(
    String label,
    String value, {
    bool isLarge = false,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: PdfColor.fromHex('#E7CCAE'), width: 1),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: isLarge ? 11 : 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#7A3B1E'),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfTh(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 8,
        ),
      ),
    );
  }

  pw.Widget _pdfTd(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8)),
    );
  }

  Future<void> _exportToPdf() async {
    if (_canonicalTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk diexport')),
      );
      return;
    }

    try {
      final bytes = await _generatePdfReport();
      await downloadFile(
        bytes: bytes,
        fileName:
            'Laporan_Penjualan_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.pdf',
        mimeType: 'application/pdf',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Laporan PDF berhasil diunduh')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal export PDF: $e')));
    }
  }

  Future<void> _printReport() async {
    if (_canonicalTransactions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak ada data untuk dicetak')),
      );
      return;
    }

    try {
      final bytes = await _generatePdfReport();
      await Printing.layoutPdf(
        name:
            'Laporan_Penjualan_${DateFormat('yyyyMMdd').format(DateTime.now())}',
        onLayout: (_) async => bytes,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal mencetak laporan: $e')));
    }
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _HeaderButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color ?? Colors.white),
      label: Text(
        label,
        style: TextStyle(color: color ?? Colors.white, fontSize: 13),
      ),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: (color ?? Colors.white).withOpacity(0.6)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _FilterField extends StatelessWidget {
  final String label;
  final String? value;
  final String placeholder;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterField({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD9C4AE)),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value ?? placeholder,
                    style: TextStyle(
                      fontSize: 13,
                      color: value != null ? Colors.black87 : Colors.black38,
                    ),
                  ),
                ),
                Icon(icon, size: 16, color: Colors.black45),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownFilter<T> extends StatelessWidget {
  final String label;
  final T? value;
  final String placeholder;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T?> onChanged;

  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.placeholder,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black54,
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<T>(
          value: value,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 9,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD9C4AE)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD9C4AE)),
            ),
            isDense: true,
          ),
          hint: Text(placeholder, style: const TextStyle(fontSize: 13)),
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          isExpanded: true,
          items: [
            DropdownMenuItem<T>(value: null, child: Text(placeholder)),
            ...items.map(
              (item) => DropdownMenuItem<T>(
                value: item,
                child: Text(itemLabel(item), overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String? sub;
  final String? badge;
  final bool large;

  const _SummaryCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    this.sub,
    this.badge,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
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
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: iconColor.withOpacity(0.18),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(icon, color: iconColor, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
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
                      fontSize: value.length > 14
                          ? 15
                          : (value.length > 9
                                ? 18
                                : large
                                ? 20
                                : 24),
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
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final String label;
  final int flex;
  const _TableHeader({required this.label, required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}

String? _cleanBuyerName(String? value) => value
    ?.trim()
    .replaceFirst(RegExp(r'^(?:(?:ibu|bapak)\s+)+', caseSensitive: false), '')
    .trim();

class _RecapTransactionRow extends StatelessWidget {
  final RecapTransaction transaction;
  final bool isEven;
  final Map<String, String> statusLabels;
  final Map<String, Color> statusColors;
  final String Function(double) formatCurrency;
  final String Function(String?, {bool withTime}) formatDate;
  final VoidCallback? onViewDetail;

  const _RecapTransactionRow({
    required this.transaction,
    required this.isEven,
    required this.statusLabels,
    required this.statusColors,
    required this.formatCurrency,
    required this.formatDate,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final order = transaction.order;
    final sale = transaction.historicalSale;
    final buyerName = _cleanBuyerName(transaction.buyerName) ?? '-';
    final status = transaction.status;
    final statusLabel = sale != null
        ? sale.statusLabel
        : statusLabels[status] ?? status;
    final statusColor = statusColors[status] ?? Colors.grey;
    final imageUrl = order?.propertyImageUrl ?? sale?.propertyThumbnailUrl;
    final invoice = order == null ? '-' : _getInvoiceNumber(order);
    final paymentMethod = transaction.paymentMethod ?? '-';
    final date = transaction.date?.toIso8601String();

    return Container(
      color: isEven ? Colors.white : const Color(0xFFFFFBF6),
      child: InkWell(
        onTap: onViewDetail,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  formatDate(date),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(invoice, style: const TextStyle(fontSize: 12)),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFF5E0C8),
                      child: Text(
                        buyerName == '-' ? '?' : buyerName[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7A3B1E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            buyerName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                          if (transaction.buyerPhone != null)
                            Text(
                              transaction.buyerPhone!,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E0C8),
                        borderRadius: BorderRadius.circular(6),
                        image: imageUrl != null && imageUrl.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(imageUrl),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: imageUrl == null || imageUrl.isEmpty
                          ? const Icon(
                              Icons.home_rounded,
                              size: 18,
                              color: Color(0xFF7A3B1E),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        transaction.propertyName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  paymentMethod,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  formatCurrency(transaction.amount),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    statusLabel,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: onViewDetail == null
                    ? const SizedBox.shrink()
                    : TextButton.icon(
                        onPressed: onViewDetail,
                        icon: const Icon(Icons.visibility_rounded, size: 15),
                        label: const Text('Lihat Detail'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF7A3B1E),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
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

class _TransactionRow extends StatelessWidget {
  final PurchaseOrderModel tx;
  final bool isEven;
  final Map<String, String> statusLabels;
  final Map<String, Color> statusColors;
  final String Function(double) formatCurrency;
  final String Function(String?, {bool withTime}) formatDate;
  final VoidCallback onViewDetail;

  const _TransactionRow({
    required this.tx,
    required this.isEven,
    required this.statusLabels,
    required this.statusColors,
    required this.formatCurrency,
    required this.formatDate,
    required this.onViewDetail,
  });

  @override
  Widget build(BuildContext context) {
    final status = tx.status;
    final statusLabel = statusLabels[status] ?? status;
    final statusColor = statusColors[status] ?? Colors.grey;
    final invoiceNum = _getInvoiceNumber(tx);
    final buyerName = _cleanBuyerName(tx.buyerNameSnapshot) ?? '';

    return Container(
      color: isEven ? Colors.white : const Color(0xFFFFFBF6),
      child: InkWell(
        onTap: onViewDetail,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDate(tx.createdAt),
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (tx.createdAt != null)
                      Text(
                        _extractTime(tx.createdAt!),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  invoiceNum,
                  style: const TextStyle(fontSize: 12, color: Colors.black87),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFFF5E0C8),
                      child: Text(
                        (buyerName.isNotEmpty)
                            ? buyerName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF7A3B1E),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            buyerName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (tx.buyerPhoneSnapshot != null)
                            Text(
                              tx.buyerPhoneSnapshot!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5E0C8),
                        borderRadius: BorderRadius.circular(6),
                        image:
                            (tx.propertyImageUrl != null &&
                                tx.propertyImageUrl!.isNotEmpty)
                            ? DecorationImage(
                                image: NetworkImage(tx.propertyImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          (tx.propertyImageUrl == null ||
                              tx.propertyImageUrl!.isEmpty)
                          ? const Icon(
                              Icons.home_rounded,
                              size: 18,
                              color: Color(0xFF7A3B1E),
                            )
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.propertyTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (tx.propertyType != null)
                            Text(
                              tx.propertyType!,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  tx.paymentMethod,
                  style: const TextStyle(fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  formatCurrency((tx.totalPrice ?? 0).toDouble()),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: TextButton.icon(
                  onPressed: onViewDetail,
                  icon: const Icon(Icons.visibility_rounded, size: 15),
                  label: const Text('Lihat Detail'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF7A3B1E),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractTime(String raw) {
    try {
      final dt = DateTime.parse(raw).toLocal();
      return '${DateFormat('HH:mm').format(dt)} WIB';
    } catch (_) {
      return '';
    }
  }
}

String _getInvoiceNumber(PurchaseOrderModel tx) {
  try {
    final dt = DateTime.parse(tx.createdAt ?? '').toLocal();
    final year = dt.year;
    final monthStr = dt.month.toString().padLeft(2, '0');
    final dayStr = dt.day.toString().padLeft(2, '0');
    final numStr = tx.id.toString().padLeft(4, '0');
    return 'INV/$year/$monthStr$dayStr/$numStr';
  } catch (_) {
    return 'INV/${DateTime.now().year}/${tx.id.toString().padLeft(4, '0')}';
  }
}
