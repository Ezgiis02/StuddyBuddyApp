// lib/core/config/theme_service.dart

import 'package:flutter/material.dart';

// 1. ThemeMode değişikliğini takip eden bir notifier (bildirici)
class ThemeService extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  void toggleTheme() {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    notifyListeners(); // Dinleyicilere durumu güncellemesini söyler
  }
}

// 2. Uygulama genelinde erişilebilecek tek bir servis örneği
final themeService = ThemeService();
