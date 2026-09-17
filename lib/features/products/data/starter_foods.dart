import '../models/product.dart';

/// A common food the user can add to their own catalogue in one tap.
///
/// These are suggestions, not a database the app reads from: adding one
/// copies it into the user's products, after which it is theirs to edit.
class StarterFood {
  const StarterFood({
    required this.name,
    required this.emoji,
    required this.categoryName,
    required this.protein,
    required this.calories,
    this.measureMode = MeasureMode.per100g,
    this.unitLabel = '100 g',
  });

  final String name;

  /// Shown until the user takes a photo of their own.
  final String emoji;

  /// Matched to a category by name at add time, so a reordered or renamed
  /// category list cannot leave these pointing at the wrong id.
  final String categoryName;

  final double protein;
  final double calories;
  final MeasureMode measureMode;
  final String unitLabel;

  Product toProduct({int? categoryId}) => Product(
        name: name,
        measureMode: measureMode,
        unitLabel: unitLabel,
        protein: protein,
        calories: calories,
        categoryId: categoryId,
        emoji: emoji,
        createdAt: DateTime.now(),
      );

  /// Values are per 100 g unless the entry says otherwise, from USDA
  /// FoodData Central where a matching record exists, and from Indian food
  /// composition sources for paneer, roti and curd. Rounded to one decimal.
  ///
  /// Where a food varies by preparation the common form is used and named:
  /// firm tofu is the calcium-sulfate kind (17.3 g), not nigari (9 g).
  static const List<StarterFood> all = <StarterFood>[
    // Proteins
    StarterFood(
      name: 'Egg',
      emoji: '🥚',
      categoryName: 'Proteins',
      protein: 6.3,
      calories: 72,
      measureMode: MeasureMode.perUnit,
      unitLabel: 'piece',
    ),
    StarterFood(
      name: 'Chicken Breast',
      emoji: '🍗',
      categoryName: 'Proteins',
      protein: 31,
      calories: 165,
    ),
    StarterFood(
      name: 'Paneer',
      emoji: '🧀',
      categoryName: 'Proteins',
      protein: 18,
      calories: 296,
    ),
    StarterFood(
      name: 'Tofu (firm)',
      emoji: '🍲',
      categoryName: 'Proteins',
      protein: 17.3,
      calories: 144,
    ),
    StarterFood(
      name: 'Whey Scoop',
      emoji: '🥤',
      categoryName: 'Proteins',
      protein: 24,
      calories: 110,
      measureMode: MeasureMode.perUnit,
      unitLabel: 'scoop',
    ),
    StarterFood(
      name: 'Lentils (cooked)',
      emoji: '🍛',
      categoryName: 'Proteins',
      protein: 9,
      calories: 116,
    ),
    StarterFood(
      name: 'Chickpeas (cooked)',
      emoji: '🫘',
      categoryName: 'Proteins',
      protein: 8.9,
      calories: 164,
    ),
    StarterFood(
      name: 'Peanuts',
      emoji: '🥜',
      categoryName: 'Proteins',
      protein: 25.8,
      calories: 567,
    ),
    StarterFood(
      name: 'Fish (Salmon)',
      emoji: '🐟',
      categoryName: 'Proteins',
      protein: 20,
      calories: 208,
    ),

    // Dairy
    StarterFood(
      name: 'Milk',
      emoji: '🥛',
      categoryName: 'Dairy',
      protein: 3.4,
      calories: 61,
    ),
    StarterFood(
      name: 'Greek Yoghurt',
      emoji: '🍶',
      categoryName: 'Dairy',
      protein: 10,
      calories: 59,
    ),
    StarterFood(
      name: 'Curd',
      emoji: '🥣',
      categoryName: 'Dairy',
      protein: 3.5,
      calories: 62,
    ),

    // Grains
    StarterFood(
      name: 'White Rice (cooked)',
      emoji: '🍚',
      categoryName: 'Grains',
      protein: 2.7,
      calories: 130,
    ),
    StarterFood(
      name: 'Roti',
      emoji: '🫓',
      categoryName: 'Grains',
      protein: 3,
      calories: 120,
      measureMode: MeasureMode.perUnit,
      unitLabel: 'piece',
    ),
    StarterFood(
      name: 'Bread Slice',
      emoji: '🍞',
      categoryName: 'Grains',
      protein: 2.7,
      calories: 79,
      measureMode: MeasureMode.perUnit,
      unitLabel: 'slice',
    ),
    StarterFood(
      name: 'Oats',
      emoji: '🥣',
      categoryName: 'Grains',
      protein: 13.2,
      calories: 379,
    ),

    // Vegetables
    StarterFood(
      name: 'Broccoli',
      emoji: '🥦',
      categoryName: 'Vegetables',
      protein: 2.8,
      calories: 34,
    ),
    StarterFood(
      name: 'Spinach',
      emoji: '🥬',
      categoryName: 'Vegetables',
      protein: 2.9,
      calories: 23,
    ),
    StarterFood(
      name: 'Potato',
      emoji: '🥔',
      categoryName: 'Vegetables',
      protein: 2,
      calories: 77,
    ),

    // Fruits
    StarterFood(
      name: 'Banana',
      emoji: '🍌',
      categoryName: 'Fruits',
      protein: 1.1,
      calories: 89,
    ),
    StarterFood(
      name: 'Apple',
      emoji: '🍎',
      categoryName: 'Fruits',
      protein: 0.3,
      calories: 52,
    ),
  ];

  /// Starter foods whose name does not already exist in the catalogue.
  static List<StarterFood> notYetAdded(Iterable<String> existingNames) {
    final Set<String> taken =
        existingNames.map((String n) => n.toLowerCase().trim()).toSet();
    return all
        .where((StarterFood f) => !taken.contains(f.name.toLowerCase()))
        .toList();
  }
}
