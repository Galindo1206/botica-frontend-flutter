import '../repositories/category_repository.dart';

class CategoryService {
  final CategoryRepository _categoryRepository;

  CategoryService({CategoryRepository? categoryRepository})
    : _categoryRepository = categoryRepository ?? CategoryRepository();

  Future<List<String>> getCategories() => _categoryRepository.getCategories();
}
