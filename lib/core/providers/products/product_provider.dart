import 'dart:developer';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/models/product_model.dart';
import 'package:desperdicio_zero/services/product_service.dart';
import 'package:desperdicio_zero/utils/logger_util.dart' show logInfo, logWarning, logError, logDebug;
import 'package:desperdicio_zero/core/providers/auth/auth_provider.dart';

/// Provider para o serviço de produtos
final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService();
});

/// Estado assíncrono para a lista de produtos
class ProductState {
  final List<Product> products;
  final bool isLoading;
  final String? error;

  const ProductState({
    this.products = const [],
    this.isLoading = false,
    this.error,
  });

  ProductState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
  }) {
    return ProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  T when<T>({
    required T Function() loading,
    required T Function(String error) error,
    required T Function(List<Product> products) data,
  }) {
    if (isLoading) {
      return loading();
    } else if (this.error != null) {
      return error(this.error!);
    } else {
      return data(products);
    }
  }

  T maybeWhen<T>({
    T Function()? loading,
    T Function(String error)? error,
    T Function(List<Product> products)? data,
    required T Function() orElse,
  }) {
    if (isLoading && loading != null) {
      return loading();
    } else if (this.error != null && error != null) {
      return error(this.error!);
    } else if (!isLoading && this.error == null && data != null) {
      return data(products);
    } else {
      return orElse();
    }
  }
}

/// Notifier para gerenciar o estado dos produtos
class ProductNotifier extends Notifier<ProductState> {
  late final ProductService _productService;
  
  @override
  ProductState build() {
    _productService = ref.watch(productServiceProvider);
    
    // CORREÇÃO: Em vez de chamar _loadProducts direto, usamos listen e microtask
    
    // 1. Ouve mudanças na autenticação. Se o usuário logar/deslogar, reagimos aqui.
    ref.listen(authNotifierProvider, (previous, next) {
      next.maybeWhen(
        authenticated: (user) {
          // Usuário autenticado? Carrega os produtos.
          _loadProducts();
        },
        orElse: () {
          // Se não estiver autenticado, limpa o estado para evitar vazamento de dados
          state = const ProductState();
        },
      );
    });

    // 2. Carregamento Inicial Seguro
    // Usamos Future.microtask para agendar a execução para APÓS o término do build atual.
    // Isso evita o erro de "Circular Dependency" ou "Uninitialized Provider".
    Future.microtask(() {
      final authState = ref.read(authNotifierProvider);
      authState.maybeWhen(
        authenticated: (_) => _loadProducts(),
        orElse: () {},
      );
    });

    // Retorna o estado inicial vazio enquanto o microtask não roda
    return const ProductState();
  }

  /// Carrega os produtos do usuário autenticado
  Future<void> _loadProducts() async {
    // Verificação de segurança: O provider ainda está ativo?
    if (!ref.mounted) return;

    // Evita recarregar se já estiver carregando (opcional, mas recomendado)
    if (state.isLoading) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Aqui usamos ref.read porque estamos dentro de uma função assíncrona, não no build
      final authState = ref.read(authNotifierProvider);
      
      final user = authState.when(
        authenticated: (profile) => profile,
        unauthenticated: () => null,
        loading: () => null,
        error: (_) => null,
        initial: () => null,
      );

      if (user == null) {
        logWarning('Provider: Usuário não autenticado, cancelando carga de produtos.');
        if (ref.mounted) {
           state = state.copyWith(
            isLoading: false,
            // Não definimos erro aqui para não mostrar mensagem vermelha na tela de login
            error: null, 
          );
        }
        return;
      }

      logInfo('Carregando produtos para usuário: ${user.id}');
      final products = await _productService.getUserProducts(user.id);

      if (!ref.mounted) return;

      logInfo('${products.length} produtos carregados');
      state = state.copyWith(
        products: products,
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;

      logError('Erro ao carregar produtos', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar produtos: ${e.toString()}',
      );
    }
  }

  /// Adiciona um novo produto
  Future<void> addProduct(Product product) async {
    if (!ref.mounted) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final authState = ref.read(authNotifierProvider);
      final user = authState.maybeWhen(
        authenticated: (profile) => profile,
        orElse: () => null,
      );

      if (user == null) {
        throw Exception('Usuário não autenticado');
      }

      logInfo('Adicionando produto...');
      final newProduct = await _productService.addProduct(
        product.copyWith(userId: user.id),
      );

      if (!ref.mounted) return;

      logInfo('Produto adicionado com sucesso');
      state = state.copyWith(
        products: [...state.products, newProduct],
        isLoading: false,
      );

      logDebug('Total de produtos agora: ${state.products.length}');
    } catch (e) {
      if (!ref.mounted) return;

      logError('Erro ao adicionar produto', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao adicionar produto: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Atualiza um produto existente
  Future<void> updateProduct(Product product) async {
    if (!ref.mounted) return;
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _productService.updateProduct(product);
      
      if (!ref.mounted) return;
      
      state = state.copyWith(
        products: state.products
            .map((p) => p.id == product.id ? product : p)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      
      log('Erro ao atualizar produto: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao atualizar produto: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Marca um produto como consumido
  Future<void> markAsConsumed(String productId) async {
    if (!ref.mounted) return;
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Encontra o produto atual
      final product = state.products.firstWhere(
        (p) => p.id == productId,
        orElse: () => throw Exception("Produto não encontrado na lista"),
      );

      final consumedProduct = product.copyWith(isConsumed: true);
      
      await _productService.updateProduct(consumedProduct);
      
      if (!ref.mounted) return;
      
      state = state.copyWith(
        products: state.products
            .map((p) => p.id == productId ? consumedProduct : p)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      
      log('Erro ao marcar produto como consumido: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao marcar produto como consumido: ${e.toString()}',
      );
      rethrow;
    }
  }

  /// Remove um produto
  Future<void> removeProduct(String productId) async {
    if (!ref.mounted) return;
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _productService.deleteProduct(productId);
      
      if (!ref.mounted) return;
      
      state = state.copyWith(
        products: state.products.where((p) => p.id != productId).toList(),
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      
      log('Erro ao remover produto: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao remover produto: ${e.toString()}',
      );
      rethrow;
    }
  }
  
  /// Atualiza a lista de produtos
  Future<void> refresh() => _loadProducts();
}

/// Provider para o ProductNotifier
final productsProvider = NotifierProvider<ProductNotifier, ProductState>(ProductNotifier.new);

/// Provider para a lista de produtos filtrada por tipo
final productsByCategoryProvider = Provider.family<List<Product>, String>((ref, type) {
  final productsState = ref.watch(productsProvider);
  
  if (productsState.isLoading) {
    return [];
  }
  
  if (productsState.error != null) {
    return [];
  }
  
  return productsState.products
      .where((product) => product.type == type)
      .toList();
});

/// Provider para um produto específico por ID
final productByIdProvider = Provider.family<Product?, String>((ref, productId) {
  final productsState = ref.watch(productsProvider);
  
  if (productsState.isLoading || productsState.error != null) {
    return null;
  }
  
  try {
    return productsState.products.firstWhere(
      (product) => product.id == productId,
    );
  } catch (e) {
    return null;
  }
});