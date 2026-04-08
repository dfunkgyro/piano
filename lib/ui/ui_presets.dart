import 'package:flutter/cupertino.dart';

class UiStylePreset {
  final String name;
  final Color background;
  final Color surface;
  final Color primary;
  final Color secondary;
  final Color text;
  final Color accent;
  final Brightness brightness;

  const UiStylePreset({
    required this.name,
    required this.background,
    required this.surface,
    required this.primary,
    required this.secondary,
    required this.text,
    required this.accent,
    required this.brightness,
  });
}

class UiLayoutPreset {
  final String name;
  final EdgeInsets contentPadding;
  final double panelSpacing;
  final double keyboardHeight;
  final bool keyboardOnTop;
  final bool compactControls;
  final bool libraryGrid;
  final double cardRadius;
  final bool showGradient;

  const UiLayoutPreset({
    required this.name,
    required this.contentPadding,
    required this.panelSpacing,
    required this.keyboardHeight,
    required this.keyboardOnTop,
    required this.compactControls,
    required this.libraryGrid,
    required this.cardRadius,
    required this.showGradient,
  });
}

class UiPresets {
  static const List<UiStylePreset> styles = [
    UiStylePreset(
      name: 'Professional',
      background: Color(0xFF0B0F1A),
      surface: Color(0xFF162233),
      primary: Color(0xFF86C5FF),
      secondary: Color(0xFFF2C14E),
      text: Color(0xFFF8F7F3),
      accent: Color(0xFF6EEB83),
      brightness: Brightness.dark,
    ),
    UiStylePreset(
      name: 'Minimalist',
      background: Color(0xFF0D1117),
      surface: Color(0xFF1A1F27),
      primary: Color(0xFFB6BEC9),
      secondary: Color(0xFF8FA2B7),
      text: Color(0xFFE8EAED),
      accent: Color(0xFF5BC0EB),
      brightness: Brightness.dark,
    ),
    UiStylePreset(
      name: 'Classic',
      background: Color(0xFF1B1511),
      surface: Color(0xFF2A211A),
      primary: Color(0xFFE3C38B),
      secondary: Color(0xFFC28F55),
      text: Color(0xFFF6EBDD),
      accent: Color(0xFFD98C52),
      brightness: Brightness.dark,
    ),
    UiStylePreset(
      name: 'Futuristic',
      background: Color(0xFF05070D),
      surface: Color(0xFF111827),
      primary: Color(0xFF7C4DFF),
      secondary: Color(0xFF22D3EE),
      text: Color(0xFFEFF6FF),
      accent: Color(0xFF00F5D4),
      brightness: Brightness.dark,
    ),
    UiStylePreset(
      name: 'Dark Wood',
      background: Color(0xFF16100C),
      surface: Color(0xFF2A1E15),
      primary: Color(0xFFD1A46D),
      secondary: Color(0xFF8C5A2B),
      text: Color(0xFFF5E8D8),
      accent: Color(0xFFB66A3C),
      brightness: Brightness.dark,
    ),
    UiStylePreset(
      name: 'Studio',
      background: Color(0xFF0C0C0E),
      surface: Color(0xFF1A1A1E),
      primary: Color(0xFF5EEAD4),
      secondary: Color(0xFFE879F9),
      text: Color(0xFFF5F5F5),
      accent: Color(0xFFF97316),
      brightness: Brightness.dark,
    ),
  ];

  static const List<UiLayoutPreset> layouts = [
    UiLayoutPreset(
      name: 'Balanced',
      contentPadding: EdgeInsets.all(16),
      panelSpacing: 12,
      keyboardHeight: 200,
      keyboardOnTop: false,
      compactControls: false,
      libraryGrid: false,
      cardRadius: 14,
      showGradient: true,
    ),
    UiLayoutPreset(
      name: 'Studio Wide',
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      panelSpacing: 16,
      keyboardHeight: 220,
      keyboardOnTop: false,
      compactControls: true,
      libraryGrid: true,
      cardRadius: 18,
      showGradient: true,
    ),
    UiLayoutPreset(
      name: 'Compact Focus',
      contentPadding: EdgeInsets.all(10),
      panelSpacing: 8,
      keyboardHeight: 170,
      keyboardOnTop: false,
      compactControls: true,
      libraryGrid: false,
      cardRadius: 10,
      showGradient: false,
    ),
    UiLayoutPreset(
      name: 'Performance',
      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      panelSpacing: 10,
      keyboardHeight: 240,
      keyboardOnTop: true,
      compactControls: true,
      libraryGrid: false,
      cardRadius: 12,
      showGradient: true,
    ),
    UiLayoutPreset(
      name: 'Lessons Stage',
      contentPadding: EdgeInsets.all(14),
      panelSpacing: 14,
      keyboardHeight: 190,
      keyboardOnTop: false,
      compactControls: false,
      libraryGrid: true,
      cardRadius: 16,
      showGradient: true,
    ),
    UiLayoutPreset(
      name: 'Minimal Grid',
      contentPadding: EdgeInsets.all(12),
      panelSpacing: 10,
      keyboardHeight: 180,
      keyboardOnTop: false,
      compactControls: true,
      libraryGrid: true,
      cardRadius: 8,
      showGradient: false,
    ),
  ];
}
