import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/menu_data.dart';
import '../data/order_store.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../theme.dart';

/// Takes a new order, and edits an existing one. Same screen either way so
/// there is only one thing to learn.
class OrderEditorScreen extends StatefulWidget {
  final Order? existing;

  const OrderEditorScreen({super.key, this.existing});

  @override
  State<OrderEditorScreen> createState() => _OrderEditorScreenState();
}

class _OrderEditorScreenState extends State<OrderEditorScreen> {
  final _store = OrderStore.instance;
  late final List<OrderLine> _lines;
  late final TextEditingController _note;
  String _category = kCategories.first;
  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    // Work on copies so backing out of the screen changes nothing.
    _lines = widget.existing?.lines.map((l) => l.copy()).toList() ?? [];
    _note = TextEditingController(text: widget.existing?.note ?? '');
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  int get _total => _lines.fold(0, (s, l) => s + l.total);
  int get _count => _lines.fold(0, (s, l) => s + l.qty);

  void _add(OrderLine line) {
    HapticFeedback.selectionClick();
    setState(() {
      final existing = _lines.where((l) => l.sameAs(line)).firstOrNull;
      if (existing != null) {
        existing.qty += line.qty;
      } else {
        _lines.add(line);
      }
    });
  }

  Future<void> _pick(MenuItem item) async {
    // Nothing to choose, so skip the sheet entirely.
    if (item.portions.length == 1 && !item.hasStyle) {
      _add(
        OrderLine(
          itemName: item.name,
          portionLabel: item.portions.first.label,
          unitPrice: item.portions.first.price,
        ),
      );
      return;
    }

    final line = await showModalBottomSheet<OrderLine>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PortionSheet(item: item),
    );
    if (line != null) _add(line);
  }

  Future<void> _save() async {
    if (_lines.isEmpty || _saving) return;
    setState(() => _saving = true);
    if (_isEdit) {
      final order = widget.existing!;
      order.lines = _lines;
      order.note = _note.text.trim();
      await _store.saveOrder(order);
    } else {
      await _store.createOrder(_lines, note: _note.text.trim());
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceHi,
        title: const Text('Delete this order?'),
        content: Text('Order #${widget.existing!.number} will be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _store.deleteOrder(widget.existing!);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _openCart() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _CartSheet(lines: _lines, note: _note),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final items = kMenu.where((m) => m.category == _category).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Order #${widget.existing!.number}' : 'New Order'),
        actions: [
          if (_isEdit)
            IconButton(
              tooltip: 'Delete order',
              icon: const Icon(Icons.delete_outline),
              color: AppColors.danger,
              iconSize: 26,
              onPressed: _delete,
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 56,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: kCategories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 9),
              itemBuilder: (context, i) {
                final c = kCategories[i];
                final on = c == _category;
                return Center(
                  child: GestureDetector(
                    onTap: () => setState(() => _category = c),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 130),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: on ? AppColors.accent : AppColors.surface,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        c,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: on ? Colors.black : AppColors.textDim,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 116,
                  ),
              itemCount: items.length,
              itemBuilder: (context, i) => _MenuTile(
                item: items[i],
                qty: _qtyOf(items[i]),
                onTap: () => _pick(items[i]),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _CartBar(
        count: _count,
        total: _total,
        saving: _saving,
        isEdit: _isEdit,
        onOpen: _lines.isEmpty ? null : _openCart,
        onSave: _lines.isEmpty ? null : _save,
      ),
    );
  }

  /// How many of this dish are already on the order, shown as a tile badge.
  int _qtyOf(MenuItem item) => _lines
      .where((l) => l.itemName == item.name)
      .fold(0, (s, l) => s + l.qty);
}

class _MenuTile extends StatelessWidget {
  final MenuItem item;
  final int qty;
  final VoidCallback onTap;

  const _MenuTile({required this.item, required this.qty, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final chosen = qty > 0;
    return Material(
      color: chosen ? AppColors.surfaceHi : AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: chosen ? AppColors.accent : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.name,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.text,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    item.portions.map((p) => '₹${p.price}').join(' / '),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDim,
                    ),
                  ),
                  const Spacer(),
                  if (chosen)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '$qty',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pick the portion, and the style when the dish has one.
class _PortionSheet extends StatefulWidget {
  final MenuItem item;

  const _PortionSheet({required this.item});

  @override
  State<_PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<_PortionSheet> {
  String _style = kStylePlain;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              item.name,
              style: const TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            if (item.hasStyle) ...[
              const SizedBox(height: 16),
              Row(
                children: [kStylePlain, kStyleSchezwan].map((s) {
                  final on = s == _style;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: s == kStylePlain ? 9 : 0),
                      child: GestureDetector(
                        onTap: () => setState(() => _style = s),
                        child: Container(
                          height: 50,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: on
                                ? AppColors.accent.withValues(alpha: 0.18)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: on ? AppColors.accent : AppColors.line,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            s,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: on ? AppColors.accent : AppColors.textDim,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 16),
            ...item.portions.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SizedBox(
                  height: 60,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      OrderLine(
                        itemName: item.name,
                        portionLabel: p.label,
                        style: item.hasStyle ? _style : null,
                        unitPrice: p.price,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surfaceHi,
                      foregroundColor: AppColors.text,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          p.label,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '₹${p.price}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Review the order, fix quantities, add a note.
class _CartSheet extends StatefulWidget {
  final List<OrderLine> lines;
  final TextEditingController note;

  const _CartSheet({required this.lines, required this.note});

  @override
  State<_CartSheet> createState() => _CartSheetState();
}

class _CartSheetState extends State<_CartSheet> {
  @override
  Widget build(BuildContext context) {
    final total = widget.lines.fold(0, (s, l) => s + l.total);
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.line,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Order items',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: AppColors.text,
                ),
              ),
              const SizedBox(height: 10),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.lines.length,
                  itemBuilder: (context, i) {
                    final l = widget.lines[i];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l.displayName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.text,
                                  ),
                                ),
                                Text(
                                  '${l.portionLabel} · ₹${l.unitPrice}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _RoundBtn(
                            icon: l.qty > 1
                                ? Icons.remove
                                : Icons.delete_outline,
                            onTap: () => setState(() {
                              if (l.qty > 1) {
                                l.qty--;
                              } else {
                                widget.lines.removeAt(i);
                              }
                            }),
                          ),
                          SizedBox(
                            width: 38,
                            child: Text(
                              '${l.qty}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          _RoundBtn(
                            icon: Icons.add,
                            onTap: () => setState(() => l.qty++),
                          ),
                          SizedBox(
                            width: 62,
                            child: Text(
                              '₹${l.total}',
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(height: 24),
              TextField(
                controller: widget.note,
                style: const TextStyle(color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'Note (less spicy, parcel, red shirt…)',
                  hintStyle: const TextStyle(color: AppColors.textDim),
                  filled: true,
                  fillColor: AppColors.surfaceHi,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(11),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(fontSize: 17, color: AppColors.textDim),
                  ),
                  const Spacer(),
                  Text(
                    '₹$total',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoundBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHi,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, size: 20, color: AppColors.text),
        ),
      ),
    );
  }
}

class _CartBar extends StatelessWidget {
  final int count;
  final int total;
  final bool saving;
  final bool isEdit;
  final VoidCallback? onOpen;
  final VoidCallback? onSave;

  const _CartBar({
    required this.count,
    required this.total,
    required this.saving,
    required this.isEdit,
    this.onOpen,
    this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final empty = count == 0;
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onOpen,
              child: Container(
                height: 62,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          empty ? 'No items yet' : '$count item${count == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textDim,
                          ),
                        ),
                        Text(
                          '₹$total',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (!empty)
                      const Icon(
                        Icons.expand_less,
                        color: AppColors.textDim,
                        size: 24,
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 62,
            width: 130,
            child: FilledButton(
              onPressed: saving ? null : onSave,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                disabledBackgroundColor: AppColors.line,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                isEdit ? 'UPDATE' : 'SAVE',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
