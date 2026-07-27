import 'dart:async';

import 'package:flutter/material.dart';

import '../data/order_store.dart';
import '../models/order.dart';
import '../theme.dart';
import '../widgets/order_card.dart';
import 'history_screen.dart';
import 'order_editor_screen.dart';

/// The board. Every live order, its state, and one tap to change it.
class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _store = OrderStore.instance;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Keeps the "12 min" waiting times honest without any user action.
    _ticker = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _newOrder() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const OrderEditorScreen()),
    );
  }

  Future<void> _open(Order order) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderEditorScreen(existing: order)),
    );
  }

  Future<void> _done(Order order) async {
    await _store.complete(order);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Order #${order.number} cleared'),
          backgroundColor: AppColors.surfaceHi,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'UNDO',
            textColor: AppColors.accent,
            onPressed: () => _store.reopen(order),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Control'),
        actions: [
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.receipt_long),
            iconSize: 26,
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const HistoryScreen()),
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: ListenableBuilder(
        listenable: _store,
        builder: (context, _) {
          final orders = _store.active;
          return Column(
            children: [
              _SummaryStrip(store: _store),
              Expanded(
                child: orders.isEmpty
                    ? const _EmptyBoard()
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                        itemCount: orders.length,
                        itemBuilder: (context, i) {
                          final o = orders[i];
                          return OrderCard(
                            order: o,
                            onOpen: () => _open(o),
                            onReady: () => _store.setReady(o, !o.isReady),
                            onPaid: () => _store.setPaid(o, !o.isPaid),
                            onDone: () => _done(o),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: SizedBox(
          height: 62,
          child: FilledButton.icon(
            onPressed: _newOrder,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.add, size: 27),
            label: const Text(
              'NEW ORDER',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  final OrderStore store;

  const _SummaryStrip({required this.store});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 4, 14, 0),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _Stat(
            label: 'COOKING',
            value: '${store.cookingCount}',
            color: AppColors.cooking,
          ),
          _divider(),
          _Stat(
            label: 'UNPAID',
            value: '${store.unpaidCount}',
            color: AppColors.paid,
          ),
          _divider(),
          _Stat(
            label: 'TODAY',
            value: '₹${store.todayEarnings}',
            color: AppColors.ready,
          ),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 30, color: AppColors.line);
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Stat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
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

class _EmptyBoard extends StatelessWidget {
  const _EmptyBoard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.ramen_dining, size: 66, color: AppColors.line),
          SizedBox(height: 14),
          Text(
            'No orders running',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textDim,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Tap NEW ORDER to start one',
            style: TextStyle(fontSize: 14, color: AppColors.textDim),
          ),
        ],
      ),
    );
  }
}
