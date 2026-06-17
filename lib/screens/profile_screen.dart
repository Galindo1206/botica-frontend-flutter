import 'package:flutter/material.dart';

import '../core/session/session_manager.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SessionManager sessionManager = SessionManager();

  String? name;
  String? email;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    final userName = await sessionManager.getUserName();
    final userEmail = await sessionManager.getUserEmail();

    if (!mounted) return;
    setState(() {
      name = userName;
      email = userEmail;
      isLoading = false;
    });
  }

  String get displayName {
    final value = name?.trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Usuario';
  }

  String get displayEmail {
    final value = email?.trim();
    if (value != null && value.isNotEmpty) return value;
    return 'Correo no disponible';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Row(
          children: [
            BrandLogo(size: 34),
            SizedBox(width: 10),
            Text('Mi perfil', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: AppColors.softGreen,
                          child: Text(
                            displayName.characters.first.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          displayName,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          displayEmail,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ProfileInfoTile(
                    icon: Icons.person_rounded,
                    label: 'Nombre',
                    value: displayName,
                  ),
                  _ProfileInfoTile(
                    icon: Icons.email_rounded,
                    label: 'Correo',
                    value: displayEmail,
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.softGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: AppColors.green),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
