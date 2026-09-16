import 'package:flutter/material.dart';

/// Single source of truth for every colour in the app.
/// Nothing else in the codebase should declare a raw [Color].
///
/// Values come from the agreed design spec. Each theme names its own
/// primary, accent, background, surface and text; everything else in the
/// app is derived from these by [AppTheme].
class AppColors {
  const AppColors._();

  // ---- Dark theme -----------------------------------------------------
  static const Color darkPrimary = Color(0xFF50C4BE);
  static const Color darkAccent = Color(0xFFFFB547);
  static const Color darkBackground = Color(0xFF0B1212);
  static const Color darkSurface = Color(0xFF121D1C);
  static const Color darkText = Color(0xFFF1F5F4);

  // ---- Light theme ----------------------------------------------------
  static const Color lightPrimary = Color(0xFF159A95);
  static const Color lightAccent = Color(0xFFF59E0B);
  static const Color lightBackground = Color(0xFFF7F9F8);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF17201F);

  // ---- Derived surfaces -----------------------------------------------
  // Raised fills (inputs, chips, track backgrounds) and hairline borders,
  // tuned to sit just off the surface colour in each theme.
  static const Color darkSurfaceAlt = Color(0xFF1B2726);
  static const Color darkOutline = Color(0xFF263433);
  static const Color darkTextSecondary = Color(0xFF9BAFAD);

  static const Color lightSurfaceAlt = Color(0xFFEDF3F2);
  static const Color lightOutline = Color(0xFFDDE6E4);
  static const Color lightTextSecondary = Color(0xFF5F706E);

  // ---- Accent for text ------------------------------------------------
  /// The accent is a fill colour; on a light surface it only reaches 2.15:1,
  /// so text that needs to read as "accent" uses these darkened variants
  /// instead. Dark mode can use the accent itself.
  static const Color darkAccentText = darkAccent;
  static const Color lightAccentText = Color(0xFF9A5D07);

  // ---- Semantic -------------------------------------------------------
  static const Color success = Color(0xFF2E9E5B);
  static const Color danger = Color(0xFFD2544B);

  // ---- Elevation ------------------------------------------------------
  /// Drop shadow under floating surfaces. Darker in dark mode, where the
  /// surface sits on a near-black ground and needs more separation.
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x66000000);

  /// Chart series palette, index-safe via modulo. Leads with the theme
  /// primary and accent, then steps through supporting tones.
  static const List<Color> chartSeries = <Color>[
    darkPrimary,
    darkAccent,
    Color(0xFF6BA292),
    Color(0xFF8FBF9F),
    Color(0xFF3E7C76),
  ];
}
