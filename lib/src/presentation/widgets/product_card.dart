import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../platform/platform_image_provider.dart';
import '../utils/formatters.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onAdd,
    required this.onEdit,
    required this.adminMode,
  });

  final Product product;
  final VoidCallback onAdd;
  final VoidCallback onEdit;
  final bool adminMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: product.isOutOfStock ? null : onAdd,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Positioned.fill(child: _ProductVisual(product: product)),
                    if (product.isOutOfStock)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: _StatusBadge(
                          label: 'Out of Stock',
                          color: Color(0xFFB42318),
                        ),
                      )
                    else if (product.isLowStock)
                      const Positioned(
                        top: 8,
                        right: 8,
                        child: _StatusBadge(
                          label: 'Low Stock',
                          color: Color(0xFFD97706),
                        ),
                      ),
                    if (adminMode)
                      Positioned(
                        left: 8,
                        top: 8,
                        child: IconButton.filledTonal(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: 'Edit product',
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                product.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                product.sku ?? 'No SKU',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF475569),
                ),
              ),
              const Spacer(),
              Row(
                children: [
                  Text(
                    currencyFormatter.format(product.price),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Stock ${product.stockQuantity}',
                    style: theme.textTheme.labelMedium,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductVisual extends StatelessWidget {
  const _ProductVisual({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final provider = imageProviderForPath(product.imagePath);
    if (provider != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image(
          image: provider,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFDCEFEA), Color(0xFFF5DAB0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 40,
          color: Color(0xFF0F172A),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}
