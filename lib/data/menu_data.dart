import '../models/menu_item.dart';

const kCategories = ['Starters', 'Rice', 'Noodles', 'Soup'];

/// The shop menu. Prices are half/full unless the labels say otherwise.
const List<MenuItem> kMenu = [
  // ---- Starters ----
  MenuItem(
    id: 'veg_manchurian',
    name: 'Veg Manchurian',
    category: 'Starters',
    portions: [Portion('Half', 60), Portion('Full', 100)],
  ),
  MenuItem(
    id: 'veg_chilli',
    name: 'Veg Chilli',
    category: 'Starters',
    portions: [Portion('Half', 60), Portion('Full', 100)],
  ),
  MenuItem(
    id: 'chicken_manchurian',
    name: 'Chicken Manchurian',
    category: 'Starters',
    portions: [Portion('Half', 80), Portion('Full', 130)],
  ),
  MenuItem(
    id: 'chicken_chilli',
    name: 'Chicken Chilli',
    category: 'Starters',
    portions: [Portion('Half', 80), Portion('Full', 130)],
  ),
  MenuItem(
    id: 'chicken_crispy',
    name: 'Chicken Crispy',
    category: 'Starters',
    portions: [Portion('Half', 100), Portion('Full', 150)],
  ),
  MenuItem(
    id: 'lollipop_oil',
    name: 'Chicken Lollipop (Oil Fried)',
    category: 'Starters',
    portions: [Portion('3 pcs', 80), Portion('6 pcs', 150)],
  ),
  MenuItem(
    id: 'lollipop_gravy',
    name: 'Chicken Lollipop (Gravy)',
    category: 'Starters',
    portions: [Portion('3 pcs', 90), Portion('6 pcs', 160)],
  ),
  MenuItem(
    id: 'lollipop_extra',
    name: 'Extra Lollipop Piece',
    category: 'Starters',
    portions: [Portion('1 pc', 40)],
  ),

  // ---- Rice ----
  MenuItem(
    id: 'veg_fried_rice',
    name: 'Veg Fried Rice',
    category: 'Rice',
    portions: [Portion('Half', 60), Portion('Full', 110)],
    hasStyle: true,
  ),
  MenuItem(
    id: 'egg_fried_rice',
    name: 'Egg Fried Rice',
    category: 'Rice',
    portions: [Portion('Half', 60), Portion('Full', 110)],
    hasStyle: true,
  ),
  MenuItem(
    id: 'chicken_fried_rice',
    name: 'Chicken Fried Rice',
    category: 'Rice',
    portions: [Portion('Half', 60), Portion('Full', 110)],
    hasStyle: true,
  ),
  MenuItem(
    id: 'chicken_combination_rice',
    name: 'Chicken Combination Rice',
    category: 'Rice',
    portions: [Portion('Half', 60), Portion('Full', 110)],
    hasStyle: true,
  ),
  MenuItem(
    id: 'chicken_triple_rice',
    name: 'Chicken Triple Rice',
    category: 'Rice',
    portions: [Portion('Half', 100), Portion('Full', 180)],
    hasStyle: true,
  ),
  MenuItem(
    id: 'veg_triple_rice',
    name: 'Veg Triple Rice',
    category: 'Rice',
    portions: [Portion('Half', 100), Portion('Full', 180)],
    hasStyle: true,
  ),

  // ---- Noodles ----
  MenuItem(
    id: 'veg_noodles',
    name: 'Veg Noodles',
    category: 'Noodles',
    portions: [Portion('Half', 60), Portion('Full', 110)],
    hasStyle: true,
  ),
  MenuItem(
    id: 'chicken_noodles',
    name: 'Chicken Noodles',
    category: 'Noodles',
    portions: [Portion('Half', 60), Portion('Full', 110)],
    hasStyle: true,
  ),

  // ---- Soup ----
  MenuItem(
    id: 'tomato_soup',
    name: 'Tomato Soup',
    category: 'Soup',
    portions: [Portion('Half', 50), Portion('Full', 80)],
  ),
  MenuItem(
    id: 'veg_soup',
    name: 'Veg Soup',
    category: 'Soup',
    portions: [Portion('Half', 50), Portion('Full', 80)],
  ),
  MenuItem(
    id: 'chicken_soup',
    name: 'Chicken Soup',
    category: 'Soup',
    portions: [Portion('Half', 50), Portion('Full', 80)],
  ),
];
