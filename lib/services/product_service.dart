import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:desperdicio_zero/models/product_model.dart';
import 'package:desperdicio_zero/utils/logger_util.dart' show logInfo, logWarning, logError, logDebug;

class ProductService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Get all products for a specific user
  Future<List<Product>> getUserProducts(String userId) async {
    try {
      final response = await _supabase
          .from('products')
          .select()
          .eq('user_id', userId)
          .order('expiration_date', ascending: true);

      return (response as List).map((p) => Product.fromJson(p)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar produtos do usuário: $e');
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
      final response = await _supabase
          .from('products')
          .select()
          .eq('id', id)
          .single();

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

      // Verificar se o usuário está autenticado
      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('Usuário não autenticado. Faça login novamente.');
      }

      final productData = product.toJson();
      productData['user_id'] = currentUser.id; // Usar o ID do usuário autenticado
      logDebug('Dados a serem inseridos: $productData');

      final response = await _supabase
          .from('products')
          .insert(productData)
          .select()
          .single();

      logInfo('Produto adicionado com sucesso: $response');
      return Product.fromJson(response);
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
        logWarning('Tentativa de atualização sem autenticação');
        throw Exception('Usuário não autenticado');
      }

      final productData = product.toJson();
      logDebug('Dados de atualização: $productData');

      final response = await _supabase
          .from('products')
          .update(productData)
          .eq('id', product.id)
          .select()
          .single();

      logInfo('Produto atualizado com sucesso: $response');
      return Product.fromJson(response);
    } catch (e) {
      logError('Erro ao atualizar produto', e);
      throw Exception('Erro ao atualizar produto: $e');
    }
  }

  // Delete a product
  Future<void> deleteProduct(String id) async {
    try {
      logInfo('Iniciando exclusão do produto ID: $id');

      final currentUser = _supabase.auth.currentUser;
      if (currentUser == null) {
        logError('Usuário não autenticado ao tentar excluir produto');
        throw Exception('Usuário não autenticado');
      }

      logDebug('Usuário autenticado: ${currentUser.id}');

      try {
        // Primeiro obtém o produto para verificar a propriedade
        logDebug('Buscando produto para verificação de propriedade...');
        final product = await getProduct(id);

        if (product.userId != currentUser.id) {
          logWarning('Erro de permissão: Usuário ${currentUser.id} tentou excluir produto de ${product.userId}');
          throw Exception('Você não tem permissão para excluir este produto');
        }

        logDebug('Iniciando exclusão no banco de dados...');
        await _supabase
            .from('products')
            .delete()
            .eq('id', id);

        logInfo('Produto $id excluído com sucesso');
      } on PostgrestException catch (e) {
        logError('Erro do Supabase ao excluir produto: ${e.message}');
        logDebug('Detalhes: ${e.details}');
        logDebug('Dica: ${e.hint}');
        logDebug('Código: ${e.code}');
        rethrow;
      } catch (e) {
        logError('Erro ao processar exclusão do produto: $e');
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
      final response = await _supabase
          .rpc('get_upcoming_expiries', params: {
            'user_uuid': _supabase.auth.currentUser!.id,
            'days_ahead': daysAhead,
          });

      return (response as List).map((p) => Product.fromJson(p)).toList();
    } catch (e) {
      throw Exception('Erro ao buscar produtos próximos do vencimento: $e');
    }
  }
}
