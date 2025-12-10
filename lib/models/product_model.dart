// Product model for the Desperdício Zero app
// Represents a product in the user's inventory

class Product {
  final String id;
  final String userId;
  final String name;
  final num quantity;
  final String unit;
  final DateTime? expirationDate;
  final String? type; // e.g., 'food', 'beverage', 'cleaning', etc.
  final String? brand;
  final String? store;
  final double? price;
  final bool isConsumed;
  final DateTime? purchaseDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Nutritional information fields
  final int? calories; // Nutritional information in kcal
  final double? carbs; // Carbohydrates in grams
  final double? protein; // Protein in grams
  final double? fat; // Fat in grams

  Product({
    required this.id,
    required this.userId,
    required this.name,
    required this.quantity,
    required this.unit,
    this.expirationDate,
    this.type,
    this.brand,
    this.store,
    this.price,
    this.isConsumed = false,
    this.purchaseDate,
    required this.createdAt,
    required this.updatedAt,
    this.calories,
    this.carbs,
    this.protein,
    this.fat,
  });

  // Check if the product is expired
  bool get isExpired {
    if (expirationDate == null) return false;
    return expirationDate!.isBefore(DateTime.now());
  }

  int? get daysToExpire {
    if (expirationDate == null) return null;
    final now = DateTime.now();
    final date = DateTime(
      expirationDate!.year,
      expirationDate!.month,
      expirationDate!.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    return date.difference(today).inDays;
  }

  bool get isCritical {
    final days = daysToExpire;
    return days != null && days <= 3;
  }

  // Converte o produto para um Map (para salvar no banco de dados)
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'is_consumed': isConsumed,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };

    // Adiciona campos opcionais apenas se não forem nulos
    if (expirationDate != null) {
      map['expiration_date'] = expirationDate!.toIso8601String();
    } else {
      map['expiration_date'] =
          null; // Garante que o campo seja atualizado para NULL no banco
    }

    if (type != null) map['type'] = type;
    if (brand != null) map['brand'] = brand;
    if (store != null) map['store'] = store;
    if (price != null) map['price'] = price;
    if (purchaseDate != null)
      map['purchase_date'] = purchaseDate!.toIso8601String();
    if (calories != null) map['calories'] = calories;
    if (carbs != null) map['carbs'] = carbs;
    if (protein != null) map['protein'] = protein;
    if (fat != null) map['fat'] = fat;

    return map;
  }

  // Creates a Product from a Map (from database)
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as num,
      unit: json['unit'] as String,
      expirationDate: json['expiration_date'] != null
          ? DateTime.tryParse(json['expiration_date'] as String)
          : null,
      type: json['type'] as String?,
      brand: json['brand'] as String?,
      store: json['store'] as String?,
      price: json['price']?.toDouble(),
      isConsumed: json['is_consumed'] as bool? ?? false,
      purchaseDate: json['purchase_date'] != null
          ? DateTime.tryParse(json['purchase_date'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      calories: json['calories'] as int?,
      carbs: json['carbs']?.toDouble(),
      protein: json['protein']?.toDouble(),
      fat: json['fat']?.toDouble(),
    );
  }

  // Creates a copy of the product with some fields updated
  Product copyWith({
    String? id,
    String? userId,
    String? name,
    num? quantity,
    String? unit,
    DateTime? expirationDate,
    String? type,
    String? brand,
    String? store,
    double? price,
    bool? isConsumed,
    DateTime? purchaseDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? calories,
    double? carbs,
    double? protein,
    double? fat,
  }) {
    return Product(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expirationDate: expirationDate ?? this.expirationDate,
      type: type ?? this.type,
      brand: brand ?? this.brand,
      store: store ?? this.store,
      price: price ?? this.price,
      isConsumed: isConsumed ?? this.isConsumed,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      calories: calories ?? this.calories,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
    );
  }

  @override
  String toString() {
    return 'Product(id: $id, name: $name, quantity: $quantity $unit, expires: $expirationDate)';
  }

  // Converts to a format suitable for PostgREST
  Map<String, dynamic> toPostgrest() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'expiration_date': expirationDate?.toIso8601String(),
      'type': type,
      'brand': brand,
      'store': store,
      'price': price,
      'is_consumed': isConsumed,
      'purchase_date': purchaseDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'calories': calories,
      'carbs': carbs,
      'protein': protein,
      'fat': fat,
    };
  }
}
