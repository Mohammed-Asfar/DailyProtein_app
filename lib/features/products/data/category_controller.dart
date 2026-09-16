// foundation.dart also exports a Category annotation, which would clash.
import 'package:flutter/widgets.dart' show ChangeNotifier;

import '../models/category.dart';
import 'category_repository.dart';

/// Holds the category list so the filter chips and the product form see the
/// same set.
class CategoryController extends ChangeNotifier {
  CategoryController({CategoryRepository? repository})
      : _repository = repository ?? CategoryRepository();

  final CategoryRepository _repository;

  List<Category> _categories = <Category>[];
  Map<int, int> _counts = <int, int>{};
  bool _loading = true;

  List<Category> get categories => List<Category>.unmodifiable(_categories);
  bool get isLoading => _loading;

  /// Number of products filed under a category.
  int countFor(int? categoryId) =>
      categoryId == null ? 0 : (_counts[categoryId] ?? 0);

  Category? byId(int? id) {
    if (id == null) return null;
    for (final Category category in _categories) {
      if (category.id == id) return category;
    }
    return null;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _categories = await _repository.all();
    _counts = await _repository.productCounts();
    _loading = false;
    notifyListeners();
  }

  Future<Category> add(Category category) async {
    final int id = await _repository.insert(category);
    await load();
    return byId(id) ?? category.copyWith(id: id);
  }

  Future<void> update(Category category) async {
    await _repository.update(category);
    await load();
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    await load();
  }

  /// Recounts products per category without refetching the categories
  /// themselves. Called after a product is added, moved or deleted.
  Future<void> refreshCounts() async {
    _counts = await _repository.productCounts();
    notifyListeners();
  }
}
