import '../utils/api_config.dart';

class Product {
  final int id;
  final int? categoryId;
  final String name;
  final String? genericName;
  final String? concentration;
  final String? pharmaceuticalForm;
  final String? presentation;
  final String? laboratory;
  final String? description;
  final String? barcode;
  final String? healthRegistration;
  final String? imagePath;
  final String? imageUrl;
  final String? categoryName;
  final double price;
  final int stock;
  final bool requiresPrescription;
  final bool isActive;

  Product({
    required this.id,
    this.categoryId,
    required this.name,
    this.genericName,
    this.concentration,
    this.pharmaceuticalForm,
    this.presentation,
    this.laboratory,
    this.description,
    this.barcode,
    this.healthRegistration,
    this.imagePath,
    this.imageUrl,
    this.categoryName,
    required this.price,
    required this.stock,
    required this.requiresPrescription,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    final category = json['category'];

    return Product(
      id: _parseInt(json['id']),
      categoryId: _nullableInt(json['category_id']),
      name: json['name']?.toString() ?? '',
      genericName: json['generic_name']?.toString(),
      concentration: json['concentration']?.toString(),
      pharmaceuticalForm: json['pharmaceutical_form']?.toString(),
      presentation: json['presentation']?.toString(),
      laboratory: json['laboratory']?.toString(),
      description: json['description']?.toString(),
      barcode: json['barcode']?.toString(),
      healthRegistration: json['health_registration']?.toString(),
      imagePath: json['image_path']?.toString(),
      imageUrl: json['image_url']?.toString(),
      categoryName: category is Map<String, dynamic>
          ? category['name']?.toString()
          : null,
      price: _parsePrice(json['sale_price'] ?? json['price'] ?? json['precio']),
      stock: _parseInt(json['stock']),
      requiresPrescription: _parseBool(json['requires_prescription']),
      isActive: _parseBool(json['is_active'], defaultValue: true),
    );
  }

  String get formattedPrice => 'S/ ${price.toStringAsFixed(2)}';

  String get displayImageUrl {
    final directUrl = imageUrl?.trim();
    if (directUrl != null && directUrl.isNotEmpty) return directUrl;

    final path = imagePath?.trim();
    if (path == null || path.isEmpty) return '';
    return ApiConfig.storageUrl(path);
  }

  String get summary {
    final parts = [
      genericName,
      concentration,
      pharmaceuticalForm,
      presentation,
    ].where((part) => (part ?? '').trim().isNotEmpty).join(' - ');

    return parts.isNotEmpty ? parts : (description ?? 'Producto de farmacia');
  }

  String get customerSubtitle {
    final parts = [presentation, laboratory]
        .map((part) => part?.trim() ?? '')
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isNotEmpty) return parts.join(' - ');
    return pharmaceuticalForm?.trim() ?? '';
  }

  bool get available => isActive && stock > 0;

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    return _parseInt(value);
  }

  static double _parsePrice(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static bool _parseBool(dynamic value, {bool defaultValue = false}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      return ['1', 'true', 'yes', 'si'].contains(value.toLowerCase());
    }
    return defaultValue;
  }
}
