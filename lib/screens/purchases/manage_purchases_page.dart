import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../models/purchase_order_model.dart';
import '../../services/purchase_service.dart';
import '../../widgets/braga_page_header.dart';

class ManagePurchasesPage extends StatefulWidget {
  const ManagePurchasesPage({super.key});

  @override
  State<ManagePurchasesPage> createState() => _ManagePurchasesPageState();
}

class _ManagePurchasesPageState extends State<ManagePurchasesPage> {
  final PurchaseService _purchaseService = PurchaseService();

  bool _isLoading = true;
  bool _isLocaleReady = false;
  String? _errorMessage;
  List<PurchaseOrderModel> _orders = const [];
  String _filterStatus = '';
  DateTime? _filterFrom;
  DateTime? _filterTo;
  int? _filterMonth;
  int? _filterYear;
  String _searchQuery = '';

  // Pagination
  int _currentPage = 1;
  static const int _itemsPerPage = 10;

  static const _statusTabs = <String, String>{
    '': 'Semua',
    'pending_payment': 'Menunggu Pembayaran',
    'payment_uploaded': 'Bukti Diunggah',
    'payment_review': 'Sedang Diverifikasi',
    'confirmed': 'Dikonfirmasi',
    'rejected': 'Ditolak',
    'cancelled': 'Dibatalkan',
  };

  // Status icons for tabs
  static const _statusIcons = <String, IconData>{
    '': Icons.grid_view_rounded,
    'pending_payment': Icons.hourglass_empty_rounded,
    'payment_uploaded': Icons.cloud_upload_outlined,
    'payment_review': Icons.remove_red_eye_outlined,
    'confirmed': Icons.check_circle_outline_rounded,
    'rejected': Icons.cancel_outlined,
    'cancelled': Icons.do_not_disturb_on_outlined,
  };

  @override
  void initState() {
    super.initState();
    _preparePage();
  }

  Future<void> _preparePage() async {
    await initializeDateFormatting('id_ID');
    if (!mounted) return;
    setState(() => _isLocaleReady = true);
    await _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _purchaseService.getAllOrders(
      status: _filterStatus.isEmpty ? null : _filterStatus,
      from: _filterFrom,
      to: _filterTo,
      month: _filterMonth,
      year: _filterYear,
    );
    if (!mounted) return;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      setState(() {
        _orders = _purchaseService.parseOrders(response.body);
        _currentPage = 1;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _errorMessage = _purchaseService.parseMessage(response.body);
      _isLoading = false;
    });
  }

  List<PurchaseOrderModel> get _filteredOrders {
    if (_searchQuery.trim().isEmpty) return _orders;
    final q = _searchQuery.toLowerCase();
    return _orders.where((o) {
      return o.propertyTitle.toLowerCase().contains(q) ||
          o.buyerNameSnapshot.toLowerCase().contains(q) ||
          (o.buyerPhoneSnapshot ?? '').contains(q);
    }).toList();
  }

  List<PurchaseOrderModel> get _pagedOrders {
    final all = _filteredOrders;
    final start = (_currentPage - 1) * _itemsPerPage;
    final end = (start + _itemsPerPage).clamp(0, all.length);
    if (start >= all.length) return [];
    return all.sublist(start, end);
  }

  int get _totalPages =>
      (_filteredOrders.length / _itemsPerPage).ceil().clamp(1, 9999);

  int _countStatus(String status) {
    if (status.isEmpty) return _orders.length;
    return _orders.where((o) => o.status == status).length;
  }

  String _formatDate(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return '-';
    try {
      return DateFormat('d MMM y, HH:mm', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _formatDateShort(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  String _formatTime(String? value) {
    final raw = value?.trim();
    if (raw == null || raw.isEmpty) return '';
    try {
      return '${DateFormat('HH:mm', 'id_ID').format(DateTime.parse(raw))} WIB';
    } catch (_) {
      return '';
    }
  }

  String _formatPrice(double price) => NumberFormat.currency(
        locale: 'id_ID',
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(price);

  Future<void> _confirmOrder(PurchaseOrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Pemesanan',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          'Konfirmasi pemesanan "${order.propertyTitle}" oleh ${order.buyerNameSnapshot}?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1F7A45)),
            child: const Text('Konfirmasi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final response = await _purchaseService.updateOrderStatus(
        purchaseId: order.id, status: 'confirmed');
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_purchaseService.parseMessage(response.body))));
    if (response.statusCode >= 200 && response.statusCode < 300) _loadOrders();
  }

