import '../../widgets/braga_page_header.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../models/buyer_record_model.dart';
import '../../models/purchase_order_model.dart';
import '../../models/recap_transaction_model.dart';
import '../../services/admin_buyer_record_service.dart';
import '../../services/auth_service.dart';
import '../../services/purchase_service.dart';
import 'widgets/staff_payment_summary_card.dart';
import 'purchase_detail_page.dart';

class MarketingTransactionRecapPage extends StatefulWidget {
  const MarketingTransactionRecapPage({super.key});

  @override
  State<MarketingTransactionRecapPage> createState() =>
      _MarketingTransactionRecapPageState();
}

class _MarketingTransactionRecapPageState
    extends State<MarketingTransactionRecapPage> {
  final PurchaseService _purchaseService = PurchaseService();
  final AdminBuyerRecordService _buyerRecordService = AdminBuyerRecordService();
  final NumberFormat _priceFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  bool _isLoading = true;
  bool _hasLoadedOrders = false;
  bool _isLocaleReady = false;
  String? _errorMessage;
  List<PurchaseOrderModel> _orders = const [];
  List<BuyerRecord> _buyerRecords = const [];
  List<HistoricalSale> _historicalSales = const [];
  String? _buyerError;
  List<int> _availableYears = [];
  DateTime? _filterFrom;
  DateTime? _filterTo;
  int? _filterMonth;
  int? _filterYear;
  String? _filterStatus;
  final TextEditingController _searchCtrl = TextEditingController();

  final List<String?> _statusFilterOptions = [
    null,
    'confirmed',
    'pending_payment',
    'payment_uploaded',
    'payment_review',
    'rejected',
    'cancelled',
  ];

  String _statusOptionLabel(String? status) {
    switch (status) {
      case 'confirmed':
        return 'Dikonfirmasi (Lunas)';
      case 'pending_payment':
        return 'Menunggu Pembayaran';
      case 'payment_uploaded':
        return 'Bukti Diunggah';
      case 'payment_review':
        return 'Sedang Ditinjau';
      case 'rejected':
        return 'Ditolak';
      case 'cancelled':
        return 'Dibatalkan';
      default:
        return 'Semua Status';
    }
  }

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10;

  // KPI Recap Stats
  List<RecapTransaction> get _filteredTransactions => RecapTransaction.combine(
    orders: _orders,
    historicalSales: _filteredHistoricalSales,
    buyerRecords: _buyerRecords,
  );

  int get _totalTransactions => _filteredTransactions.length;

  int get _uniqueBuyerCount => _filteredTransactions
      .map((transaction) => transaction.buyerKey(_buyerRecords))
      .toSet()
      .length;

  int get _confirmedUnitCount => _filteredTransactions
      .where((transaction) => transaction.isConfirmed)
      .length;

  double get _totalRevenue => _filteredTransactions
      .where((transaction) => transaction.isConfirmed)
      .fold<double>(0, (sum, transaction) => sum + transaction.amount);

  @override
  void initState() {
    super.initState();
    _preparePage();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _preparePage() async {
    await initializeDateFormatting('id_ID');
    if (!mounted) return;
    setState(() => _isLocaleReady = true);
    await Future.wait([_loadOrders(), _loadBuyerData()]);
  }

  Future<void> _refreshRecap() async {
    await Future.wait([_loadOrders(), _loadBuyerData()]);
  }

  Future<void> _loadOrders() async {
    if (!_hasLoadedOrders) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    final searchVal = _searchCtrl.text.trim();
    final response = await _purchaseService.getAllOrders(
      status: _filterStatus,
      search: searchVal.isEmpty ? null : searchVal,
      from: _filterFrom,
      to: _filterTo,
      month: _filterMonth,
      year: _filterYear,
    );
    if (!mounted) return;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      setState(() {
        _errorMessage = _purchaseService.parseMessage(response.body);
        _isLoading = false;
      });
      return;
    }

    final parsedOrders = _purchaseService.parseOrders(response.body);

    setState(() {
      _orders = parsedOrders;
      _currentPage = 1;
      _isLoading = false;
      _hasLoadedOrders = true;

      if (_availableYears.isEmpty ||
          (_filterFrom == null &&
              _filterTo == null &&
              _filterMonth == null &&
              _filterYear == null)) {
        final yearsSet = <int>{};
        for (final order in parsedOrders) {
          if (order.createdAt != null) {
            final dt = DateTime.tryParse(order.createdAt!);
            if (dt != null) {
              yearsSet.add(dt.year);
            }
          }
        }
        for (final sale in _historicalSales) {
          if (sale.transactionDate != null) {
            yearsSet.add(sale.transactionDate!.toLocal().year);
          }
        }
        yearsSet.add(DateTime.now().year);
        _availableYears = yearsSet.toList()..sort((a, b) => b.compareTo(a));
      }
    });
  }

  Future<void> _loadBuyerData() async {
    try {
      final records = <BuyerRecord>[];
      final sales = <HistoricalSale>[];
      var recordsPage = 1;
      var salesPage = 1;
      var recordsTotal = 0;
      var salesTotal = 0;

      do {
        final response = await _buyerRecordService.getBuyerRecords(
          page: recordsPage,
          limit: 100,
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw StateError(_buyerRecordService.parseMessage(response.body));
        }
        records.addAll(_buyerRecordService.parseBuyerRecords(response.body));
        recordsTotal = _buyerRecordService.parseTotalCount(response.body);
        recordsPage++;
      } while (records.length < recordsTotal);

      do {
        final response = await _buyerRecordService.getHistoricalSales(
          page: salesPage,
          limit: 100,
        );
        if (response.statusCode < 200 || response.statusCode >= 300) {
          throw StateError(_buyerRecordService.parseMessage(response.body));
        }
        sales.addAll(_buyerRecordService.parseHistoricalSales(response.body));
        salesTotal = _buyerRecordService.parseTotalCount(response.body);
        salesPage++;
      } while (sales.length < salesTotal);

      if (!mounted) return;
      setState(() {
        _buyerRecords = records;
        _historicalSales = sales;
        _buyerError = null;
        final years = _availableYears.toSet();
        for (final sale in sales) {
          if (sale.transactionDate != null) {
            years.add(sale.transactionDate!.toLocal().year);
          }
        }
        _availableYears = years.toList()..sort((a, b) => b.compareTo(a));
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _buyerError = error.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  List<HistoricalSale> get _filteredHistoricalSales {
    final search = _searchCtrl.text.trim().toLowerCase();
    return _historicalSales.where((sale) {
      final saleStatus = switch (sale.status) {
        'completed' => 'confirmed',
        'pending' => 'pending_payment',
        _ => sale.status,
      };
      if (_filterStatus != null && saleStatus != _filterStatus) return false;

      final date = sale.transactionDate?.toLocal();
      if (_filterFrom != null &&
          (date == null || _dateOnly(date).isBefore(_dateOnly(_filterFrom!)))) {
        return false;
      }
      if (_filterTo != null &&
          (date == null || _dateOnly(date).isAfter(_dateOnly(_filterTo!)))) {
        return false;
      }
      if (_filterMonth != null && date?.month != _filterMonth) return false;
      if (_filterYear != null && date?.year != _filterYear) return false;
      if (search.isEmpty) return true;

      final buyer = _buyerRecordForSale(sale);
      final searchableValues = [
        sale.buyerFullName,
        buyer?.fullName,
        sale.buyerPhone,
        buyer?.phone,
        sale.propertyNameSnapshot,
        sale.propertyLocation,
        sale.paymentMethod,
        sale.notes,
      ];
      return searchableValues.any(
        (value) => value?.toLowerCase().contains(search) ?? false,
      );
    }).toList();
  }

  DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  String _normalizedBuyerName(String name) => name
      .trim()
      .replaceFirst(RegExp(r'^(?:(?:ibu|bapak)\s+)+', caseSensitive: false), '')
      .trim()
      .toLowerCase();

  String _displayBuyerName(String name) => name
      .trim()
      .replaceFirst(RegExp(r'^(?:(?:ibu|bapak)\s+)+', caseSensitive: false), '')
      .trim();

  BuyerRecord? _buyerRecordForSale(HistoricalSale sale) {
    for (final buyer in _buyerRecords) {
      if (buyer.id == sale.buyerRecordId) return buyer;
    }
    return null;
  }

  List<RecapTransaction> get _pagedTransactions {
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, _filteredTransactions.length);
    if (start >= _filteredTransactions.length) return [];
    return _filteredTransactions.sublist(start, end);
  }

  int get _totalPages =>
      (_filteredTransactions.length / _itemsPerPage).ceil().clamp(1, 9999);

  String _formatDateShort(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed == null) return '-';
    return DateFormat('dd MMM yyyy', 'id_ID').format(parsed.toLocal());
  }

  String _formatTime(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed == null) return '';
    return '${DateFormat('HH:mm', 'id_ID').format(parsed.toLocal())} WIB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(onRefresh: _refreshRecap, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // ── HERO BANNER COKLAT ────────────────────────────────────────────
        SliverToBoxAdapter(child: _buildHeroBanner()),

        // ── KONTEN UTAMA ──────────────────────────────────────────────────
        if (_isLoading)
          const SliverFillRemaining(
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_errorMessage != null)
          SliverFillRemaining(child: _buildErrorState())
        else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSummaryCards(),
                  const SizedBox(height: 12),
                  _buildFilterSection(),
                  const SizedBox(height: 24),
                  _buildTransactionTable(),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ── HERO BANNER ──────────────────────────────────────────────────────────
  // -- HERO BANNER (Standardized with BragaPageHeader) ---------------------
  Widget _buildHeroBanner() {
    return BragaPageHeader(
      title: 'Rekap Data Transaksi',
      subtitle: 'Kelola dan pantau semua transaksi pemesanan properti',
      onBack: () => Navigator.of(context).maybePop(),
      decorativeIcon: Icons.receipt_long_rounded,
    );
  }

  // ── RINGKASAN REKAP STATS (KPI CARDS) ──────────────────────────────────
  Widget _buildSummaryCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760
            ? 4
            : constraints.maxWidth >= 460
            ? 2
            : 1;
        final cards = [
          _buildSummaryCardItem(
            title: 'Total Transaksi',
            value: '$_totalTransactions',
            subtitle: 'Pesanan properti',
          ),
          _buildSummaryCardItem(
            title: 'Pembeli Bertransaksi',
            value: '$_uniqueBuyerCount',
            subtitle: 'Pembeli unik pada transaksi',
          ),
          _buildSummaryCardItem(
            title: 'Unit Terjual',
            value: '$_confirmedUnitCount',
            subtitle: 'Transaksi lunas',
          ),
          _buildSummaryCardItem(
            title: 'Omzet Lunas',
            value: _priceFormat.format(_totalRevenue),
            subtitle: 'Transaksi dikonfirmasi',
          ),
        ];

        const spacing = 8.0;
        final cardWidth =
            (constraints.maxWidth - spacing * (columns - 1)) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: cards
              .map((card) => SizedBox(width: cardWidth, child: card))
              .toList(),
        );
      },
    );
  }

  Widget _buildSummaryCardItem({
    required String title,
    required String value,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEE5DC)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A7568),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontSize: value.length > 14 ? 15 : (value.length > 9 ? 18 : 20),
              fontWeight: FontWeight.w900,
              color: const Color(0xFF2A1508),
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 10, color: Color(0xFFAAAAAA)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── FILTER SECTION ───────────────────────────────────────────────────────
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Search bar
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFDDDDDD)),
                  ),
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: (_) => _loadOrders(),
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      hintText: 'Cari nama pembeli, judul properti, lokasi...',
                      hintStyle: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF999999),
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Color(0xFF8B4513),
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 16),
                              onPressed: () {
                                _searchCtrl.clear();
                                _loadOrders();
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _loadOrders,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  minimumSize: const Size(0, 42),
                ),
                child: const Text(
                  'Cari',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2: Status & Dates & Month & Year & Reset
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // Status filter
              SizedBox(
                width: 180,
                child: _buildDropdownField<String?>(
                  icon: Icons.filter_list_rounded,
                  hint: 'Semua status',
                  value: _filterStatus,
                  items: _statusFilterOptions
                      .map(
                        (s) => DropdownMenuItem(
                          value: s,
                          child: Text(
                            _statusOptionLabel(s),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _filterStatus = v),
                ),
              ),
              // Tanggal awal
              SizedBox(
                width: 140,
                child: _buildDateField(
                  'Tanggal awal',
                  _filterFrom,
                  () => _pickDate(isFrom: true),
                ),
              ),
              // Tanggal akhir
              SizedBox(
                width: 140,
                child: _buildDateField(
                  'Tanggal akhir',
                  _filterTo,
                  () => _pickDate(isFrom: false),
                ),
              ),
              // Bulan
              SizedBox(
                width: 140,
                child: _buildDropdownField<int?>(
                  icon: Icons.calendar_month_rounded,
                  hint: 'Semua bulan',
                  value: _filterMonth,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua bulan'),
                    ),
                    ...List.generate(
                      12,
                      (i) => DropdownMenuItem(
                        value: i + 1,
                        child: Text(
                          _isLocaleReady
                              ? DateFormat.MMMM(
                                  'id_ID',
                                ).format(DateTime(2024, i + 1))
                              : '${i + 1}',
                        ),
                      ),
                    ),
                  ],
                  onChanged: (v) => setState(() => _filterMonth = v),
                ),
              ),
              // Tahun
              SizedBox(
                width: 130,
                child: _buildDropdownField<int?>(
                  icon: Icons.event_note_rounded,
                  hint: 'Semua tahun',
                  value: _filterYear,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua tahun'),
                    ),
                    ..._availableYears.map(
                      (y) => DropdownMenuItem(value: y, child: Text('$y')),
                    ),
                  ],
                  onChanged: (v) => setState(() => _filterYear = v),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _searchCtrl.clear();
                    _filterStatus = null;
                    _filterFrom = null;
                    _filterTo = null;
                    _filterMonth = null;
                    _filterYear = null;
                  });
                  _loadOrders();
                },
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF8B4513),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Reset',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
              FilledButton.icon(
                onPressed: _loadOrders,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF8B4513),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.filter_alt_rounded, size: 14),
                label: const Text(
                  'Terapkan',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(String label, DateTime? value, VoidCallback onTap) {
    final formatted = value == null
        ? null
        : (_isLocaleReady
              ? DateFormat('dd MMM yyyy', 'id_ID').format(value)
              : '${value.day}/${value.month}/${value.year}');
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(10),
          color: const Color(0xFFFAFAFA),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.event_outlined,
              size: 14,
              color: Color(0xFF8B4513),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF999999),
                    ),
                  ),
                  Text(
                    formatted ?? 'Pilih tanggal',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: formatted != null
                          ? const Color(0xFF1A1A1A)
                          : const Color(0xFFBBBBBB),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: Color(0xFF999999),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required IconData icon,
    required String hint,
    required T? value,
    required List<DropdownMenuItem<T?>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(10),
        color: const Color(0xFFFAFAFA),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF8B4513)),
          const SizedBox(width: 6),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<T?>(
                value: value,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: Color(0xFF999999),
                  size: 14,
                ),
                hint: Text(
                  hint,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFBBBBBB),
                  ),
                ),
                items: items,
                onChanged: onChanged,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A1A),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isFrom ? _filterFrom : _filterTo) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) {
        _filterFrom = picked;
      } else {
        _filterTo = picked;
      }
    });
  }

  // ── TABEL TRANSAKSI TERBARU ───────────────────────────────────────────────
  BuyerRecord? _buyerRecordFor(PurchaseOrderModel order) {
    for (final buyer in _buyerRecords) {
      if (order.buyerRecordId != null && buyer.id == order.buyerRecordId) {
        return buyer;
      }
    }

    for (final buyer in _buyerRecords) {
      if (order.buyerUserId != null &&
          buyer.linkedUserId == order.buyerUserId) {
        return buyer;
      }
    }

    final orderPhone = (order.buyerPhoneSnapshot ?? '').replaceAll(
      RegExp(r'\D'),
      '',
    );
    if (orderPhone.isNotEmpty) {
      for (final buyer in _buyerRecords) {
        final buyerPhone = (buyer.phone ?? '').replaceAll(RegExp(r'\D'), '');
        if (buyerPhone.isNotEmpty && buyerPhone == orderPhone) return buyer;
      }
    }

    final orderName = _normalizedBuyerName(order.buyerNameSnapshot);
    if (orderName.isNotEmpty) {
      for (final buyer in _buyerRecords) {
        if (_normalizedBuyerName(buyer.fullName) == orderName) return buyer;
      }
    }
    return null;
  }

  Widget _buildTransactionTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
            child: Row(
              children: [
                const Text(
                  'Transaksi',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const Spacer(),
                if (_totalTransactions > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$_totalTransactions transaksi',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF8B4513),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          if (_buyerError != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'Data transaksi pembeli gagal dimuat: $_buyerError',
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),

          if (_totalTransactions == 0)
            _buildEmptyState()
          else ...[
            // Header tabel
            _buildTableHeader(),
            const Divider(height: 1, color: Color(0xFFEFEFEF)),
            // Rows
            ..._pagedTransactions.map(
              (transaction) => transaction.order != null
                  ? _buildTableRow(transaction.order!)
                  : _buildHistoricalSaleTableRow(transaction.historicalSale!),
            ),
            // Footer pagination
            _buildPaginationFooter(),
          ],
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      color: const Color(0xFFFAFAFA),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: const Row(
        children: [
          Expanded(flex: 4, child: _TableHeaderCell('Properti')),
          Expanded(flex: 3, child: _TableHeaderCell('Pembeli')),
          Expanded(flex: 2, child: _TableHeaderCell('Status')),
          Expanded(flex: 3, child: _TableHeaderCell('Tanggal Transaksi')),
          Expanded(flex: 3, child: _TableHeaderCell('Nilai Transaksi')),
          SizedBox(width: 110, child: _TableHeaderCell('Aksi')),
        ],
      ),
    );
  }

  Widget _buildTableRow(PurchaseOrderModel order) {
    final buyer = _buyerRecordFor(order);
    final buyerName = _displayBuyerName(
      buyer?.fullName ?? order.buyerNameSnapshot,
    );
    final buyerPhone = buyer?.phone ?? order.buyerPhoneSnapshot;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Properti
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    _PropertyThumbnail(url: order.propertyThumbnailUrl),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.propertyTitle,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 11,
                                color: Color(0xFF999999),
                              ),
                              const SizedBox(width: 2),
                              Expanded(
                                child: Text(
                                  order.propertyLocation,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF999999),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Pembeli
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((buyerPhone ?? '').isNotEmpty)
                      Text(
                        buyerPhone!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                  ],
                ),
              ),
              // Status
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StaffStatusBadge(
                    status: order.status,
                    paymentMethod: order.paymentMethod,
                  ),
                ),
              ),
              // Tanggal
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          size: 12,
                          color: Color(0xFF888888),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDateShort(order.createdAt),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Padding(
                      padding: const EdgeInsets.only(left: 16),
                      child: Text(
                        _formatTime(order.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Nilai
              Expanded(
                flex: 3,
                child: Text(
                  _priceFormat.format(order.totalPrice ?? order.propertyPrice),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ),
              // Aksi
              SizedBox(
                width: 110,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            PurchaseDetailPage(purchaseId: order.id),
                      ),
                    );
                    _loadOrders();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: const Color(0xFF8B4513),
                    side: const BorderSide(color: Color(0xFF8B4513)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 12),
                  label: const Text(
                    'Lihat Detail',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF5F5F5)),
      ],
    );
  }

  Widget _buildHistoricalSaleTableRow(HistoricalSale sale) {
    final buyer = _buyerRecordForSale(sale);
    final buyerName = _displayBuyerName(
      buyer?.fullName ?? sale.buyerFullName ?? '',
    );
    final buyerPhone = buyer?.phone ?? sale.buyerPhone;
    final propertyName = sale.propertyTitleCurrent?.trim().isNotEmpty == true
        ? sale.propertyTitleCurrent!
        : sale.propertyNameSnapshot;
    final saleStatus = switch (sale.status) {
      'completed' => 'confirmed',
      'pending' => 'pending_payment',
      _ => sale.status,
    };

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Row(
                  children: [
                    _PropertyThumbnail(url: sale.propertyThumbnailUrl),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            propertyName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1A1A),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (sale.propertyLocation?.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  size: 11,
                                  color: Color(0xFF999999),
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    sale.propertyLocation!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF999999),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      buyerName,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A1A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (buyerPhone?.isNotEmpty == true)
                      Text(
                        buyerPhone!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF888888),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: StaffStatusBadge(
                    status: saleStatus,
                    paymentMethod: sale.paymentMethod,
                  ),
                ),
              ),
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 12,
                      color: Color(0xFF888888),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        sale.transactionDate == null
                            ? '-'
                            : DateFormat(
                                'dd MMM yyyy',
                                'id_ID',
                              ).format(sale.transactionDate!.toLocal()),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 3,
                child: Text(
                  sale.transactionValue == null
                      ? '-'
                      : _priceFormat.format(sale.transactionValue),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ),
              SizedBox(
                width: 110,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PurchaseDetailPage(
                          purchaseId: sale.id,
                          historicalSale: sale,
                        ),
                      ),
                    );
                    _loadBuyerData();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: const Color(0xFF8B4513),
                    side: const BorderSide(color: Color(0xFF8B4513)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 12),
                  label: const Text(
                    'Lihat Detail',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF5F5F5)),
      ],
    );
  }

  Widget _buildPaginationFooter() {
    final startItem = (_currentPage - 1) * _itemsPerPage + 1;
    final endItem = (_currentPage * _itemsPerPage).clamp(0, _totalTransactions);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFEFEFEF))),
        color: Color(0xFFFAFAFA),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(14),
          bottomRight: Radius.circular(14),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Menampilkan $startItem – $endItem dari $_totalTransactions transaksi',
            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
          const Spacer(),
          // Prev
          _PaginationButton(
            icon: Icons.chevron_left_rounded,
            enabled: _currentPage > 1,
            onTap: () => setState(() => _currentPage--),
          ),
          const SizedBox(width: 4),
          // Page number
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF8B4513),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$_currentPage',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Next
          _PaginationButton(
            icon: Icons.chevron_right_rounded,
            enabled: _currentPage < _totalPages,
            onTap: () => setState(() => _currentPage++),
          ),
          const SizedBox(width: 16),
          // Items per page
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: _itemsPerPage,
              items: [5, 10, 20, 50]
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        '$v / halaman',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _itemsPerPage = v;
                  _currentPage = 1;
                });
              },
              style: const TextStyle(fontSize: 12, color: Color(0xFF1A1A1A)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Column(
          children: const [
            Icon(Icons.inbox_outlined, size: 48, color: Color(0xFFCCCCCC)),
            SizedBox(height: 12),
            Text(
              'Belum ada transaksi',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF555555),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Rekap akan muncul setelah transaksi dicatat.',
              style: TextStyle(fontSize: 12, color: Color(0xFFAAAAAA)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            size: 48,
            color: Color(0xFFCC3333),
          ),
          const SizedBox(height: 12),
          Text(
            _errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF555555)),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _loadOrders,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
            ),
            child: const Text('Coba lagi'),
          ),
        ],
      ),
    );
  }
}

