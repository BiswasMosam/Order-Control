/// The shop often runs past midnight, so a business day is counted from
/// 5 AM to 5 AM. An order taken at 1 AM still belongs to the night before.
const int kDayStartHour = 5;

DateTime businessDayOf(DateTime t) {
  final d = t.hour < kDayStartHour ? t.subtract(const Duration(days: 1)) : t;
  return DateTime(d.year, d.month, d.day);
}

/// One line on an order. Name, portion and price are snapshots taken when
/// the line was added, so old orders keep their totals if the menu changes.
class OrderLine {
  int? id;
  int? orderId;
  final String itemName;
  final String portionLabel;
  final String? style; // Plain / Schezwan, null when the dish has no style
  final int unitPrice;
  int qty;

  OrderLine({
    this.id,
    this.orderId,
    required this.itemName,
    required this.portionLabel,
    this.style,
    required this.unitPrice,
    this.qty = 1,
  });

  int get total => unitPrice * qty;

  String get displayName => style == null ? itemName : '$style $itemName';

  /// Two lines merge when they are the same dish, portion and style.
  bool sameAs(OrderLine other) =>
      itemName == other.itemName &&
      portionLabel == other.portionLabel &&
      style == other.style;

  Map<String, Object?> toMap() => {
    'id': id,
    'order_id': orderId,
    'item_name': itemName,
    'portion_label': portionLabel,
    'style': style,
    'unit_price': unitPrice,
    'qty': qty,
  };

  factory OrderLine.fromMap(Map<String, Object?> m) => OrderLine(
    id: m['id'] as int?,
    orderId: m['order_id'] as int?,
    itemName: m['item_name'] as String,
    portionLabel: m['portion_label'] as String,
    style: m['style'] as String?,
    unitPrice: m['unit_price'] as int,
    qty: m['qty'] as int,
  );

  OrderLine copy() => OrderLine(
    id: id,
    orderId: orderId,
    itemName: itemName,
    portionLabel: portionLabel,
    style: style,
    unitPrice: unitPrice,
    qty: qty,
  );
}

class Order {
  int? id;
  int number; // resets every business day
  DateTime createdAt;
  bool isReady;
  bool isPaid;
  bool isCompleted;
  String note;
  List<OrderLine> lines;

  Order({
    this.id,
    required this.number,
    required this.createdAt,
    this.isReady = false,
    this.isPaid = false,
    this.isCompleted = false,
    this.note = '',
    List<OrderLine>? lines,
  }) : lines = lines ?? [];

  int get total => lines.fold(0, (sum, l) => sum + l.total);

  int get itemCount => lines.fold(0, (sum, l) => sum + l.qty);

  /// Everything settled, so the order can be cleared off the board.
  bool get isSettled => isReady && isPaid;

  Map<String, Object?> toMap() => {
    'id': id,
    'number': number,
    'created_at': createdAt.millisecondsSinceEpoch,
    'business_day': businessDayOf(createdAt).millisecondsSinceEpoch,
    'is_ready': isReady ? 1 : 0,
    'is_paid': isPaid ? 1 : 0,
    'is_completed': isCompleted ? 1 : 0,
    'note': note,
  };

  factory Order.fromMap(Map<String, Object?> m) => Order(
    id: m['id'] as int?,
    number: m['number'] as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
    isReady: (m['is_ready'] as int) == 1,
    isPaid: (m['is_paid'] as int) == 1,
    isCompleted: (m['is_completed'] as int) == 1,
    note: (m['note'] as String?) ?? '',
  );
}
