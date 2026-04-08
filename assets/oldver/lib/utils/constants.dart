// ============================================
// constants.dart - Enhanced App Constants
// ============================================

import 'package:flutter/material.dart';

class AppConstants {
  // ============================================
  // APP INFO
  // ============================================
  static const String appName = 'MIDI Piano Pro';
  static const String appVersion = '3.1.0';
  static const String appDescription =
      'Professional MIDI Piano with AI Teaching & Enhanced Bluetooth';

  // ============================================
  // MIDI CONFIGURATION - ENHANCED
  // ============================================
  static const int midiFirstNote = 21; // A0
  static const int midiLastNote = 108; // C8
  static const int totalKeys = 88;
  static const int middleC = 60; // C4

  // Bluetooth MIDI Settings
  static const int defaultPacketQueueSize = 200;
  static const int minPacketQueueSize = 100;
  static const int maxPacketQueueSize = 500;

  static const Duration basePacketProcessingInterval =
      Duration(milliseconds: 3);
  static const Duration slowPacketProcessingInterval =
      Duration(milliseconds: 5);
  static const Duration fastPacketProcessingInterval =
      Duration(milliseconds: 2);

  static const Duration defaultScanTimeout = Duration(seconds: 5);
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration reconnectionDelay = Duration(seconds: 2);

  static const int maxConnectionAttempts = 3;
  static const int maxScanAttempts = 3;

  // MIDI Message Types
  static const int midiNoteOff = 0x80;
  static const int midiNoteOn = 0x90;
  static const int midiControlChange = 0xB0;
  static const int midiProgramChange = 0xC0;
  static const int midiAftertouch = 0xD0;
  static const int midiPitchBend = 0xE0;

  // Performance Thresholds
  static const int highQueueUtilizationPercent = 70;
  static const int mediumQueueUtilizationPercent = 40;
  static const int maxDroppedPacketsWarning = 10;
  static const Duration slowProcessingWarningThreshold =
      Duration(milliseconds: 10);

  // ============================================
  // AUDIO SETTINGS
  // ============================================
  static const double defaultVolume = 1.0;
  static const double minVolume = 0.0;
  static const double maxVolume = 2.0;
  static const double volumeIncrement = 0.1;

  static const int audioSampleRate = 44100;
  static const int audioBufferSize = 512; // Lower = less latency, more CPU

  // ============================================
  // LATENCY SETTINGS - ENHANCED
  // ============================================
  static const double defaultLatency = 0.0;
  static const double minLatency = -100.0;
  static const double maxLatency = 200.0;
  static const double latencyIncrement = 5.0;

  // Device-specific latency presets
  static const Map<String, double> deviceLatencyPresets = {
    'widi': 10.0,
    'yamaha': 15.0,
    'roland': 12.0,
    'kawai': 12.0,
    'generic': 0.0,
  };

  // ============================================
  // PRACTICE SETTINGS
  // ============================================
  static const int defaultPracticeGoalMinutes = 30;
  static const int minPracticeGoalMinutes = 5;
  static const int maxPracticeGoalMinutes = 240;
  static const int practiceGoalIncrement = 5;

  // Practice milestones (notes played)
  static const List<int> practiceMilestones = [
    100,
    500,
    1000,
    5000,
    10000,
  ];

  // ============================================
  // UI CONSTANTS - ENHANCED
  // ============================================

  // Keyboard
  static const double keyboardMinHeight = 150.0;
  static const double keyboardMaxHeight = 300.0;
  static const double keyboardDefaultHeight = 200.0;
  static const double keyWidth = 20.0;
  static const double blackKeyHeightRatio = 0.6;
  static const double blackKeyWidthRatio = 0.7;

  // Key colors
  static const Color whiteKeyColor = Colors.white;
  static const Color blackKeyColor = Color(0xFF1A1A1A);
  static const Color whiteKeyPressedColor = Color(0xFF64B5F6);
  static const Color blackKeyPressedColor = Color(0xFF4A90E2);
  static const Color whiteKeyShadow = Color(0xFFE0E0E0);
  static const Color blackKeyShadow = Color(0xFF000000);

  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  static const Duration keyPressAnimation = Duration(milliseconds: 50);

  // UI Spacing
  static const double smallPadding = 8.0;
  static const double mediumPadding = 16.0;
  static const double largePadding = 24.0;
  static const double cardBorderRadius = 12.0;
  static const double buttonBorderRadius = 8.0;

