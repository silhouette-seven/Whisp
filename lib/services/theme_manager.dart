import 'package:flutter/material.dart';

enum AppTheme { forest, ocean, lava }

class ThemeManager {
  static final ThemeManager _instance = ThemeManager._internal();
  factory ThemeManager() => _instance;
  ThemeManager._internal();

  final ValueNotifier<AppTheme> currentTheme = ValueNotifier(AppTheme.forest);

  void setTheme(AppTheme theme) {
    currentTheme.value = theme;
  }

  String getBackgroundImage(AppTheme theme) {
    switch (theme) {
      case AppTheme.forest:
        return 'assets/forest.jpg';
      case AppTheme.ocean:
        return 'assets/ocean.jpg';
      case AppTheme.lava:
        return 'assets/lava.jpg';
    }
  }

  Color getThemeColor(AppTheme theme) {
    switch (theme) {
      case AppTheme.forest:
        return Colors.green;
      case AppTheme.ocean:
        return Colors.blue;
      case AppTheme.lava:
        return Colors.orange;
    }
  }

  String getThemeName(AppTheme theme) {
    switch (theme) {
      case AppTheme.forest:
        return 'Forest';
      case AppTheme.ocean:
        return 'Ocean';
      case AppTheme.lava:
        return 'Lava';
    }
  }
}
