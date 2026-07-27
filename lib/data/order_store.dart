import 'package:flutter/foundation.dart';

import '../models/order.dart';
import 'database.dart';

/// Single source of truth for the screens. Everything lives on the device.
class OrderStore extends ChangeNotifier {
  OrderStore._();

  static final OrderStore instance = OrderStore._();

  final _db = OrderDatabase.instance;

  List<Order> _active = [];
  List<Order> _today = [];
  bool _loaded = false;

  List<Order> get active => _active;
  List<Order> get today => _today;
  bool get loaded => _loaded;

  /// Orders still waiting on the kitchen.
  int get cookingCount => _active.where((o) => !o.isReady).length;

  /// Orders handed over today but not yet paid.
  int get unpaidCount => _active.where((o) => !o.isPaid).length;

  int get todayEarnings =>
      _today.where((o) => o.isPaid).fold(0, (s, o) => s + o.total);

  int get todayPending =>
      _today.where((o) => !o.isPaid).fold(0, (s, o) => s + o.total);

  Future<void> load() async {
    _active = await _db.activeOrders();
    _today = await _db.ordersForDay(businessDayOf(DateTime.now()));
    _loaded = true;
    notifyListeners();
  }

  Future<Order> createOrder(List<OrderLine> lines, {String note = ''}) async {
    final now = DateTime.now();
    final order = Order(
      number: await _db.nextNumber(now),
      createdAt: now,
      note: note,
      lines: lines,
    );
    order.id = await _db.insertOrder(order);
    await load();
    return order;
  }

  Future<void> saveOrder(Order order) async {
    await _db.updateOrder(order);
    await load();
  }

  Future<void> setReady(Order order, bool value) async {
    order.isReady = value;
    await _db.updateFlags(order);
    await load();
  }

  Future<void> setPaid(Order order, bool value) async {
    order.isPaid = value;
    await _db.updateFlags(order);
    await load();
  }

  /// Clears the order off the board. Ready and paid are implied by a
  /// completed order, so tick them too.
  Future<void> complete(Order order) async {
    order.isCompleted = true;
    order.isReady = true;
    order.isPaid = true;
    await _db.updateFlags(order);
    await load();
  }

  Future<void> reopen(Order order) async {
    order.isCompleted = false;
    await _db.updateFlags(order);
    await load();
  }

  Future<void> deleteOrder(Order order) async {
    if (order.id != null) await _db.deleteOrder(order.id!);
    await load();
  }
}
