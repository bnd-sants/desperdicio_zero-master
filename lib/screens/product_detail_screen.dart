import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/product_model.dart';
import 'package:desperdicio_zero/core/providers/products/product_provider.dart';
import 'package:desperdicio_zero/core/providers/auth/auth_provider.dart';

class ProductDetailScreen extends ConsumerWidget {
  final Product product;
  final VoidCallback onEdit;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onEdit,
  });

  // Função para confirmar a exclusão do produto
  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text('Tem certeza que deseja excluir este produto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(productsProvider.notifier).removeProduct(product.id);
        if (context.mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Produto excluído com sucesso!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao excluir produto: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authNotifierProvider);
    String? currentUserId;
    if (authState is Authenticated) {
      currentUserId = authState.user.id;
    }
    final canEdit = currentUserId != null && currentUserId == product.userId;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Produto'),
        actions: [
          if (canEdit) ...[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              tooltip: 'Editar produto',
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _confirmDelete(context, ref),
              tooltip: 'Excluir produto',
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _buildInfoRow('Tipo:', product.type ?? 'Não informado'),
            _buildInfoRow('Quantidade:', '${product.quantity} ${product.unit}'),
            if (product.brand != null) _buildInfoRow('Marca:', product.brand!),
            if (product.store != null) _buildInfoRow('Loja:', product.store!),
            if (product.price != null) _buildInfoRow('Preço:', 'R\$ ${product.price!.toStringAsFixed(2)}'),
            if (product.purchaseDate != null) 
              _buildInfoRow('Data de Compra:', _formatDate(product.purchaseDate!)),
            if (product.expirationDate != null)
              _buildInfoRow('Data de Validade:', _formatDate(product.expirationDate!)),
            const SizedBox(height: 24),
            if (product.expirationDate != null)
              _buildExpirationStatus(context, product.expirationDate!),
            
            // Botão de ação para marcar como consumido
            if (canEdit)
              Column(
                children: [
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          // Marca o produto como consumido (remove do banco)
                          await ref.read(productsProvider.notifier).removeProduct(product.id);
                          if (context.mounted) {
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Produto marcado como consumido!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro ao marcar como consumido: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: const Text('Marcar como Consumido'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildExpirationStatus(BuildContext context, DateTime expirationDate) {
    final now = DateTime.now();
    final difference = expirationDate.difference(now);
    final days = difference.inDays;
    
    Color statusColor;
    String statusText;
    
    if (days < 0) {
      statusColor = Colors.red;
      statusText = 'Vencido há ${-days} dias';
    } else if (days == 0) {
      statusColor = Colors.orange;
      statusText = 'Vence hoje!';
    } else if (days <= 3) {
      statusColor = Colors.orange;
      statusText = 'Vence em $days dias';
    } else {
      statusColor = Colors.green;
      statusText = 'Vence em $days dias';
    }
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(Icons.calendar_today, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              statusText,
              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}
