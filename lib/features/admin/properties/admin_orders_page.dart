import 'package:flutter/material.dart';
import 'dart:math' as math;

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

enum OrderStatus { dikonfirmasi, sedangDiverifikasi, dibatalkan, pending }

class OrderItem {
  final String date;
  final String time;
  final String invoiceNumber;
  final String propertyName;
  final String propertyType;
  final String propertyImageUrl;
  final String buyerName;
  final String buyerPhone;
  final String buyerEmail;
  final int orderValue;
  final OrderStatus status;
  final String statusDate;
  final String statusTime;
  final String paymentMethod;
  final String bankName;
  final String paymentStatus;

  const OrderItem({
    required this.date,
    required this.time,
    required this.invoiceNumber,
    required this.propertyName,
    required this.propertyType,
    required this.propertyImageUrl,
    required this.buyerName,
    required this.buyerPhone,
    required this.buyerEmail,
    required this.orderValue,
    required this.status,
    required this.statusDate,
    required this.statusTime,
    required this.paymentMethod,
    required this.bankName,
    required this.paymentStatus,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  // Filter state
  DateTime _startDate = DateTime(2026, 6, 1);
  DateTime _endDate = DateTime(2026, 6, 12);
  String _selectedStatus = 'Semua Status';
  String _selectedPaymentMethod = 'Semua Metode';

  // Pagination
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  final List<String> _statusOptions = [
    'Semua Status',
    'Dikonfirmasi',
    'Sedang Diverifikasi',
    'Dibatalkan',
    'Pending',
  ];

  final List<String> _paymentMethodOptions = [
    'Semua Metode',
    'QRIS',
    'Virtual Account',
    'Cash',
  ];

  // Sample data
  final List<OrderItem> _allOrders = const [
    OrderItem(
      date: '12 Jun 2026',
      time: '10:30 WIB',
      invoiceNumber: 'INV/2026/0612/0012',
      propertyName: 'Astana Residence Prambanan',
      propertyType: 'Type 120 · 2 Lantai',
      propertyImageUrl: '',
      buyerName: 'Meylina',
      buyerPhone: '08123456789',
      buyerEmail: 'mey@gmail.com',
      orderValue: 185000000,
      status: OrderStatus.dikonfirmasi,
      statusDate: '12 Jun 2026',
      statusTime: '10:30 WIB',
      paymentMethod: 'QRIS',
      bankName: 'Bank Mandiri',
      paymentStatus: 'Lunas',
    ),
    OrderItem(
      date: '11 Jun 2026',
      time: '14:20 WIB',
      invoiceNumber: 'INV/2026/0611/0011',
      propertyName: 'Grand Harmoni Residence',
      propertyType: 'Type 90 · 2 Lantai',
      propertyImageUrl: '',
      buyerName: 'Andi Pratama',
      buyerPhone: '08223334444',
      buyerEmail: 'andi.pratama@gmail.com',
      orderValue: 75000000,
      status: OrderStatus.sedangDiverifikasi,
      statusDate: '11 Jun 2026',
      statusTime: '14:20 WIB',
      paymentMethod: 'Virtual Account',
      bankName: 'BNI',
      paymentStatus: 'Menunggu',
    ),
    OrderItem(
      date: '10 Jun 2026',
      time: '09:15 WIB',
      invoiceNumber: 'INV/2026/0610/0010',
      propertyName: 'Citra Garden Residence',
      propertyType: 'Type 110 · 2 Lantai',
      propertyImageUrl: '',
      buyerName: 'Rina Safitri',
      buyerPhone: '08134567890',
      buyerEmail: 'rina.safitri@gmail.com',
      orderValue: 110000000,
      status: OrderStatus.dikonfirmasi,
      statusDate: '10 Jun 2026',
      statusTime: '09:15 WIB',
      paymentMethod: 'QRIS',
      bankName: 'BCA',
      paymentStatus: 'Lunas',
    ),
    OrderItem(
      date: '09 Jun 2026',
      time: '16:45 WIB',
      invoiceNumber: 'INV/2026/0609/0009',
      propertyName: 'Harmoni Green Residence',
      propertyType: 'Type 80 · 1 Lantai',
      propertyImageUrl: '',
      buyerName: 'Budi Santoso',
      buyerPhone: '081298765432',
      buyerEmail: 'budi.santoso@gmail.com',
      orderValue: 60000000,
      status: OrderStatus.dibatalkan,
      statusDate: '09 Jun 2026',
      statusTime: '16:45 WIB',
      paymentMethod: 'QRIS',
      bankName: 'BRI',
      paymentStatus: 'Dibatalkan',
    ),
    OrderItem(
      date: '08 Jun 2026',
      time: '11:00 WIB',
      invoiceNumber: 'INV/2026/0608/0008',
      propertyName: 'Puri Asri Residence',
      propertyType: 'Type 100 · 2 Lantai',
      propertyImageUrl: '',
      buyerName: 'Siti Rahma',
      buyerPhone: '081234509876',
      buyerEmail: 'siti.rahma@gmail.com',
      orderValue: 95000000,
      status: OrderStatus.dikonfirmasi,
      statusDate: '08 Jun 2026',
      statusTime: '11:00 WIB',
      paymentMethod: 'QRIS',
      bankName: 'Bank Mandiri',
      paymentStatus: 'Lunas',
    ),
  ];

  List<OrderItem> get _filteredOrders {
    return _allOrders.where((order) {
      if (_selectedStatus != 'Semua Status') {
        final statusMatch = switch (_selectedStatus) {
          'Dikonfirmasi' => order.status == OrderStatus.dikonfirmasi,
          'Sedang Diverifikasi' =>
            order.status == OrderStatus.sedangDiverifikasi,
          'Dibatalkan' => order.status == OrderStatus.dibatalkan,
          'Pending' => order.status == OrderStatus.pending,
          _ => true,
        };
        if (!statusMatch) return false;
      }
      if (_selectedPaymentMethod != 'Semua Metode') {
        if (order.paymentMethod != _selectedPaymentMethod) return false;
      }
      return true;
    }).toList();
  }

  int get _totalConfirmed =>
      _allOrders.where((o) => o.status == OrderStatus.dikonfirmasi).length;
  int get _totalPending =>
      _allOrders.where((o) => o.status == OrderStatus.sedangDiverifikasi || o.status == OrderStatus.pending).length;
  int get _totalCancelled =>
      _allOrders.where((o) => o.status == OrderStatus.dibatalkan).length;
  int get _totalValue =>
      _allOrders.fold(0, (sum, o) => sum + o.orderValue);

  String _formatCurrency(int value) {
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return 'Rp $formatted';
  }

  Future<void> _pickDate(BuildContext context, bool isStart) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStart ? _startDate : _endDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFB85C1A),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredOrders;
    final totalPages = (filtered.length / _itemsPerPage).ceil().clamp(1, 999);
    final pageOrders = filtered
        .skip((_currentPage - 1) * _itemsPerPage)
        .take(_itemsPerPage)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFAF5F0),
      body: Column(
        children: [
          // ── Hero Header ─────────────────────────────────────────────
          _OrdersHeroBanner(onBack: () => Navigator.maybePop(context)),

          // ── Scrollable Body ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter card
                  _FilterCard(
                    startDate: _startDate,
                    endDate: _endDate,
                    selectedStatus: _selectedStatus,
                    selectedPaymentMethod: _selectedPaymentMethod,
                    statusOptions: _statusOptions,
                    paymentMethodOptions: _paymentMethodOptions,
                    onPickStartDate: () => _pickDate(context, true),
                    onPickEndDate: () => _pickDate(context, false),
                    onStatusChanged: (v) =>
                        setState(() => _selectedStatus = v ?? _selectedStatus),
                    onPaymentMethodChanged: (v) => setState(
                      () => _selectedPaymentMethod =
                          v ?? _selectedPaymentMethod,
                    ),
                    onApply: () => setState(() => _currentPage = 1),
                    onReset: () => setState(() {
                      _startDate = DateTime(2026, 6, 1);
                      _endDate = DateTime(2026, 6, 12);
                      _selectedStatus = 'Semua Status';
                      _selectedPaymentMethod = 'Semua Metode';
                      _currentPage = 1;
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Stats cards
                  _StatsRow(
                    total: _allOrders.length,
                    confirmed: _totalConfirmed,
                    pending: _totalPending,
                    cancelled: _totalCancelled,
                    totalValue: _totalValue,
                    formatCurrency: _formatCurrency,
                  ),
                  const SizedBox(height: 20),

                  // Orders table header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.format_list_bulleted_rounded,
                            size: 18,
                            color: Color(0xFF2F2318),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Daftar Pemesanan',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF2F2318),
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          _TableActionButton(
                            icon: Icons.view_column_rounded,
                            label: 'Kolom',
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          _TableActionButton(
                            icon: Icons.refresh_rounded,
                            label: 'Refresh',
                            onTap: () => setState(() {}),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Table
                  _OrdersTable(
                    orders: pageOrders,
                    formatCurrency: _formatCurrency,
                  ),
                  const SizedBox(height: 12),

                  // Pagination + info
                  _PaginationRow(
                    total: filtered.length,
                    currentPage: _currentPage,
                    totalPages: totalPages,
                    itemsPerPage: _itemsPerPage,
                    onPageChanged: (p) => setState(() => _currentPage = p),
                  ),
                  const SizedBox(height: 12),

                  // Bottom note
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F2),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFECDDCC)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 15,
                          color: Color(0xFFB85C1A),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Catatan: Untuk melakukan konfirmasi pembayaran, tolak transaksi, atau cetak invoice, silakan buka halaman detail pemesanan.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF6B5240),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero Banner
// ─────────────────────────────────────────────────────────────────────────────

class _OrdersHeroBanner extends StatelessWidget {
  final VoidCallback onBack;
  const _OrdersHeroBanner({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF5C1800), Color(0xFF9A3200), Color(0xFFC75010)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            // Decorative background
            Positioned.fill(
              child: CustomPaint(painter: _HeroBgPainter()),
            ),
            // Icons on right
            const Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: _HeroIcons(),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 8, 140, 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Kelola Pemesanan',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Kelola, pantau, dan perbarui seluruh pemesanan\nproperti secara menyeluruh.',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Color(0xFFFFDDBB),
                          height: 1.4,
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
    );
  }
}

class _HeroBgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.15 * i, size.height * 0.5),
        30.0 + i * 12,
        paint,
      );
    }

