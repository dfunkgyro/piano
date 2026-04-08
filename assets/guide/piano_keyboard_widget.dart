import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class PianoKeyboardWidget extends StatefulWidget {
  final Set<int> activeNotes;
  final Set<int> highlightNotes;
  final Function(int)? onKeyPressed;
  final Function(int)? onKeyReleased;
  final double height;
  final bool showLabels;

  const PianoKeyboardWidget({
    super.key,
    required this.activeNotes,
    this.highlightNotes = const {},
    this.onKeyPressed,
    this.onKeyReleased,
    this.height = 200,
    this.showLabels = true,
  });

  @override
  State<PianoKeyboardWidget> createState() => _PianoKeyboardWidgetState();
}

class _PianoKeyboardWidgetState extends State<PianoKeyboardWidget> {
  static const int startNote = 21; // A0
  static const int endNote = 108; // C8
  static const int totalKeys = 88;

  // Piano key pattern starting from A (for A0)
  // A, A#, B, C, C#, D, D#, E, F, F#, G, G#
  static const List<bool> keyPattern = [
    true, // A
    false, // A#
    true, // B
    true, // C
    false, // C#
    true, // D
    false, // D#
    true, // E
    true, // F
    false, // F#
    true, // G
    false, // G#
  ];

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Auto-scroll to middle C (note 60) on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToMiddleC();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToMiddleC() {
    // Middle C is note 60, which is at index 39 (60 - 21)
    const middleCIndex = 39;
    final whiteKeysToMiddleC = _countWhiteKeysUpTo(middleCIndex);
    final scrollPosition = whiteKeysToMiddleC * 24.0 - 200; // Center in view

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        scrollPosition.clamp(0.0, _scrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  int _countWhiteKeysUpTo(int index) {
    int count = 0;
    for (int i = 0; i < index && i < totalKeys; i++) {
      if (!_isBlackKey(startNote + i)) {
        count++;
      }
    }
    return count;
  }

  bool _isBlackKey(int midiNote) {
    final noteInScale = (midiNote - 21) % 12;
    return !keyPattern[noteInScale];
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
      'G#',
    ];
    final octave = _getOctave(midiNote);
    final noteIndex = (midiNote - 21) % 12;
    return '${noteNames[noteIndex]}$octave';
  }

  int _getOctave(int midiNote) {
    // A0 = 21, so we calculate from there
    return (midiNote - 12) ~/ 12;
  }

  Color _getKeyColor(int midiNote, bool isPressed, bool isHighlighted) {
    if (isHighlighted) {
      return _isBlackKey(midiNote)
          ? const Color(0xFFFFA726) // Orange for black keys
          : const Color(0xFFFFD54F); // Yellow for white keys
    }
    if (isPressed) {
      return _isBlackKey(midiNote)
          ? const Color(0xFF4A90E2) // Blue for black keys
          : const Color(0xFF64B5F6); // Light blue for white keys
    }
    return _isBlackKey(midiNote)
        ? const Color(0xFF1A1A1A) // Black
        : Colors.white;
  }

  List<Widget> _buildWhiteKeys() {
    final whiteKeys = <Widget>[];

    for (int i = 0; i < totalKeys; i++) {
      final midiNote = startNote + i;
      if (_isBlackKey(midiNote)) continue;

      final isPressed = widget.activeNotes.contains(midiNote);
      final isHighlighted = widget.highlightNotes.contains(midiNote);
      final noteName = _getNoteName(midiNote);

      whiteKeys.add(
        GestureDetector(
          onTapDown: (_) => widget.onKeyPressed?.call(midiNote),
          onTapUp: (_) => widget.onKeyReleased?.call(midiNote),
          onTapCancel: () => widget.onKeyReleased?.call(midiNote),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 50),
            width: 24,
            margin: const EdgeInsets.symmetric(horizontal: 0.5),
            decoration: BoxDecoration(
              color: _getKeyColor(midiNote, isPressed, isHighlighted),
              border: Border.all(color: Colors.black, width: 1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
              boxShadow: isPressed || isHighlighted
                  ? [
                      BoxShadow(
                        color:
                            (isHighlighted
                                    ? const Color(0xFFFFA726)
                                    : const Color(0xFF4A90E2))
                                .withOpacity(0.5),
                        blurRadius: 12,
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
                if ((isPressed || isHighlighted) && widget.showLabels)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      noteName,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isHighlighted ? Colors.black87 : Colors.white,
                      ),
                    ),
                  ),
                // Show C notes
                if (widget.showLabels &&
                    noteName.startsWith('C') &&
                    !isPressed &&
                    !isHighlighted)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      noteName,
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return whiteKeys;
  }

  List<Widget> _buildBlackKeys() {
    final blackKeys = <Widget>[];
    double position = 0;

    for (int i = 0; i < totalKeys; i++) {
      final midiNote = startNote + i;

      if (!_isBlackKey(midiNote)) {
        // White key - advance position
        position += 24.0 + 1.0; // width + margin
        blackKeys.add(const SizedBox(width: 25));
      } else {
        // Black key - place it between white keys
        final isPressed = widget.activeNotes.contains(midiNote);
        final isHighlighted = widget.highlightNotes.contains(midiNote);
        final noteName = _getNoteName(midiNote);

        blackKeys.add(
          Transform.translate(
            offset: const Offset(-12.5, 0), // Center on the gap
            child: GestureDetector(
              onTapDown: (_) => widget.onKeyPressed?.call(midiNote),
              onTapUp: (_) => widget.onKeyReleased?.call(midiNote),
              onTapCancel: () => widget.onKeyReleased?.call(midiNote),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 50),
                width: 16,
                height: widget.height * 0.6,
                decoration: BoxDecoration(
                  color: _getKeyColor(midiNote, isPressed, isHighlighted),
                  border: Border.all(color: Colors.black, width: 1),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(3),
                    bottomRight: Radius.circular(3),
                  ),
                  boxShadow: isPressed || isHighlighted
                      ? [
                          BoxShadow(
                            color:
                                (isHighlighted
                                        ? const Color(0xFFFFA726)
                                        : const Color(0xFF4A90E2))
                                    .withOpacity(0.6),
                            blurRadius: 16,
                            spreadRadius: 3,
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if ((isPressed || isHighlighted) && widget.showLabels)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          noteName,
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.bold,
                            color: isHighlighted
                                ? Colors.black87
                                : Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
        position += 25;
      }
    }

    return blackKeys;
  }

  @override
  Widget build(BuildContext context) {
    // Count white keys for total width
    int whiteKeyCount = 0;
    for (int i = 0; i < totalKeys; i++) {
      if (!_isBlackKey(startNote + i)) {
        whiteKeyCount++;
      }
    }

    final totalWidth = whiteKeyCount * 25.0; // 24px + 1px margin

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [CupertinoColors.systemGrey6, CupertinoColors.systemGrey5],
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
          // Title bar with info
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                const Icon(
                  CupertinoIcons.music_note_2,
                  size: 16,
                  color: CupertinoColors.systemGrey,
                ),
                const SizedBox(width: 8),
                Text(
                  '88-Key Piano (A0-C8)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                const Spacer(),
                if (widget.activeNotes.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${widget.activeNotes.length} active',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: CupertinoColors.systemBlue,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Scrollable keyboard
          Expanded(
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Container(
                width: totalWidth,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Stack(
                  children: [
                    // White keys (bottom layer)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: _buildWhiteKeys(),
                    ),

                    // Black keys (top layer)
                    Positioned(
                      left: 0,
                      top: 0,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _buildBlackKeys(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Legend and controls
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            decoration: const BoxDecoration(
              color: CupertinoColors.systemBackground,
              border: Border(
                top: BorderSide(color: CupertinoColors.systemGrey5, width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildLegendItem(const Color(0xFF64B5F6), 'Playing'),
                    const SizedBox(width: 16),
                    if (widget.highlightNotes.isNotEmpty)
                      _buildLegendItem(const Color(0xFFFFD54F), 'Target'),
                  ],
                ),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  minSize: 0,
                  onPressed: _scrollToMiddleC,
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.location_fill, size: 14),
                      SizedBox(width: 4),
                      Text('Middle C', style: TextStyle(fontSize: 11)),
                    ],
                  ),
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
  final Set<int> highlightNotes;

  const CompactPianoDisplay({
    super.key,
    required this.activeNotes,
    this.highlightNotes = const {},
  });

  bool _isBlackKey(int midiNote) {
    const keyPattern = [
      true,
      false,
      true,
      true,
      false,
      true,
      false,
      true,
      true,
      false,
      true,
      false,
    ];
    final noteInScale = (midiNote - 21) % 12;
    return !keyPattern[noteInScale];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.music_note_2,
            size: 20,
            color: CupertinoColors.systemGrey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(88, (index) {
                  final midiNote = 21 + index;
                  final isActive = activeNotes.contains(midiNote);
                  final isHighlight = highlightNotes.contains(midiNote);
                  final isBlack = _isBlackKey(midiNote);

                  return Container(
                    width: isBlack ? 4 : 5,
                    height: isBlack ? 24 : 32,
                    margin: const EdgeInsets.symmetric(horizontal: 0.5),
                    decoration: BoxDecoration(
                      color: isHighlight
                          ? const Color(0xFFFFD54F)
                          : (isActive
                                ? const Color(0xFF4A90E2)
                                : (isBlack ? Colors.black : Colors.white)),
                      border: Border.all(color: Colors.black26, width: 0.5),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  );
                }),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${activeNotes.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.systemBlue,
                ),
              ),
              const Text(
                'active',
                style: TextStyle(
                  fontSize: 10,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
