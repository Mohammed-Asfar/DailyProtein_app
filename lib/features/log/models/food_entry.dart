import '../../products/models/product.dart';

enum Meal {
  breakfast,
  lunch,
  dinner,
  snack;

  String get storageValue => name;

  static Meal fromStorage(String value) => Meal.values.firstWhere(
        (Meal m) => m.name == value,
        orElse: () => Meal.snack,
      );

  String get label => switch (this) {
        Meal.breakfast => 'Breakfast',
        Meal.lunch => 'Lunch',
        Meal.dinner => 'Dinner',
        Meal.snack => 'Snack',
      };
}

/// One logged food for one day. Nutrition figures are snapshotted at log
/// time so editing a product later does not rewrite past days.
class FoodEntry {
  const FoodEntry({
    this.id,
    required this.productId,
    required this.date,
    required this.quantity,
    required this.protein,
    required this.calories,
    required this.cost,
    required this.meal,
    required this.createdAt,
    this.product,
  });

  final int? id;
  final int productId;

  /// Day key in `yyyy-MM-dd` form.
  final String date;

  final double quantity;
  final double protein;
  final double calories;
  final double cost;
  final Meal meal;
  final DateTime createdAt;

  /// Joined product, populated by the repository for display. Null when the
  /// product row was deleted.
  final Product? product;

  String get displayName => product?.name ?? 'Deleted product';

  String get quantityLabel {
    final String unit = product?.quantityUnit ?? 'g';
    final String qty = quantity == quantity.roundToDouble()
        ? quantity.toStringAsFixed(0)
        : quantity.toStringAsFixed(1);
    return '$qty $unit';
  }

  FoodEntry copyWith({
    int? id,
    int? productId,
    String? date,
    double? quantity,
    double? protein,
    double? calories,
    double? cost,
    Meal? meal,
    DateTime? createdAt,
    Product? product,
  }) {
    return FoodEntry(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      date: date ?? this.date,
      quantity: quantity ?? this.quantity,
      protein: protein ?? this.protein,
      calories: calories ?? this.calories,
      cost: cost ?? this.cost,
      meal: meal ?? this.meal,
      createdAt: createdAt ?? this.createdAt,
      product: product ?? this.product,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        if (id != null) 'id': id,
        'product_id': productId,
        'date': date,
        'quantity': quantity,
        'protein': protein,
        'calories': calories,
        'cost': cost,
        'meal': meal.storageValue,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory FoodEntry.fromMap(Map<String, Object?> map, {Product? product}) =>
      FoodEntry(
        id: map['id'] as int?,
        productId: map['product_id'] as int,
        date: map['date'] as String,
        quantity: (map['quantity'] as num).toDouble(),
        protein: (map['protein'] as num).toDouble(),
        calories: (map['calories'] as num).toDouble(),
        cost: (map['cost'] as num).toDouble(),
        meal: Meal.fromStorage(map['meal'] as String),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int,
        ),
        product: product,
      );

  /// Builds an entry by calculating nutrition from [product] and [quantity].
  factory FoodEntry.calculate({
    required Product product,
    required double quantity,
    required String date,
    required Meal meal,
  }) {
    return FoodEntry(
      productId: product.id!,
      date: date,
      quantity: quantity,
      protein: product.proteinFor(quantity),
      calories: product.caloriesFor(quantity),
      cost: product.costFor(quantity),
      meal: meal,
      createdAt: DateTime.now(),
      product: product,
    );
  }
}

/// Aggregated totals for a single day.
class DayTotals {
  const DayTotals({
    required this.date,
    required this.protein,
    required this.calories,
    required this.cost,
    required this.entryCount,
  });

  const DayTotals.empty(this.date)
      : protein = 0,
        calories = 0,
        cost = 0,
        entryCount = 0;

  final String date;
  final double protein;
  final double calories;
  final double cost;
  final int entryCount;

  /// Money spent per gram of protein, null when nothing was spent or eaten.
  double? get costPerGram {
    if (cost <= 0 || protein <= 0) return null;
    return cost / protein;
  }
}
