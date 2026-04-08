// ============================================
// UPDATED main.dart - Uses Complete Home Screen
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'dart:async';
import 'dart:isolate';
import 'package:shared_preferences/shared_preferences.dart';

// Import services
import 'services/aws_auth_service.dart';
import 'services/aws_service.dart';
import 'utils/theme_service.dart';
import 'utils/app_info.dart';

// IMPORTANT: Import the COMPLETE home screen
import 'screens/home_screen.dart'; // This should be CompleteHomeScreen
import 'screens/auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  bool envLoaded = false;
  bool cloudInitialized = false;
  bool aiInitialized = false;

  // Enable wake lock
  try {
    await WakelockPlus.enable();
    debugPrint('✅ Wake lock enabled');
  } catch (e) {
    debugPrint('⚠️ Wake lock error: $e');
  }

  // Load environment variables
  try {
    await dotenv.load(fileName: "assets/.env");
    envLoaded = true;
    debugPrint('✅ Environment loaded');
  } catch (e) {
    debugPrint('⚠️ .env file not found - running in local-only mode');
  }

  // Initialize AWS Cloud
  if (envLoaded) {
    try {
      final awsApiUrl = dotenv.env['AWS_API_URL'] ?? '';
      if (awsApiUrl.isNotEmpty) {
        await AwsService.instance.initialize(awsApiUrl);
        final awsPoolId = dotenv.env['AWS_USER_POOL_ID'] ?? '';
        final awsClientId = dotenv.env['AWS_USER_POOL_CLIENT_ID'] ?? '';
        if (awsPoolId.isNotEmpty && awsClientId.isNotEmpty) {
          await AwsAuthService.instance.initialize(
              userPoolId: awsPoolId, clientId: awsClientId);
        }
        cloudInitialized = true;
        aiInitialized = true;
        debugPrint('AWS Cloud initialized');
      }
    } catch (e) {
      debugPrint('AWS Cloud init failed: $e');
    }
  }

  // Load theme
  await ThemeService.loadTheme();

  debugPrint('\n🎹 Initialization Summary:');
  debugPrint('Environment: ${envLoaded ? "✅" : "❌"}');
  debugPrint('AWS Cloud: ${cloudInitialized ? "✅" : "❌"}');
  debugPrint('AI Tutor: ${aiInitialized ? "✅" : "❌"}');

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runZonedGuarded(() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      AwsService.instance.reportError(
        message: details.exceptionAsString(),
        stack: details.stack?.toString(),
        context: {
          'library': details.library ?? '',
          'context': details.context?.toDescription() ?? '',
        },
        appVersion: '3.0.0+1',
        platform: 'flutter',
      );
    };
    WidgetsBinding.instance.platformDispatcher.onError = (error, stack) {
      AwsService.instance.reportError(
        message: error.toString(),
        stack: stack.toString(),
        context: {'dispatcher': 'PlatformDispatcher.onError'},
        appVersion: '3.0.0+1',
        platform: 'flutter',
      );
      return true;
    };
    Isolate.current.addErrorListener(
      RawReceivePort((dynamic pair) {
        final List<dynamic> errorAndStack = pair as List<dynamic>;
        final error = errorAndStack[0];
        final stack = errorAndStack.length > 1 ? errorAndStack[1] : null;
        AwsService.instance.reportError(
          message: error.toString(),
          stack: stack?.toString(),
          context: {'isolate': 'current'},
          appVersion: '3.0.0+1',
          platform: 'flutter',
        );
      }).sendPort,
    );

    runApp(
      GrandPianoApp(
        cloudEnabled: cloudInitialized,
        aiEnabled: aiInitialized,
      ),
    );
  }, (error, stack) {
    AwsService.instance.reportError(
      message: error.toString(),
      stack: stack.toString(),
      context: {'zone': 'runZonedGuarded'},
      appVersion: '3.0.0+1',
      platform: 'flutter',
    );
  });
}

class GrandPianoApp extends StatefulWidget {
  final bool cloudEnabled;
  final bool aiEnabled;

  const GrandPianoApp({
    super.key,
    required this.cloudEnabled,
    required this.aiEnabled,
  });

  @override
  State<GrandPianoApp> createState() => _GrandPianoAppState();
}

class _GrandPianoAppState extends State<GrandPianoApp> {
  bool _checkingAuth = true;
  bool _signedIn = false;
  bool _guestMode = false;

  @override
  void initState() {
    super.initState();
    _loadAuthState();
  }

  Future<void> _loadAuthState() async {
    final prefs = await SharedPreferences.getInstance();
    final isGuest = prefs.getBool('guest_mode') ?? false;
    if (isGuest) {
      setState(() {
        _checkingAuth = false;
        _signedIn = false;
        _guestMode = true;
      });
      return;
    }
    if (!widget.cloudEnabled) {
      setState(() {
        _checkingAuth = false;
        _signedIn = false;
        _guestMode = false;
      });
      return;
    }
    final ok = await AwsAuthService.instance.ensureValidSession();
    setState(() {
      _checkingAuth = false;
      _signedIn = ok;
      _guestMode = false;
    });
  }

  Future<void> _setGuestMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('guest_mode', enabled);
    setState(() {
      _guestMode = enabled;
      if (enabled) {
        _signedIn = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeService.theme;

    if (AppInfo.safeModeWeb && kIsWeb) {
      return const CupertinoApp(
        debugShowCheckedModeBanner: false,
        home: CupertinoPageScaffold(
          child: SafeArea(
            child: Center(
              child: Text(
                'SAFE MODE BUILD\\nWeb bucket verification',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ),
          ),
        ),
      );
    }

    return CupertinoApp(
      title: 'GrandPiano - Professional MIDI Piano',
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
      home: _checkingAuth
          ? const CupertinoPageScaffold(
              child: Center(child: CupertinoActivityIndicator()))
          : (widget.cloudEnabled && !_signedIn && !_guestMode)
              ? AuthScreen(
                  onSignedIn: () {
                    setState(() => _signedIn = true);
                  },
                  onContinueAsGuest: () => _setGuestMode(true),
                )
              : CompleteHomeScreen(
                  cloudEnabled: widget.cloudEnabled,
                  signedIn: _signedIn,
                  guestMode: _guestMode,
                  aiEnabled: widget.aiEnabled,
                  onThemeChanged: () {
                    setState(() {}); // Rebuild app when theme changes
                  },
                  onSignedOut: () {
                    _setGuestMode(false);
                    setState(() => _signedIn = false);
                  },
                  onExitGuest: () => _setGuestMode(false),
                ),
    );
  }
}
