import 'package:flutter/material.dart' hide FormField;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../models/purchase_order_model.dart';
import '../../services/auth_service.dart';
import '../../services/buyer_profile_service.dart';
import '../../services/purchase_service.dart';
import 'widgets/form_field.dart' as custom_form;
import 'widgets/payment_info_card.dart';
import 'widgets/payment_method_selector.dart';
import 'widgets/purchase_theme.dart';
import '../../widgets/braga_page_header.dart';

class PurchaseFormPage extends StatefulWidget {
  const PurchaseFormPage({
    super.key,
    required this.propertyId,
    required this.propertyTitle,
    required this.propertyPrice,
  });

  final int propertyId;
  final String propertyTitle;
  final int propertyPrice;

  @override
  State<PurchaseFormPage> createState() => _PurchaseFormPageState();
}

class _PurchaseFormPageState extends State<PurchaseFormPage> {
  final PurchaseService _purchaseService = PurchaseService();
  final BuyerProfileService _buyerProfileService = BuyerProfileService();
  final ScrollController _scrollController = ScrollController();

  final _buyerNameController = TextEditingController();
  final _buyerPhoneController = TextEditingController();
  final _buyerAddressController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedPaymentMethod = 'QRIS';
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _isLocaleReady = false;

  String? _validateBuyerName(String? value) {
    if (value?.isEmpty ?? true) return 'Nama pemesan wajib diisi';
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) return null;
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10) return 'Nomor telepon tidak valid';
    return null;
  }

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  @override
  void initState() {
    super.initState();
    _preparePage();
  }

  Future<void> _preparePage() async {
    await initializeDateFormatting('id_ID');
    if (!mounted) return;
    setState(() => _isLocaleReady = true);
    await _prefillBuyerData();
  }

  @override
  void dispose() {
    _buyerNameController.dispose();
    _buyerPhoneController.dispose();
    _buyerAddressController.dispose();
    _notesController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _prefillBuyerData() async {
    final session = AuthService().getSession();
    _buyerNameController.text = session?['name']?.toString() ?? '';

    try {
      final profileResp = await _buyerProfileService.getMyBuyerProfile();
      if (!mounted) return;

      if (profileResp.statusCode >= 200 && profileResp.statusCode < 300) {
        final profile = _buyerProfileService.parseProfile(profileResp.body);
        _buyerPhoneController.text = profile.contact.whatsapp;
        final parts = <String>[
          if (profile.address.addressLine.isNotEmpty)
            profile.address.addressLine,
          if (profile.address.district.isNotEmpty)
            profile.address.district,
          if (profile.address.city.isNotEmpty) profile.address.city,
          if (profile.address.province.isNotEmpty)
            profile.address.province,
          if (profile.address.postalCode.isNotEmpty)
            profile.address.postalCode,
        ];
        _buyerAddressController.text = parts.join(', ');
      }
    } catch (_) {
      // Profile unavailable — buyer fills in manually
    }

    if (!mounted) return;
    setState(() => _isLoading = false);
  }

  Future<void> _submit() async {
    final name = _buyerNameController.text.trim();
    final phone = _buyerPhoneController.text.trim();
    final address = _buyerAddressController.text.trim();
    final notes = _notesController.text.trim();

    if (name.isEmpty) {
      _showMessage('Nama pemesan wajib diisi');
      return;
    }

    setState(() => _isSubmitting = true);

    final response = await _purchaseService.createPurchase(
      propertyId: widget.propertyId,
      paymentMethod: _selectedPaymentMethod,
      buyerName: name,
      buyerPhone: phone.isEmpty ? null : phone,
      buyerAddress: address.isEmpty ? null : address,
      notes: notes.isEmpty ? null : notes,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final order = _purchaseService.parseOrder(response.body);
      await _showSuccessDialog(order);
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        '/purchase-detail',
        arguments: order.id,
      );
    } else {
      _showMessage(_purchaseService.parseMessage(response.body));
    }
  }

  Future<void> _showSuccessDialog(PurchaseOrderModel order) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 460),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE6F6EC),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 44,
                      color: PurchaseTheme.success,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Center(
                  child: Text(
                    'Pesanan berhasil dibuat',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF171717),
                      fontFamily: 'TomatoGrotesk',
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Center(
                  child: Text(
                    _statusLabel(order.status),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: PurchaseTheme.navy,
                      fontFamily: 'TomatoGrotesk',
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBF7),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFF0E1D2)),
                  ),
                  child: Column(
                    children: [
                      _DialogRow(label: 'Properti', value: order.propertyTitle),
                      _DialogRow(label: 'Metode', value: order.paymentMethod),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                PaymentInfoCard(
                  order: order,
                  formatPrice: _formatPrice,
                  formatDate: _formatDate,
                  statusLabel: _statusLabel,
                  compact: true,
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showBuyerDetailSheet(order),
                        icon: const Icon(Icons.person_outline_rounded),
                        label: const Text('Detail Pemesan'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: PurchaseTheme.navy,
                          side: const BorderSide(color: Color(0xFFD4D7EA)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PurchaseTheme.navy,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                        child: const Text('Lihat Detail'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showBuyerDetailSheet(PurchaseOrderModel order) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BuyerDetailSheet(
        order: order,
        total: _formatPrice(order.payableAmount),
      ),
    );
  }

  String _formatDate(String? value) {
    final parsed = DateTime.tryParse(value ?? '');
    if (parsed == null) return '-';
    return DateFormat('dd MMM yyyy, HH:mm', 'id_ID').format(parsed.toLocal());
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending_payment':
        return 'Menunggu Pembayaran';
      case 'payment_uploaded':
        return 'Bukti Pembayaran Diunggah';
      case 'payment_review':
        return 'Pembayaran Ditinjau';
      case 'confirmed':
        return 'Pembayaran Berhasil';
      case 'rejected':
        return 'Pembayaran Ditolak';
      case 'cancelled':
        return 'Pesanan Dibatalkan';
      default:
        return status;
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final total = _formatPrice(widget.propertyPrice.toDouble());

    return Scaffold(
      backgroundColor: PurchaseTheme.checkoutBackground,
      body: Column(
        children: [
          const BragaPageHeader(
            title: 'Pesan',
            subtitle: 'Selesaikan pesanan properti Anda.',
            decorativeIcon: Icons.shopping_cart_checkout_rounded,
          ),
          Expanded(
            child: (_isLoading || !_isLocaleReady)
                ? const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(PurchaseTheme.navy),
                    ),
                  )
                : SingleChildScrollView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PropertySummaryRow(
                    title: widget.propertyTitle,
                    price: total,
                  ),
                  const SizedBox(height: 22),
                  _CheckoutSection(
                    title: 'Metode Pembayaran',
                    child: PaymentMethodSelector(
                      selected: _selectedPaymentMethod,
                      onChanged: (method) =>
                          setState(() => _selectedPaymentMethod = method),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _CheckoutSection(
                    title: 'Data Pemesan',
                    child: Column(
                      children: [
                        custom_form.FormField(
                          controller: _buyerNameController,
                          label: 'Nama Lengkap',
                          hint: 'Masukkan nama sesuai KTP',
                          isRequired: true,
                          validator: _validateBuyerName,
                          icon: Icons.person_outline_rounded,
                          validateRealTime: true,
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: PurchaseTheme.spacing16),
                        custom_form.FormField(
                          controller: _buyerPhoneController,
                          label: 'Nomor WhatsApp',
                          hint: '08xx xxxx xxxx',
                          keyboardType: TextInputType.phone,
                          validator: _validatePhone,
                          icon: Icons.phone_outlined,
                          validateRealTime: true,
                          formatPhone: true,
                        ),
                        const SizedBox(height: PurchaseTheme.spacing16),
                        custom_form.FormField(
                          controller: _buyerAddressController,
                          label: 'Alamat Korespondensi',
                          hint: 'Alamat lengkap untuk korespondensi',
                          maxLength: 255,
                          showCharacterCount: true,
                          validateRealTime: false,
                        ),
                        const SizedBox(height: PurchaseTheme.spacing16),
                        custom_form.FormField(
                          controller: _notesController,
                          label: 'Catatan Tambahan',
                          hint: 'Informasi tambahan untuk tim marketing',
                          maxLength: 500,
                          showCharacterCount: true,
                          validateRealTime: false,
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          decoration: const BoxDecoration(
            color: PurchaseTheme.cardBackground,
            border: Border(top: BorderSide(color: PurchaseTheme.dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF777777),
                        fontFamily: 'TomatoGrotesk',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      total,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF171717),
                        fontFamily: 'TomatoGrotesk',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: PurchaseTheme.spacing14),
              SizedBox(
                height: PurchaseTheme.checkoutButtonHeight,
                width: 128,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PurchaseTheme.navy,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey.shade300,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Pesan',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'TomatoGrotesk',
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

class _BuyerDetailSheet extends StatelessWidget {
  const _BuyerDetailSheet({required this.order, required this.total});

  final PurchaseOrderModel order;
  final String total;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 14),
          decoration: const BoxDecoration(
            color: Color(0xFFFFF4E8),
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: EdgeInsets.fromLTRB(18, 10, 18, 24 + bottomPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6D5540),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFD9B0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Color(0xFF8E4E16),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Detail Pemesan',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF171717),
                              fontFamily: 'TomatoGrotesk',
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Data pemesan dan ringkasan pesanan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8A735F),
                              fontFamily: 'TomatoGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _BuyerInfoCard(
                  title: 'Data Pemesan',
                  icon: Icons.badge_outlined,
                  rows: [
                    _BuyerInfoRowData('Nama', order.buyerNameSnapshot),
                    _BuyerInfoRowData(
                      'WhatsApp',
                      order.buyerPhoneSnapshot ?? '-',
                    ),
                    _BuyerInfoRowData(
                      'Alamat',
                      order.buyerAddressSnapshot ?? '-',
                    ),
                    _BuyerInfoRowData('Catatan', order.notes ?? '-'),
                  ],
                ),
                const SizedBox(height: 12),
                _BuyerInfoCard(
                  title: 'Rincian Pesanan',
                  icon: Icons.receipt_long_rounded,
                  rows: [
                    _BuyerInfoRowData('Properti', order.propertyTitle),
                    _BuyerInfoRowData('Metode', order.paymentMethod),
                    _BuyerInfoRowData('Total', total, isEmphasized: true),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2A5A),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: const Text(
                      'Tutup',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontFamily: 'TomatoGrotesk',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BuyerInfoCard extends StatelessWidget {
  const _BuyerInfoCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_BuyerInfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF0DCC8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF8E4E16)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF171717),
                  fontFamily: 'TomatoGrotesk',
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...rows.map(_BuyerInfoRow.new),
        ],
      ),
    );
  }
}

class _BuyerInfoRowData {
  const _BuyerInfoRowData(this.label, this.value, {this.isEmphasized = false});

  final String label;
  final String value;
  final bool isEmphasized;
}

class _BuyerInfoRow extends StatelessWidget {
  const _BuyerInfoRow(this.data);

  final _BuyerInfoRowData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: Color(0xFF8A735F),
              fontFamily: 'TomatoGrotesk',
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.value.trim().isEmpty ? '-' : data.value,
            style: TextStyle(
              fontSize: data.isEmphasized ? 15 : 13,
              fontWeight: data.isEmphasized ? FontWeight.w900 : FontWeight.w700,
              color: data.isEmphasized
                  ? const Color(0xFF1E2A5A)
                  : const Color(0xFF303030),
              height: 1.35,
              fontFamily: 'TomatoGrotesk',
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertySummaryRow extends StatelessWidget {
  const _PropertySummaryRow({required this.title, required this.price});

  final String title;
  final String price;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: PurchaseTheme.dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFDD096), Color(0xFF8E4E16)],
              ),
            ),
            child: const Icon(
              Icons.home_work_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF171717),
                    fontFamily: 'TomatoGrotesk',
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  price,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF777777),
                    fontFamily: 'TomatoGrotesk',
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Pemesanan Properti  x1',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF303030),
                    fontFamily: 'TomatoGrotesk',
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

class _CheckoutSection extends StatelessWidget {
  const _CheckoutSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Color(0xFF303030),
            fontFamily: 'TomatoGrotesk',
          ),
        ),
        const SizedBox(height: PurchaseTheme.spacing10),
        child,
      ],
    );
  }
}

class _DialogRow extends StatelessWidget {
  const _DialogRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF777777),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
