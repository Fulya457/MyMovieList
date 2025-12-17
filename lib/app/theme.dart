import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundBlack = Color(0xFF12141C);
  static const Color surfaceDark = Color(0xFF1E202B);
  static const Color primaryBlue = Color(
    0xFF09FBD3,
  ); // Neonumsu modern bir mavi/turkuaz
  static const Color accentPink = Color(0xFFFE53BB); // Vurgular için
  static const Color textWhite = Color(0xFFF2F2F2);
  AppTheme._();

  // Renk Paleti (Dark & Blue)
  // Vurgular için

  static ThemeData get darkTheme => ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: backgroundBlack,
    primaryColor: primaryBlue,

    // AppBar (Üst Kısım) Teması
    appBarTheme: const AppBarTheme(
      backgroundColor:
          backgroundBlack, // Üst taraf siyah olsun ki mavi yazı parlasın
      elevation: 0,
      centerTitle: true,
      iconTheme: IconThemeData(color: primaryBlue),
      titleTextStyle: TextStyle(
        color: primaryBlue,
        fontSize: 22,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.0,
      ),
    ),

    // Alt Menü
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: backgroundBlack,
      indicatorColor: primaryBlue.withOpacity(0.2),
      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: primaryBlue);
        }
        return const IconThemeData(color: Colors.grey);
      }),
    ),

    // Genel Renk Şeması
    colorScheme: const ColorScheme.dark(
      surface: surfaceDark,
      onSurface: Colors.white,
      primary: primaryBlue,
      secondary: primaryBlue,
    ),
  );
}
