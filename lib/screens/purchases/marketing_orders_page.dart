import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../models/purchase_order_model.dart';
import '../../services/purchase_service.dart';
import '../../widgets/braga_page_header.dart';
import 'widgets/staff_payment_summary_card.dart';

class MarketingOrdersPage extends StatefulWidget {
  const MarketingOrdersPage({super.key});

  @override
  State<MarketingOrdersPage> createState() => _MarketingOrdersPageState();
}

class _MarketingOrdersPageState extends State<MarketingOrdersPage> {
  final PurchaseService _purchaseService = PurchaseService();
  final NumberFormat _priceFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy, HH:mm', 'id_ID');

  bool _isLoading = true;
  String? _errorMessage;
  List<PurchaseOrderModel> _orders = const [];
  DateTime? _filterFrom;
  DateTime? _filterTo;
  int? _filterMonth;
  int? _filterYear;

  @override
  void initState() {
    super.initState();
    _preparePage();
  }

  Future<void> _preparePage() async {
    await initializeDateFormatting('id_ID');
    if (!mounted) return;
    await _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final response = await _purchaseService.getAllOrders(
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

    setState(() {
      _orders = _purchaseService.parseOrders(response.body);
      _isLoading = false;
    });
  }

  String _formatDate(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed == null) return '-';
    return _dateFormat.format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7ED),
      body: Column(
        children: [
          const BragaPageHeader(
            title: 'Data Pemesanan Saya',
            subtitle: 'Pantau pesanan buyer Anda.',
            decorativeIcon: Icons.shopping_bag_rounded,
          ),
          Expanded(
            child: RefreshIndicator(onRefresh: _loadOrders, child: _buildBody()),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage != null) {
      return _MessageState(
        title: 'Gagal memuat data',
        message: _errorMessage!,
        actionLabel: 'Coba lagi',
        onAction: _loadOrders,
      );
    }
    if (_orders.isEmpty) {
      return const _MessageState(
        title: 'Belum ada pemesanan',
        message: 'Pemesanan buyer akan muncul di sini.',
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) return _buildFilterCard();
        final order = _orders[index - 1];
        return _OrderCard(
          order: order,
          date: _formatDate(order.createdAt),
          price: _priceFormat.format(order.propertyPrice),
        );
      },
    );
  }

  Widget _buildFilterCard() {
    final years = List<int>.generate(8, (index) => DateTime.now().year - index);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9D7BF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filter Pemesanan',
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickDate(isFrom: true),
                icon: const Icon(Icons.event_rounded),
                label: Text(_dateOnly(_filterFrom) ?? 'Tanggal awal'),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickDate(isFrom: false),
                icon: const Icon(Icons.event_available_rounded),
                label: Text(_dateOnly(_filterTo) ?? 'Tanggal akhir'),
              ),
              DropdownButton<int?>(
                value: _filterMonth,
                hint: const Text('Bulan'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Semua bulan'),
                  ),
                  ...List.generate(
                    12,
                    (index) => DropdownMenuItem<int?>(
                      value: index + 1,
                      child: Text(
                        DateFormat.MMMM(
                          'id_ID',
                        ).format(DateTime(2024, index + 1)),
                      ),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _filterMonth = value),
              ),
              DropdownButton<int?>(
                value: _filterYear,
                hint: const Text('Tahun'),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Semua tahun'),
                  ),
                  ...years.map(
                    (year) => DropdownMenuItem<int?>(
                      value: year,
                      child: Text(year.toString()),
                    ),
                  ),
                ],
                onChanged: (value) => setState(() => _filterYear = value),
              ),
            ],
          ),
          Row(
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _filterFrom = null;
                    _filterTo = null;
                    _filterMonth = null;
                    _filterYear = null;
                  });
                  _loadOrders();
                },
                child: const Text('Reset'),
              ),
              const Spacer(),
              FilledButton(
                onPressed: _loadOrders,
                child: const Text('Terapkan'),
              ),
            ],
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

  String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    return DateFormat('dd MMM yyyy', 'id_ID').format(value);
  }
}

class _OrderCard extends StatelessWidget {
  final PurchaseOrderModel order;
  final String date;
  final String price;

  const _OrderCard({
    required this.order,
    required this.date,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE9D7BF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.propertyTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _StatusChip(status: order.status, paymentMethod: order.paymentMethod),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.propertyLocation,
            style: const TextStyle(color: Color(0xFF7A6552)),
          ),
          const SizedBox(height: 12),
          StaffPaymentSummaryCard(
            order: order,
            formatPrice: (value) => price,
            formatDate: (_) => date,
            compact: true,
          ),
          const SizedBox(height: 12),
          _InfoRow(label: 'Buyer', value: order.buyerNameSnapshot),
          _InfoRow(label: 'Tanggal', value: date),
          _InfoRow(label: 'Pembayaran', value: order.paymentMethod),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  final String? paymentMethod;

  const _StatusChip({required this.status, this.paymentMethod});

  @override
  Widget build(BuildContext context) => StaffStatusBadge(status: status, paymentMethod: paymentMethod);
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF7A6552)),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _MessageState({
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE9D7BF)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.inbox_rounded,
                size: 46,
                color: Color(0xFF8F4E1E),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF6D5540)),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
