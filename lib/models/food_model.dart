class Food {
  final int? id;
  final String name;
  final String? category;
  final double? calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final String? imageUrl;
  final String? barcode;

  Food({
    this.id,
    required this.name,
    this.category,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.imageUrl,
    this.barcode,
  });

  // Converte o objeto para um Map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'imageUrl': imageUrl,
      'barcode': barcode,
    };
  }
  
  // Cria um objeto a partir de um Map
  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as int?,
      name: json['name'] as String,
      category: json['category'] as String?,
      calories: (json['calories'] as num?)?.toDouble(),
      protein: (json['protein'] as num?)?.toDouble(),
      carbs: (json['carbs'] as num?)?.toDouble(),
      fat: (json['fat'] as num?)?.toDouble(),
      imageUrl: json['imageUrl'] as String?,
      barcode: json['barcode'] as String?,
    );
  }
  
  // Cria uma cópia do objeto com as alterações fornecidas
  Food copyWith({
    int? id,
    String? name,
    String? category,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    String? imageUrl,
    String? barcode,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      imageUrl: imageUrl ?? this.imageUrl,
      barcode: barcode ?? this.barcode,
    );
  }
}