    final linePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 5; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width * 0.6, y), linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _HeroIcons extends StatelessWidget {
  const _HeroIcons();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _HeroIconBox(
            icon: Icons.receipt_long_rounded,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 8),
          _HeroIconBox(
            icon: Icons.home_work_rounded,
            color: Colors.white.withValues(alpha: 0.15),
          ),
          const SizedBox(width: 8),
          _HeroIconBox(
            icon: Icons.calendar_month_rounded,
            color: Colors.white.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }
}

class _HeroIconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _HeroIconBox({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
        ),
      ),
      child: Icon(icon, color: Colors.white.withValues(alpha: 0.7), size: 18),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Card
// ─────────────────────────────────────────────────────────────────────────────

class _FilterCard extends StatelessWidget {
  final DateTime startDate;
  final DateTime endDate;
  final String selectedStatus;
  final String selectedPaymentMethod;
  final List<String> statusOptions;
  final List<String> paymentMethodOptions;
  final VoidCallback onPickStartDate;
  final VoidCallback onPickEndDate;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onPaymentMethodChanged;
  final VoidCallback onApply;
  final VoidCallback onReset;

  const _FilterCard({
    required this.startDate,
    required this.endDate,
    required this.selectedStatus,
    required this.selectedPaymentMethod,
    required this.statusOptions,
    required this.paymentMethodOptions,
    required this.onPickStartDate,
    required this.onPickEndDate,
    required this.onStatusChanged,
    required this.onPaymentMethodChanged,
    required this.onApply,
    required this.onReset,
  });

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECDDCC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB85C1A).withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Row(
            children: [
              Icon(
                Icons.filter_list_rounded,
                size: 18,
                color: Color(0xFFB85C1A),
              ),
              SizedBox(width: 8),
              Text(
                'Filter Transaksi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2F2318),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Saring data berdasarkan tanggal dan status transaksi.',
            style: TextStyle(fontSize: 11.5, color: Color(0xFF9E856C)),
          ),
          const SizedBox(height: 14),

          // Date row
          Row(
            children: [
              Expanded(
                child: _DateField(
                  label: 'Tanggal Awal',
                  value: _fmt(startDate),
                  onTap: onPickStartDate,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DateField(
                  label: 'Tanggal Akhir',
                  value: _fmt(endDate),
                  onTap: onPickEndDate,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Dropdowns row
          Row(
            children: [
              Expanded(
                child: _DropdownField(
                  label: 'Status',
                  value: selectedStatus,
                  items: statusOptions,
                  onChanged: onStatusChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DropdownField(
                  label: 'Metode Pembayaran',
                  value: selectedPaymentMethod,
                  items: paymentMethodOptions,
                  onChanged: onPaymentMethodChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Action buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: onApply,
                    icon: const Icon(Icons.filter_alt_rounded, size: 16),
                    label: const Text(
                      'Terapkan',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F2318),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: 42,
                  child: OutlinedButton.icon(
                    onPressed: onReset,
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text(
                      'Reset',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6B5240),
                      side: const BorderSide(color: Color(0xFFECDDCC)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF5F0),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE7CCAE)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              size: 14,
              color: Color(0xFFB85C1A),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Color(0xFF9E856C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2F2318),
                    ),
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

class _DropdownField extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF5F0),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE7CCAE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: Color(0xFF9E856C),
              fontWeight: FontWeight.w600,
            ),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              isDense: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: Color(0xFF6B5240),
              ),
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2F2318),
              ),
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats Row
// ─────────────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int total;
  final int confirmed;
  final int pending;
  final int cancelled;
  final int totalValue;
  final String Function(int) formatCurrency;

  const _StatsRow({
    required this.total,
    required this.confirmed,
    required this.pending,
    required this.cancelled,
    required this.totalValue,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.shopping_bag_outlined,
                iconBg: const Color(0xFFFFF0DC),
                iconColor: const Color(0xFFCB7D2A),
                value: total.toString(),
                label: 'Total Pemesanan',
                sublabel: 'Semua transaksi',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.check_circle_outline_rounded,
                iconBg: const Color(0xFFE6F7EE),
                iconColor: const Color(0xFF2D9B5A),
                value: confirmed.toString(),
                label: 'Dikonfirmasi',
                sublabel: 'Transaksi berhasil dikonfirmasi',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.access_time_rounded,
                iconBg: const Color(0xFFFFF5E0),
                iconColor: const Color(0xFFD48A00),
                value: pending.toString(),
                label: 'Pending / Ditinjau',
                sublabel: 'Menunggu verifikasi',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _StatCard(
                icon: Icons.cancel_outlined,
                iconBg: const Color(0xFFFFEAEA),
                iconColor: const Color(0xFFC74C4C),
                value: cancelled.toString(),
                label: 'Dibatalkan',
                sublabel: 'Transaksi dibatalkan',
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Total value — full width
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE7CCAE)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB85C1A).withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE0FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: Color(0xFF7B4FBF),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatCurrency(totalValue),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2F2318),
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Total keseluruhan',
                      style: TextStyle(fontSize: 11, color: Color(0xFF9E856C)),
                    ),
                  ],
                ),
              ),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Total Nilai Pemesanan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF6B5240),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final String label;
  final String sublabel;

  const _StatCard({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE7CCAE)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB85C1A).withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF2F2318),
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F2318),
                  ),
                ),
                Text(
                  sublabel,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF9E856C),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Table Action Button
