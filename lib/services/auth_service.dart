import '../core/network/api_exception.dart';
import '../repositories/auth_repository.dart';

class AuthService {
  final AuthRepository _authRepository;

  AuthService({AuthRepository? authRepository})
    : _authRepository = authRepository ?? AuthRepository();

  Future<String?> login(String email, String password) async {
    try {
      final result = await _authRepository.login(email, password);
      return result.token;
    } on ApiException {
      return null;
    }
  }

  Future<String?> register(String name, String email, String password) async {
    try {
      final result = await _authRepository.register(name, email, password);
      return result.token;
    } on ApiException {
      return null;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      await _authRepository.forgotPassword(email);
      return true;
    } on ApiException {
      return false;
    }
  }
}
