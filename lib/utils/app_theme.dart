import 'package:flutter/cupertino.dart';

class AppTheme {
  final Color backgroundColor;
  final Color surfaceColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color textColor;
  final Brightness brightness;
  final Color accentColor;

  const AppTheme({
    required this.backgroundColor,
    required this.surfaceColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.textColor,
    required this.accentColor,
    required this.brightness,
  });

  static const AppTheme dark = AppTheme(
    backgroundColor: Color(0xFF0B0F1A),
    surfaceColor: Color(0xFF161B26),
    primaryColor: Color(0xFF8DE4FF),
    secondaryColor: Color(0xFFF4D06F),
    textColor: Color(0xFFF8F7F3),
    accentColor: Color(0xFF6EEB83),
    brightness: Brightness.dark,
  );

  factory AppTheme.fromStyle({
    required Color background,
    required Color surface,
    required Color primary,
    required Color secondary,
    required Color text,
    required Color accent,
    Brightness brightness = Brightness.dark,
  }) {
    return AppTheme(
      backgroundColor: background,
      surfaceColor: surface,
      primaryColor: primary,
      secondaryColor: secondary,
      textColor: text,
      accentColor: accent,
      brightness: brightness,
    );
  }
}
