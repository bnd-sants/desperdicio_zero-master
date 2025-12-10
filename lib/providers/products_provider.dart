import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/models/product_model.dart';
import 'package:desperdicio_zero/services/product_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desperdicio_zero/core/providers/gamification_provider.dart';
import 'package:desperdicio_zero/core/providers/shopping_list_provider.dart';

final productsProvider = StateNotifierProvider<ProductsNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductsNotifier(ref);
});

class ProductsNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  final Ref ref;

  ProductsNotifier(this.ref) : super(const AsyncValue.loading()) {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    state = const AsyncValue.loading();
    
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) {
        debugPrint('Nenhum usuário autenticado. Lista de produtos vazia.');
        state = const AsyncValue.data([]);
        return;
      }

      final service = ProductService();
      final products = await service.getUserProducts(currentUser.id);
      state = AsyncValue.data(products);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      debugPrint('Error loading products: $e');
    }
  }

  Future<void> addProduct(Product product) async {
    try {
      final service = ProductService();
      await service.addProduct(product);
      await fetchProducts();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      debugPrint('Error adding product: $e');
      rethrow;
    }
  }

  Future<void> updateProduct(Product updatedProduct) async {
    try {
      final service = ProductService();
      await service.updateProduct(updatedProduct);
      // Gamificação (como antes)
      if (updatedProduct.isConsumed) {
        final daysToExpire = updatedProduct.daysToExpire;
        final isCritical = daysToExpire != null && daysToExpire <= 2;
        ref.read(gamificationProvider.notifier).onProductConsumed(isCritical: isCritical);
      }
      // Sugerir na lista de compras se quantidade chegou a zero
      if (updatedProduct.quantity == 0) {
        ref.read(shoppingListProvider.notifier).suggestItemFromProduct(updatedProduct);
      }
      await fetchProducts();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      debugPrint('Error updating product: $e');
      rethrow;
    }
  }

  Future<void> deleteProduct(String productId) async {
    try {
      final service = ProductService();
      await service.deleteProduct(productId);
      await fetchProducts();
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      debugPrint('Error deleting product: $e');
      rethrow;
    }
  }
}
