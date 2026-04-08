import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AwsAuthService {
  static final AwsAuthService instance = AwsAuthService._internal();
  factory AwsAuthService() => instance;
  AwsAuthService._internal();

  static const _prefIdToken = 'aws_id_token';
  static const _prefAccessToken = 'aws_access_token';
  static const _prefRefreshToken = 'aws_refresh_token';
  static const _prefUsername = 'aws_username';

  late CognitoUserPool _userPool;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize(
      {required String userPoolId,
      required String clientId}) async {
    if (_isInitialized) return;
    if (userPoolId.isEmpty || clientId.isEmpty) return;

    _userPool = CognitoUserPool(userPoolId, clientId);
    _isInitialized = true;
  }

  Future<void> _saveTokens(CognitoUserSession session, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
        _prefIdToken, session.getIdToken().getJwtToken() ?? '');
    await prefs.setString(
        _prefAccessToken, session.getAccessToken().getJwtToken() ?? '');
    await prefs.setString(
        _prefRefreshToken, session.getRefreshToken()?.token ?? '');
    await prefs.setString(_prefUsername, email);
  }

  Future<bool> signIn(String email, String password) async {
    if (!_isInitialized) return false;

    try {
      final user = CognitoUser(email, _userPool);
      final authDetails =
          AuthenticationDetails(username: email, password: password);
      final session = await user.authenticateUser(authDetails);
      if (session == null) return false;

      await _saveTokens(session, email);
      return true;
    } catch (e) {
      debugPrint('AWS sign-in error: $e');
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    if (!_isInitialized) return false;
    try {
      final userAttributes = [AttributeArg(name: 'email', value: email)];
      await _userPool.signUp(email, password, userAttributes: userAttributes);
      return true;
    } catch (e) {
      debugPrint('AWS sign-up error: $e');
      return false;
    }
  }

  Future<bool> confirmSignUp(String email, String code) async {
    if (!_isInitialized) return false;
    try {
      final user = CognitoUser(email, _userPool);
      return await user.confirmRegistration(code);
    } catch (e) {
      debugPrint('AWS confirm error: $e');
      return false;
    }
  }

  Future<String?> getIdToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefIdToken);
  }

  Future<bool> isSignedIn() async {
    final token = await getIdToken();
    return token != null && token.isNotEmpty;
  }

  Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefRefreshToken);
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_prefUsername);
  }

  Future<bool> refreshSession() async {
    if (!_isInitialized) return false;
    try {
      final username = await getUsername();
      final refreshToken = await getRefreshToken();
      if (username == null || username.isEmpty) return false;
      if (refreshToken == null || refreshToken.isEmpty) return false;

      final user = CognitoUser(username, _userPool);
      final session =
          await user.refreshSession(CognitoRefreshToken(refreshToken));
      if (session == null) return false;

      await _saveTokens(session, username);
      return true;
    } catch (e) {
      debugPrint('AWS refresh error: $e');
      return false;
    }
  }

  Future<bool> ensureValidSession() async {
    if (await isSignedIn()) return true;
    return refreshSession();
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefIdToken);
    await prefs.remove(_prefAccessToken);
    await prefs.remove(_prefRefreshToken);
    await prefs.remove(_prefUsername);
  }
}
