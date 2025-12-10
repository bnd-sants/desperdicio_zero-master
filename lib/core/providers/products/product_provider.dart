import 'dart:developer';
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

  /// Creates a copy of this state with the given fields replaced by the non-null values.
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

  /// Returns a value based on the current state
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

  /// Returns a value based on the current state, with an orElse fallback
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
class ProductNotifier extends StateNotifier<ProductState> {
  final ProductService _productService;
  final Ref _ref;
  
  ProductNotifier(this._productService, this._ref) 
    : super(const ProductState()) {
    _loadProducts();
  }

  bool _isDisposed = false;
  
  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Carrega os produtos do usuário autenticado
  Future<void> _loadProducts() async {
    if (_isDisposed) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final authState = _ref.read(authNotifierProvider);
      if (authState is! Authenticated) {
        logWarning('Provider: Usuário não autenticado');
        state = state.copyWith(
          isLoading: false,
          error: 'Usuário não autenticado',
        );
        return;
      }

      logInfo('Carregando produtos para usuário: ${authState.user.id}');
      final products = await _productService.getUserProducts(authState.user.id);

      if (_isDisposed) return;

      logInfo('${products.length} produtos carregados');
      state = state.copyWith(
        products: products,
        isLoading: false,
      );
    } catch (e) {
      if (_isDisposed) return;

      logError('Erro ao carregar produtos', e);
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar produtos: ${e.toString()}',
      );
    }
  }

  /// Adiciona um novo produto
  Future<void> addProduct(Product product) async {
    if (_isDisposed) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final authState = _ref.read(authNotifierProvider);
      if (authState is! Authenticated) {
        throw Exception('Usuário não autenticado');
      }

      logInfo('Adicionando produto...');
      final newProduct = await _productService.addProduct(
        product.copyWith(userId: authState.user.id),
      );

      if (_isDisposed) return;

      logInfo('Produto adicionado com sucesso');
      state = state.copyWith(
        products: [...state.products, newProduct],
        isLoading: false,
      );

      logDebug('Total de produtos agora: ${state.products.length}');
    } catch (e) {
      if (_isDisposed) return;

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
    if (_isDisposed) return;
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _productService.updateProduct(product);
      
      if (_isDisposed) return;
      
      state = state.copyWith(
        products: state.products
            .map((p) => p.id == product.id ? product : p)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      if (_isDisposed) return;
      
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
    if (_isDisposed) return;
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final product = state.products.firstWhere((p) => p.id == productId);
      final consumedProduct = product.copyWith(isConsumed: true);
      
      await _productService.updateProduct(consumedProduct);
      
      if (_isDisposed) return;
      
      state = state.copyWith(
        products: state.products
            .map((p) => p.id == productId ? consumedProduct : p)
            .toList(),
        isLoading: false,
      );
    } catch (e) {
      if (_isDisposed) return;
      
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
    if (_isDisposed) return;
    
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      await _productService.deleteProduct(productId);
      
      if (_isDisposed) return;
      
      state = state.copyWith(
        products: state.products.where((p) => p.id != productId).toList(),
        isLoading: false,
      );
    } catch (e) {
      if (_isDisposed) return;
      
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
final productsProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final productService = ref.watch(productServiceProvider);
  return ProductNotifier(productService, ref);
});

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
