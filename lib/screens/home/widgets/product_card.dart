import 'package:flutter/material.dart';
import '../../../models/product_model.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Quantidade: ${product.quantity} ${product.unit}',
                    style: const TextStyle(fontSize: 14),
                  ),
                  if (product.expirationDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Validade: ${_formatDate(product.expirationDate!)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ],
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }
}
