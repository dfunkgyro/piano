import 'package:flutter/cupertino.dart';
import '../utils/app_theme.dart';
import 'ui_controller.dart';
import 'ui_presets.dart';

class UiSwitcher extends StatelessWidget {
  const UiSwitcher({super.key});

  void _showStylePicker(BuildContext context, AppTheme theme) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Style'),
          actions: [
            for (int i = 0; i < UiPresets.styles.length; i++)
              CupertinoActionSheetAction(
                onPressed: () {
                  UiController.setStyle(i);
                  Navigator.of(context).pop();
                },
                child: Text(UiPresets.styles[i].name),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  void _showLayoutPicker(BuildContext context, AppTheme theme) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Layout'),
          actions: [
            for (int i = 0; i < UiPresets.layouts.length; i++)
              CupertinoActionSheetAction(
                onPressed: () {
                  UiController.setLayout(i);
                  Navigator.of(context).pop();
                },
                child: Text(UiPresets.layouts[i].name),
              ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UiController.config,
      builder: (context, config, _) {
        final style = UiPresets.styles[config.styleIndex];
        final theme = AppTheme.fromStyle(
          background: style.background,
          surface: style.surface,
          primary: style.primary,
          secondary: style.secondary,
          text: style.text,
          accent: style.accent,
          brightness: style.brightness,
        );
        return Row(
          children: [
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: theme.surfaceColor,
              onPressed: () => _showStylePicker(context, theme),
              child: Text(
                UiPresets.styles[config.styleIndex].name,
                style: TextStyle(color: theme.textColor, fontSize: 11),
              ),
            ),
            const SizedBox(width: 6),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: theme.surfaceColor,
              onPressed: () => _showLayoutPicker(context, theme),
              child: Text(
                UiPresets.layouts[config.layoutIndex].name,
                style: TextStyle(color: theme.textColor, fontSize: 11),
              ),
            ),
          ],
        );
      },
    );
  }
}
