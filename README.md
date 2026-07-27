# Order Control

An Android order board for a small Chinese food shop. Built for speed at the counter: every live order sits on one screen, and every status change is a single tap.

Offline by design. All data lives in a local SQLite database on the phone, so there is no login, no internet and no monthly bill.

## What it does

**The board** shows every running order as a card. Each card carries the order number, how long it has been waiting, the items, the note, the total, and three buttons:

| Button | Meaning |
| --- | --- |
| READY | Kitchen has finished the food |
| PAID | Money has been collected |
| DONE | Order is closed and leaves the board |

The card border is orange while the kitchen still has it and turns green once it is ready. An order that has been waiting fifteen minutes or more shows its waiting time in red. Marking an order DONE puts an UNDO in reach for a few seconds, so a mistap costs nothing.

A strip at the top of the board keeps a running count of how many orders are cooking, how many are unpaid, and how much the shop has taken today.

**Taking an order** is a grid of dishes grouped by Starters, Rice, Noodles and Soup. Tap a dish, tap the portion, and it is on the order. Rice and noodles ask Plain or Schezwan first. Dishes already on the order carry a quantity badge, so it is obvious what has been added. The bar at the bottom always shows the item count and running total, and opens the full list where quantities can be changed and a note added.

**The day book** lists the day's orders with the money earned and still pending, and steps back through earlier days. Tapping an order lets it be marked paid, put back on the board, or deleted.

## The menu

Prices are half / full unless the labels say otherwise.

### Starters

| Dish | Half | Full |
| --- | --- | --- |
| Veg Manchurian | 60 | 100 |
| Veg Chilli | 60 | 100 |
| Chicken Manchurian | 80 | 130 |
| Chicken Chilli | 80 | 130 |
| Chicken Crispy | 100 | 150 |
| Chicken Lollipop (Oil Fried) | 80 (3 pcs) | 150 (6 pcs) |
| Chicken Lollipop (Gravy) | 90 (3 pcs) | 160 (6 pcs) |
| Extra Lollipop Piece | 40 each | |

### Rice

Every rice comes Plain or Schezwan at the same price.

| Dish | Half | Full |
| --- | --- | --- |
| Veg Fried Rice | 60 | 110 |
| Egg Fried Rice | 60 | 110 |
| Chicken Fried Rice | 60 | 110 |
| Chicken Combination Rice | 60 | 110 |
| Chicken Triple Rice | 100 | 180 |
| Veg Triple Rice | 100 | 180 |

### Noodles

Plain or Schezwan, same price.

| Dish | Half | Full |
| --- | --- | --- |
| Veg Noodles | 60 | 110 |
| Chicken Noodles | 60 | 110 |

### Soup

| Dish | Half | Full |
| --- | --- | --- |
| Tomato Soup | 50 | 80 |
| Veg Soup | 50 | 80 |
| Chicken Soup | 50 | 80 |

To change a price or add a dish, edit [lib/data/menu_data.dart](lib/data/menu_data.dart). Orders store their own copy of the name, portion and price at the moment they are taken, so past totals stay correct after a price change.

## A note on the day

The shop runs past midnight, so a business day is counted from 5 AM to 5 AM. An order taken at 1 AM belongs to the night before, and order numbers restart at 1 with each new business day.

## Building it

Needs the Flutter SDK and the Android toolchain.

```bash
flutter pub get
flutter test
flutter build apk --release
```

The APK lands in `build/app/outputs/flutter-apk/app-release.apk`. Copy it to the phone and install.

To run it on a connected phone while developing:

```bash
flutter run
```

## Layout

```
lib/
  main.dart                     app entry
  theme.dart                    dark palette and status colours
  models/
    menu_item.dart              dish, portions, Plain or Schezwan flag
    order.dart                  order, order line, business day rule
  data/
    menu_data.dart              the shop menu
    database.dart               SQLite tables and queries
    order_store.dart            single source of truth for the screens
  screens/
    orders_screen.dart          the board
    order_editor_screen.dart    take and edit an order
    history_screen.dart         the day book
  widgets/
    order_card.dart             one order on the board
    status_button.dart          Ready, Paid and Done toggle
test/
  order_test.dart               totals, line merging, day rollover
```

## Stack

Flutter 3.38, Dart 3.10, sqflite for local storage, intl for dates. No backend, no accounts, no network permission.
