import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import '../../models/purchase_order_model.dart';
import '../../services/purchase_service.dart';
import 'widgets/payment_info_card.dart';
import 'widgets/purchase_theme.dart';
import '../../widgets/braga_page_header.dart';

class PurchaseStatusPage extends StatefulWidget {
  const PurchaseStatusPage({super.key});

  @override
  State<PurchaseStatusPage> createState() => _PurchaseStatusPageState();
}

class _PurchaseStatusPageState extends State<PurchaseStatusPage> {
  final PurchaseService _purchaseService = PurchaseService();

  bool _isLoading = true;
  bool _isLocaleReady = false;
  String? _errorMessage;
  List<PurchaseOrderModel> _orders = const [];

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

    final response = await _purchaseService.getMyOrders();
    if (!mounted) return;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      setState(() {
        _orders = _purchaseService.parseOrders(response.body);
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _errorMessage = _purchaseService.parseMessage(response.body);
      _isLoading = false;
    });
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

  String _formatPrice(double price) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F3EC),
      body: Column(
        children: [
          const BragaPageHeader(
            title: 'Status Pemesanan',
            subtitle: 'Pantau status pesanan properti Anda.',
            decorativeIcon: Icons.receipt_long_rounded,
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFF8F3EC), Color(0xFFFDFBF8)],
                ),
              ),
              child: RefreshIndicator(onRefresh: _loadOrders, child: _buildBody()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (!_isLocaleReady || _isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          _MessageCard(
            title: 'Gagal memuat status pemesanan',
            message: _errorMessage!,
            actionLabel: 'Coba lagi',
            onPressed: _loadOrders,
          ),
        ],
      );
    }

    if (_orders.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: const [_EmptyStatusCard()],
      );
    }

    final latestOrder = _orders.first;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      children: [
        _StatusHeroCard(
          order: latestOrder,
          formatPrice: _formatPrice,
          formatDate: _formatDate,
          onOpenDetail: () => Navigator.pushNamed(
            context,
            '/purchase-detail',
            arguments: latestOrder.id,
          ).then((_) => _loadOrders()),
          onUploadProof: latestOrder.canUploadProof
              ? () => Navigator.pushNamed(
                  context,
                  '/upload-payment',
                  arguments: latestOrder,
                ).then((_) => _loadOrders())
              : null,
        ),
        const SizedBox(height: 20),
        _StatusSummaryRow(
          order: latestOrder,
          formatPrice: _formatPrice,
          formatDate: _formatDate,
          statusLabel: _statusLabelText,
        ),
        const SizedBox(height: 22),
        const Text(
          'Timeline Transaksi',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: Color(0xFF171717),
            fontFamily: 'TomatoGrotesk',
          ),
        ),
        const SizedBox(height: 12),
        ..._orders.skip(1).map(
          (order) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _PurchaseStatusTile(
              order: order,
              formatDate: _formatDate,
              formatPrice: _formatPrice,
              onOpenDetail: () => Navigator.pushNamed(
                context,
                '/purchase-detail',
                arguments: order.id,
              ).then((_) => _loadOrders()),
              onUploadProof: order.canUploadProof
                  ? () => Navigator.pushNamed(
                      context,
                      '/upload-payment',
                      arguments: order,
                    ).then((_) => _loadOrders())
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 22),
        const _SupportCard(),
      ],
    );
  }

}

class _StatusHeroCard extends StatelessWidget {
  const _StatusHeroCard({
    required this.order,
    required this.formatPrice,
    required this.formatDate,
    required this.onOpenDetail,
    this.onUploadProof,
  });

  final PurchaseOrderModel order;
  final String Function(double) formatPrice;
  final String Function(String?) formatDate;
  final VoidCallback onOpenDetail;
  final VoidCallback? onUploadProof;

