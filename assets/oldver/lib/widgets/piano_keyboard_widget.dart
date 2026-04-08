import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PianoKeyboardWidget extends StatefulWidget {
  final Set<int> activeNotes;
  final Function(int)? onKeyPressed;
  final Function(int)? onKeyReleased;

  const PianoKeyboardWidget({
    super.key,
    required this.activeNotes,
    this.onKeyPressed,
    this.onKeyReleased,
  });

  @override
  State<PianoKeyboardWidget> createState() => _PianoKeyboardWidgetState();
}

class _PianoKeyboardWidgetState extends State<PianoKeyboardWidget> {
  static const int startNote = 21; // A0
  static const int endNote = 108; // C8
  static const int totalKeys = 88;

  // Piano key pattern (1 = white, 0 = black)
  static const List<bool> keyPattern = [
    true,
    false,
    true,
    false,
    true,
    true,
    false,
    true,
    false,
    true,
    false,
    true
  ];

  bool _isBlackKey(int midiNote) {
    final noteInOctave = (midiNote - 21) % 12;
    return !keyPattern[noteInOctave];
  }

  String _getNoteName(int midiNote) {
    const noteNames = [
      'A',
      'A#',
      'B',
      'C',
      'C#',
      'D',
      'D#',
      'E',
      'F',
      'F#',
      'G',
      'G#'
    ];
    final noteIndex = (midiNote - 21) % 12;
    final octave = ((midiNote - 21) / 12).floor();
    return '${noteNames[noteIndex]}$octave';
  }

  Color _getKeyColor(int midiNote, bool isPressed) {
    if (isPressed) {
      return _isBlackKey(midiNote)
          ? const Color(0xFF4A90E2) // Bright blue for black keys
          : const Color(0xFF64B5F6); // Light blue for white keys
    }
    return _isBlackKey(midiNote)
        ? const Color(0xFF1A1A1A) // Black
        : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            CupertinoColors.systemGrey6,
            CupertinoColors.systemGrey5,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Title bar
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  CupertinoIcons.music_note_2,
                  size: 16,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  '88-Key Piano Keyboard',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),

          // Scrollable keyboard
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Container(
                width: totalKeys * 20.0, // Each key is 20 pixels wide
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Stack(
                  children: [
                    // White keys (bottom layer)
                    Row(
                      children: List.generate(totalKeys, (index) {
                        final midiNote = startNote + index;
                        if (_isBlackKey(midiNote))
                          return const SizedBox.shrink();

                        final isPressed = widget.activeNotes.contains(midiNote);

                        return GestureDetector(
                          onTapDown: (_) => widget.onKeyPressed?.call(midiNote),
                          onTapUp: (_) => widget.onKeyReleased?.call(midiNote),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 50),
                            width: 20,
                            margin: const EdgeInsets.symmetric(horizontal: 0.5),
                            decoration: BoxDecoration(
                              color: _getKeyColor(midiNote, isPressed),
                              border: Border.all(
                                color: Colors.black,
                                width: 1,
                              ),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(4),
                                bottomRight: Radius.circular(4),
                              ),
                              boxShadow: isPressed
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF4A90E2)
                                            .withOpacity(0.5),
                                        blurRadius: 8,
                                        spreadRadius: 2,
                                      ),
                                    ]
                                  : [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 2,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isPressed)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      _getNoteName(midiNote),
                                      style: const TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),

                    // Black keys (top layer)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Row(
                        children: List.generate(totalKeys, (index) {
                          final midiNote = startNote + index;
                          if (!_isBlackKey(midiNote)) {
                            return const SizedBox(width: 20);
                          }

                          final isPressed =
                              widget.activeNotes.contains(midiNote);

                          return Transform.translate(
                            offset: const Offset(
                                -10, 0), // Center between white keys
                            child: GestureDetector(
                              onTapDown: (_) =>
                                  widget.onKeyPressed?.call(midiNote),
                              onTapUp: (_) =>
                                  widget.onKeyReleased?.call(midiNote),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 50),
                                width: 14,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: _getKeyColor(midiNote, isPressed),
                                  border: Border.all(
                                    color: Colors.black,
                                    width: 1,
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(3),
                                    bottomRight: Radius.circular(3),
                                  ),
                                  boxShadow: isPressed
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF4A90E2)
                                                .withOpacity(0.6),
                                            blurRadius: 12,
                                            spreadRadius: 3,
                                          ),
                                        ]
                                      : [
                                          BoxShadow(
                                            color:
                                                Colors.black.withOpacity(0.5),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (isPressed)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          _getNoteName(midiNote),
                                          style: const TextStyle(
                                            fontSize: 7,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Legend
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(
                  const Color(0xFF64B5F6),
                  'Active White Key',
                ),
                const SizedBox(width: 16),
                _buildLegendItem(
                  const Color(0xFF4A90E2),
                  'Active Black Key',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: Colors.black26),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: CupertinoColors.systemGrey,
          ),
        ),
      ],
    );
  }
}

// Compact keyboard for status display
class CompactPianoDisplay extends StatelessWidget {
  final Set<int> activeNotes;

  const CompactPianoDisplay({super.key, required this.activeNotes});

  bool _isBlackKey(int midiNote) {
    const keyPattern = [
      true,
      false,
      true,
      false,
      true,
      true,
      false,
      true,
      false,
      true,
      false,
      true
    ];
    final noteInOctave = (midiNote - 21) % 12;
    return !keyPattern[noteInOctave];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.music_note_2,
            size: 16,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(88, (index) {
                  final midiNote = 21 + index;
                  final isActive = activeNotes.contains(midiNote);
                  final isBlack = _isBlackKey(midiNote);

                  return Container(
                    width: isBlack ? 3 : 4,
                    height: isBlack ? 20 : 28,
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF4A90E2)
                          : (isBlack ? Colors.black : Colors.white),
                      border: Border.all(
                        color: Colors.black26,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${activeNotes.length}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: CupertinoColors.systemBlue,
            ),
          ),
        ],
      ),
    );
  }
}
