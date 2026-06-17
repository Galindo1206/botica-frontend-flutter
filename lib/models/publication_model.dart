import '../utils/api_config.dart';
import 'product_model.dart';

class Publication {
  final int id;
  final String title;
  final String? description;
  final String? imagePath;
  final String? imageUrl;
  final String type;
  final int? productId;
  final int? categoryId;
  final Product? product;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final int sortOrder;
  final bool isActive;

  const Publication({
    required this.id,
    required this.title,
    this.description,
    this.imagePath,
    this.imageUrl,
    required this.type,
    this.productId,
    this.categoryId,
    this.product,
    this.startsAt,
    this.endsAt,
    required this.sortOrder,
    required this.isActive,
  });

  factory Publication.fromJson(Map<String, dynamic> json) {
    return Publication(
      id: _parseInt(json['id']),
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      imagePath: json['image_path']?.toString(),
      imageUrl: json['image_url']?.toString(),
      type: json['type']?.toString() ?? 'announcement',
      productId: _nullableInt(json['product_id']),
      categoryId: _nullableInt(json['category_id']),
      product: json['product'] is Map<String, dynamic>
          ? Product.fromJson(json['product'])
          : null,
      startsAt: _parseDate(json['starts_at']),
      endsAt: _parseDate(json['ends_at']),
      sortOrder: _parseInt(json['sort_order']),
      isActive: _parseBool(json['is_active'], defaultValue: true),
    );
  }

  String get displayImageUrl {
    final directUrl = imageUrl?.trim();
    if (directUrl != null && directUrl.isNotEmpty) return directUrl;

    final path = imagePath?.trim();
    if (path == null || path.isEmpty) return '';
    return ApiConfig.storageUrl(path);
  }

  String get typeLabel {
    return switch (type) {
      'offer' => 'Oferta',
      'news' => 'Novedad',
      'campaign' => 'Campana',
      _ => 'Anuncio',
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value') ?? 0;
  }

  static int? _nullableInt(dynamic value) {
    if (value == null) return null;
    return _parseInt(value);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
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
