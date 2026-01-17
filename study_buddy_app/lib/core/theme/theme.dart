import 'package:flutter/material.dart';

// ----------------------
// LIGHT THEME
// ----------------------
final ThemeData lightTheme =
    ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5), // gri-beyaz
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.light,
      ),
    ).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
      ),

      // Yeni Material 3 tipi
      cardTheme: CardThemeData(
        elevation: 2,
        color: Colors.white,
        surfaceTintColor: Colors.transparent, // gölge patlamasını engeller
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );

// ----------------------
// DARK THEME
// ----------------------
final ThemeData darkTheme =
    ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF1A002E), // çok koyu mor
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.deepPurple,
        brightness: Brightness.dark,
      ),
    ).copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1A002E),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 1,
      ),

      cardTheme: CardThemeData(
        elevation: 4,
        color: const Color(0xFF2C004B), // koyu mor kart rengi
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
