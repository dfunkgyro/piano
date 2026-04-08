import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  final String apiUrl;
  final String userPoolId;
  final String userPoolClientId;
  final String bedrockModelId;
  final bool useSafeUi;
  final bool allowGuestApi;

  const AppConfig({
    required this.apiUrl,
    required this.userPoolId,
    required this.userPoolClientId,
    required this.bedrockModelId,
    required this.useSafeUi,
    required this.allowGuestApi,
  });

  bool get cloudEnabled => apiUrl.isNotEmpty;
  bool get authEnabled =>
      userPoolId.isNotEmpty && userPoolClientId.isNotEmpty;

  static Future<AppConfig> load() async {
    try {
      await dotenv.load(fileName: 'assets/app.env');
    } catch (e) {
      try {
        await dotenv.load(fileName: 'assets/.env');
      } catch (e2) {
        debugPrint('Config load failed: $e2');
      }
    }

    final apiUrl = (dotenv.env['AWS_API_URL'] ?? '').trim();
    final userPoolId = (dotenv.env['AWS_USER_POOL_ID'] ?? '').trim();
    final userPoolClientId =
        (dotenv.env['AWS_USER_POOL_CLIENT_ID'] ?? '').trim();
    final bedrockModelId = (dotenv.env['BEDROCK_MODEL_ID'] ?? '').trim();
    final useSafeUi =
        (dotenv.env['APP_USE_SAFE_UI'] ?? 'false').toLowerCase() == 'true';
    final allowGuestApi =
        (dotenv.env['APP_ALLOW_GUEST_API'] ?? 'false').toLowerCase() == 'true';

    return AppConfig(
      apiUrl: apiUrl,
      userPoolId: userPoolId,
      userPoolClientId: userPoolClientId,
      bedrockModelId: bedrockModelId,
      useSafeUi: useSafeUi,
      allowGuestApi: allowGuestApi,
    );
  }
}
