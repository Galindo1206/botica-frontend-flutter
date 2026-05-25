import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const FarmaciaApp());
}

class FarmaciaApp extends StatelessWidget {
  const FarmaciaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Farmacia App',
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
