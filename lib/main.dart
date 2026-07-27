import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/order_store.dart';
import 'screens/orders_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await OrderStore.instance.load();
  runApp(const OrderControlApp());
}

class OrderControlApp extends StatelessWidget {
  const OrderControlApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Order Control',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const OrdersScreen(),
    );
  }
}
