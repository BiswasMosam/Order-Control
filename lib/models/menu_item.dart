/// One sellable size of a dish, e.g. "Half" at 60 or "6 pcs" at 150.
class Portion {
  final String label;
  final int price;

  const Portion(this.label, this.price);
}

/// A dish on the menu. [hasStyle] marks the rice and noodles that come
/// in both Plain and Schezwan (same price, different cooking).
class MenuItem {
  final String id;
  final String name;
  final String category;
  final List<Portion> portions;
  final bool hasStyle;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.portions,
    this.hasStyle = false,
  });

  /// Cheapest price, used for the "from 60" hint on the menu tile.
  int get fromPrice =>
      portions.map((p) => p.price).reduce((a, b) => a < b ? a : b);
}

const kStylePlain = 'Plain';
const kStyleSchezwan = 'Schezwan';
