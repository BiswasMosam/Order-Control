import 'package:flutter/material.dart';

import '../models/order.dart';
import '../theme.dart';
import 'status_button.dart';

/// One live order on the board. Everything the shop needs to decide what to
/// do next is on the face of the card, and every action is one tap.
class OrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onOpen;
  final VoidCallback onReady;
  final VoidCallback onPaid;
  final VoidCallback onDone;

  const OrderCard({
    super.key,
    required this.order,
    required this.onOpen,
    required this.onReady,
    required this.onPaid,
    required this.onDone,
  });

  /// Orange while the kitchen still has it, green once it is ready.
  Color get _edge => order.isReady ? AppColors.ready : AppColors.cooking;

  @override
  Widget build(BuildContext context) {
    final waited = DateTime.now().difference(order.createdAt);
    final late = !order.isReady && waited.inMinutes >= 15;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _edge.withValues(alpha: 0.55), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onOpen,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 13, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 11,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: _edge,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '#${order.number}',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Icon(
                        Icons.schedule,
                        size: 14,
                        color: late ? AppColors.danger : AppColors.textDim,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _elapsed(waited),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: late ? FontWeight.w800 : FontWeight.w500,
                          color: late ? AppColors.danger : AppColors.textDim,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '₹${order.total}',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: AppColors.text,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  ...order.lines.map(
                    (l) => Padding(
                      padding: const EdgeInsets.only(bottom: 3),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 30,
                            child: Text(
                              '${l.qty}×',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              '${l.displayName}  ·  ${l.portionLabel}',
                              style: const TextStyle(
                                fontSize: 15,
                                height: 1.3,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (order.note.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.sticky_note_2_outlined,
                          size: 15,
                          color: AppColors.accent,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            order.note,
                            style: const TextStyle(
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: Row(
              children: [
                StatusButton(
                  label: 'READY',
                  icon: Icons.restaurant,
                  color: AppColors.ready,
                  active: order.isReady,
                  onTap: onReady,
                ),
                const SizedBox(width: 8),
                StatusButton(
                  label: 'PAID',
                  icon: Icons.currency_rupee,
                  color: AppColors.paid,
                  active: order.isPaid,
                  onTap: onPaid,
                ),
                const SizedBox(width: 8),
                StatusButton(
                  label: 'DONE',
                  icon: Icons.check_circle_outline,
                  color: AppColors.accent,
                  active: order.isSettled,
                  onTap: onDone,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _elapsed(Duration d) {
    if (d.inMinutes < 1) return 'just now';
    if (d.inMinutes < 60) return '${d.inMinutes} min';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}
