import 'package:flutter/cupertino.dart';

class ControllerPreset {
  final String name;
  final String manufacturer;
  final int minNote;
  final int maxNote;
  final int totalKeys;
  final List<int> velocityCurves;
  final bool hasModWheel;
  final bool hasPitchBend;
  final bool hasSustainPedal;
  final bool hasExpressionPedal;
  final int controllerCount;
  final int faderCount;
  final int buttonCount;
  final bool hasDirectLink;
  final Map<String, dynamic> features;

  const ControllerPreset({
    required this.name,
    required this.manufacturer,
    required this.minNote,
    required this.maxNote,
    required this.totalKeys,
    required this.velocityCurves,
    required this.hasModWheel,
    required this.hasPitchBend,
    required this.hasSustainPedal,
    required this.hasExpressionPedal,
    required this.controllerCount,
    required this.faderCount,
    required this.buttonCount,
    required this.hasDirectLink,
    required this.features,
  });
}

class MidiControllerDatabase {
  static const Map<String, ControllerPreset> controllers = {
    'M-Audio Oxygen 88': ControllerPreset(
      name: 'M-Audio Oxygen 88',
      manufacturer: 'M-Audio',
      minNote: 21, // A0
      maxNote: 108, // C8
      totalKeys: 88,
      velocityCurves: [1, 2, 3, 4],
      hasModWheel: true,
      hasPitchBend: true,
      hasSustainPedal: true,
      hasExpressionPedal: true,
      controllerCount: 8,
      faderCount: 9,
      buttonCount: 9,
      hasDirectLink: true,
      features: {
        'keybed': 'Graded Hammer-Action',
        'pedalInputs': 3,
        'sustainInputs': 2,
        'midiOut': true,
        'presets': 'Factory presets for virtual instruments',
        'transportControls': 6,
        'snapshots': 2,
        'led': '3-digit',
        'selectButtons': 3,
        'compatibility': 'Pro Tools and other DAWs',
      },
    ),

    'M-Audio Oxygen 61': ControllerPreset(
      name: 'M-Audio Oxygen 61',
      manufacturer: 'M-Audio',
      minNote: 36, // C2
      maxNote: 96, // C7
      totalKeys: 61,
      velocityCurves: [1, 2, 3, 4],
      hasModWheel: true,
      hasPitchBend: true,
      hasSustainPedal: true,
      hasExpressionPedal: false,
      controllerCount: 8,
      faderCount: 9,
      buttonCount: 9,
      hasDirectLink: true,
      features: {'keybed': 'Semi-weighted', 'pedalInputs': 1, 'midiOut': true},
    ),

    'Yamaha P-125': ControllerPreset(
      name: 'Yamaha P-125',
      manufacturer: 'Yamaha',
      minNote: 21, // A0
      maxNote: 108, // C8
      totalKeys: 88,
      velocityCurves: [1, 2, 3, 4],
      hasModWheel: false,
      hasPitchBend: false,
      hasSustainPedal: true,
      hasExpressionPedal: false,
      controllerCount: 0,
      faderCount: 0,
      buttonCount: 0,
      hasDirectLink: false,
      features: {
        'keybed': 'GHS Weighted',
        'pedalInputs': 1,
        'voices': 24,
        'polyphony': 192,
      },
    ),

    'Roland FP-30X': ControllerPreset(
      name: 'Roland FP-30X',
      manufacturer: 'Roland',
      minNote: 21, // A0
      maxNote: 108, // C8
      totalKeys: 88,
      velocityCurves: [1, 2, 3, 4, 5],
      hasModWheel: false,
      hasPitchBend: false,
      hasSustainPedal: true,
      hasExpressionPedal: true,
      controllerCount: 0,
      faderCount: 0,
      buttonCount: 0,
      hasDirectLink: false,
      features: {
        'keybed': 'PHA-4 Standard',
        'pedalInputs': 1,
        'bluetooth': 'MIDI and Audio',
        'polyphony': 256,
      },
    ),

    'Arturia KeyLab 88 MkII': ControllerPreset(
      name: 'Arturia KeyLab 88 MkII',
      manufacturer: 'Arturia',
      minNote: 21, // A0
      maxNote: 108, // C8
      totalKeys: 88,
      velocityCurves: [1, 2, 3],
      hasModWheel: true,
      hasPitchBend: true,
      hasSustainPedal: true,
      hasExpressionPedal: true,
      controllerCount: 9,
      faderCount: 9,
      buttonCount: 16,
      hasDirectLink: true,
      features: {
        'keybed': 'Hammer-Action',
        'pads': 16,
        'display': 'OLED',
        'daw': 'Analog Lab integration',
      },
    ),

    'Korg D1': ControllerPreset(
      name: 'Korg D1',
      manufacturer: 'Korg',
      minNote: 21, // A0
      maxNote: 108, // C8
      totalKeys: 88,
      velocityCurves: [1, 2, 3],
      hasModWheel: false,
      hasPitchBend: false,
      hasSustainPedal: true,
      hasExpressionPedal: false,
      controllerCount: 0,
      faderCount: 0,
      buttonCount: 0,
      hasDirectLink: false,
      features: {'keybed': 'RH3 Weighted', 'pedalInputs': 2, 'polyphony': 120},
    ),

    'Casio Privia PX-S1100': ControllerPreset(
      name: 'Casio Privia PX-S1100',
      manufacturer: 'Casio',
      minNote: 21, // A0
      maxNote: 108, // C8
      totalKeys: 88,
      velocityCurves: [1, 2, 3, 4],
      hasModWheel: false,
      hasPitchBend: false,
      hasSustainPedal: true,
      hasExpressionPedal: false,
      controllerCount: 0,
      faderCount: 0,
      buttonCount: 0,
      hasDirectLink: false,
      features: {
        'keybed': 'Smart Scaled Hammer Action',
        'bluetooth': 'MIDI and Audio',
        'portability': 'Ultra-slim design',
      },
    ),

    'Kawai ES920': ControllerPreset(
      name: 'Kawai ES920',
      manufacturer: 'Kawai',
      minNote: 21, // A0
      maxNote: 108, // C8
      totalKeys: 88,
      velocityCurves: [1, 2, 3, 4, 5],
      hasModWheel: false,
      hasPitchBend: false,
      hasSustainPedal: true,
      hasExpressionPedal: false,
      controllerCount: 0,
      faderCount: 0,
      buttonCount: 0,
      hasDirectLink: false,
      features: {
        'keybed': 'Responsive Hammer Compact',
        'bluetooth': 'MIDI',
        'polyphony': 256,
        'voices': 38,
      },
    ),

    'Generic 88-Key': ControllerPreset(
      name: 'Generic 88-Key MIDI Controller',
      manufacturer: 'Generic',
      minNote: 21, // A0
      maxNote: 108, // C8
      totalKeys: 88,
      velocityCurves: [1],
      hasModWheel: true,
      hasPitchBend: true,
      hasSustainPedal: true,
      hasExpressionPedal: false,
      controllerCount: 0,
      faderCount: 0,
      buttonCount: 0,
      hasDirectLink: false,
      features: {'keybed': 'Standard'},
    ),
  };

