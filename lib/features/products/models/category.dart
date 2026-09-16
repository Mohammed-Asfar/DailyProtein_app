import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// A grouping for products. Eight ship built in; the user can add more.
class Category {
  const Category({
    this.id,
    required this.name,
    required this.icon,
    required this.colour,
    this.builtIn = false,
    this.sortOrder = 0,
  });

  final int? id;
  final String name;

  /// Icon key, resolved by [iconData]. Stored as a name rather than a code
  /// point so the database does not depend on Flutter's icon internals.
  final String icon;

  /// Colour key, resolved against [AppIconColors].
  final String colour;

  /// Built-in categories cannot be deleted, only renamed.
  final bool builtIn;

  final int sortOrder;

  static const Map<String, IconData> _icons = <String, IconData>{
    'apple': Icons.apple_rounded,
    'leaf': Icons.eco_rounded,
    'grain': Icons.grain_rounded,
    // A drumstick rather than an egg: "Proteins" is mostly meat, and the
    // egg reads as its own food rather than the group.
    'protein': Icons.kebab_dining_rounded,
    'dairy': Icons.icecream_rounded,
    'snack': Icons.cookie_rounded,
    'drink': Icons.local_cafe_rounded,
    'other': Icons.category_rounded,
    'egg': Icons.egg_rounded,
    'fish': Icons.set_meal_rounded,
    'meat': Icons.lunch_dining_rounded,
    'rice': Icons.rice_bowl_rounded,
    'bread': Icons.bakery_dining_rounded,
  };

  /// Icon keys offered when creating a category.
  static List<String> get iconKeys => _icons.keys.toList();

  /// Colour keys offered when creating a category.
  static const List<String> colourKeys = <String>[
    'flame',
    'leaf',
    'amber',
    'chart',
    'cyan',
    'violet',
  ];

  IconData get iconData => _icons[icon] ?? Icons.category_rounded;

  Color resolveColour(AppIconColors icons) => switch (colour) {
        'flame' => icons.flame,
        'leaf' => icons.leaf,
        'amber' => icons.amber,
        'chart' => icons.chart,
        'cyan' => icons.cyan,
        'violet' => icons.violet,
        _ => icons.leaf,
      };

  Category copyWith({
    int? id,
    String? name,
    String? icon,
    String? colour,
    bool? builtIn,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      colour: colour ?? this.colour,
      builtIn: builtIn ?? this.builtIn,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toMap() => <String, Object?>{
        if (id != null) 'id': id,
        'name': name,
        'icon': icon,
        'colour': colour,
        'built_in': builtIn ? 1 : 0,
        'sort_order': sortOrder,
      };

  factory Category.fromMap(Map<String, Object?> map) => Category(
        id: map['id'] as int?,
        name: map['name'] as String,
        icon: map['icon'] as String,
        colour: map['colour'] as String,
        builtIn: (map['built_in'] as int? ?? 0) == 1,
        sortOrder: map['sort_order'] as int? ?? 0,
      );
}
