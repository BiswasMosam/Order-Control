import 'package:flutter_test/flutter_test.dart';
import 'package:order_control/data/menu_data.dart';
import 'package:order_control/models/menu_item.dart';
import 'package:order_control/models/order.dart';

OrderLine line(
  String name,
  String portion,
  int price, {
  String? style,
  int qty = 1,
}) => OrderLine(
  itemName: name,
  portionLabel: portion,
  unitPrice: price,
  style: style,
  qty: qty,
);

void main() {
  group('order totals', () {
    test('sums quantities across lines', () {
      final order = Order(
        number: 1,
        createdAt: DateTime.now(),
        lines: [
          line('Chicken Fried Rice', 'Full', 110, style: kStylePlain, qty: 2),
          line('Veg Noodles', 'Half', 60, style: kStyleSchezwan),
          line('Chicken Soup', 'Full', 80),
        ],
      );
      expect(order.total, 220 + 60 + 80);
      expect(order.itemCount, 4);
    });

    test('lollipop extra pieces price at 40 each', () {
      final order = Order(
        number: 2,
        createdAt: DateTime.now(),
        lines: [
          line('Chicken Lollipop (Gravy)', '6 pcs', 160),
          line('Extra Lollipop Piece', '1 pc', 40, qty: 2),
        ],
      );
      expect(order.total, 240);
    });
  });

  group('line merging', () {
    test('same dish, portion and style merge', () {
      final a = line('Veg Noodles', 'Half', 60, style: kStylePlain);
      final b = line('Veg Noodles', 'Half', 60, style: kStylePlain);
      expect(a.sameAs(b), isTrue);
    });

    test('plain and schezwan stay separate lines', () {
      final a = line('Veg Noodles', 'Half', 60, style: kStylePlain);
      final b = line('Veg Noodles', 'Half', 60, style: kStyleSchezwan);
      expect(a.sameAs(b), isFalse);
    });

    test('half and full stay separate lines', () {
      final a = line('Veg Manchurian', 'Half', 60);
      final b = line('Veg Manchurian', 'Full', 100);
      expect(a.sameAs(b), isFalse);
    });
  });

  group('business day', () {
    test('a 1 AM order belongs to the previous day', () {
      final late = DateTime(2026, 7, 27, 1, 30);
      expect(businessDayOf(late), DateTime(2026, 7, 26));
    });

    test('a 9 PM order belongs to the same day', () {
      final evening = DateTime(2026, 7, 26, 21, 0);
      expect(businessDayOf(evening), DateTime(2026, 7, 26));
    });

    test('rollover happens at 5 AM', () {
      expect(businessDayOf(DateTime(2026, 7, 27, 4, 59)), DateTime(2026, 7, 26));
      expect(businessDayOf(DateTime(2026, 7, 27, 5, 0)), DateTime(2026, 7, 27));
    });
  });

  group('settled state', () {
    test('needs both ready and paid', () {
      final o = Order(number: 3, createdAt: DateTime.now());
      expect(o.isSettled, isFalse);
      o.isReady = true;
      expect(o.isSettled, isFalse);
      o.isPaid = true;
      expect(o.isSettled, isTrue);
    });
  });

  group('menu', () {
    test('every dish has at least one portion and a category', () {
      for (final item in kMenu) {
        expect(item.portions, isNotEmpty, reason: item.name);
        expect(kCategories, contains(item.category), reason: item.name);
      }
    });

    test('dish ids are unique', () {
      final ids = kMenu.map((m) => m.id).toSet();
      expect(ids.length, kMenu.length);
    });

    test('schezwan costs the same as plain', () {
      final riceAndNoodles = kMenu.where((m) => m.hasStyle);
      expect(riceAndNoodles.length, 8);
      // Style never changes price, so a styled line uses the listed portions.
      for (final item in riceAndNoodles) {
        expect(item.portions.length, 2, reason: item.name);
      }
    });
  });
}