  String get _orderReference => 'INV/${order.id.toString().padLeft(6, '0')}';

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(order.status);
    final orderDate = formatDate(order.createdAt);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      decoration: BoxDecoration(
        color: PurchaseTheme.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE6DACB)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8E4E16).withOpacity(0.06),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _PropertyThumb(imageUrl: order.propertyThumbnailUrl, size: 72),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.propertyTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF171717),
                        fontFamily: 'TomatoGrotesk',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      order.propertyLocation,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF777777),
                        fontFamily: 'TomatoGrotesk',
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: badge.background,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge.label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: badge.foreground,
                              fontFamily: 'TomatoGrotesk',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE6DACB)),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'No. Pemesanan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF777777),
                      fontFamily: 'TomatoGrotesk',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _orderReference,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF171717),
                      fontFamily: 'TomatoGrotesk',
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'Tanggal Pemesanan',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF777777),
                      fontFamily: 'TomatoGrotesk',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    orderDate,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF171717),
                      fontFamily: 'TomatoGrotesk',
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            _statusDescription(order.status),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF777777),
              height: 1.5,
              fontFamily: 'TomatoGrotesk',
            ),
          ),
          const SizedBox(height: 18),
          _OrderProgressTimeline(status: order.status),
          const SizedBox(height: 18),
          PaymentInfoCard(
            order: order,
            formatPrice: formatPrice,
            formatDate: formatDate,
            statusLabel: _statusLabelText,
            compact: true,
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: onUploadProof,
              style: ElevatedButton.styleFrom(
                backgroundColor: onUploadProof == null
                    ? const Color(0xFFE8E8E8)
                    : PurchaseTheme.navy,
                foregroundColor: onUploadProof == null
                    ? const Color(0xFF888888)
                    : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                onUploadProof == null
                    ? order.isCancelled
                        ? 'Pesanan Dibatalkan'
                        : 'Bukti Sedang Diproses'
                    : 'Upload Bukti Pembayaran',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'TomatoGrotesk',
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: onOpenDetail,
              style: OutlinedButton.styleFrom(
                foregroundColor: PurchaseTheme.navy,
                side: const BorderSide(color: Color(0xFFD4D7EA)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text(
                'Lihat Detail Pemesanan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'TomatoGrotesk',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PurchaseStatusTile extends StatelessWidget {
  const _PurchaseStatusTile({
    required this.order,
    required this.formatDate,
    required this.formatPrice,
    required this.onOpenDetail,
    this.onUploadProof,
  });

  final PurchaseOrderModel order;
  final String Function(String?) formatDate;
  final String Function(double) formatPrice;
  final VoidCallback onOpenDetail;
  final VoidCallback? onUploadProof;

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(order.status);

    return InkWell(
      onTap: onOpenDetail,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: PurchaseTheme.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8DACA)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                _PropertyThumb(imageUrl: order.propertyThumbnailUrl, size: 48),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.propertyTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF171717),
                          fontFamily: 'TomatoGrotesk',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatDate(order.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF777777),
                          fontFamily: 'TomatoGrotesk',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: badge.background,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badge.label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: badge.foreground,
                    fontFamily: 'TomatoGrotesk',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatPrice(order.propertyPrice),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF171717),
                      fontFamily: 'TomatoGrotesk',
                    ),
                  ),
                ),
                if (onUploadProof != null)
                  TextButton(
                    onPressed: onUploadProof,
                    child: const Text('Upload Bukti'),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            _DetailRow(
              label: 'Total Transfer',
              value: formatPrice(order.payableAmount),
            ),
            _DetailRow(
              label: 'Batas Bayar',
              value: formatDate(order.paymentDueAt),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusInfoCard extends StatelessWidget {
  const _StatusInfoCard({
    required this.title,
    required this.rows,
  });

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: PurchaseTheme.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8DACA)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Color(0xFF171717),
              fontFamily: 'TomatoGrotesk',
            ),
          ),
          const SizedBox(height: 14),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF777777),
                fontFamily: 'TomatoGrotesk',
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: Color(0xFF171717),
                fontFamily: 'TomatoGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusSummaryRow extends StatelessWidget {
  const _StatusSummaryRow({
    required this.order,
    required this.formatPrice,
    required this.formatDate,
    required this.statusLabel,
  });

  final PurchaseOrderModel order;
  final String Function(double) formatPrice;
  final String Function(String?) formatDate;
  final String Function(String) statusLabel;

  String get _scheduleDate {
    final raw = order.paymentProofUploadedAt ?? order.paymentDueAt;
    return formatDate(raw);
  }

  String get _scheduleTime {
    final raw = order.paymentProofUploadedAt ?? order.paymentDueAt;
    final parsed = DateTime.tryParse(raw ?? '');
    if (parsed == null) return '-';
    return DateFormat('HH:mm', 'id_ID').format(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;
        return isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildPaymentCard()),
                  const SizedBox(width: 14),
                  Expanded(child: _buildScheduleCard()),
                ],
              )
            : Column(
                children: [
                  _buildPaymentCard(),
                  const SizedBox(height: 14),
                  _buildScheduleCard(),
                ],
              );
      },
    );
  }

  Widget _buildPaymentCard() {
    return _StatusInfoCard(
      title: 'Status Pembayaran',
      rows: [
        _InfoRow(label: 'Total Pembayaran', value: formatPrice(order.payableAmount)),
        _InfoRow(label: 'Metode Pembayaran', value: order.paymentMethod),
        _InfoRow(label: 'Batas Bayar', value: formatDate(order.paymentDueAt)),
        _InfoRow(label: 'Status', value: statusLabel(order.status)),
      ],
    );
  }

  Widget _buildScheduleCard() {
    return _StatusInfoCard(
      title: 'Jadwal Survei',
      rows: [
        _InfoRow(label: 'Tanggal Survei', value: _scheduleDate),
        _InfoRow(label: 'Waktu', value: _scheduleTime),
        _InfoRow(label: 'Lokasi Properti', value: order.propertyLocation),
        _InfoRow(label: 'Marketing', value: order.processedByName ?? '-'),
      ],
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7EF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFF1D9B9)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE9D2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.headset_mic_rounded,
                  color: Color(0xFF8A5926),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Ada yang ingin ditanyakan?',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF171717),
                        fontFamily: 'TomatoGrotesk',
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Hubungi tim marketing kami untuk informasi lebih lanjut.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF777777),
                        height: 1.4,
                        fontFamily: 'TomatoGrotesk',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/consultation'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF8E4E16),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text('Hubungi Marketing'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyThumb extends StatelessWidget {
  const _PropertyThumb({required this.imageUrl, required this.size});

  final String? imageUrl;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return _FallbackThumb(size: size);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.24),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _FallbackThumb(size: size),
      ),
    );
  }
}

