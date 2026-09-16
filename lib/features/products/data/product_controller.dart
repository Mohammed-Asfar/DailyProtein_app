import 'package:flutter/foundation.dart';

import '../models/product.dart';
import 'product_repository.dart';

/// Holds the product catalogue so every screen sees the same list.
class ProductController extends ChangeNotifier {
  ProductController({ProductRepository? repository})
      : _repository = repository ?? ProductRepository();

  final ProductRepository _repository;

  List<Product> _products = <Product>[];
  bool _loading = true;

  List<Product> get products => List<Product>.unmodifiable(_products);
  bool get isLoading => _loading;
  bool get isEmpty => !_loading && _products.isEmpty;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _products = await _repository.all();
    _loading = false;
    notifyListeners();
  }

  Future<Product> add(Product product) async {
    final int id = await _repository.insert(product);
    final Product saved = product.copyWith(id: id);
    _products = <Product>[..._products, saved]
      ..sort(
        (Product a, Product b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    notifyListeners();
    return saved;
  }

  Future<void> update(Product product) async {
    await _repository.update(product);
    _products = _products
        .map((Product p) => p.id == product.id ? product : p)
        .toList()
      ..sort(
        (Product a, Product b) =>
            a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
    notifyListeners();
  }

  Future<void> delete(int id) async {
    await _repository.delete(id);
    _products = _products.where((Product p) => p.id != id).toList();
    notifyListeners();
  }

  Future<int> entryCount(int productId) => _repository.entryCount(productId);

  List<Product> search(String query) {
    final String q = query.trim().toLowerCase();
    if (q.isEmpty) return products;
    return _products
        .where((Product p) => p.name.toLowerCase().contains(q))
        .toList();
  }

  /// The cheapest protein sources the user has priced, best value first.
  List<Product> cheapestSources({int limit = 3}) {
    final List<Product> priced = _products
        .where((Product p) => p.costPerGramProtein != null)
        .toList()
      ..sort(
        (Product a, Product b) =>
            a.costPerGramProtein!.compareTo(b.costPerGramProtein!),
      );
    return priced.take(limit).toList();
  }
}
