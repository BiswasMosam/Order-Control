import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/database.dart';
import '../data/order_store.dart';
import '../models/order.dart';
import '../theme.dart';

/// The day's book: what came in, what was collected, what is still owed.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _store = OrderStore.instance;
  DateTime _day = businessDayOf(DateTime.now());
  List<Order> _orders = [];
  bool _loading = true;

  static final _time = DateFormat('h:mm a');
  static final _date = DateFormat('EEE, d MMM');

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final rows = await OrderDatabase.instance.ordersForDay(_day);
    if (!mounted) return;
    setState(() {
      _orders = rows;
      _loading = false;
    });
  }

  void _shift(int days) {
    final next = _day.add(Duration(days: days));
    if (next.isAfter(businessDayOf(DateTime.now()))) return;
    setState(() => _day = next);
    _load();
  }

  Future<void> _actions(Order order) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Text(
              'Order #${order.number}  ·  ₹${order.total}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            if (!order.isPaid)
              ListTile(
                leading: const Icon(Icons.currency_rupee, color: AppColors.paid),
                title: const Text('Mark as paid'),
                onTap: () async {
                  Navigator.pop(sheet);
                  await _store.setPaid(order, true);
                  await _load();
                },
              ),
            if (order.isCompleted)
              ListTile(
                leading: const Icon(Icons.undo, color: AppColors.accent),
                title: const Text('Put back on the board'),
                onTap: () async {
                  Navigator.pop(sheet);
                  await _store.reopen(order);
                  await _load();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text(
                'Delete order',
                style: TextStyle(color: AppColors.danger),
              ),
              onTap: () async {
                Navigator.pop(sheet);
                await _store.deleteOrder(order);
                await _load();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final earned = _orders
        .where((o) => o.isPaid)
        .fold(0, (s, o) => s + o.total);
    final pending = _orders
        .where((o) => !o.isPaid)
        .fold(0, (s, o) => s + o.total);
    final isToday = _day == businessDayOf(DateTime.now());

    return Scaffold(
      appBar: AppBar(title: const Text('Day book')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => _shift(-1),
                  icon: const Icon(Icons.chevron_left),
                  iconSize: 30,
                  color: AppColors.text,
                ),
                Expanded(
                  child: Text(
                    isToday ? 'Today' : _date.format(_day),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: isToday ? null : () => _shift(1),
                  icon: const Icon(Icons.chevron_right),
                  iconSize: 30,
                  color: isToday ? AppColors.line : AppColors.text,
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(14, 4, 14, 10),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _Fig(
                  label: 'ORDERS',
                  value: '${_orders.length}',
                  color: AppColors.text,
                ),
                _Fig(
                  label: 'EARNED',
                  value: '₹$earned',
                  color: AppColors.ready,
                ),
                _Fig(
                  label: 'PENDING',
                  value: '₹$pending',
                  color: pending > 0 ? AppColors.cooking : AppColors.textDim,
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _orders.isEmpty
                ? const Center(
                    child: Text(
                      'No orders on this day',
                      style: TextStyle(fontSize: 16, color: AppColors.textDim),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
                    itemCount: _orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, i) {
                      final o = _orders[i];
                      return Material(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _actions(o),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(13),
                            child: Row(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '#${o.number}',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    Text(
                                      _time.format(o.createdAt),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textDim,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Text(
                                    o.lines
                                        .map(
                                          (l) => '${l.qty}× ${l.displayName}',
                                        )
                                        .join(', '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textDim,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '₹${o.total}',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.text,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      o.isPaid ? 'PAID' : 'UNPAID',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.6,
                                        color: o.isPaid
                                            ? AppColors.ready
                                            : AppColors.cooking,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _Fig extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Fig({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: AppColors.textDim,
            ),
          ),
        ],
      ),
    );
  }
}
