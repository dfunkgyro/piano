import 'package:flutter/cupertino.dart';
import 'theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _wakeLockEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedTheme = ThemeService.currentTheme;
    _selectedLayout = ThemeService.currentLayout;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _wakeLockEnabled = prefs.getBool('wake_lock_enabled') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading settings: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleWakeLock(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('wake_lock_enabled', enabled);
      setState(() => _wakeLockEnabled = enabled);

      _showSuccessMessage(enabled
          ? 'Screen will stay on during practice'
          : 'Normal sleep mode enabled');
    } catch (e) {
      print('Error toggling wake lock: $e');
    }
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
        middle: Text(
          'Settings',
          style: TextStyle(color: theme.textColor),
        ),
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
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.paintbrush_fill,
                        color: theme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Theme',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Theme Cards
                  ...AppTheme.values.map((themeOption) {
                    final themeData = ThemeService.themes[themeOption]!;
                    final isSelected = _selectedTheme == themeOption;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _changeTheme(themeOption),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: themeData.backgroundGradient,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.primaryColor
                                  : CupertinoColors.systemGrey5,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  gradient: themeData.cardGradient,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: themeData.primaryColor,
                                    width: 2,
                                  ),
                                ),
                                child: Icon(
                                  CupertinoIcons.color_filter,
                                  color: themeData.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      themeData.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: themeData.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        _ColorDot(
                                            color: themeData.primaryColor),
                                        const SizedBox(width: 6),
                                        _ColorDot(
                                            color: themeData.secondaryColor),
                                        const SizedBox(width: 6),
                                        _ColorDot(color: themeData.accentColor),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  CupertinoIcons.checkmark_circle_fill,
                                  color: theme.primaryColor,
                                  size: 32,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Layout Selection
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: theme.cardGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.rectangle_3_offgrid,
                        color: theme.primaryColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Layout',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: theme.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Layout Cards
                  ...AppLayout.values.map((layoutOption) {
                    final layoutData = ThemeService.layouts[layoutOption]!;
                    final isSelected = _selectedLayout == layoutOption;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => _changeLayout(layoutOption),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.primaryColor.withOpacity(0.1)
                                : theme.surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.primaryColor
                                  : CupertinoColors.systemGrey5,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getLayoutIcon(layoutOption),
                                  color: theme.primaryColor,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      layoutData.name,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: theme.textColor,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      layoutData.description,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.textColor.withOpacity(0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  CupertinoIcons.checkmark_circle_fill,
                                  color: theme.primaryColor,
                                  size: 32,
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        CupertinoIcons.info_circle_fill,
                        color: theme.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'About Customization',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.primaryColor,
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
        border: Border.all(
          color: CupertinoColors.white,
          width: 2,
        ),
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
