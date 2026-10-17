import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/core/ble_connection.dart';
import 'package:app/core/ble_handler.dart';
import 'package:app/core/app_state.dart';
import 'package:app/core/notification_service.dart';
import 'package:app/ui/widgets/bottom_navigation_bar.dart'; // CustomBottomNav
import 'package:permission_handler/permission_handler.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => BLEController()),
        ChangeNotifierProxyProvider<BLEController, BLEConnectionController>(
          create: (_) => BLEConnectionController(),
          update: (_, bleCtrl, bleConnCtrl) {
            bleConnCtrl ??= BLEConnectionController();
            bleConnCtrl.injectBLEController(bleCtrl);
            return bleConnCtrl;
          },
        ),
        ChangeNotifierProvider(create: (_) => AppState()),  // 👈 NECESSARIO!
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Somministrazione Insulina',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: CustomBottomNav(currentIndex: 0),  // 👈 Home inizia da qui
    );
  }
}