  Future<void> _rejectOrder(PurchaseOrderModel order) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Tolak Pemesanan',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                'Tolak pemesanan "${order.propertyTitle}" oleh ${order.buyerNameSnapshot}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alasan penolakan *',
                hintText: 'Masukkan alasan penolakan',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () {
              final text = reasonController.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(
                    content: Text('Alasan penolakan wajib diisi')));
                return;
              }
              Navigator.pop(ctx, text);
            },
            style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFC0392B)),
            child: const Text('Tolak'),
          ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    final response = await _purchaseService.updateOrderStatus(
        purchaseId: order.id,
        status: 'rejected',
        rejectionReason: reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_purchaseService.parseMessage(response.body))));
    if (response.statusCode >= 200 && response.statusCode < 300) _loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          const BragaPageHeader(
            title: 'Kelola Pemesanan',
            subtitle: 'Kelola dan pantau seluruh pemesanan properti',
            decorativeIcon: Icons.receipt_long_rounded,
          ),
          _buildFilterBar(),
          _buildStatusTabs(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOrders,
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }


  // ── FILTER BAR (search + date + bulan + tahun + terapkan) ─────────────────
  Widget _buildFilterBar() {
    final years =
        List<int>.generate(8, (i) => DateTime.now().year - i);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          // Search field
          Expanded(
            flex: 5,
            child: SizedBox(
              height: 44,
              child: TextField(
                onChanged: (v) => setState(() {
                  _searchQuery = v;
                  _currentPage = 1;
                }),
                decoration: InputDecoration(
                  hintText: 'Cari transaksi (nama pembeli / properti / no. pemesanan)...',
                  hintStyle: const TextStyle(
                      fontSize: 12, color: Color(0xFFBBBBBB)),
                  prefixIcon: const Icon(Icons.search_rounded,
                      size: 18, color: Color(0xFF999999)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0xFF8B4513)),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFFAFAFA),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Tanggal awal
          _buildCompactDateField('Tanggal awal', _filterFrom,
              () => _pickDate(isFrom: true)),
          const SizedBox(width: 8),
          // Tanggal akhir
          _buildCompactDateField('Tanggal akhir', _filterTo,
              () => _pickDate(isFrom: false)),
          const SizedBox(width: 8),
          // Bulan
          _buildCompactDropdown<int?>(
            label: 'Bulan',
            value: _filterMonth,
            items: [
              const DropdownMenuItem(value: null, child: Text('Semua bulan')),
              ...List.generate(
                  12,
                  (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text(_isLocaleReady
                          ? DateFormat.MMMM('id_ID')
                              .format(DateTime(2024, i + 1))
                          : '${i + 1}'))),
            ],
            onChanged: (v) => setState(() => _filterMonth = v),
          ),
          const SizedBox(width: 8),
          // Tahun
          _buildCompactDropdown<int?>(
            label: 'Tahun',
            value: _filterYear,
            items: [
              const DropdownMenuItem(
                  value: null, child: Text('Semua tahun')),
              ...years.map((y) =>
                  DropdownMenuItem(value: y, child: Text('$y'))),
            ],
            onChanged: (v) => setState(() => _filterYear = v),
          ),
          const SizedBox(width: 10),
          // Terapkan
          SizedBox(
            height: 44,
            child: FilledButton.icon(
              onPressed: _loadOrders,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8B4513),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              ),
              icon: const Icon(Icons.filter_alt_rounded, size: 16),
              label: const Text('Terapkan',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactDateField(
      String label, DateTime? value, VoidCallback onTap) {
    final formatted = value == null
        ? null
        : (_isLocaleReady
            ? DateFormat('dd/MM/yyyy').format(value)
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: Color(0xFF8B4513)),
            const SizedBox(width: 6),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 9, color: Color(0xFF999999))),
                Text(
                  formatted ?? 'Pilih tanggal',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: formatted != null
                        ? const Color(0xFF1A1A1A)
                        : const Color(0xFFBBBBBB),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded,
                size: 14, color: Color(0xFF999999)),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactDropdown<T>({
    required String label,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 9, color: Color(0xFF999999))),
          DropdownButtonHideUnderline(
            child: SizedBox(
              height: 22,
              child: DropdownButton<T?>(
                value: value,
                isDense: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 14, color: Color(0xFF999999)),
                hint: Text(label,
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFBBBBBB))),
                items: items,
                onChanged: onChanged,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A)),
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
      initialDate:
          (isFrom ? _filterFrom : _filterTo) ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;
    setState(() {
      if (isFrom) _filterFrom = picked;
      else _filterTo = picked;
    });
  }

  // ── STATUS TABS ────────────────────────────────────────────────────────────
  Widget _buildStatusTabs() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _statusTabs.entries.map((entry) {
            final isSelected = _filterStatus == entry.key;
            final count = _countStatus(entry.key);
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _filterStatus = entry.key;
                    _currentPage = 1;
                  });
                  _loadOrders();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF8B4513)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF8B4513)
                          : const Color(0xFFDDDDDD),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _statusIcons[entry.key] ?? Icons.circle,
                        size: 14,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF888888),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        entry.value,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF555555),
                        ),
                      ),
                      if (count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Colors.white.withAlpha(50)
                                : const Color(0xFFFF6B35),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ── BODY ───────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    if (!_isLocaleReady || _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _buildEmptyCard(
            icon: Icons.error_outline_rounded,
            iconColor: const Color(0xFFC0392B),
            title: 'Gagal memuat data',
            subtitle: _errorMessage!,
            action: TextButton(
                onPressed: _loadOrders, child: const Text('Coba lagi')),
          ),
        ],
      );
    }

    if (_filteredOrders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _buildEmptyCard(
            icon: Icons.inbox_outlined,
            iconColor: const Color(0xFFCCCCCC),
            title: 'Belum ada pemesanan',
            subtitle: 'Pemesanan dari buyer akan muncul di sini.',
          ),
        ],
      );
    }

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        ..._pagedOrders.map((order) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _OrderCard(
                order: order,
                formatDate: _formatDate,
                formatDateShort: _formatDateShort,
                formatTime: _formatTime,
                formatPrice: _formatPrice,
                onConfirm:
                    (order.isPaymentUploaded ||
                            order.isPaymentReview ||
                            ((order.paymentMethod == 'Cash Payment' ||
                                    order.paymentMethod == 'QRIS') &&
                                order.status == 'pending_payment'))
                        ? () => _confirmOrder(order)
                        : null,
                onReject:
                    (order.isPaymentUploaded || order.isPaymentReview)
                        ? () => _rejectOrder(order)
                        : null,
              ),
            )),
        _buildPaginationFooter(),
      ],
    );
  }

  Widget _buildEmptyCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: iconColor),
          const SizedBox(height: 12),
          Text(title,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(subtitle,
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 13, color: Color(0xFF888888))),
          if (action != null) ...[const SizedBox(height: 12), action],
        ],
      ),
    );
  }

  Widget _buildPaginationFooter() {
    final total = _filteredOrders.length;
    final start = (_currentPage - 1) * _itemsPerPage + 1;
    final end = (_currentPage * _itemsPerPage).clamp(0, total);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Menampilkan $start - $end dari $total pemesanan',
            style:
                const TextStyle(fontSize: 12, color: Color(0xFF888888)),
          ),
          const Spacer(),
          _PaginationBtn(
            icon: Icons.chevron_left_rounded,
            enabled: _currentPage > 1,
            onTap: () => setState(() => _currentPage--),
          ),
          const SizedBox(width: 4),
          ...List.generate(_totalPages, (i) {
            final page = i + 1;
            final isActive = page == _currentPage;
            return Padding(
              padding: const EdgeInsets.only(right: 4),
              child: GestureDetector(
                onTap: () => setState(() => _currentPage = page),
                child: Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF8B4513)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: isActive
                            ? const Color(0xFF8B4513)
                            : const Color(0xFFDDDDDD)),
                  ),
                  child: Text(
                    '$page',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : const Color(0xFF555555),
                    ),
                  ),
                ),
              ),
            );
          }).take(5).toList(),
          if (_totalPages > 5)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text('...', style: TextStyle(color: Color(0xFF888888))),
            ),
          _PaginationBtn(
            icon: Icons.chevron_right_rounded,
            enabled: _currentPage < _totalPages,
            onTap: () => setState(() => _currentPage++),
          ),
        ],
      ),
    );
  }
}