// ─────────────────────────────────────────────────────────────────────────────

class _TableActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _TableActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFECDDCC)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: const Color(0xFF6B5240)),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF6B5240),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Orders Table
// ─────────────────────────────────────────────────────────────────────────────

class _OrdersTable extends StatelessWidget {
  final List<OrderItem> orders;
  final String Function(int) formatCurrency;

  const _OrdersTable({required this.orders, required this.formatCurrency});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFECDDCC)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFB85C1A).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFAF5F0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(
                bottom: BorderSide(color: Color(0xFFECDDCC)),
              ),
            ),
            child: const Row(
              children: [
                _HeaderCell('Tanggal', flex: 3),
                _HeaderCell('No. Pemesanan', flex: 4),
                _HeaderCell('Properti', flex: 5),
                _HeaderCell('Pembeli', flex: 4),
                _HeaderCell('Nilai Pemesanan', flex: 4),
                _HeaderCell('Status', flex: 4),
                _HeaderCell('Metode Pembayaran', flex: 4),
                _HeaderCell('Aksi', flex: 3),
              ],
            ),
          ),
          // Rows
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Tidak ada data pemesanan',
                  style: TextStyle(color: Color(0xFF9E856C), fontSize: 13),
                ),
              ),
            )
          else
            ...orders.asMap().entries.map((entry) {
              final isLast = entry.key == orders.length - 1;
              return _OrderRow(
                order: entry.value,
                isLast: isLast,
                formatCurrency: formatCurrency,
              );
            }),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final int flex;

  const _HeaderCell(this.text, {required this.flex});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Color(0xFF6B5240),
        ),
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  final OrderItem order;
  final bool isLast;
  final String Function(int) formatCurrency;

  const _OrderRow({
    required this.order,
    required this.isLast,
    required this.formatCurrency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: Color(0xFFF4EAE0)),
              ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Date
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.date,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F2318),
                  ),
                ),
                Text(
                  order.time,
                  style: const TextStyle(
                    fontSize: 10.5,
                    color: Color(0xFF9E856C),
                  ),
                ),
              ],
            ),
          ),
          // Invoice
          Expanded(
            flex: 4,
            child: Text(
              order.invoiceNumber,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2F2318),
              ),
            ),
          ),
          // Property
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: const Color(0xFFECDDCC),
                  ),
                  child: const Icon(
                    Icons.home_rounded,
                    size: 18,
                    color: Color(0xFFB85C1A),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.propertyName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2F2318),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        order.propertyType,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9E856C),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Buyer
          Expanded(
            flex: 4,
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFFECDDCC),
                  child: Icon(
                    Icons.person_rounded,
                    size: 15,
                    color: Color(0xFF9E856C),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.buyerName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF2F2318),
                        ),
                      ),
                      Text(
                        order.buyerPhone,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9E856C),
                        ),
                      ),
                      Text(
                        order.buyerEmail,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF9E856C),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Value
          Expanded(
            flex: 4,
            child: Text(
              formatCurrency(order.orderValue),
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: Color(0xFF2F2318),
              ),
            ),
          ),
          // Status
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _StatusBadge(status: order.status),
                const SizedBox(height: 3),
                Text(
                  '${order.statusDate} ${order.statusTime}',
                  style: const TextStyle(
                    fontSize: 9.5,
                    color: Color(0xFF9E856C),
                  ),
                ),
              ],
            ),
          ),
          // Payment method
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.paymentMethod,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2F2318),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      order.bankName,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6B5240),
                      ),
                    ),
                    const SizedBox(width: 4),
                    _PaymentStatusBadge(status: order.paymentStatus),
                  ],
                ),
              ],
            ),
          ),
          // Action
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Flexible(
                  child: GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF0DC),
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(color: const Color(0xFFE7CCAE)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_rounded,
                            size: 13,
                            color: Color(0xFFB85C1A),
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Lihat Detail',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFB85C1A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5F0),
                      borderRadius: BorderRadius.circular(7),
                      border: Border.all(color: const Color(0xFFECDDCC)),
                    ),
                    child: const Icon(
                      Icons.more_vert_rounded,
                      size: 16,
                      color: Color(0xFF6B5240),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final OrderStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg, icon) = switch (status) {
      OrderStatus.dikonfirmasi => (
        'Dikonfirmasi',
        const Color(0xFFE6F7EE),
        const Color(0xFF2D9B5A),
        Icons.check_circle_rounded,
      ),
      OrderStatus.sedangDiverifikasi => (
        'Sedang Diverifikasi',
        const Color(0xFFFFF5E0),
        const Color(0xFFD48A00),
        Icons.access_time_rounded,
      ),
      OrderStatus.dibatalkan => (
        'Dibatalkan',
        const Color(0xFFFFEAEA),
        const Color(0xFFC74C4C),
        Icons.cancel_rounded,
      ),
      OrderStatus.pending => (
        'Pending',
        const Color(0xFFE8F0FF),
        const Color(0xFF3B6FD4),
        Icons.pending_rounded,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentStatusBadge extends StatelessWidget {
  final String status;
  const _PaymentStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final isLunas = status == 'Lunas';
    final isMenunggu = status == 'Menunggu';

    final bg = isLunas
        ? const Color(0xFFE6F7EE)
        : isMenunggu
            ? const Color(0xFFFFF5E0)
            : const Color(0xFFFFEAEA);
    final fg = isLunas
        ? const Color(0xFF2D9B5A)
        : isMenunggu
            ? const Color(0xFFD48A00)
            : const Color(0xFFC74C4C);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 9.5,
          fontWeight: FontWeight.w700,
          color: fg,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Pagination
// ─────────────────────────────────────────────────────────────────────────────

class _PaginationRow extends StatelessWidget {
  final int total;
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final ValueChanged<int> onPageChanged;

  const _PaginationRow({
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.itemsPerPage,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final start = math.min((currentPage - 1) * itemsPerPage + 1, total);
    final end = math.min(currentPage * itemsPerPage, total);

    // Build page numbers to show
    final pages = <int?>[];
    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      pages.add(1);
      if (currentPage > 3) pages.add(null); // ellipsis
      for (int i = math.max(2, currentPage - 1);
          i <= math.min(totalPages - 1, currentPage + 1);
          i++) {
        pages.add(i);
      }
      if (currentPage < totalPages - 2) pages.add(null); // ellipsis
      pages.add(totalPages);
    }

    return Column(
      children: [
        Text(
          'Menampilkan $start - $end dari $total pemesanan',
          style: const TextStyle(fontSize: 11.5, color: Color(0xFF9E856C)),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _PageButton(
              child: const Icon(
                Icons.chevron_left_rounded,
                size: 18,
                color: Color(0xFF6B5240),
              ),
              isActive: false,
              isDisabled: currentPage == 1,
              onTap: () {
                if (currentPage > 1) onPageChanged(currentPage - 1);
              },
            ),
            const SizedBox(width: 6),
            ...pages.map((p) {
              if (p == null) {
                return const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    '...',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9E856C),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _PageButton(
                  child: Text(
                    p.toString(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: p == currentPage
                          ? Colors.white
                          : const Color(0xFF6B5240),
                    ),
                  ),
                  isActive: p == currentPage,
                  isDisabled: false,
                  onTap: () => onPageChanged(p),
                ),
              );
            }),
            _PageButton(
              child: const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: Color(0xFF6B5240),
              ),
              isActive: false,
              isDisabled: currentPage == totalPages,
              onTap: () {
                if (currentPage < totalPages) onPageChanged(currentPage + 1);
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  final Widget child;
  final bool isActive;
  final bool isDisabled;
  final VoidCallback onTap;

  const _PageButton({
    required this.child,
    required this.isActive,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: isActive
              ? const Color(0xFF2F2318)
              : isDisabled
                  ? const Color(0xFFF4EAE0)
                  : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isActive
                ? const Color(0xFF2F2318)
                : const Color(0xFFECDDCC),
          ),
        ),
        child: Center(child: child),
      ),
    );
  }
}