import 'package:flutter/material.dart';

import '../models/product_model.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 0,
        title: const Row(
          children: [
            BrandLogo(size: 34),
            SizedBox(width: 10),
            Text('Producto', style: TextStyle(fontWeight: FontWeight.w900)),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ProductHero(product: product),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((product.categoryName ?? '').trim().isNotEmpty)
                        Text(
                          product.categoryName?.trim() ?? '',
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      const SizedBox(height: 6),
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 28,
                          height: 1.05,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Pill(
                            label: product.available
                                ? 'Disponible'
                                : 'Sin stock',
                            icon: product.available
                                ? Icons.check_circle_rounded
                                : Icons.cancel_rounded,
                            color: product.available
                                ? AppColors.deepGreen
                                : AppColors.red,
                            background: product.available
                                ? AppColors.softGreen
                                : AppColors.softRed,
                          ),
                          if (product.requiresPrescription)
                            const _Pill(
                              label: 'Requiere receta',
                              icon: Icons.description_rounded,
                              color: AppColors.red,
                              background: AppColors.softRed,
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        product.formattedPrice,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        (product.description ?? '').trim().isNotEmpty
                            ? product.description?.trim() ?? product.summary
                            : product.summary,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 16,
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CustomerInfoPanel(product: product),
        ],
      ),
    );
  }
}

class _ProductHero extends StatelessWidget {
  final Product product;

  const _ProductHero({required this.product});

  @override
  Widget build(BuildContext context) {
    final url = product.displayImageUrl;

    return Container(
      height: 260,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        color: AppColors.softGreen,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: url.isEmpty
          ? const Icon(
              Icons.medication_rounded,
              color: AppColors.green,
              size: 96,
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              cacheWidth: 900,
              cacheHeight: 520,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator());
              },
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.medication_rounded,
                  color: AppColors.green,
                  size: 96,
                );
              },
            ),
    );
  }
}

class _CustomerInfoPanel extends StatelessWidget {
  final Product product;

  const _CustomerInfoPanel({required this.product});

  @override
  Widget build(BuildContext context) {
    final items = [
      _InfoItem(
        'Presentacion',
        product.presentation,
        Icons.inventory_2_rounded,
      ),
      _InfoItem(
        'Tipo de producto',
        product.pharmaceuticalForm,
        Icons.medication_liquid_rounded,
      ),
      _InfoItem('Laboratorio', product.laboratory, Icons.apartment_rounded),
    ].where((item) => (item.value ?? '').trim().isNotEmpty).toList();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detalles para comprar',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          if (items.isEmpty)
            const Text(
              'No hay más detalles disponibles para este producto.',
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            )
          else
            ...items.map((item) => _DetailRow(item: item)),
        ],
      ),
    );
  }
}

class _InfoItem {
  final String title;
  final String? value;
  final IconData icon;

  _InfoItem(this.title, this.value, this.icon);
}

class _DetailRow extends StatelessWidget {
  final _InfoItem item;

  const _DetailRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final value = item.value?.trim() ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: AppColors.softGreen,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: AppColors.green, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color background;

  const _Pill({
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
