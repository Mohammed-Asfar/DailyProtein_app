import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/models/body_profile.dart';

/// User preferences backed by SharedPreferences.
class SettingsRepository {
  static const String _kGoal = 'daily_protein_goal';
  static const String _kCalorieGoal = 'daily_calorie_goal';
  static const String _kThemeMode = 'theme_mode';
  static const String _kCurrency = 'currency_symbol';
  static const String _kUpdateCheck = 'check_for_updates';
  static const String _kOnboarded = 'onboarding_complete';
  static const String _kGoalKind = 'fitness_goal';

  static const double defaultGoal = 120;
  static const double defaultCalorieGoal = 2000;
  static const String defaultCurrency = '₹';

  /// On by default: an offline app that never mentions a new build
  /// leaves users on a stale version indefinitely.
  static const bool defaultCheckForUpdates = true;

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

  Future<bool> checkForUpdates() async =>
      (await _prefs).getBool(_kUpdateCheck) ?? defaultCheckForUpdates;

  Future<void> setCheckForUpdates(bool value) async =>
      (await _prefs).setBool(_kUpdateCheck, value);

  /// Whether the welcome flow has been completed. Absent on a fresh
  /// install, which is what makes it show exactly once.
  Future<bool> hasOnboarded() async =>
      (await _prefs).getBool(_kOnboarded) ?? false;

  Future<void> setOnboarded(bool value) async =>
      (await _prefs).setBool(_kOnboarded, value);

  /// What the user said they were after during onboarding. Kept so the
  /// choice can be shown and revisited, not just used once.
  Future<FitnessGoal> fitnessGoal() async {
    final String? raw = (await _prefs).getString(_kGoalKind);
    return FitnessGoal.values.firstWhere(
      (FitnessGoal g) => g.name == raw,
      orElse: () => FitnessGoal.maintainWeight,
    );
  }

  Future<void> setFitnessGoal(FitnessGoal goal) async =>
      (await _prefs).setString(_kGoalKind, goal.name);

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
