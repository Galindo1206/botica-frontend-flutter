import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/product_model.dart';
import '../services/product_service.dart';
import 'product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ProductService productService = ProductService();
  final TextEditingController searchController = TextEditingController();

  List<Product> products = [];
  List<Product> filteredProducts = [];

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    loadProducts();

    searchController.addListener(() {
      filterProducts(searchController.text);
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> loadProducts() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'No hay token guardado';
        });
        return;
      }

      final result = await productService.getProducts(token);

      setState(() {
        products = result;
        filteredProducts = result;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error al cargar productos';
      });

      print('Error productos: $e');
    }
  }

  void filterProducts(String query) {
    final text = query.toLowerCase().trim();

    setState(() {
      if (text.isEmpty) {
        filteredProducts = products;
      } else {
        filteredProducts = products.where((product) {
          final name = product.name.toLowerCase();
          final description = product.description?.toLowerCase() ?? '';
          final barcode = product.barcode?.toLowerCase() ?? '';

          return name.contains(text) ||
              description.contains(text) ||
              barcode.contains(text);
        }).toList();
      }
    });
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');

    if (!mounted) return;

    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWideScreen = width >= 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Medicamentos'),
        actions: [
          IconButton(onPressed: loadProducts, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isWideScreen ? 900 : double.infinity,
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: buildBody(isWideScreen),
          ),
        ),
      ),
    );
  }

  Widget buildBody(bool isWideScreen) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(child: Text(errorMessage!));
    }

    return Column(
      children: [
        TextField(
          controller: searchController,
          decoration: InputDecoration(
            hintText: 'Buscar medicamento...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            '${filteredProducts.length} medicamento(s) encontrado(s)',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),

        const SizedBox(height: 12),

        Expanded(
          child: filteredProducts.isEmpty
              ? const Center(child: Text('No se encontraron medicamentos'))
              : isWideScreen
              ? buildGrid()
              : buildList(),
        ),
      ],
    );
  }

  Widget buildList() {
    return ListView.builder(
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return ProductCard(product: product);
      },
    );
  }

  Widget buildGrid() {
    return GridView.builder(
      itemCount: filteredProducts.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.4,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return ProductCard(product: product);
      },
    );
  }
}

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1.5,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailScreen(product: product),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: (product.imagePath ?? '').isNotEmpty
              ? Image.asset(
                  'assets/images/${product.imagePath}',
                  width: 55,
                  height: 55,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.medication, size: 40);
                  },
                )
              : const Icon(Icons.medication, size: 40),
        ),
        title: Text(
          product.name,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.description ?? 'Sin descripción',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              const SizedBox(height: 6),

              Text(
                'Stock: ${product.stock}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        trailing: product.barcode == null || product.barcode!.isEmpty
            ? null
            : Text(
                product.barcode!,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
      ),
    );
  }
}
