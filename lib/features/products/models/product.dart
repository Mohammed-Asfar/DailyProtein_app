/// How a product's nutrition figures are expressed.
enum MeasureMode {
  /// Values are per one countable item, e.g. 1 egg = 6 g protein.
  perUnit,

  /// Values are per 100 g / 100 ml, e.g. chicken = 27 g protein per 100 g.
  per100g;

  String get storageValue => name;

  static MeasureMode fromStorage(String value) => MeasureMode.values.firstWhere(
        (MeasureMode m) => m.name == value,
        orElse: () => MeasureMode.perUnit,
      );

  String get label =>
      this == MeasureMode.perUnit ? 'Per piece / serving' : 'Per 100 g';

  /// Suffix shown next to a nutrition figure, e.g. "6 g protein /piece".
  String basisSuffix(String unitLabel) =>
      this == MeasureMode.perUnit ? 'per $unitLabel' : 'per 100 g';
}

class Product {
  const Product({
    this.id,
    required this.name,
    required this.measureMode,
    required this.unitLabel,
    required this.protein,
    this.calories,
    this.price,
    required this.createdAt,
  });

  final int? id;
  final String name;
  final MeasureMode measureMode;

  /// Name of one countable item ("piece", "egg", "scoop"). For [per100g]
  /// products this stays "100 g" and is only used for display.
  final String unitLabel;

  /// Protein in grams, per unit or per 100 g depending on [measureMode].
  final double protein;

  /// Calories per unit or per 100 g. Null when the user skipped it.
  final double? calories;

  /// Price per unit or per 100 g. Null when the user skipped it.
  final double? price;

  final DateTime createdAt;

  /// Grams of protein contained in [quantity] of this product, where
  /// quantity is a count for [perUnit] and grams for [per100g].
  double proteinFor(double quantity) => protein * _factor(quantity);

  double caloriesFor(double quantity) => (calories ?? 0) * _factor(quantity);

  double costFor(double quantity) => (price ?? 0) * _factor(quantity);

  double _factor(double quantity) =>
      measureMode == MeasureMode.perUnit ? quantity : quantity / 100;

  /// Cost of one gram of protein, or null when price is unknown or
  /// the product has no protein.
  double? get costPerGramProtein {
    if (price == null || protein <= 0) return null;
    return price! / protein;
  }

  /// Label for the quantity field when logging, e.g. "Quantity (piece)".
  String get quantityUnit =>
      measureMode == MeasureMode.perUnit ? unitLabel : 'g';

  Product copyWith({
    int? id,
    String? name,
    MeasureMode? measureMode,
    String? unitLabel,
    double? protein,
    double? Function()? calories,
    double? Function()? price,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      measureMode: measureMode ?? this.measureMode,
      unitLabel: unitLabel ?? this.unitLabel,
      protein: protein ?? this.protein,
      calories: calories != null ? calories() : this.calories,
      price: price != null ? price() : this.price,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        if (id != null) 'id': id,
        'name': name,
        'measure_mode': measureMode.storageValue,
        'unit_label': unitLabel,
        'protein': protein,
        'calories': calories,
        'price': price,
        'created_at': createdAt.millisecondsSinceEpoch,
      };

  factory Product.fromMap(Map<String, Object?> map) => Product(
        id: map['id'] as int?,
        name: map['name'] as String,
        measureMode: MeasureMode.fromStorage(map['measure_mode'] as String),
        unitLabel: map['unit_label'] as String,
        protein: (map['protein'] as num).toDouble(),
        calories: (map['calories'] as num?)?.toDouble(),
        price: (map['price'] as num?)?.toDouble(),
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int,
        ),
      );
}
