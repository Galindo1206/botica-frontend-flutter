class Product {
  final int id;
  final String name;
  final String? description;
  final String? barcode;
  final String? imagePath;
  final int stock;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.barcode,
    this.imagePath,
    required this.stock,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      name: json['name'] ?? '',
      description: json['description'],
      barcode: json['barcode'],
      imagePath: json['image_path'],
      stock: json['stock'] ?? 0,
    );
  }
}
