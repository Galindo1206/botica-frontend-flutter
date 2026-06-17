import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import '../core/session/session_manager.dart';
import '../models/user_model.dart';

class AuthResult {
  final String? token;
  final User? user;

  const AuthResult({this.token, this.user});
}

class AuthRepository {
  final ApiClient _apiClient;
  final SessionManager _sessionManager;

  AuthRepository({ApiClient? apiClient, SessionManager? sessionManager})
    : _apiClient = apiClient ?? ApiClient(sessionManager: sessionManager),
      _sessionManager = sessionManager ?? SessionManager();

  Future<AuthResult> login(String email, String password) async {
    final data = await _apiClient.post(
      '/login',
      body: {'email': email, 'password': password},
    );

    final result = _readAuthResult(data);
    final token = result.token;
    if (token == null || token.isEmpty) {
      throw const ApiException('El servidor no devolvió un token de sesión');
    }

    await _sessionManager.saveSession(
      token: token,
      email: result.user?.email ?? email,
      name: result.user?.name,
    );

    return result;
  }

  Future<AuthResult> register(
    String name,
    String email,
    String password,
  ) async {
    final data = await _apiClient.post(
      '/register',
      body: {
        'name': name,
        'email': email,
        'password': password,
        'password_confirmation': password,
      },
    );

    await _sessionManager.rememberEmail(email);
    return _readAuthResult(data);
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/logout-all', authenticated: true);
    } finally {
      await _sessionManager.clearSession();
    }
  }

  Future<void> sendVerificationCode(String email) async {
    await _apiClient.post('/send-verification-code', body: {'email': email});
  }

  Future<void> verifyEmail(String email, String code) async {
    await _apiClient.post(
      '/verify-email',
      body: {'email': email, 'code': code},
    );
  }

  Future<void> forgotPassword(String email) async {
    await _apiClient.post('/forgot-password', body: {'email': email});
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String password,
  }) async {
    await _apiClient.post(
      '/reset-password',
      body: {
        'email': email,
        'code': code,
        'password': password,
        'password_confirmation': password,
      },
    );
  }

  AuthResult _readAuthResult(dynamic data) {
    if (data is! Map<String, dynamic>) return const AuthResult();

    final rootToken = data['token'] ?? data['access_token'];
    final nestedData = data['data'];
    final nestedToken = nestedData is Map<String, dynamic>
        ? nestedData['token'] ?? nestedData['access_token']
        : null;

    final userJson =
        data['user'] ??
        (nestedData is Map<String, dynamic> ? nestedData['user'] : null);

    return AuthResult(
      token: (rootToken ?? nestedToken)?.toString(),
      user: userJson is Map<String, dynamic> ? User.fromJson(userJson) : null,
    );
  }
}
