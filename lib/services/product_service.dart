import '../models/product_model.dart';
import '../repositories/product_repository.dart';

class ProductService {
  final ProductRepository _productRepository;

  ProductService({ProductRepository? productRepository})
    : _productRepository = productRepository ?? ProductRepository();

  Future<List<Product>> getProducts() => _productRepository.getProducts();
}
