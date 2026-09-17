import 'package:flutter/material.dart';

import '../../../core/models/body_profile.dart';
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
  bool _checkForUpdates = SettingsRepository.defaultCheckForUpdates;
  bool _hasOnboarded = false;
  FitnessGoal _fitnessGoal = FitnessGoal.maintainWeight;
  bool _loaded = false;

  ThemeMode get themeMode => _themeMode;
  double get proteinGoal => _proteinGoal;
  double get calorieGoal => _calorieGoal;
  String get currencySymbol => _currencySymbol;
  bool get checkForUpdates => _checkForUpdates;
  bool get hasOnboarded => _hasOnboarded;
  FitnessGoal get fitnessGoal => _fitnessGoal;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    _themeMode = await _repository.themeMode();
    _proteinGoal = await _repository.proteinGoal();
    _calorieGoal = await _repository.calorieGoal();
    _currencySymbol = await _repository.currencySymbol();
    _checkForUpdates = await _repository.checkForUpdates();
    _hasOnboarded = await _repository.hasOnboarded();
    _fitnessGoal = await _repository.fitnessGoal();
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

  Future<void> setFitnessGoal(FitnessGoal goal) async {
    _fitnessGoal = goal;
    notifyListeners();
    await _repository.setFitnessGoal(goal);
  }

  /// Marks the welcome flow done so it does not show again.
  Future<void> completeOnboarding() async {
    if (_hasOnboarded) return;
    _hasOnboarded = true;
    notifyListeners();
    await _repository.setOnboarded(true);
  }

  Future<void> setCheckForUpdates(bool value) async {
    if (value == _checkForUpdates) return;
    _checkForUpdates = value;
    notifyListeners();
    await _repository.setCheckForUpdates(value);
  }
}
