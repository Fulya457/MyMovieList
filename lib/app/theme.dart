// Dosya: lib/app/theme.dart

import 'package:flutter/material.dart';
import 'package:mymovielist/data/movie_manager.dart';

class AppTheme {
  AppTheme._();

  // --- RENK PALETİ ---

  // Karanlık Mod (Dark) - Orijinal
  static const int _darkBgInt = 0xFF12141C;
  static const Color _darkSurface = Color(0xFF1E202B);
  static const Color _darkPrimary = Color(0xFF09FBD3);
  static const Color _darkText = Color(0xFFF2F2F2);

  // Aydınlık Mod (Light) - GÜNCELLENDİ
  // Arka Plan: "Blue Grey 100" (Hafif Mavi-Gri, çiğ beyaz değil)
  static const int _lightBgInt = 0xFFCFD8DC;

  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightPrimary = Color(0xFF2962FF);

  // Yazı Rengi: "Derin Okyanus Mavisi / Lacivert" (Net okunur, siyah değil)
  static const Color _lightText = Color(0xFF01377D);

  static const Color accentPink = Color(0xFFFE53BB);

  // --- DİNAMİK GETTER'LAR ---

  static Color get primaryBlue =>
      MovieManager.instance.isDarkMode ? _darkPrimary : _lightPrimary;

  static Color get backgroundBlack => MovieManager.instance.isDarkMode
      ? const Color(_darkBgInt)
      : const Color(_lightBgInt);

  static Color get surfaceDark =>
      MovieManager.instance.isDarkMode ? _darkSurface : _lightSurface;

  static Color get textColor =>
      MovieManager.instance.isDarkMode ? _darkText : _lightText;

  static Color get iconColor =>
      MovieManager.instance.isDarkMode ? Colors.white : const Color(0xFF455A64);

  // --- TEMA OLUŞTURUCU ---
  static ThemeData get currentTheme {
    final bool isDark = MovieManager.instance.isDarkMode;

    final roundedShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: backgroundBlack,
      primaryColor: primaryBlue,

      textTheme: TextTheme(
        bodyMedium: TextStyle(color: textColor),
        bodyLarge: TextStyle(color: textColor),
        titleLarge: TextStyle(color: textColor, fontWeight: FontWeight.bold),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: backgroundBlack,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : _lightPrimary),
        titleTextStyle: TextStyle(
          color: primaryBlue,
          fontSize: 22,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),

      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? const Color(_darkBgInt) : Colors.white,
        indicatorColor: primaryBlue.withValues(alpha: 0.2),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            color: isDark ? Colors.white70 : Colors.black54,
            fontSize: 12,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: primaryBlue);
          }
          return IconThemeData(color: isDark ? Colors.grey : Colors.grey[600]);
        }),
      ),

      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: isDark ? 0 : 2,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        shape: roundedShape,
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceDark,
        modalBackgroundColor: surfaceDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: TextStyle(
          color: textColor.withValues(alpha: 0.8),
          fontSize: 16,
        ),
      ),

      colorScheme: isDark
          ? const ColorScheme.dark(
              surface: _darkSurface,
              onSurface: Colors.white,
              primary: _darkPrimary,
              secondary: accentPink,
            )
          : const ColorScheme.light(
              surface: _lightSurface,
              onSurface: _lightText,
              primary: _lightPrimary,
              secondary: accentPink,
            ),
    );
  }
}
