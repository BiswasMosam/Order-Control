import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/order.dart';

class OrderDatabase {
  OrderDatabase._();

  static final OrderDatabase instance = OrderDatabase._();

  Database? _db;

  Future<Database> get db async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, 'order_control.db'),
      version: 1,
      onCreate: (db, _) async {
        await db.execute('''
          CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            number INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            business_day INTEGER NOT NULL,
            is_ready INTEGER NOT NULL DEFAULT 0,
            is_paid INTEGER NOT NULL DEFAULT 0,
            is_completed INTEGER NOT NULL DEFAULT 0,
            note TEXT NOT NULL DEFAULT ''
          )
        ''');
        await db.execute('''
          CREATE TABLE order_lines (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            order_id INTEGER NOT NULL,
            item_name TEXT NOT NULL,
            portion_label TEXT NOT NULL,
            style TEXT,
            unit_price INTEGER NOT NULL,
            qty INTEGER NOT NULL DEFAULT 1,
            FOREIGN KEY (order_id) REFERENCES orders (id) ON DELETE CASCADE
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_orders_day ON orders (business_day)',
        );
        await db.execute(
          'CREATE INDEX idx_lines_order ON order_lines (order_id)',
        );
      },
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
    );
  }

  /// Next token number for the current business day.
  Future<int> nextNumber(DateTime now) async {
    final d = await db;
    final day = businessDayOf(now).millisecondsSinceEpoch;
    final rows = await d.rawQuery(
      'SELECT MAX(number) AS n FROM orders WHERE business_day = ?',
      [day],
    );
    final current = rows.first['n'] as int?;
    return (current ?? 0) + 1;
  }

  Future<int> insertOrder(Order order) async {
    final d = await db;
    return d.transaction((txn) async {
      final map = order.toMap()..remove('id');
      final orderId = await txn.insert('orders', map);
      for (final line in order.lines) {
        final lm = line.toMap()
          ..remove('id')
          ..['order_id'] = orderId;
        await txn.insert('order_lines', lm);
      }
      return orderId;
    });
  }

  /// Replaces the order row and all of its lines.
  Future<void> updateOrder(Order order) async {
    final d = await db;
    await d.transaction((txn) async {
      await txn.update(
        'orders',
        order.toMap(),
        where: 'id = ?',
        whereArgs: [order.id],
      );
      await txn.delete(
        'order_lines',
        where: 'order_id = ?',
        whereArgs: [order.id],
      );
      for (final line in order.lines) {
        final lm = line.toMap()
          ..remove('id')
          ..['order_id'] = order.id;
        await txn.insert('order_lines', lm);
      }
    });
  }

  /// Cheap write for the Ready / Paid / Completed toggles.
  Future<void> updateFlags(Order order) async {
    final d = await db;
    await d.update(
      'orders',
      {
        'is_ready': order.isReady ? 1 : 0,
        'is_paid': order.isPaid ? 1 : 0,
        'is_completed': order.isCompleted ? 1 : 0,
      },
      where: 'id = ?',
      whereArgs: [order.id],
    );
  }

  Future<void> deleteOrder(int id) async {
    final d = await db;
    await d.delete('orders', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Order>> activeOrders() =>
      _query('is_completed = 0', const [], 'created_at ASC');

  /// [day] must already be a business day from [businessDayOf]. Normalising
  /// again here would push a midnight value back onto the previous day.
  Future<List<Order>> ordersForDay(DateTime day) =>
      _query('business_day = ?', [day.millisecondsSinceEpoch], 'created_at DESC');

  Future<List<Order>> _query(
    String where,
    List<Object?> args,
    String orderBy,
  ) async {
    final d = await db;
    final rows = await d.query(
      'orders',
      where: where,
      whereArgs: args,
      orderBy: orderBy,
    );
    if (rows.isEmpty) return [];

    final orders = rows.map(Order.fromMap).toList();
    final ids = orders.map((o) => o.id!).toList();
    final placeholders = List.filled(ids.length, '?').join(',');
    final lineRows = await d.query(
      'order_lines',
      where: 'order_id IN ($placeholders)',
      whereArgs: ids,
      orderBy: 'id ASC',
    );

    final byOrder = <int, List<OrderLine>>{};
    for (final row in lineRows) {
      final line = OrderLine.fromMap(row);
      byOrder.putIfAbsent(line.orderId!, () => []).add(line);
    }
    for (final o in orders) {
      o.lines = byOrder[o.id] ?? [];
    }
    return orders;
  }
}
