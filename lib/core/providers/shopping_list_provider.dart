import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:desperdicio_zero/models/product_model.dart';

enum ShoppingListItemStatus { needed, bought, suggested }

class ShoppingListItem {
  final String id;
  final String name;
  final int quantity;
  final String unit;
  final ShoppingListItemStatus status;
  final String? fromProductId; // se for sugestão baseada em produto já cadastrado

  const ShoppingListItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    this.status = ShoppingListItemStatus.needed,
    this.fromProductId,
  });

  ShoppingListItem copyWith({
    String? id,
    String? name,
    int? quantity,
    String? unit,
    ShoppingListItemStatus? status,
    String? fromProductId,
  }) => ShoppingListItem(
        id: id ?? this.id,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        status: status ?? this.status,
        fromProductId: fromProductId ?? this.fromProductId,
      );
}

class ShoppingListNotifier extends Notifier<List<ShoppingListItem>> {
  @override
  List<ShoppingListItem> build() => [];

  void addItem(ShoppingListItem item) {
    state = [...state, item];
  }

  void removeItem(String id) {
    state = state.where((e) => e.id != id).toList();
  }

  void markAsBought(String id) {
    state = state.map((e) =>
      e.id == id ? e.copyWith(status: ShoppingListItemStatus.bought) : e
    ).toList();
  }

  void suggestItemFromProduct(Product product) {
    final alreadySuggested = state.any((e) => e.fromProductId == product.id && e.status != ShoppingListItemStatus.bought);
    if(!alreadySuggested) {
      state = [
        ...state,
        ShoppingListItem(
          id: 'suggest_${product.id}',
          name: product.name,
          quantity: product.quantity is int ? product.quantity as int : 1,
          unit: product.unit,
          status: ShoppingListItemStatus.suggested,
          fromProductId: product.id,
        )
      ];
    }
  }

  void clearBought() {
    state = state.where((e) => e.status != ShoppingListItemStatus.bought).toList();
  }
}

final shoppingListProvider = NotifierProvider<ShoppingListNotifier, List<ShoppingListItem>>(
  ShoppingListNotifier.new,
);
