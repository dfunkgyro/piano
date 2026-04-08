import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../services/app_debug_log_service.dart';
import '../ui/ui_controller.dart';
import '../ui/ui_presets.dart';
import '../ui/ui_switcher.dart';
import '../utils/app_theme.dart';
import '../widgets/motion_fx.dart';

class SafeDebugScreen extends StatelessWidget {
  const SafeDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UiController.config,
      builder: (context, config, _) {
        final style = UiPresets.styles[config.styleIndex];
        final layout = UiPresets.layouts[config.layoutIndex];
        final theme = AppTheme.fromStyle(
          background: style.background,
          surface: style.surface,
          primary: style.primary,
          secondary: style.secondary,
          text: style.text,
          accent: style.accent,
          brightness: style.brightness,
        );

        return CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: theme.surfaceColor,
            middle: Text('Debug', style: TextStyle(color: theme.textColor)),
            trailing: const UiSwitcher(),
          ),
          child: MotionBackdrop(
            backgroundColor: theme.backgroundColor,
            surfaceColor: theme.surfaceColor,
            accentColor: theme.primaryColor,
            child: SafeArea(
              child: ValueListenableBuilder<List<String>>(
                valueListenable: AppDebugLogService.instance.logs,
                builder: (context, logs, _) {
                  return Column(
                    children: [
                      Padding(
                        padding: layout.contentPadding,
                        child: MotionCard(
                          color: theme.surfaceColor.withOpacity(0.74),
                          borderColor: theme.textColor.withOpacity(0.1),
                          radius: layout.cardRadius,
                          glowColor: theme.primaryColor,
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Debug Log',
                                style: TextStyle(
                                  color: theme.textColor,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Copy this log and send it back for troubleshooting Bluetooth, MIDI parsing, bridge, and runtime issues.',
                                style: TextStyle(
                                  color: theme.textColor.withOpacity(0.72),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: CupertinoButton(
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                      color: theme.primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                      onPressed: () async {
                                        await Clipboard.setData(
                                          ClipboardData(
                                            text: AppDebugLogService.instance.exportText(),
                                          ),
                                        );
                                      },
                                      child: const Text('Copy Logs'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  CupertinoButton(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    color: theme.surfaceColor.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(12),
                                    onPressed: AppDebugLogService.instance.clear,
                                    child: Text(
                                      'Clear',
                                      style: TextStyle(color: theme.textColor),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: logs.isEmpty
                            ? Center(
                                child: Text(
                                  'No logs yet.',
                                  style: TextStyle(
                                    color: theme.textColor.withOpacity(0.7),
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.fromLTRB(
                                  layout.contentPadding.left,
                                  0,
                                  layout.contentPadding.right,
                                  layout.contentPadding.bottom,
                                ),
                                itemCount: logs.length,
                                itemBuilder: (context, index) {
                                  final entry = logs[logs.length - 1 - index];
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.surfaceColor.withOpacity(0.62),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: theme.textColor.withOpacity(0.08),
                                      ),
                                    ),
                                    child: Text(
                                      entry,
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontSize: 11,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
