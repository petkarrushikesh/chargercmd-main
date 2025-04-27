import 'package:flutter/material.dart';
import 'package:flutter_ble/splash_screen.dart';
import 'scan_devices_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Bluetooth Charger Control',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: SplashScreen(), //
    );
  }
}
