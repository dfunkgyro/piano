// ============================================
// midi_helper.dart
// ============================================

import 'dart:math';
import 'package:flutter/foundation.dart';

class MidiHelper {
  // MIDI Constants
  static const int noteOff = 0x80;
  static const int noteOn = 0x90;
  static const int polyPressure = 0xA0;
  static const int controlChange = 0xB0;
  static const int programChange = 0xC0;
  static const int channelPressure = 0xD0;
  static const int pitchBend = 0xE0;

  // Control Change numbers
  static const int ccModWheel = 1;
  static const int ccVolume = 7;
  static const int ccPan = 10;
  static const int ccExpression = 11;
  static const int ccSustainPedal = 64;
  static const int ccSostenutoPedal = 66;
  static const int ccSoftPedal = 67;
  static const int ccAllNotesOff = 123;

  // Parse MIDI message
  static MidiMessage parseMidiData(List<int> data) {
    if (data.length < 2) {
      return MidiMessage(type: MidiMessageType.unknown, data: data);
    }

    final status = data[0] & 0xF0;
    final channel = data[0] & 0x0F;

    switch (status) {
      case noteOn:
        if (data.length >= 3) {
          final note = data[1];
          final velocity = data[2];
          return MidiMessage(
            type:
                velocity > 0 ? MidiMessageType.noteOn : MidiMessageType.noteOff,
            channel: channel,
            note: note,
            velocity: velocity,
            data: data,
          );
        }
        break;

      case noteOff:
        if (data.length >= 3) {
          return MidiMessage(
            type: MidiMessageType.noteOff,
            channel: channel,
            note: data[1],
            velocity: data[2],
            data: data,
          );
        }
        break;

      case controlChange:
        if (data.length >= 3) {
          return MidiMessage(
            type: MidiMessageType.controlChange,
            channel: channel,
            controller: data[1],
            value: data[2],
            data: data,
          );
        }
        break;

      case pitchBend:
        if (data.length >= 3) {
          final value = (data[2] << 7) | data[1];
          return MidiMessage(
            type: MidiMessageType.pitchBend,
            channel: channel,
            value: value,
            data: data,
          );
        }
        break;
    }

    return MidiMessage(type: MidiMessageType.unknown, data: data);
  }

  // Create MIDI note on message
  static List<int> createNoteOn(int note, int velocity, {int channel = 0}) {
    return [
      noteOn | (channel & 0x0F),
      note & 0x7F,
      velocity & 0x7F,
    ];
  }

  // Create MIDI note off message
  static List<int> createNoteOff(int note, {int channel = 0}) {
    return [
      noteOff | (channel & 0x0F),
      note & 0x7F,
      0,
    ];
  }

  // Create control change message
  static List<int> createControlChange(int controller, int value,
      {int channel = 0}) {
    return [
      controlChange | (channel & 0x0F),
      controller & 0x7F,
      value & 0x7F,
    ];
  }

  // Check if note is in valid MIDI range
  static bool isValidNote(int note) {
    return note >= 0 && note <= 127;
  }

  // Check if velocity is valid
  static bool isValidVelocity(int velocity) {
    return velocity >= 0 && velocity <= 127;
  }

  // Get note name with octave
  static String getNoteName(int midiNote, {bool includeOctave = true}) {
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
    final noteName = noteNames[midiNote % 12];

    if (includeOctave) {
      final octave = (midiNote / 12).floor() - 1;
      return '$noteName$octave';
    }

    return noteName;
  }

  // Parse note name to MIDI number
  static int? parseNoteName(String noteName) {
    final pattern = RegExp(r'^([A-G]#?)(-?\d+)$');
    final match = pattern.firstMatch(noteName);

    if (match == null) return null;

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
      'B': 11,
    };

    final note = match.group(1)!;
    final octave = int.parse(match.group(2)!);
    final noteValue = noteMap[note];

    if (noteValue == null) return null;

    return (octave + 1) * 12 + noteValue;
  }

  // Check if note is black key
  static bool isBlackKey(int midiNote) {
    const blackKeys = [1, 3, 6, 8, 10]; // C#, D#, F#, G#, A#
    return blackKeys.contains(midiNote % 12);
  }

  // Get interval between two notes
  static int getInterval(int note1, int note2) {
    return (note2 - note1).abs();
  }

  // Get interval name
  static String getIntervalName(int semitones) {
    const intervals = [
      'Unison',
      'Minor 2nd',
      'Major 2nd',
      'Minor 3rd',
      'Major 3rd',
      'Perfect 4th',
      'Tritone',
      'Perfect 5th',
      'Minor 6th',
      'Major 6th',
      'Minor 7th',
      'Major 7th',
      'Octave'
    ];

    if (semitones >= 0 && semitones < intervals.length) {
      return intervals[semitones];
    }

    return '$semitones semitones';
  }

  // Transpose note
  static int transposeNote(int note, int semitones) {
    return (note + semitones).clamp(0, 127);
  }

  // Calculate delay compensation for BLE MIDI
  static double calculateBleLatency(int packetSize) {
    // BLE MIDI typically has 7.5ms, 15ms, or 30ms intervals
    if (packetSize <= 20) return 7.5;
    if (packetSize <= 40) return 15.0;
    return 30.0;
  }

  // Estimate connection quality
  static String getConnectionQuality(double latency) {
    if (latency < 10) return 'Excellent';
    if (latency < 20) return 'Good';
    if (latency < 50) return 'Fair';
    return 'Poor';
  }
}

// MIDI Message class
class MidiMessage {
  final MidiMessageType type;
  final int? channel;
  final int? note;
  final int? velocity;
  final int? controller;
  final int? value;
  final List<int> data;

  MidiMessage({
    required this.type,
    this.channel,
    this.note,
    this.velocity,
    this.controller,
    this.value,
    required this.data,
  });

  @override
  String toString() {
    switch (type) {
      case MidiMessageType.noteOn:
        return 'Note On: ${MidiHelper.getNoteName(note!)} velocity=$velocity';
      case MidiMessageType.noteOff:
        return 'Note Off: ${MidiHelper.getNoteName(note!)}';
      case MidiMessageType.controlChange:
        return 'CC: controller=$controller value=$value';
      case MidiMessageType.pitchBend:
        return 'Pitch Bend: value=$value';
      default:
        return 'MIDI: ${data.map((b) => b.toRadixString(16)).join(' ')}';
    }
  }
}

enum MidiMessageType {
  noteOn,
  noteOff,
  controlChange,
  programChange,
  pitchBend,
  channelPressure,
  polyPressure,
  unknown,
}
