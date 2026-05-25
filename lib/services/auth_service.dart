import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/api_config.dart';

class AuthService {
  Future<String?> login(String email, String password) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/login');

    final response = await http.post(
      url,
      headers: {'Accept': 'application/json'},
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      return data['token'];
    } else {
      return null;
    }
  }
}
