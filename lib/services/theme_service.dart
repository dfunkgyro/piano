// ============================================
// theme_service.dart - Complete Theme Service
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppTheme {
  classic,
  dark,
  ocean,
  sunset,
}

enum AppLayout {
  compact,
  standard,
  expanded,
  professional,
}

class ThemeData {
  final String name;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final Color surfaceColor;
  final Color textColor;
  final Color accentColor;
  final Gradient backgroundGradient;
  final Gradient cardGradient;
  final Brightness brightness;

  const ThemeData({
    required this.name,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.surfaceColor,
    required this.textColor,
    required this.accentColor,
    required this.backgroundGradient,
    required this.cardGradient,
    required this.brightness,
  });
}

class LayoutData {
  final String name;
  final String description;
  final double keyboardHeight;
  final bool showQuickStats;
  final bool showAIBanner;
  final bool compactControls;
  final EdgeInsets padding;

  const LayoutData({
    required this.name,
    required this.description,
    required this.keyboardHeight,
    required this.showQuickStats,
    required this.showAIBanner,
    required this.compactControls,
    required this.padding,
  });
}

class ThemeService {
  static const String _themeKey = 'app_theme';
  static const String _layoutKey = 'app_layout';

  // Theme definitions
  static const Map<AppTheme, ThemeData> themes = {
    AppTheme.classic: ThemeData(
      name: 'Classic Piano',
      primaryColor: CupertinoColors.systemBlue,
      secondaryColor: CupertinoColors.systemIndigo,
      backgroundColor: CupertinoColors.systemBackground,
      surfaceColor: CupertinoColors.white,
      textColor: CupertinoColors.black,
      accentColor: CupertinoColors.systemGreen,
      backgroundGradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          CupertinoColors.systemGroupedBackground,
          CupertinoColors.white,
        ],
      ),
      cardGradient: LinearGradient(
        colors: [
          CupertinoColors.white,
          Color(0xFFF5F5F7),
        ],
      ),
      brightness: Brightness.light,
    ),
    AppTheme.dark: ThemeData(
      name: 'Midnight Concert',
      primaryColor: CupertinoColors.systemIndigo,
      secondaryColor: CupertinoColors.systemPurple,
      backgroundColor: Color(0xFF1C1C1E),
      surfaceColor: Color(0xFF2C2C2E),
      textColor: CupertinoColors.white,
      accentColor: CupertinoColors.systemPurple,
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF1C1C1E),
          Color(0xFF2C2C2E),
          Color(0xFF3A3A3C),
        ],
      ),
      cardGradient: LinearGradient(
        colors: [
          Color(0xFF2C2C2E),
          Color(0xFF3A3A3C),
        ],
      ),
      brightness: Brightness.dark,
    ),
    AppTheme.ocean: ThemeData(
      name: 'Ocean Breeze',
      primaryColor: CupertinoColors.systemTeal,
      secondaryColor: CupertinoColors.systemBlue,
      backgroundColor: Color(0xFFE0F7FA),
      surfaceColor: Color(0xFFB2EBF2),
      textColor: Color(0xFF006064),
      accentColor: CupertinoColors.systemCyan,
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF80DEEA),
          Color(0xFF4DD0E1),
          Color(0xFF26C6DA),
        ],
      ),
      cardGradient: LinearGradient(
        colors: [
          Color(0xFFB2EBF2),
          Color(0xFF80DEEA),
        ],
      ),
      brightness: Brightness.light,
    ),
    AppTheme.sunset: ThemeData(
      name: 'Sunset Symphony',
      primaryColor: CupertinoColors.systemOrange,
      secondaryColor: CupertinoColors.systemPink,
      backgroundColor: Color(0xFFFFF3E0),
      surfaceColor: Color(0xFFFFE0B2),
      textColor: Color(0xFFE65100),
      accentColor: CupertinoColors.systemRed,
      backgroundGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFCC80),
          Color(0xFFFFB74D),
          Color(0xFFFFA726),
        ],
      ),
      cardGradient: LinearGradient(
        colors: [
          Color(0xFFFFE0B2),
          Color(0xFFFFCC80),
        ],
      ),
      brightness: Brightness.light,
    ),
  };

  // Layout definitions
  static const Map<AppLayout, LayoutData> layouts = {
    AppLayout.compact: LayoutData(
      name: 'Compact',
      description: 'Minimal interface for maximum keyboard space',
      keyboardHeight: 250,
      showQuickStats: false,
      showAIBanner: false,
      compactControls: true,
      padding: EdgeInsets.all(8),
    ),
    AppLayout.standard: LayoutData(
      name: 'Standard',
      description: 'Balanced layout with all essential features',
      keyboardHeight: 200,
      showQuickStats: true,
      showAIBanner: true,
      compactControls: false,
      padding: EdgeInsets.all(16),
    ),
    AppLayout.expanded: LayoutData(
      name: 'Expanded',
      description: 'Spacious layout with enhanced visuals',
      keyboardHeight: 180,
      showQuickStats: true,
      showAIBanner: true,
      compactControls: false,
      padding: EdgeInsets.all(20),
    ),
    AppLayout.professional: LayoutData(
      name: 'Professional',
      description: 'Studio-grade interface with detailed controls',
      keyboardHeight: 220,
      showQuickStats: true,
      showAIBanner: true,
      compactControls: false,
      padding: EdgeInsets.all(16),
    ),
  };

  static AppTheme _currentTheme = AppTheme.classic;
  static AppLayout _currentLayout = AppLayout.standard;

  static Future<void> loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final themeIndex = prefs.getInt(_themeKey) ?? 0;
      final layoutIndex = prefs.getInt(_layoutKey) ?? 1;

      _currentTheme = AppTheme.values[themeIndex];
      _currentLayout = AppLayout.values[layoutIndex];
    } catch (e) {
      print('Error loading theme: $e');
    }
  }

  static Future<void> setTheme(AppTheme theme) async {
    _currentTheme = theme;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, theme.index);
  }

  static Future<void> setLayout(AppLayout layout) async {
    _currentLayout = layout;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_layoutKey, layout.index);
  }

  static AppTheme get currentTheme => _currentTheme;
  static AppLayout get currentLayout => _currentLayout;
  static ThemeData get theme => themes[_currentTheme]!;
  static LayoutData get layout => layouts[_currentLayout]!;
}
