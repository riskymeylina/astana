import 'package:flutter/material.dart';
import 'purchase_theme.dart';

class PaymentMethodSelector extends StatefulWidget {
  const PaymentMethodSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final String selected;
  final Function(String) onChanged;

  @override
  State<PaymentMethodSelector> createState() => _PaymentMethodSelectorState();
}

class _PaymentMethodSelectorState extends State<PaymentMethodSelector> {
  static const List<Map<String, dynamic>> _methods = [
    {
      'id': 'QRIS',
      'title': 'QRIS',
      'subtitle': 'Otomatis & Terverifikasi Realtime',
      'description':
          'Scan QR Code dari aplikasi Mobile Banking (BCA, Mandiri, BNI, BRI) atau E-Wallet (GoPay, OVO, DANA, ShopeePay).',
      'badge': 'Rekomendasi • Instan',
      'badgeColor': Color(0xFF1E5FAF),
      'badgeBg': Color(0xFFE8F1FC),
      'icon': Icons.qr_code_scanner_rounded,
      'partners': 'BCA • Mandiri • BRI • GoPay • OVO • DANA • ShopeePay',
    },
    {
      'id': 'Cash Payment',
      'title': 'Cash Payment (Tunai)',
      'subtitle': 'Bayar di Kantor Pemasaran',
      'description':
          'Lakukan pembayaran tunai langsung ke kasir di Kantor Pemasaran Resmi Astana Karya. Kwitansi resmi akan diterbitkan langsung.',
      'badge': 'Tanpa Biaya Admin',
      'badgeColor': Color(0xFF1F7A45),
      'badgeBg': Color(0xFFE8F6ED),
      'icon': Icons.payments_rounded,
      'partners': 'Lokasi: Kantor Pemasaran Astana Karya (08:00 - 16:30 WIB)',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ..._methods.map((method) {
          final isSelected = widget.selected == method['id'];
          final isQris = method['id'] == 'QRIS';

          return Padding(
            padding: const EdgeInsets.only(bottom: PurchaseTheme.spacing12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => widget.onChanged(method['id']),
              child: AnimatedContainer(
                duration: PurchaseTheme.durationShort,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isQris ? const Color(0xFFF4F8FD) : PurchaseTheme.paymentSelectedBg)
                      : PurchaseTheme.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (isQris ? const Color(0xFF1E5FAF) : PurchaseTheme.success)
                        : PurchaseTheme.dividerColor,
                    width: isSelected ? 1.6 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: (isQris ? const Color(0xFF1E5FAF) : PurchaseTheme.success)
                                .withOpacity(0.12),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (isQris
                                ? const Color(0xFF1E5FAF).withOpacity(0.12)
                                : PurchaseTheme.success.withOpacity(0.14))
                            : const Color(0xFFF6F1EA),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(
                        method['icon'],
                        color: isSelected
                            ? (isQris ? const Color(0xFF1E5FAF) : PurchaseTheme.success)
                            : const Color(0xFF8A735F),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: PurchaseTheme.spacing14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  method['title'],
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF222222),
                                    fontFamily: 'TomatoGrotesk',
                                  ),
                                ),
                              ),
                              Icon(
                                isSelected
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                color: isSelected
                                    ? (isQris ? const Color(0xFF1E5FAF) : PurchaseTheme.success)
                                    : const Color(0xFFB8B8B8),
                                size: 22,
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            method['subtitle'],
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? (isQris ? const Color(0xFF1E5FAF) : PurchaseTheme.success)
                                  : const Color(0xFF8A735F),
                              fontFamily: 'TomatoGrotesk',
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            method['description'],
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF666666),
                              height: 1.4,
                              fontFamily: 'TomatoGrotesk',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: method['badgeBg'] as Color,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  method['badge'] as String,
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w900,
                                    color: method['badgeColor'] as Color,
                                    fontFamily: 'TomatoGrotesk',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            method['partners'] as String,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF888888),
                              fontFamily: 'TomatoGrotesk',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0E1D2)),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.security_rounded,
                color: Color(0xFF9A6700),
                size: 18,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Transaksi QRIS diproses secara aman dan terenkripsi.',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6D5540),
                    fontFamily: 'TomatoGrotesk',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
