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
  bool _allowGuestApi = false;

  bool get isInitialized => _isInitialized;

  Future<void> initialize(String apiUrl, {bool allowGuestApi = false}) async {
    if (_isInitialized) return;
    _baseUrl = apiUrl.trim();
    if (_baseUrl.endsWith('/')) {
      _baseUrl = _baseUrl.substring(0, _baseUrl.length - 1);
    }
    if (_baseUrl.isEmpty) return;

    _deviceId = await DeviceId.getOrCreate();
    _allowGuestApi = allowGuestApi;
    _isInitialized = true;
  }

  Map<String, String> _headers() {
    return {
      'Content-Type': 'application/json',
      'x-device-id': _deviceId ?? '',
    };
  }

  Future<String?> _getIdToken() async {
    final token = await AwsAuthService.instance.getIdToken();
    if (token == null || token.isEmpty) return null;
    return token;
  }

  Future<Map<String, String>> _headersWithAuth() async {
    final headers = _headers();
    final token = await _getIdToken();
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  String _buildPath(String path, {required bool hasToken}) {
    if (hasToken || !_allowGuestApi) return path;
    if (path.startsWith('/guest/')) return path;
    return '/guest$path';
  }

  Future<Map<String, dynamic>?> _getJson(String path) async {
    try {
      final token = await _getIdToken();
      final resolvedPath = _buildPath(path, hasToken: token != null);
      final resp = await http.get(Uri.parse('$_baseUrl$resolvedPath'),
          headers: await _headersWithAuth());
      if (resp.statusCode >= 200 && resp.statusCode < 300) {
        return jsonDecode(resp.body) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('AWS GET error: $e');
    }
    return null;
  }

  Future<Map<String, dynamic>?> _postJson(
      String path, Map<String, dynamic> body) async {
    try {
      final token = await _getIdToken();
      final resolvedPath = _buildPath(path, hasToken: token != null);
      final resp = await http.post(Uri.parse('$_baseUrl$resolvedPath'),
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

  Future<Map<String, dynamic>?> _putJson(
      String path, Map<String, dynamic> body) async {
    try {
      final token = await _getIdToken();
      final resolvedPath = _buildPath(path, hasToken: token != null);
      final resp = await http.put(Uri.parse('$_baseUrl$resolvedPath'),
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
    final token = await _getIdToken();
    if (token == null && !_allowGuestApi) return null;
    final response = await _postJson('/sessions/start', {});
    return response?['sessionId'] as String?;
  }

  Future<void> endSession(String sessionId) async {
    if (!_isInitialized) return;
    final token = await _getIdToken();
    if (token == null && !_allowGuestApi) return;
    await _postJson('/sessions/$sessionId/end', {});
  }

  Future<void> trackNote(String sessionId, int note, double velocity) async {
    if (!_isInitialized) return;
    final token = await _getIdToken();
    if (token == null && !_allowGuestApi) return;
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
    final token = await _getIdToken();
    if (token == null && !_allowGuestApi) {
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
    final token = await _getIdToken();
    if (token == null && !_allowGuestApi) {
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
    final token = await _getIdToken();
    if (token == null && !_allowGuestApi) return [];
    final response = await _getJson('/sessions/recent?limit=$limit');
    final sessions = response?['sessions'];
    if (sessions is List) {
      return List<Map<String, dynamic>>.from(sessions);
    }
    return [];
  }

  Future<void> saveSongProgress(String songId, double progress) async {
    if (!_isInitialized) return;
    final token = await _getIdToken();
    if (token == null && !_allowGuestApi) return;
    await _putJson('/songs/$songId/progress', {
      'progress': progress,
    });
  }

  Future<double> getSongProgress(String songId) async {
    if (!_isInitialized) return 0.0;
    final token = await _getIdToken();
    if (token == null && !_allowGuestApi) return 0.0;
    final response = await _getJson('/songs/$songId/progress');
    if (response == null) return 0.0;
    return (response['progress'] as num?)?.toDouble() ?? 0.0;
  }

  Future<Map<String, dynamic>?> getProfile() async {
    if (!_isInitialized) return null;
    final token = await _getIdToken();
    if (token == null && !_allowGuestApi) return null;
    return _getJson('/profile');
  }

  Future<String?> aiChat({
    required List<Map<String, String>> messages,
  }) async {
    if (!_isInitialized) return null;
    final token = await _getIdToken();
    if (token == null && !_allowGuestApi) return null;
    final response = await _postJson('/ai/chat', {
      'messages': messages,
    });
    return response?['content'] as String?;
  }
}
