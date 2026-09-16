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
    this.categoryId,
    this.imagePath,
    this.emoji,
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

  /// Category this product belongs to, null when uncategorised.
  final int? categoryId;

  /// Absolute path to a photo in the app's own storage, null when none was
  /// chosen. Files outside app storage are not referenced, so a photo cannot
  /// vanish from under the app.
  final String? imagePath;

  /// A food emoji shown when there is no photo. Comes from the starter
  /// catalogue, or from whatever the user picks.
  final String? emoji;

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
    int? Function()? categoryId,
    String? Function()? imagePath,
    String? Function()? emoji,
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
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      imagePath: imagePath != null ? imagePath() : this.imagePath,
      emoji: emoji != null ? emoji() : this.emoji,
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
        'category_id': categoryId,
        'image_path': imagePath,
        'emoji': emoji,
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
        categoryId: map['category_id'] as int?,
        imagePath: map['image_path'] as String?,
        emoji: map['emoji'] as String?,
        createdAt: DateTime.fromMillisecondsSinceEpoch(
          map['created_at'] as int,
        ),
      );
}