// ── ORDER CARD ──────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final PurchaseOrderModel order;
  final String Function(String?) formatDate;
  final String Function(String?) formatDateShort;
  final String Function(String?) formatTime;
  final String Function(double) formatPrice;
  final VoidCallback? onConfirm;
  final VoidCallback? onReject;

  const _OrderCard({
    required this.order,
    required this.formatDate,
    required this.formatDateShort,
    required this.formatTime,
    required this.formatPrice,
    this.onConfirm,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEFEFEF)),
        boxShadow: const [
          BoxShadow(
              color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── BARIS ATAS: thumbnail + info properti + status ──────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail placeholder
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 120,
                    height: 88,
                    color: const Color(0xFFEDE0D4),
                    child: const Icon(Icons.home_outlined,
                        color: Color(0xFF8B4513), size: 36),
                  ),
                ),
                const SizedBox(width: 14),
                // Info properti
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Judul + status + more
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              order.propertyTitle,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildStatusBadge(order.status),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Lokasi
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined,
                              size: 13, color: Color(0xFF888888)),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              order.propertyLocation,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF888888)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Tags tipe/lantai jika ada
                      Wrap(
                        spacing: 6,
                        children: [
                          if ((order.notes ?? '').isNotEmpty)
                            _buildTag(order.notes!.split(' ').first),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Tanggal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            '${formatDateShort(order.createdAt)} • ${formatTime(order.createdAt)}',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF888888)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── INFORMASI PEMBAYARAN ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _buildPaymentInfoSection(context),
          ),

          const SizedBox(height: 12),

          // ── DATA PEMBELI + TOMBOL AKSI ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Buyer info
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.person_outline_rounded,
                          size: 16, color: Color(0xFF888888)),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Pembeli',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF888888))),
                          Text(
                            order.buyerNameSnapshot,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1A1A1A)),
                          ),
                          Text(
                            [
                              if ((order.buyerPhoneSnapshot ?? '')
                                  .isNotEmpty)
                                order.buyerPhoneSnapshot!,
                            ].join(' • '),
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF888888)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Tombol aksi
                Wrap(
                  spacing: 8,
                  children: [
                    // Konfirmasi
                    if (onConfirm != null)
                      FilledButton.icon(
                        onPressed: onConfirm,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1F7A45),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(
                            Icons.check_circle_outline_rounded,
                            size: 14),
                        label: const Text('Konfirmasi',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                    // Minta Klarifikasi / Tolak
                    if (onReject != null)
                      OutlinedButton.icon(
                        onPressed: onReject,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: const Color(0xFFE65C00),
                          side: const BorderSide(
                              color: Color(0xFFE65C00)),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        icon: const Icon(Icons.help_outline_rounded,
                            size: 14),
                        label: const Text('Minta Klarifikasi',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentInfoSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF7F4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEEE0D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B4513),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_outlined,
                        color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('Informasi Pembayaran',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Total transfer (navy box)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2A5A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Transfer',
                        style: TextStyle(
                            fontSize: 10,
                            color: Color(0xFFBBC8E8),
                            fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(
                      formatPrice(order.payableAmount),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Detail kolom
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: _buildPaymentDetailCol(
                        icon: Icons.calendar_today_outlined,
                        label: 'Tanggal Transfer',
                        value: formatDateShort(order.paymentProofUploadedAt),
                        sub: formatTime(order.paymentProofUploadedAt),
                      ),
                    ),
                    Expanded(
                      child: _buildPaymentDetailCol(
                        icon: Icons.credit_card_outlined,
                        label: 'Metode Pembayaran',
                        value: order.paymentMethod,
                        sub: '',
                      ),
                    ),
                    Expanded(
                      child: _buildPaymentDetailCol(
                        icon: Icons.description_outlined,
                        label: 'Bukti Pembayaran',
                        value: (order.paymentProofUrl ?? '').isNotEmpty
                            ? 'Tersedia'
                            : 'Belum diunggah',
                        sub: '',
                        hasButton: (order.paymentProofUrl ?? '').isNotEmpty,
                        context: context,
                        proofUrl: order.paymentProofUrl,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentDetailCol({
    required IconData icon,
    required String label,
    required String value,
    required String sub,
    bool hasButton = false,
    BuildContext? context,
    String? proofUrl,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: const Color(0xFF888888)),
            const SizedBox(width: 4),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: Color(0xFF888888)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1A1A)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis),
        if (sub.isNotEmpty)
          Text(sub,
              style: const TextStyle(
                  fontSize: 11, color: Color(0xFF888888))),
        if (hasButton && context != null) ...[
          const SizedBox(height: 6),
          OutlinedButton.icon(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: const Color(0xFF1E5FAF),
              side: const BorderSide(color: Color(0xFF1E5FAF)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            icon: const Icon(Icons.visibility_outlined, size: 12),
            label: const Text('Lihat Bukti',
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    final style = _statusStyle(status);
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 12, color: style.fg),
          const SizedBox(width: 4),
          Text(style.label,
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: style.fg)),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFF0E8DE),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8B4513))),
    );
  }
}

// ── STATUS STYLE ─────────────────────────────────────────────────────────────
class _StatusStyle {
  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;
  const _StatusStyle(
      {required this.label,
      required this.bg,
      required this.fg,
      required this.icon});
}

_StatusStyle _statusStyle(String status) {
  switch (status) {
    case 'confirmed':
      return const _StatusStyle(
          label: 'Dikonfirmasi',
          bg: Color(0xFFE6F6EC),
          fg: Color(0xFF1F7A45),
          icon: Icons.check_circle_outline_rounded);
    case 'rejected':
      return const _StatusStyle(
          label: 'Ditolak',
          bg: Color(0xFFFCE8E6),
          fg: Color(0xFFC0392B),
          icon: Icons.cancel_outlined);
    case 'cancelled':
      return const _StatusStyle(
          label: 'Dibatalkan',
          bg: Color(0xFFF1F1F1),
          fg: Color(0xFF6B7280),
          icon: Icons.do_not_disturb_on_outlined);
    case 'payment_uploaded':
      return const _StatusStyle(
          label: 'Bukti Diunggah',
          bg: Color(0xFFE3EFFD),
          fg: Color(0xFF1E5FAF),
          icon: Icons.cloud_upload_outlined);
    case 'payment_review':
      return const _StatusStyle(
          label: 'Sedang Diverifikasi',
          bg: Color(0xFFFFF3E0),
          fg: Color(0xFFE65C00),
          icon: Icons.remove_red_eye_outlined);
    default:
      return const _StatusStyle(
          label: 'Menunggu Pembayaran',
          bg: Color(0xFFFFF3D9),
          fg: Color(0xFF9A6700),
          icon: Icons.hourglass_empty_rounded);
  }
}

// ── PAGINATION BUTTON ─────────────────────────────────────────────────────────
class _PaginationBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;
  const _PaginationBtn(
      {required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(
              color: enabled
                  ? const Color(0xFFDDDDDD)
                  : const Color(0xFFEEEEEE)),
          borderRadius: BorderRadius.circular(8),
          color: enabled ? Colors.white : const Color(0xFFF9F9F9),
        ),
        child: Icon(icon,
            size: 20,
            color: enabled
                ? const Color(0xFF1A1A1A)
                : const Color(0xFFCCCCCC)),
      ),
    );
  }
}