class _FallbackThumb extends StatelessWidget {
  const _FallbackThumb({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFDD096), Color(0xFF8E4E16)],
        ),
      ),
      child: Icon(
        Icons.home_work_rounded,
        color: Colors.white,
        size: size * 0.48,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF777777),
                fontFamily: 'TomatoGrotesk',
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF303030),
                height: 1.35,
                fontFamily: 'TomatoGrotesk',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: PurchaseTheme.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: PurchaseTheme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: Color(0xFF171717),
              fontFamily: 'TomatoGrotesk',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6D5540),
              fontFamily: 'TomatoGrotesk',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onPressed, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _EmptyStatusCard extends StatelessWidget {
  const _EmptyStatusCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: PurchaseTheme.cardBackground,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: PurchaseTheme.dividerColor),
      ),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3D9),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              size: 38,
              color: Color(0xFF9A6700),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Belum Ada Pemesanan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Color(0xFF171717),
              fontFamily: 'TomatoGrotesk',
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Status pemesanan properti Anda akan tampil di halaman ini setelah melakukan checkout.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF777777),
              height: 1.45,
              fontFamily: 'TomatoGrotesk',
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamedAndRemoveUntil(
                context,
                '/home',
                (route) => false,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PurchaseTheme.navy,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: const Text('Cari Properti'),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderProgressTimeline extends StatelessWidget {
  const _OrderProgressTimeline({required this.status});

  final String status;

  int get _activeStep {
    switch (status) {
      case 'payment_uploaded':
        return 2;
      case 'payment_review':
        return 3;
      case 'confirmed':
        return 5;
      case 'rejected':
      case 'cancelled':
        return 1;
      default:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = [
      _TimelineStepData('Pesanan Dibuat', Icons.receipt_long_rounded),
      _TimelineStepData('Bukti Diunggah', Icons.upload_file_rounded),
      _TimelineStepData('Verifikasi Marketing', Icons.person_search_rounded),
      _TimelineStepData('Dikonfirmasi Admin', Icons.verified_rounded),
      _TimelineStepData('Selesai', Icons.check_circle_rounded),
    ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFF0E1D2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Progres Pesanan',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Color(0xFF171717),
              fontFamily: 'TomatoGrotesk',
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var index = 0; index < steps.length; index++) ...[
                Expanded(
                  child: _TimelineStep(
                    data: steps[index],
                    isActive: index < _activeStep,
                    isProblem: status == 'rejected' || status == 'cancelled',
                  ),
                ),
                if (index != steps.length - 1)
                  Container(
                    width: 14,
                    height: 2,
                    color: index < _activeStep - 1
                        ? PurchaseTheme.success
                        : const Color(0xFFE4D8CB),
                  ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineStepData {
  const _TimelineStepData(this.label, this.icon);

  final String label;
  final IconData icon;
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.data,
    required this.isActive,
    required this.isProblem,
  });

  final _TimelineStepData data;
  final bool isActive;
  final bool isProblem;

  @override
  Widget build(BuildContext context) {
    final color = isProblem && isActive
        ? PurchaseTheme.error
        : isActive
        ? PurchaseTheme.success
        : const Color(0xFFB8B8B8);

    return Column(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withOpacity(0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(data.icon, size: 17, color: color),
        ),
        const SizedBox(height: 6),
        Text(
          data.label,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: color,
            fontFamily: 'TomatoGrotesk',
          ),
        ),
      ],
    );
  }
}

class _StatusBadgeStyle {
  const _StatusBadgeStyle({
    required this.label,
    required this.background,
    required this.foreground,
  });

  final String label;
  final Color background;
  final Color foreground;
}

_StatusBadgeStyle _statusBadge(String status) {
  switch (status) {
    case 'confirmed':
      return const _StatusBadgeStyle(
        label: 'Dikonfirmasi',
        background: Color(0xFFE6F6EC),
        foreground: Color(0xFF1F7A45),
      );
    case 'rejected':
      return const _StatusBadgeStyle(
        label: 'Ditolak',
        background: Color(0xFFFCE8E6),
        foreground: Color(0xFFC0392B),
      );
    case 'cancelled':
      return const _StatusBadgeStyle(
        label: 'Dibatalkan',
        background: Color(0xFFF1F1F1),
        foreground: Color(0xFF6B7280),
      );
    case 'payment_uploaded':
      return const _StatusBadgeStyle(
        label: 'Bukti Diunggah',
        background: Color(0xFFE3EFFD),
        foreground: Color(0xFF1E5FAF),
      );
    case 'payment_review':
      return const _StatusBadgeStyle(
        label: 'Sedang Ditinjau',
        background: Color(0xFFEDE7F6),
        foreground: Color(0xFF5E35B1),
      );
    default:
      return const _StatusBadgeStyle(
        label: 'Menunggu Pembayaran',
        background: Color(0xFFFFF3D9),
        foreground: Color(0xFF9A6700),
      );
  }
}

String _statusLabelText(String status) => _statusBadge(status).label;

String _statusDescription(String status) {
  switch (status) {
    case 'confirmed':
      return 'Pesanan Anda sudah dikonfirmasi oleh tim marketing.';
    case 'rejected':
      return 'Pesanan Anda belum dapat diproses. Silakan cek detail riwayat pemesanan.';
    case 'cancelled':
      return 'Pesanan otomatis dibatalkan karena melewati batas waktu pembayaran.';
    case 'payment_uploaded':
    case 'payment_review':
      return 'Bukti pembayaran sudah diterima dan sedang ditinjau oleh tim kami.';
    default:
      return 'Pesanan sudah dibuat. Silakan unggah bukti pembayaran agar tim kami dapat memprosesnya.';
  }
}
