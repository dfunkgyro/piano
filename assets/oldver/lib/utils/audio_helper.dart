// ============================================
// audio_helper.dart - Audio Utility Functions
// ============================================
// Import required for pow and log functions
import 'dart:math';

class AudioHelper {
  /// Convert MIDI note number to note name with octave
  static String midiToNoteName(int midiNote) {
    const noteNames = [
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
    final octave = (midiNote / 12).floor() - 1;
    final noteName = noteNames[midiNote % 12];
    return '$noteName$octave';
  }

  /// Convert note name to MIDI note number
  static int noteNameToMidi(String noteName) {
    const noteMap = {
      'C': 0,
      'C#': 1,
      'D': 2,
      'D#': 3,
      'E': 4,
      'F': 5,
      'F#': 6,
      'G': 7,
      'G#': 8,
      'A': 9,
      'A#': 10,
      'B': 11
    };

    // Extract note and octave
    final match = RegExp(r'([A-G]#?)(\d+)').firstMatch(noteName);
    if (match == null) return 60; // Default to middle C

    final note = match.group(1)!;
    final octave = int.parse(match.group(2)!);

    return (octave + 1) * 12 + (noteMap[note] ?? 0);
  }

  /// Convert MIDI note to frequency in Hz
  static double midiToFrequency(int midiNote) {
    return 440.0 * pow(2.0, (midiNote - 69) / 12.0);
  }

  /// Convert frequency to MIDI note
  static int frequencyToMidi(double frequency) {
    return (69 + 12 * (log(frequency / 440.0) / log(2))).round();
  }

  /// Check if note is a black key
  static bool isBlackKey(int midiNote) {
    const blackKeys = [1, 3, 6, 8, 10]; // C#, D#, F#, G#, A#
    return blackKeys.contains(midiNote % 12);
  }

  /// Check if note is a white key
  static bool isWhiteKey(int midiNote) {
    return !isBlackKey(midiNote);
  }

  /// Get the piano key index (0-87 for an 88-key piano)
  static int getKeyIndex(int midiNote) {
    return midiNote - 21; // A0 is MIDI note 21
  }

  /// Validate if MIDI note is within piano range
  static bool isValidPianoNote(int midiNote) {
    return midiNote >= 21 && midiNote <= 108; // A0 to C8
  }

  /// Apply velocity curve for natural piano feel
  static double applyVelocityCurve(double velocity) {
    // Exponential curve for more natural dynamics
    if (velocity < 0.3) {
      return velocity * 0.5 + 0.1; // Soft: 0.1-0.25
    } else if (velocity < 0.7) {
      final normalized = (velocity - 0.3) / 0.4;
      return 0.25 + (normalized * normalized * 0.45); // Medium: 0.25-0.70
    } else {
      final normalized = (velocity - 0.7) / 0.3;
      return 0.70 + (normalized * 0.3); // Hard: 0.70-1.0
    }
  }

  /// Calculate note duration category
  static String getNoteDurationCategory(Duration duration) {
    final ms = duration.inMilliseconds;
    if (ms < 100) return 'Staccato';
    if (ms < 300) return 'Short';
    if (ms < 800) return 'Medium';
    if (ms < 2000) return 'Long';
    return 'Sustained';
  }

  /// Parse MIDI message
  static Map<String, dynamic> parseMidiMessage(List<int> data) {
    if (data.length < 3) {
      return {'type': 'unknown', 'data': data};
    }

    final status = data[0];
    final messageType = status & 0xF0;
    final channel = status & 0x0F;
    final note = data[1];
    final velocity = data[2];

    switch (messageType) {
      case 0x90: // Note On
        return {
          'type': velocity > 0 ? 'note_on' : 'note_off',
          'channel': channel,
          'note': note,
          'velocity': velocity,
          'noteName': midiToNoteName(note),
        };
      case 0x80: // Note Off
        return {
          'type': 'note_off',
          'channel': channel,
          'note': note,
          'velocity': velocity,
          'noteName': midiToNoteName(note),
        };
      case 0xB0: // Control Change
        return {
          'type': 'control_change',
          'channel': channel,
          'controller': note,
          'value': velocity,
        };
      case 0xE0: // Pitch Bend
        final value = (velocity << 7) | note;
        return {
          'type': 'pitch_bend',
          'channel': channel,
          'value': value,
        };
      default:
        return {
          'type': 'other',
          'status': status,
          'data': data,
        };
    }
  }

  /// Format duration to readable string
  static String formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Calculate average velocity from a list
  static double calculateAverageVelocity(List<double> velocities) {
    if (velocities.isEmpty) return 0.0;
    return velocities.reduce((a, b) => a + b) / velocities.length;
  }

  /// Normalize velocity to 0-1 range
  static double normalizeVelocity(int midiVelocity) {
    return (midiVelocity / 127.0).clamp(0.0, 1.0);
  }

  /// Convert normalized velocity to MIDI velocity
  static int denormalizeVelocity(double normalizedVelocity) {
    return (normalizedVelocity * 127).round().clamp(0, 127);
  }

  /// Get note color for visualization
  static String getNoteColor(int midiNote) {
    return isBlackKey(midiNote) ? '#000000' : '#FFFFFF';
  }

  /// Calculate decay time based on velocity
  static Duration calculateDecayTime(double velocity,
      {bool sustainPedal = false}) {
    const baseDecay = Duration(milliseconds: 800);
    final velocityFactor = velocity * 0.5 + 0.5; // 0.5-1.0 range

    if (sustainPedal) {
      return Duration(
          milliseconds:
              (baseDecay.inMilliseconds * 3.5 * velocityFactor).toInt());
    } else {
      return Duration(
          milliseconds: (baseDecay.inMilliseconds * velocityFactor).toInt());
    }
  }

  /// Check if two notes are within an octave
  static bool isWithinOctave(int note1, int note2) {
    return (note1 - note2).abs() <= 12;
  }

  /// Get interval between two notes
  static int getInterval(int note1, int note2) {
    return (note2 - note1).abs();
  }

  /// Get interval name
  static String getIntervalName(int interval) {
    const intervalNames = {
      0: 'Unison',
      1: 'Minor 2nd',
      2: 'Major 2nd',
      3: 'Minor 3rd',
      4: 'Major 3rd',
      5: 'Perfect 4th',
      6: 'Tritone',
      7: 'Perfect 5th',
      8: 'Minor 6th',
      9: 'Major 6th',
      10: 'Minor 7th',
      11: 'Major 7th',
      12: 'Octave',
    };
    return intervalNames[interval % 12] ?? 'Unknown';
  }

  /// Transpose note by semitones
  static int transposeNote(int midiNote, int semitones) {
    return (midiNote + semitones).clamp(21, 108);
  }
}