// ── HELPER WIDGETS ────────────────────────────────────────────────────────────
class _PropertyThumbnail extends StatelessWidget {
  const _PropertyThumbnail({required this.url});

  final String? url;

  String? _resolveUrl() {
    final value = url?.trim();
    if (value == null || value.isEmpty) return null;
    if (value.startsWith('http://') || value.startsWith('https://')) {
      return value;
    }
    final path = value.startsWith('/') ? value : '/$value';
    return '${AuthService.serverBaseUrl}$path';
  }

  Widget _placeholder() => Container(
    width: 48,
    height: 48,
    color: const Color(0xFFF0E6D8),
    child: const Icon(Icons.home_outlined, color: Color(0xFF8B4513), size: 24),
  );

  @override
  Widget build(BuildContext context) {
    final imageUrl = _resolveUrl();
    return SizedBox(
      width: 48,
      height: 48,
      child: imageUrl == null
          ? _placeholder()
          : Image.network(
              imageUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              filterQuality: FilterQuality.low,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;
                return _placeholder();
              },
              errorBuilder: (context, error, stackTrace) => _placeholder(),
            ),
    );
  }
}

class _TableHeaderCell extends StatelessWidget {
  final String text;
  const _TableHeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Color(0xFF888888),
      ),
    );
  }
}

class _PaginationButton extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PaginationButton({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(
            color: enabled ? const Color(0xFFDDDDDD) : const Color(0xFFEEEEEE),
          ),
          borderRadius: BorderRadius.circular(8),
          color: enabled ? Colors.white : const Color(0xFFF9F9F9),
        ),
        child: Icon(
          icon,
          size: 20,
          color: enabled ? const Color(0xFF1A1A1A) : const Color(0xFFCCCCCC),
        ),
      ),
    );
  }
}
