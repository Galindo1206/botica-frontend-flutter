import 'package:flutter/material.dart';

import '../core/network/api_exception.dart';
import '../repositories/auth_repository.dart';
import '../routes/app_routes.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final AuthRepository authRepository = AuthRepository();
  bool isLoading = false;
  bool obscurePassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showMessage('Completa todos los campos');
      return;
    }

    if (!_isStrongPassword(password)) {
      _showMessage('Usa 8 caracteres, una mayuscula y un numero');
      return;
    }

    if (password != confirmPassword) {
      _showMessage('Las contrasenas no coinciden');
      return;
    }

    setState(() => isLoading = true);

    try {
      await authRepository.register(name, email, password);
      await authRepository.sendVerificationCode(email);

      if (!mounted) return;
      _showMessage('Cuenta creada. Revisa tu correo.');
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.verifyEmail,
        arguments: email,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      if (_isExistingEmailError(error)) {
        await _sendCodeAndOpenVerification(email);
        return;
      }
      _showMessage(error.message);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool _isExistingEmailError(ApiException error) {
    final emailErrors = error.errors?['email'];
    final hasEmailError = emailErrors is List && emailErrors.isNotEmpty;

    return error.statusCode == 422 &&
        (hasEmailError ||
            error.message.toLowerCase().contains('email') ||
            error.message.toLowerCase().contains('correo'));
  }

  Future<void> _sendCodeAndOpenVerification(String email) async {
    try {
      await authRepository.sendVerificationCode(email);

      if (!mounted) return;
      _showMessage('La cuenta ya existe. Te enviamos un codigo nuevo.');
      Navigator.pushReplacementNamed(
        context,
        AppRoutes.verifyEmail,
        arguments: email,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      _showMessage(error.message);
    }
  }

  bool _isStrongPassword(String password) {
    return password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.center,
                        child: BrandLogo(size: 72, elevated: true),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Registrate como cliente',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tu cuenta se creara con rol Cliente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.muted),
                      ),
                      const SizedBox(height: 22),
                      _RegisterField(
                        controller: nameController,
                        label: 'Nombre completo',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 14),
                      _RegisterField(
                        controller: emailController,
                        label: 'Correo electronico',
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 14),
                      _RegisterField(
                        controller: passwordController,
                        label: 'Contrasena',
                        icon: Icons.lock_outline_rounded,
                        obscureText: obscurePassword,
                        suffixIcon: IconButton(
                          tooltip: obscurePassword
                              ? 'Mostrar contrasena'
                              : 'Ocultar contrasena',
                          onPressed: () {
                            setState(() {
                              obscurePassword = !obscurePassword;
                            });
                          },
                          icon: Icon(
                            obscurePassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      _RegisterField(
                        controller: confirmPasswordController,
                        label: 'Confirmar contrasena',
                        icon: Icons.lock_reset_rounded,
                        obscureText: obscureConfirmPassword,
                        suffixIcon: IconButton(
                          tooltip: obscureConfirmPassword
                              ? 'Mostrar contrasena'
                              : 'Ocultar contrasena',
                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      ElevatedButton(
                        onPressed: isLoading ? null : register,
                        child: isLoading
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.4,
                                ),
                              )
                            : const Text('Crear cuenta'),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.pushReplacementNamed(
                                context,
                                AppRoutes.login,
                              ),
                        child: const Text('Ya tengo cuenta'),
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

class _RegisterField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _RegisterField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
      ),
    );
  }
}
