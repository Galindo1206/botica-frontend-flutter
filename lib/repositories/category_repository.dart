import '../core/network/api_client.dart';

class CategoryRepository {
  final ApiClient _apiClient;

  CategoryRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<String>> getCategories() async {
    final data = await _apiClient.get('/categories', authenticated: false);
    final categoriesJson = data is Map<String, dynamic> ? data['data'] : data;

    if (categoriesJson is! List) return [];

    final names =
        categoriesJson
            .whereType<Map<String, dynamic>>()
            .where((category) => category['is_active'] != false)
            .map((category) => category['name']?.toString().trim() ?? '')
            .where((name) => name.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    return names;
  }
}
