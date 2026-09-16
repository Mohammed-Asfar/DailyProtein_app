import 'package:flutter/material.dart';

import 'settings_repository.dart';

/// App-wide settings state. Held above [MaterialApp] so a theme change
/// rebuilds the whole tree.
class SettingsController extends ChangeNotifier {
  SettingsController({SettingsRepository? repository})
      : _repository = repository ?? SettingsRepository();

  final SettingsRepository _repository;

  ThemeMode _themeMode = ThemeMode.system;
  double _proteinGoal = SettingsRepository.defaultGoal;
  double _calorieGoal = SettingsRepository.defaultCalorieGoal;
  String _currencySymbol = SettingsRepository.defaultCurrency;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  double get proteinGoal => _proteinGoal;
  double get calorieGoal => _calorieGoal;
  String get currencySymbol => _currencySymbol;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _themeMode = await _repository.themeMode();
    _proteinGoal = await _repository.proteinGoal();
    _calorieGoal = await _repository.calorieGoal();
    _currencySymbol = await _repository.currencySymbol();
    _loaded = true;
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    await _repository.setThemeMode(mode);
  }

  Future<void> setProteinGoal(double value) async {
    _proteinGoal = value;
    notifyListeners();
    await _repository.setProteinGoal(value);
  }

  Future<void> setCalorieGoal(double value) async {
    _calorieGoal = value;
    notifyListeners();
    await _repository.setCalorieGoal(value);
  }

  Future<void> setCurrencySymbol(String value) async {
    _currencySymbol = value;
    notifyListeners();
    await _repository.setCurrencySymbol(value);
  }
}
