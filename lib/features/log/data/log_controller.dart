import 'package:flutter/foundation.dart';

import '../../../core/utils/date_utils.dart';
import '../../products/models/product.dart';
import '../models/food_entry.dart';
import 'entry_repository.dart';

/// Owns the currently viewed day, its entries and its totals.
class LogController extends ChangeNotifier {
  LogController({EntryRepository? repository})
      : _repository = repository ?? EntryRepository(),
        _date = DayKey.today;

  final EntryRepository _repository;

  String _date;
  List<FoodEntry> _entries = <FoodEntry>[];
  DayTotals _totals = DayTotals.empty(DayKey.today);
  bool _loading = true;

  String get date => _date;
  bool get isViewingToday => DayKey.isToday(_date);
  List<FoodEntry> get entries => List<FoodEntry>.unmodifiable(_entries);
  DayTotals get totals => _totals;
  bool get isLoading => _loading;
  bool get isEmpty => !_loading && _entries.isEmpty;

  /// Entries grouped by meal, in meal order, skipping empty meals.
  Map<Meal, List<FoodEntry>> get entriesByMeal {
    final Map<Meal, List<FoodEntry>> grouped = <Meal, List<FoodEntry>>{};
    for (final Meal meal in Meal.values) {
      final List<FoodEntry> forMeal =
          _entries.where((FoodEntry e) => e.meal == meal).toList();
      if (forMeal.isNotEmpty) grouped[meal] = forMeal;
    }
    return grouped;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _entries = await _repository.forDate(_date);
    _totals = await _repository.totalsForDate(_date);
    _loading = false;
    notifyListeners();
  }

  Future<void> setDate(String date) async {
    if (date == _date) return;
    _date = date;
    await load();
  }

  Future<void> goToToday() => setDate(DayKey.today);

  Future<void> shiftDay(int days) {
    final DateTime shifted = DayKey.parse(_date).add(Duration(days: days));
    if (shifted.isAfter(DateTime.now())) return Future<void>.value();
    return setDate(DayKey.of(shifted));
  }

  /// Logs [quantity] of [product] against the current day and recalculates
  /// protein, calories and cost from the product's per-unit figures.
  Future<void> addFood({
    required Product product,
    required double quantity,
    required Meal meal,
    String? date,
  }) async {
    final FoodEntry entry = FoodEntry.calculate(
      product: product,
      quantity: quantity,
      date: date ?? _date,
      meal: meal,
    );
    final int id = await _repository.insert(entry);
    if (entry.date == _date) {
      _entries = <FoodEntry>[..._entries, entry.copyWith(id: id)];
      _recomputeTotals();
      notifyListeners();
    }
  }

  Future<void> updateEntry(FoodEntry entry) async {
    await _repository.update(entry);
    _entries =
        _entries.map((FoodEntry e) => e.id == entry.id ? entry : e).toList();
    _recomputeTotals();
    notifyListeners();
  }

  Future<void> deleteEntry(int id) async {
    await _repository.delete(id);
    _entries = _entries.where((FoodEntry e) => e.id != id).toList();
    _recomputeTotals();
    notifyListeners();
  }

  /// Restores a deleted entry, used by the undo action on the snackbar.
  Future<void> restoreEntry(FoodEntry entry) async {
    final int id = await _repository.insert(entry);
    if (entry.date == _date) {
      _entries = <FoodEntry>[..._entries, entry.copyWith(id: id)]
        ..sort(
          (FoodEntry a, FoodEntry b) => a.createdAt.compareTo(b.createdAt),
        );
      _recomputeTotals();
      notifyListeners();
    }
  }

  void _recomputeTotals() {
    double protein = 0;
    double calories = 0;
    double cost = 0;
    for (final FoodEntry entry in _entries) {
      protein += entry.protein;
      calories += entry.calories;
      cost += entry.cost;
    }
    _totals = DayTotals(
      date: _date,
      protein: protein,
      calories: calories,
      cost: cost,
      entryCount: _entries.length,
    );
  }
}
