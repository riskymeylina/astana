import 'buyer_record_model.dart';
import 'purchase_order_model.dart';

class RecapTransaction {
  const RecapTransaction._({this.order, this.historicalSale})
    : assert(order != null || historicalSale != null);

  factory RecapTransaction.fromOrder(PurchaseOrderModel order) =>
      RecapTransaction._(order: order);

  factory RecapTransaction.fromHistoricalSale(HistoricalSale sale) =>
      RecapTransaction._(historicalSale: sale);

  final PurchaseOrderModel? order;
  final HistoricalSale? historicalSale;

  bool get isHistorical => historicalSale != null;

  DateTime? get date => isHistorical
      ? historicalSale!.transactionDate
      : DateTime.tryParse(order!.createdAt ?? '');

  String get buyerName => isHistorical
      ? historicalSale!.buyerFullName ?? ''
      : order!.buyerNameSnapshot;

  String? get buyerPhone =>
      isHistorical ? historicalSale!.buyerPhone : order!.buyerPhoneSnapshot;

  String get propertyName => isHistorical
      ? (historicalSale!.propertyTitleCurrent?.trim().isNotEmpty == true
            ? historicalSale!.propertyTitleCurrent!
            : historicalSale!.propertyNameSnapshot)
      : order!.propertyTitle;

  int? get propertyId =>
      isHistorical ? historicalSale!.propertyId : order!.propertyId;

  String get status => isHistorical
      ? switch (historicalSale!.status) {
          'completed' => 'confirmed',
          'pending' => 'pending_payment',
          _ => historicalSale!.status,
        }
      : order!.status;

  bool get isConfirmed => status == 'confirmed';

  double get amount => isHistorical
      ? (historicalSale!.transactionValue ?? 0).toDouble()
      : (order!.totalPrice ?? order!.propertyPrice);

  String? get paymentMethod =>
      isHistorical ? historicalSale!.paymentMethod : order!.paymentMethod;

  String buyerKey(List<BuyerRecord> buyerRecords) => _buyerKey(buyerRecords);

  Set<String> duplicateKeys(List<BuyerRecord> buyerRecords) {
    final buyerKey = _buyerKey(buyerRecords);
    final keys = <String>{
      'name:$buyerKey|property:${_normalize(propertyName)}',
    };
    if (propertyId != null) {
      keys.add('name:$buyerKey|property-id:$propertyId');
    }
    return keys;
  }

  String _buyerKey(List<BuyerRecord> buyerRecords) {
    if (isHistorical) return 'record:${historicalSale!.buyerRecordId}';
    final transaction = order!;
    if (transaction.buyerRecordId != null) {
      return 'record:${transaction.buyerRecordId}';
    }
    for (final buyer in buyerRecords) {
      if (transaction.buyerUserId != null &&
          buyer.linkedUserId == transaction.buyerUserId) {
        return 'record:${buyer.id}';
      }
    }

    final phone = _normalizePhone(transaction.buyerPhoneSnapshot);
    if (phone.isNotEmpty) {
      for (final buyer in buyerRecords) {
        if (_normalizePhone(buyer.phone) == phone) return 'record:${buyer.id}';
      }
      return 'phone:$phone';
    }

    final name = _normalizeName(transaction.buyerNameSnapshot);
    for (final buyer in buyerRecords) {
      if (_normalizeName(buyer.fullName) == name) return 'record:${buyer.id}';
    }
    return 'name:$name';
  }

  static List<RecapTransaction> combine({
    required List<PurchaseOrderModel> orders,
    required List<HistoricalSale> historicalSales,
    List<BuyerRecord> buyerRecords = const [],
  }) {
    final online = orders.map(RecapTransaction.fromOrder).toList()
      ..sort(_newestFirst);
    final historical =
        historicalSales.map(RecapTransaction.fromHistoricalSale).toList()
          ..sort(_newestFirst);
    final unique = <RecapTransaction>[];
    final seenKeys = <String>{};

    for (final transaction in [...online, ...historical]) {
      final keys = transaction.duplicateKeys(buyerRecords);
      if (keys.any(seenKeys.contains)) continue;
      unique.add(transaction);
      seenKeys.addAll(keys);
    }

    unique.sort(_newestFirst);
    return unique;
  }

  static int _newestFirst(RecapTransaction left, RecapTransaction right) {
    final leftDate = left.date;
    final rightDate = right.date;
    if (leftDate == null) return rightDate == null ? 0 : 1;
    if (rightDate == null) return -1;
    return rightDate.compareTo(leftDate);
  }

  static String _normalizeName(String value) => value
      .trim()
      .replaceFirst(RegExp(r'^(?:(?:ibu|bapak)\s+)+', caseSensitive: false), '')
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
      .trim();

  static String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), ' ').trim();

  static String _normalizePhone(String? value) {
    var digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (digits.startsWith('62')) digits = '0${digits.substring(2)}';
    return digits;
  }
}
