// ============================================
// settings_screen.dart - App Settings
// ============================================

import 'package:flutter/cupertino.dart';
import '../services/theme_service.dart';

class SettingsScreen extends StatefulWidget {
  final Function() onThemeChanged;

  const SettingsScreen({
    super.key,
    required this.onThemeChanged,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AppTheme _selectedTheme;
  late AppLayout _selectedLayout;

  @override
  void initState() {
    super.initState();
    _selectedTheme = ThemeService.currentTheme;
    _selectedLayout = ThemeService.currentLayout;
  }

  Future<void> _changeTheme(AppTheme theme) async {
    await ThemeService.setTheme(theme);
    setState(() => _selectedTheme = theme);
    widget.onThemeChanged();
    _showSuccessMessage('Theme changed to ${ThemeService.themes[theme]!.name}');
  }

  Future<void> _changeLayout(AppLayout layout) async {
    await ThemeService.setLayout(layout);
    setState(() => _selectedLayout = layout);
    widget.onThemeChanged();
    _showSuccessMessage(
        'Layout changed to ${ThemeService.layouts[layout]!.name}');
  }

  void _showSuccessMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Icon(
          CupertinoIcons.checkmark_circle_fill,
          color: CupertinoColors.systemGreen,
          size: 48,
        ),
        content: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(message),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService.theme;

    return CupertinoPageScaffold(
      backgroundColor: theme.backgroundColor,
      navigationBar: CupertinoNavigationBar(
        backgroundColor: theme.surfaceColor.withOpacity(0.8),
        middle: Text('Settings', style: TextStyle(color: theme.textColor)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Theme Selection
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: theme.cardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.paintbrush,
                          color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Theme',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...AppTheme.values.map((themeOption) {
                    final themeData = ThemeService.themes[themeOption]!;
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: () => _changeTheme(themeOption),
                      child: Row(
                        children: [
                          Icon(
                            _selectedTheme == themeOption
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.circle,
                            color: themeData.primaryColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              themeData.name,
                              style: TextStyle(
                                fontSize: 16,
                                color: theme.textColor,
                                fontWeight: _selectedTheme == themeOption
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              _ColorDot(color: themeData.primaryColor),
                              const SizedBox(width: 4),
                              _ColorDot(color: themeData.secondaryColor),
                              const SizedBox(width: 4),
                              _ColorDot(color: themeData.accentColor),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Layout Selection
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: theme.cardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.rectangle_grid_2x2,
                          color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Layout',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...AppLayout.values.map((layoutOption) {
                    final layoutData = ThemeService.layouts[layoutOption]!;
                    return CupertinoButton(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      onPressed: () => _changeLayout(layoutOption),
                      child: Row(
                        children: [
                          Icon(
                            _getLayoutIcon(layoutOption),
                            color: _selectedLayout == layoutOption
                                ? theme.primaryColor
                                : theme.textColor.withOpacity(0.5),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  layoutData.name,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: theme.textColor,
                                    fontWeight: _selectedLayout == layoutOption
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                Text(
                                  layoutData.description,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textColor.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (_selectedLayout == layoutOption)
                            Icon(
                              CupertinoIcons.checkmark_circle_fill,
                              color: theme.primaryColor,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Info Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: theme.cardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.info_circle,
                          color: theme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Tips',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Choose a theme that matches your mood and environment\n'
                    '• Select a layout based on your playing style\n'
                    '• Settings are saved automatically\n'
                    '• Restart the app to see all changes',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textColor.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getLayoutIcon(AppLayout layout) {
    switch (layout) {
      case AppLayout.compact:
        return CupertinoIcons.square_stack_3d_down_right;
      case AppLayout.standard:
        return CupertinoIcons.rectangle_grid_2x2;
      case AppLayout.expanded:
        return CupertinoIcons.rectangle_split_3x3;
      case AppLayout.professional:
        return CupertinoIcons.slider_horizontal_3;
    }
  }
}

class _ColorDot extends StatelessWidget {
  final Color color;

  const _ColorDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: CupertinoColors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}
