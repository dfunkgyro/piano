import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'utils/app_theme.dart';
import 'utils/constants.dart';
import 'screens/safe_shell.dart';
import 'screens/home_screen.dart';
import 'services/aws_service.dart';
import 'services/aws_auth_service.dart';
import 'services/app_debug_log_service.dart';
import 'utils/app_config.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    FlutterError.onError = (details) {
      AppDebugLogService.instance.add(
        'APP',
        'FlutterError: ${details.exceptionAsString()}',
      );
      debugPrint(details.exceptionAsString());
      debugPrintStack(stackTrace: details.stack);
    };

    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      AppDebugLogService.instance.add('APP', 'PlatformError: $error');
      debugPrint(error.toString());
      debugPrintStack(stackTrace: stack);
      return true;
    };

    try {
      await WakelockPlus.enable();
    } catch (_) {}

    final config = await AppConfig.load();
    if (config.authEnabled) {
      await AwsAuthService.instance.initialize(
        userPoolId: config.userPoolId,
        clientId: config.userPoolClientId,
      );
    }
    if (config.cloudEnabled) {
      await AwsService.instance.initialize(
        config.apiUrl,
        allowGuestApi: config.allowGuestApi,
      );
    }

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0x00000000),
        statusBarIconBrightness: Brightness.light,
      ),
    );

    runApp(GrandPianoApp(config: config));
  }, (error, stack) {
    AppDebugLogService.instance.add('APP', 'ZoneError: $error');
    debugPrint(error.toString());
    debugPrintStack(stackTrace: stack);
  });
}

class GrandPianoApp extends StatelessWidget {
  final AppConfig config;
  const GrandPianoApp({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.dark;

    return CupertinoApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: CupertinoThemeData(
        primaryColor: theme.primaryColor,
        scaffoldBackgroundColor: theme.backgroundColor,
        barBackgroundColor: theme.surfaceColor,
        textTheme: CupertinoTextThemeData(
          primaryColor: theme.textColor,
          textStyle: TextStyle(color: theme.textColor),
        ),
        brightness: theme.brightness,
      ),
      home: config.useSafeUi
          ? const SafeShell()
          : CompleteHomeScreen(
              cloudEnabled: config.cloudEnabled,
              aiEnabled: config.cloudEnabled,
              onThemeChanged: () {},
            ),
    );
  }
}
