import 'package:flutter/material.dart';

import '../core/session/session_manager.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final sessionManager = SessionManager();
  bool visible = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => setState(() => visible = true));
    checkLogin();
  }

  Future<void> checkLogin() async {
    await Future.delayed(const Duration(milliseconds: 1300));
    final isLoggedIn = await sessionManager.isLoggedIn;

    if (!mounted) return;
    Navigator.pushReplacementNamed(
      context,
      isLoggedIn ? AppRoutes.home : AppRoutes.login,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green,
      body: Center(
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: const Duration(milliseconds: 520),
          curve: Curves.easeOut,
          child: AnimatedScale(
            scale: visible ? 1 : 0.92,
            duration: const Duration(milliseconds: 520),
            curve: Curves.easeOutBack,
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                BrandLogo(size: 126, elevated: true),
                SizedBox(height: 24),
                Text(
                  'KunanApp',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Salud clara, rápida y cerca de ti',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
