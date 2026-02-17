import 'dart:async';

import 'package:desperdicio_zero/models/product_model.dart';
import 'package:desperdicio_zero/services/local_product_cache_service.dart';
import 'package:desperdicio_zero/utils/logger_util.dart'
    show logDebug, logError, logInfo, logWarning;
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final LocalProductCacheService _localCache = LocalProductCacheService();

  bool _lastLoadFromOffline = false;
  bool get lastLoadFromOffline => _lastLoadFromOffline;

  // Get all products for a specific user with offline read fallback.
  Future<List<Product>> getUserProducts(
    String userId, {
    bool preferOffline = true,
  }) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('user_id', userId)
          .order('expiration_date', ascending: true);

      final products = (response as List).map((p) => Product.fromJson(p)).toList();
      await syncProductsToLocalCache(userId, products);
      _lastLoadFromOffline = false;
      return products;
    } catch (e) {
      if (preferOffline) {
        logWarning('Falha no carregamento remoto, usando cache local: $e');
        final cachedProducts = await _localCache.getProducts(userId);
        _lastLoadFromOffline = true;
        return cachedProducts;
      }
      throw Exception('Erro ao buscar produtos do usuario: $e');
    }
  }

  Future<void> syncProductsToLocalCache(
    String userId,
    List<Product> products,
  ) async {
    try {
      await _localCache.saveProducts(userId, products);
    } catch (e) {
      logWarning('Falha ao sincronizar cache local de produtos: $e');
    }
  }

  // Get all products (for admin use only)
  Future<List<Product>> getAllProducts() async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .order('expiration_date', ascending: true);

      return (response as List).map((p) => Product.fromJson(p)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar produtos: $e');
    }
  }

  // Get a single product by ID
  Future<Product> getProduct(String id) async {
    try {
      final response = await _supabase.from('products').select().eq('id', id).single();

      return Product.fromJson(response);
    } catch (e) {
      throw Exception('Erro ao buscar produto: $e');
    }
  }

  // Add a new product
  Future<Product> addProduct(Product product) async {
    try {
      logDebug('Tentando adicionar produto...');
      logDebug('Nome: ${product.name}');
      logDebug('User ID: ${product.userId}');
      logDebug('Quantidade: ${product.quantity}');
      logDebug('Unidade: ${product.unit}');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario nao autenticado. Faca login novamente.');
      }

      final productData = product.toJson();
      productData['user_id'] = currentUser.id;
      logDebug('Dados a serem inseridos: $productData');

      final response = await _supabase.from('products').insert(productData).select().single();

      logInfo('Produto adicionado com sucesso: $response');
      final created = Product.fromJson(response);
      await _syncCurrentUserProductsToCache();
      return created;
    } catch (e) {
      logError('Erro ao adicionar produto', e);
      throw Exception('Erro ao adicionar produto: $e');
    }
  }

  // Update an existing product
  Future<Product> updateProduct(Product product) async {
    try {
      logDebug('Atualizando produto: ${product.id}');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        logWarning('Tentativa de atualizacao sem autenticacao');
        throw Exception('Usuario nao autenticado');
      }

      final productData = product.toJson();
      logDebug('Dados de atualizacao: $productData');

      final response = await _supabase
          .from('products')
          .update(productData)
          .eq('id', product.id)
          .select()
          .single();

      logInfo('Produto atualizado com sucesso: $response');
      final updated = Product.fromJson(response);
      await _syncCurrentUserProductsToCache();
      return updated;
    } catch (e) {
      logError('Erro ao atualizar produto', e);
      throw Exception('Erro ao atualizar produto: $e');
    }
  }

  // Delete a product
  Future<void> deleteProduct(String id) async {
    try {
      logInfo('Iniciando exclusao do produto ID: $id');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        logError('Usuario nao autenticado ao tentar excluir produto');
        throw Exception('Usuario nao autenticado');
      }

      logDebug('Usuario autenticado: ${currentUser.id}');

      try {
        logDebug('Buscando produto para verificacao de propriedade...');
        final product = await getProduct(id);

        if (product.userId != currentUser.id) {
          logWarning(
            'Erro de permissao: Usuario ${currentUser.id} tentou excluir produto de ${product.userId}',
          );
          throw Exception('Voce nao tem permissao para excluir este produto');
        }

        logDebug('Iniciando exclusao no banco de dados...');
        await _supabase.from('products').delete().eq('id', id);

        logInfo('Produto $id excluido com sucesso');
        await _syncCurrentUserProductsToCache();
      } on PostgrestException catch (e) {
        logError('Erro do Supabase ao excluir produto: ${e.message}');
        logDebug('Detalhes: ${e.details}');
        logDebug('Dica: ${e.hint}');
        logDebug('Codigo: ${e.code}');
        rethrow;
      } catch (e) {
        logError('Erro ao processar exclusao do produto: $e');
        rethrow;
      }
    } catch (e) {
      logError('Erro ao excluir produto', e);
      if (e is! Exception) {
        throw Exception('Erro ao excluir o produto: $e');
      }
      rethrow;
    }
  }

  // Get products expiring soon (within X days)
  Future<List<Product>> getExpiringProducts(int daysAhead) async {
    try {
      final response = await _supabase.rpc(
        'get_upcoming_expiries',
        params: {
          'user_uuid': _supabase.auth.currentUser!.id,
          'days_ahead': daysAhead,
        },
      );

      return (response as List).map((p) => Product.fromJson(p)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar produtos proximos do vencimento: $e');
    }
  }

  Future<void> _syncCurrentUserProductsToCache() async {
    final currentUser = _supabase.auth.currentUser;
    if (currentUser == null) return;

    final response = await _supabase
        .from('products')
        .select()
        .eq('user_id', currentUser.id)
        .order('expiration_date', ascending: true);
    final products = (response as List).map((p) => Product.fromJson(p)).toList();
    await syncProductsToLocalCache(currentUser.id, products);
  }
}
