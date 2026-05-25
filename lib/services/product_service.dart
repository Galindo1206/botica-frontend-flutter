import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/product_model.dart';
import '../utils/api_config.dart';

class ProductService {
  Future<List<Product>> getProducts(String token) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/products');

    final response = await http.get(
      url,
      headers: {'Accept': 'application/json', 'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List productsJson = data;

      return productsJson.map((json) => Product.fromJson(json)).toList();
    } else {
      throw Exception('Error al cargar productos');
    }
  }
}
