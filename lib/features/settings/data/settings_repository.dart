import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User preferences backed by SharedPreferences.
class SettingsRepository {
  static const String _kGoal = 'daily_protein_goal';
  static const String _kCalorieGoal = 'daily_calorie_goal';
  static const String _kThemeMode = 'theme_mode';
  static const String _kCurrency = 'currency_symbol';

  static const double defaultGoal = 120;
  static const double defaultCalorieGoal = 2000;
  static const String defaultCurrency = '₹';

  Future<SharedPreferences> get _prefs => SharedPreferences.getInstance();

  Future<double> proteinGoal() async =>
      (await _prefs).getDouble(_kGoal) ?? defaultGoal;

  Future<void> setProteinGoal(double value) async =>
      (await _prefs).setDouble(_kGoal, value);

  Future<double> calorieGoal() async =>
      (await _prefs).getDouble(_kCalorieGoal) ?? defaultCalorieGoal;

  Future<void> setCalorieGoal(double value) async =>
      (await _prefs).setDouble(_kCalorieGoal, value);

  Future<String> currencySymbol() async =>
      (await _prefs).getString(_kCurrency) ?? defaultCurrency;

  Future<void> setCurrencySymbol(String value) async =>
      (await _prefs).setString(_kCurrency, value);

  Future<ThemeMode> themeMode() async {
    final String? raw = (await _prefs).getString(_kThemeMode);
    return ThemeMode.values.firstWhere(
      (ThemeMode m) => m.name == raw,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async =>
      (await _prefs).setString(_kThemeMode, mode.name);
}
