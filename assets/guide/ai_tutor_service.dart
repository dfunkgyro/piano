import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class AITutorService {
  static String? _apiKey;
  static const String _baseUrl = 'https://api.openai.com/v1/chat/completions';

  final List<Map<String, String>> _conversationHistory = [];

  static void initialize(String apiKey) {
    _apiKey = apiKey;
  }

  AITutorService() {
    _conversationHistory.add({
      'role': 'system',
      'content':
          '''You are an expert piano teacher and MIDI technology specialist. 
Your role is to help users:
- Learn piano techniques and theory
- Understand MIDI concepts and BLE-MIDI connections
- Troubleshoot latency and connection issues
- Practice effectively with their MIDI keyboard
- Set up optimal latency settings for their setup

Be friendly, encouraging, and provide practical, actionable advice. 
Keep responses concise but informative. Use analogies when explaining technical concepts.
Focus on helping users improve their playing and optimize their setup.'''
    });
  }

  Future<String> getWelcomeMessage() async {
    return await getResponse(
      'Give me a warm, brief welcome message as a piano tutor. Mention that I can help with playing techniques, MIDI setup, and latency optimization.',
      addToHistory: false,
    );
  }

  Future<String> getResponse(String userMessage,
      {bool addToHistory = true}) async {
    if (_apiKey == null || _apiKey!.isEmpty) {
      return 'AI Tutor is not configured. Please add your OpenAI API key to the .env file.';
    }

    if (addToHistory) {
      _conversationHistory.add({
        'role': 'user',
        'content': userMessage,
      });
    }

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': _conversationHistory,
          'max_tokens': 500,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final assistantMessage =
            data['choices'][0]['message']['content'] as String;

        if (addToHistory) {
          _conversationHistory.add({
            'role': 'assistant',
            'content': assistantMessage,
          });
        }

        return assistantMessage;
      } else {
        debugPrint(
            'OpenAI API Error: ${response.statusCode} - ${response.body}');
        return 'Sorry, I encountered an error. Please check your API key and internet connection.';
      }
    } catch (e) {
      debugPrint('Error calling OpenAI API: $e');
      return 'Sorry, I couldn\'t connect to the AI service. Please check your internet connection.';
    }
  }

  Future<String> getLatencyAdvice(
      double currentLatency, String deviceType) async {
    final message =
        '''I'm using a $deviceType MIDI device with current latency set to ${currentLatency}ms. 
Can you give me specific advice on whether this latency is optimal for my setup and how to adjust it?''';

    return await getResponse(message);
  }

  Future<String> getConnectionHelp(String issue) async {
    final message =
        'I\'m having trouble with my MIDI connection: $issue. Can you help me troubleshoot?';
    return await getResponse(message);
  }

  Future<String> getPracticeSuggestion(String skillLevel) async {
    final message =
        'I\'m a $skillLevel piano player. What should I practice today with my MIDI keyboard?';
    return await getResponse(message);
  }

  Future<String> explainBLEMIDI() async {
    final message = '''Can you explain BLE-MIDI technology in simple terms? 
Why is there latency, and why is it different on different devices?''';
    return await getResponse(message);
  }

  Future<String> getTechniqueHelp(String technique) async {
    final message = 'Can you help me improve my $technique technique on piano?';
    return await getResponse(message);
  }

  void clearHistory() {
    _conversationHistory.clear();
    _conversationHistory.add({
      'role': 'system',
      'content':
          '''You are an expert piano teacher and MIDI technology specialist. 
Your role is to help users learn piano and optimize their MIDI setup.'''
    });
  }

  List<Map<String, String>> get conversationHistory => _conversationHistory;
}
