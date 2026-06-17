import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../repositories/auth_repository.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

class EmailVerificationScreen extends StatefulWidget {
  const EmailVerificationScreen({super.key});

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final codeController = TextEditingController();
  final authRepository = AuthRepository();

  bool isLoading = false;
  bool isSending = false;
  String? email;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    email ??= ModalRoute.of(context)?.settings.arguments as String?;
  }

  @override
  void dispose() {
    codeController.dispose();
    super.dispose();
  }

  Future<void> sendCode() async {
    final currentEmail = email;
    if (currentEmail == null || currentEmail.isEmpty) return;

    setState(() => isSending = true);

    try {
      await authRepository.sendVerificationCode(currentEmail);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Codigo enviado al correo')));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  Future<void> verify() async {
    final currentEmail = email;
    final code = codeController.text.trim();

    if (currentEmail == null || currentEmail.isEmpty || code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el código de verificación')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      await authRepository.verifyEmail(currentEmail, code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo verificado. Ahora inicia sesión.'),
        ),
      );
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.login,
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Verificar correo'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Align(
                        alignment: Alignment.center,
                        child: BrandLogo(size: 72, elevated: true),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'Codigo de verificacion',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        email == null
                            ? 'Ingresa el código enviado a tu correo.'
                            : 'Ingresa el código enviado a $email.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: codeController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Codigo',
                          prefixIcon: Icon(Icons.pin_outlined),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : verify,
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text('Verificar correo'),
                        ),
                      ),
                      TextButton(
                        onPressed: isSending ? null : sendCode,
                        child: Text(
                          isSending ? 'Enviando...' : 'Reenviar código',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
