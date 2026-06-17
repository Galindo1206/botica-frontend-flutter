import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const _tokenKey = 'token';
  static const _emailKey = 'user_email';
  static const _nameKey = 'user_name';
  static const _knownEmailsKey = 'known_emails';

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<bool> get isLoggedIn async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nameKey);
  }

  Future<void> saveSession({
    required String token,
    String? email,
    String? name,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);

    if (email != null && email.trim().isNotEmpty) {
      final normalizedEmail = email.trim().toLowerCase();
      await prefs.setString(_emailKey, normalizedEmail);
      await rememberEmail(normalizedEmail);
    }

    if (name != null && name.trim().isNotEmpty) {
      await prefs.setString(_nameKey, name.trim());
    }
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
  }

  Future<void> rememberEmail(String email) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (normalizedEmail.isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final emails = prefs.getStringList(_knownEmailsKey) ?? [];

    if (!emails.contains(normalizedEmail)) {
      emails.add(normalizedEmail);
      await prefs.setStringList(_knownEmailsKey, emails);
    }
  }
}
