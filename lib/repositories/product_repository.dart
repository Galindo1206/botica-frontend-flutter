import '../core/network/api_client.dart';
import '../models/product_model.dart';

class ProductRepository {
  final ApiClient _apiClient;

  ProductRepository({ApiClient? apiClient})
    : _apiClient = apiClient ?? ApiClient();

  Future<List<Product>> getProducts() async {
    final data = await _apiClient.get('/products');
    final productsJson = data is Map<String, dynamic> ? data['data'] : data;

    if (productsJson is! List) return [];

    return productsJson
        .whereType<Map<String, dynamic>>()
        .map(Product.fromJson)
        .toList();
  }
}
