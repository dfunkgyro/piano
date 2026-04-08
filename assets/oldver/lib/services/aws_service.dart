import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../utils/device_id.dart';
import 'aws_auth_service.dart';

class AwsService {
  static final AwsService instance = AwsService._internal();
  factory AwsService() => instance;
  AwsService._internal();

  bool _isInitialized = false;
  String _baseUrl = '';
  String? _deviceId;
  int? _lastBackendStatus;
  String? _lastBackendError;

  bool get isInitialized => _isInitialized;
  int? get lastBackendStatus => _lastBackendStatus;
  String? get lastBackendError => _lastBackendError;

  Future<void> initialize(String apiUrl) async {
    if (_isInitialized) return;
    _baseUrl = apiUrl.trim();
    if (_baseUrl.endsWith('/')) {
      _baseUrl = _baseUrl.substring(0, _baseUrl.length - 1);
    }
    if (_baseUrl.isEmpty) return;

    _deviceId = await DeviceId.getOrCreate();
    _isInitialized = true;
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'x-device-id': _deviceId ?? '',
    };
  }

  Future<Map<String, String>> _headersWithAuth() async {
    final headers = _headers();
    final token = await AwsAuthService.instance.getIdToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<Map<String, dynamic>?> _getJson(String path) async {
    try {
      final resp = await http.get(Uri.parse('$_baseUrl$path'),
          headers: await _headersWithAuth());
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('AWS GET error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>> checkBackend() async {
    if (!_isInitialized) {
      _lastBackendStatus = null;
      _lastBackendError = 'not_initialized';
      return {
        'ok': false,
        'statusCode': null,
        'error': _lastBackendError,
      };
    }
    try {
      final resp = await http.get(
        Uri.parse('$_baseUrl/profile'),
        headers: await _headersWithAuth(),
      );
      _lastBackendStatus = resp.statusCode;
      _lastBackendError = null;
      return {
        'ok': resp.statusCode >= 200 && resp.statusCode < 300,
        'statusCode': resp.statusCode,
        'error': resp.statusCode >= 200 && resp.statusCode < 300
            ? null
            : 'http_${resp.statusCode}',
      };
    } catch (e) {
      _lastBackendStatus = null;
      _lastBackendError = e.toString();
      return {
        'ok': false,
        'statusCode': null,
        'error': _lastBackendError,
      };
    }
  }

  Future<Map<String, dynamic>?> _postJson(
      String path, Map<String, dynamic> body) async {
    try {
      final resp = await http.post(Uri.parse('$_baseUrl$path'),
          headers: await _headersWithAuth(), body: jsonEncode(body));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isEmpty) return {};
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('AWS POST error: $e');
    }
    return null;
  }

  Future<void> reportError({
    required String message,
    String? stack,
    Map<String, dynamic>? context,
    String? appVersion,
    String? platform,
  }) async {
    if (!_isInitialized) return;
    try {
      await _postJson('/errors', {
        'message': message,
        'stack': stack ?? '',
        'context': context ?? {},
        'appVersion': appVersion ?? '',
        'platform': platform ?? '',
      });
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> _putJson(
      String path, Map<String, dynamic> body) async {
    try {
      final resp = await http.put(Uri.parse('$_baseUrl$path'),
          headers: await _headersWithAuth(), body: jsonEncode(body));
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        if (resp.body.isEmpty) return {};
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('AWS PUT error: $e');
    }
    return null;
  }

  Future<String?> startSession() async {
    if (!_isInitialized) return null;
    final response = await _postJson('/sessions/start', {});
    return response?['sessionId'] as String?;
  }

  Future<void> endSession(String sessionId,
      {Map<String, dynamic>? summary}) async {
    if (!_isInitialized) return;
    await _postJson('/sessions/$sessionId/end', {
      if (summary != null) 'summary': summary,
    });
  }

  Future<Map<String, dynamic>?> generateSessionInsights(
      String sessionId, {Map<String, dynamic>? summary}) async {
    if (!_isInitialized) return null;
    return _postJson('/sessions/$sessionId/insights', {
      if (summary != null) 'summary': summary,
    });
  }

  Future<Map<String, dynamic>?> getSessionInsights(String sessionId) async {
    if (!_isInitialized) return null;
    return _getJson('/sessions/$sessionId/insights');
  }

  Future<void> trackNote(String sessionId, int note, double velocity) async {
    if (!_isInitialized) return;
    await _postJson('/sessions/$sessionId/notes', {
      'note': note,
      'velocity': velocity,
    });
  }

  Future<Map<String, dynamic>> getUserAnalytics({int days = 30}) async {
    if (!_isInitialized) {
      return {
        'total_sessions': 0,
        'total_minutes': 0,
        'total_notes': 0,
        'average_accuracy': 0.0,
      };
    }

    final response = await _getJson('/analytics?days=$days');
    if (response == null) {
      return {
        'total_sessions': 0,
        'total_minutes': 0,
        'total_notes': 0,
        'average_accuracy': 0.0,
      };
    }
    return response;
  }

  Future<Map<String, dynamic>> getStats() async {
    if (!_isInitialized) {
      return {
        'totalSessions': 0,
        'totalMinutes': 0,
        'totalNotes': 0,
        'averageSessionMinutes': 0,
      };
    }

    final response = await _getJson('/stats');
    if (response == null) {
      return {
        'totalSessions': 0,
        'totalMinutes': 0,
        'totalNotes': 0,
        'averageSessionMinutes': 0,
      };
    }
    return response;
  }

  Future<List<Map<String, dynamic>>> getRecentSessions({int limit = 10}) async {
    if (!_isInitialized) return [];
    final response = await _getJson('/sessions/recent?limit=$limit');
    final sessions = response?['sessions'];
    if (sessions is List) {
      return List<Map<String, dynamic>>.from(sessions);
    }
    return [];
  }

  Future<void> saveSongProgress(String songId, double progress) async {
    if (!_isInitialized) return;
    await _putJson('/songs/$songId/progress', {
      'progress': progress,
    });
  }

  Future<double> getSongProgress(String songId) async {
    if (!_isInitialized) return 0.0;
    final response = await _getJson('/songs/$songId/progress');
    if (response == null) return 0.0;
    return (response['progress'] as num?)?.toDouble() ?? 0.0;
  }

  Future<List<Map<String, dynamic>>> getRecentErrors({int limit = 50}) async {
    if (!_isInitialized) return [];
    final response = await _getJson('/errors?limit=$limit');
    final errors = response?['errors'];
    if (errors is List) {
      return List<Map<String, dynamic>>.from(errors);
    }
    return [];
  }

  Future<Map<String, dynamic>?> getProfile() async {
    if (!_isInitialized) return null;
    return _getJson('/profile');
  }

  Future<String?> aiChat({
    required List<Map<String, String>> messages,
  }) async {
    if (!_isInitialized) return null;
    final response = await _postJson('/ai/chat', {
      'messages': messages,
    });
    return response?['content'] as String?;
  }
}
