import 'package:flutter/material.dart';

/// Couleurs centralisées utilisées dans l’interface du forum.
abstract final class AppColors {
  // Fonds presque noirs et surfaces étagées pour distinguer les cartes sans bruit.
  static const background = Color(0xFF0D0E12);
  static const surface = Color(0xFF17181E);
  static const surfaceRaised = Color(0xFF202129);

  // Contraste élevé pour le texte, accent violet et contours discrets.
  static const ink = Color(0xFFF5F5F7);
  static const muted = Color(0xFFA1A2AE);
  static const violet = Color(0xFFB29BFF);
  static const indicator = Color(0xFF302744);
  static const border = Color(0xFF30313A);
}

/// Définit le thème sombre commun basé sur Material 3.
abstract final class AppTheme {
  static final dark = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.violet,
      brightness: Brightness.dark,
      surface: AppColors.surface,
    ),
    // Harmonise les libellés de la barre d’onglets.
    navigationBarTheme: const NavigationBarThemeData(
      labelTextStyle: WidgetStatePropertyAll(
        TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    // Applique le même style aux champs des formulaires.
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surfaceRaised,
      hintStyle: const TextStyle(color: AppColors.muted, fontSize: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.violet, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.surfaceRaised,
      contentTextStyle: const TextStyle(color: AppColors.ink),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}
