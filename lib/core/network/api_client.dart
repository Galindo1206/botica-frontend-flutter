import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../utils/api_config.dart';
import '../session/session_manager.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _httpClient;
  final SessionManager _sessionManager;

  ApiClient({http.Client? httpClient, SessionManager? sessionManager})
    : _httpClient = httpClient ?? http.Client(),
      _sessionManager = sessionManager ?? SessionManager();

  Future<dynamic> get(String path, {bool authenticated = true}) {
    return _send(
      (uri, headers) => _httpClient.get(uri, headers: headers),
      path,
      authenticated: authenticated,
    );
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) {
    return _send(
      (uri, headers) => _httpClient.post(
        uri,
        headers: headers,
        body: body == null ? null : jsonEncode(body),
      ),
      path,
      authenticated: authenticated,
    );
  }

  Future<dynamic> _send(
    Future<http.Response> Function(Uri uri, Map<String, String> headers)
    request,
    String path, {
    required bool authenticated,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path');
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated) {
      final token = await _sessionManager.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    late final http.Response response;
    try {
      response = await request(
        uri,
        headers,
      ).timeout(const Duration(seconds: 10));
    } on FormatException {
      throw const ApiException('La respuesta del servidor no es valida');
    } on http.ClientException {
      throw const ApiException(
        'No se pudo conectar con el servidor. Revisa la URL de la API o CORS.',
      );
    } catch (_) {
      throw const ApiException(
        'No se pudo conectar con el servidor. Intenta nuevamente.',
      );
    }

    final decodedBody = _decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    if (response.statusCode == 401) {
      await _sessionManager.clearSession();
    }

    throw ApiException(
      _readErrorMessage(decodedBody),
      statusCode: response.statusCode,
      errors: decodedBody is Map<String, dynamic>
          ? decodedBody['errors'] as Map<String, dynamic>?
          : null,
    );
  }

  dynamic _decode(String body) {
    if (body.trim().isEmpty) return null;
    try {
      return jsonDecode(body);
    } on FormatException {
      throw const ApiException('La respuesta del servidor no es JSON valido');
    }
  }

  String _readErrorMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final message = body['message'];
      if (message != null) return message.toString();

      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final firstError = errors.values.first;
        if (firstError is List && firstError.isNotEmpty) {
          return firstError.first.toString();
        }
        return firstError.toString();
      }
    }

    return 'No se pudo completar la solicitud';
  }
}