  static ControllerPreset? getPresetByName(String name) {
    // Try exact match first
    if (controllers.containsKey(name)) {
      return controllers[name];
    }

    // Try partial match
    final nameLower = name.toLowerCase();
    for (var entry in controllers.entries) {
      if (entry.key.toLowerCase().contains(nameLower) ||
          nameLower.contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Return generic 88-key as fallback
    return controllers['Generic 88-Key'];
  }

  static String getNoteRangeDescription(ControllerPreset preset) {
    final minNoteName = _getNoteNameFromMidi(preset.minNote);
    final maxNoteName = _getNoteNameFromMidi(preset.maxNote);
    return '$minNoteName ($preset.minNote}) to $maxNoteName (${preset.maxNote})';
  }

  static String _getNoteNameFromMidi(int midiNote) {
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
      'B',
    ];
    final octave = (midiNote / 12).floor() - 1;
    final noteName = noteNames[midiNote % 12];
    return '$noteName$octave';
  }

  static List<ControllerPreset> getAllPresets() {
    return controllers.values.toList();
  }

  static List<ControllerPreset> get88KeyControllers() {
    return controllers.values.where((p) => p.totalKeys == 88).toList();
  }
}

// Widget to display controller information
class ControllerInfoCard extends StatelessWidget {
  final ControllerPreset preset;

  const ControllerInfoCard({super.key, required this.preset});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.systemGrey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.music_note_2,
                color: CupertinoColors.systemBlue,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      preset.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      preset.manufacturer,
                      style: const TextStyle(
                        fontSize: 14,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildInfoRow('Keys', '${preset.totalKeys} keys'),
          _buildInfoRow(
            'Range',
            MidiControllerDatabase.getNoteRangeDescription(preset),
          ),
          _buildInfoRow(
            'Velocity Curves',
            preset.velocityCurves.length.toString(),
          ),

          if (preset.keybed != null) _buildInfoRow('Keybed', preset.keybed!),

          const SizedBox(height: 12),
          const Text(
            'Features',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (preset.hasModWheel) _buildFeatureChip('Mod Wheel'),
              if (preset.hasPitchBend) _buildFeatureChip('Pitch Bend'),
              if (preset.hasSustainPedal) _buildFeatureChip('Sustain Pedal'),
              if (preset.hasExpressionPedal) _buildFeatureChip('Expression'),
              if (preset.controllerCount > 0)
                _buildFeatureChip('${preset.controllerCount} Knobs'),
              if (preset.faderCount > 0)
                _buildFeatureChip('${preset.faderCount} Faders'),
              if (preset.hasDirectLink) _buildFeatureChip('DirectLink'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemBlue.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: CupertinoColors.systemBlue,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

extension ControllerPresetExtension on ControllerPreset {
  String? get keybed => features['keybed'] as String?;
  int? get pedalInputs => features['pedalInputs'] as int?;
  String? get bluetooth => features['bluetooth'] as String?;
}