  // ============================================
  // NETWORK SETTINGS
  // ============================================
  static const Duration networkTimeout = Duration(seconds: 30);
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);

  // ============================================
  // CACHE SETTINGS
  // ============================================
  static const Duration cacheExpiration = Duration(hours: 24);
  static const int maxCachedSongs = 50;
  static const int maxCachedSessions = 100;

  // ============================================
  // PAGINATION
  // ============================================
  static const int defaultPageSize = 20;
  static const int songsPerPage = 10;
  static const int leaderboardLimit = 100;
  static const int maxSearchResults = 50;

  // ============================================
  // VALIDATION
  // ============================================
  static const int minPasswordLength = 8;
  static const int maxPasswordLength = 128;
  static const int maxDisplayNameLength = 50;
  static const int maxDeviceNameLength = 100;
  static const int maxEmailLength = 254;

  // ============================================
  // FILE PATHS
  // ============================================
  static const String soundsPath = 'assets/sounds/';
  static const String iconsPath = 'assets/icon/';
  static const String sheetMusicPath = 'assets/sheet_music/';
  static const String tutorialsPath = 'assets/tutorials/';
  static const String fontsPath = 'fonts/';

  // ============================================
  // PREFERENCES KEYS
  // ============================================
  static const String prefKeyLatency = 'latency_setting';
  static const String prefKeyVolume = 'volume_setting';
  static const String prefKeyTheme = 'app_theme';
  static const String prefKeyLayout = 'app_layout';
  static const String prefKeyAutoScan = 'auto_scan_enabled';
  static const String prefKeyAutoConnect = 'auto_connect_enabled';
  static const String prefKeyFavoriteDevice = 'favorite_device_id';
  static const String prefKeyWakeLock = 'wake_lock_enabled';
  static const String prefKeyPracticeGoal = 'practice_goal_minutes';
  static const String prefKeyLastConnectedDevice = 'last_connected_device';
  static const String prefKeyMidiChannel = 'midi_channel';
  static const String prefKeyTranspose = 'transpose_semitones';
  static const String prefKeyMetronomeEnabled = 'metronome_enabled';
  static const String prefKeyMetronomeBPM = 'metronome_bpm';

  // ============================================
  // ERROR MESSAGES - ENHANCED
  // ============================================
  static const String errorNoInternet = 'No internet connection';
  static const String errorMidiNotFound = 'MIDI device not found';
  static const String errorBluetoothOff = 'Bluetooth is turned off';
  static const String errorBluetoothUnauthorized =
      'Bluetooth permission denied';
  static const String errorPermissionDenied = 'Permission denied';
  static const String errorAudioInit = 'Failed to initialize audio';
  static const String errorConnectionTimeout = 'Connection timeout';
  static const String errorConnectionFailed = 'Connection failed';
  static const String errorDeviceDisconnected = 'Device disconnected';
  static const String errorScanFailed = 'Failed to scan for devices';
  static const String errorQueueOverflow = 'MIDI queue overflow';
  static const String errorPacketDrop = 'Packet drop detected';

  // ============================================
  // SUCCESS MESSAGES
  // ============================================
  static const String successConnected = 'Connected successfully';
  static const String successDisconnected = 'Disconnected';
  static const String successScanComplete = 'Scan complete';
  static const String successSongComplete = 'Song completed!';
  static const String successPracticeGoalReached = 'Practice goal reached!';

  // ============================================
  // DEVICE PROFILES - ENHANCED
  // ============================================
  static const Map<String, Map<String, dynamic>> deviceProfiles = {
    'widi_uhost': {
      'keywords': ['widi uhost'],
      'connectionDelay': 1500,
      'requiresRetry': true,
      'maxRetries': 4,
      'defaultLatency': 10.0,
      'notes': 'Use with digital pianos via MIDI cable',
    },
    'widi_bud_pro': {
      'keywords': ['widi bud pro'],
      'connectionDelay': 1500,
      'requiresRetry': true,
      'maxRetries': 4,
      'defaultLatency': 10.0,
      'notes': 'Plug directly into piano MIDI port',
    },
    'widi_bud': {
      'keywords': ['widi bud'],
      'connectionDelay': 1500,
      'requiresRetry': true,
      'maxRetries': 4,
      'defaultLatency': 10.0,
      'notes': 'Basic WIDI adapter',
    },
    'yamaha': {
      'keywords': ['yamaha', 'p-', 'p45', 'p125', 'clavinova'],
      'connectionDelay': 1000,
      'requiresRetry': true,
      'maxRetries': 3,
      'defaultLatency': 15.0,
      'notes': 'Yamaha digital pianos',
    },
    'roland': {
      'keywords': ['roland', 'fp-', 'rd-'],
      'connectionDelay': 800,
      'requiresRetry': false,
      'maxRetries': 2,
      'defaultLatency': 12.0,
      'notes': 'Roland digital pianos',
    },
    'kawai': {
      'keywords': ['kawai', 'es', 'mp'],
      'connectionDelay': 800,
      'requiresRetry': false,
      'maxRetries': 2,
      'defaultLatency': 12.0,
      'notes': 'Kawai digital pianos',
    },
    'casio': {
      'keywords': ['casio', 'privia', 'cdp'],
      'connectionDelay': 1000,
      'requiresRetry': true,
      'maxRetries': 3,
      'defaultLatency': 15.0,
      'notes': 'Casio digital pianos',
    },
    'korg': {
      'keywords': ['korg', 'b2', 'd1'],
      'connectionDelay': 800,
      'requiresRetry': false,
      'maxRetries': 2,
      'defaultLatency': 12.0,
      'notes': 'Korg digital pianos',
    },
  };

  // ============================================
  // KEYBOARD LAYOUTS
  // ============================================
  static const List<bool> pianoKeyPattern = [
    true, // C - white
    false, // C# - black
    true, // D - white
    false, // D# - black
    true, // E - white
    true, // F - white
    false, // F# - black
    true, // G - white
    false, // G# - black
    true, // A - white
    false, // A# - black
    true, // B - white
  ];

  static const List<String> noteNames = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B'
  ];

  // ============================================
  // MUSIC THEORY
  // ============================================
  static const Map<String, int> noteToMidi = {
    'C': 0,
    'C#': 1,
    'Db': 1,
    'D': 2,
    'D#': 3,
    'Eb': 3,
    'E': 4,
    'F': 5,
    'F#': 6,
    'Gb': 6,
    'G': 7,
    'G#': 8,
    'Ab': 8,
    'A': 9,
    'A#': 10,
    'Bb': 10,
    'B': 11,
  };

  // Common chord progressions for teaching
  static const Map<String, List<List<int>>> chordProgressions = {
    'I-IV-V-I': [
      [60, 64, 67], // C Major
      [65, 69, 72], // F Major
      [67, 71, 74], // G Major
      [60, 64, 67], // C Major
    ],
    'ii-V-I': [
      [62, 65, 69], // D minor
      [67, 71, 74], // G Major
      [60, 64, 67], // C Major
    ],
  };

  // ============================================
  // AI TUTOR SETTINGS
  // ============================================
  static const int aiProactiveCheckInterval = 30; // seconds
  static const int aiMinNotesBeforeSuggestion = 10;
  static const int aiConsecutiveCorrectThreshold = 20;
  static const int aiSessionMinutesBreakReminder = 5;

  // ============================================
  // FEATURE FLAGS
  // ============================================
  static const bool enableAdvancedDiagnostics = true;
  static const bool enablePerformanceMonitoring = true;
  static const bool enableAutoReconnect = true;
  static const bool enablePacketQueueOptimization = true;
  static const bool enableDeviceProfiles = true;
  static const bool enableAdaptiveProcessing = true;

  // ============================================
  // DEBUG SETTINGS
  // ============================================
  static const bool debugMidiMessages = false;
  static const bool debugBluetoothEvents = false;
  static const bool debugPerformanceMetrics = true;
  static const bool debugPacketQueue = true;

  // ============================================
  // HELPER METHODS
  // ============================================

  /// Get MIDI note name from note number
  static String getMidiNoteName(int midiNote) {
    final noteIndex = (midiNote - 21) % 12;
    final octave = ((midiNote - 21) / 12).floor();
    return '${noteNames[noteIndex]}$octave';
  }

  /// Check if MIDI note is a black key
  static bool isBlackKey(int midiNote) {
    final noteInOctave = (midiNote - 21) % 12;
    return !pianoKeyPattern[noteInOctave];
  }

  /// Check if MIDI note is within piano range
  static bool isValidPianoNote(int midiNote) {
    return midiNote >= midiFirstNote && midiNote <= midiLastNote;
  }

  /// Get device profile by device name
  static Map<String, dynamic>? getDeviceProfile(String deviceName) {
    final nameLower = deviceName.toLowerCase();

    for (var entry in deviceProfiles.entries) {
      final keywords = entry.value['keywords'] as List<String>;
      for (var keyword in keywords) {
        if (nameLower.contains(keyword.toLowerCase())) {
          return entry.value;
        }
      }
    }

    return null;
  }

  /// Get recommended latency for device
  static double getRecommendedLatency(String deviceName) {
    final profile = getDeviceProfile(deviceName);
    return profile?['defaultLatency'] ?? defaultLatency;
  }
}
