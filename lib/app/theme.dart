import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get darkTheme => ThemeData(
    colorScheme: ColorScheme.dark(
      surface: Color(0xFF343538),
      onSurface: Colors.white,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: Color.fromARGB(255, 93, 33, 222),
      ),
    ),
  );
}
