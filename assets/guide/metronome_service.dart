import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:audioplayers/audioplayers.dart';
// Widget for visual metronome display
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

enum TimeSignature {
  fourFour(4, 4, 'Common Time'),
  threeFour(3, 4, 'Waltz Time'),
  sixEight(6, 8, 'Compound Duple'),
  fiveFour(5, 4, 'Odd Time'),
  sevenEight(7, 8, 'Irregular');

  final int beatsPerMeasure;
  final int beatUnit;
  final String name;
  const TimeSignature(this.beatsPerMeasure, this.beatUnit, this.name);
}

class MetronomeService {
  Timer? _timer;
  final AudioPlayer _clickPlayer = AudioPlayer();
  final AudioPlayer _accentPlayer = AudioPlayer();

  bool _isRunning = false;
  int _currentBeat = 0;
  int _bpm = 120;
  TimeSignature _timeSignature = TimeSignature.fourFour;
  bool _accentFirstBeat = true;
  bool _visualOnly = false;

  // Callbacks
  Function(int beat, bool isAccent)? onBeat;
  Function(int bpm)? onTempoChange;

  // Stats
  int _totalBeats = 0;
  DateTime? _sessionStart;

  bool get isRunning => _isRunning;
  int get bpm => _bpm;
  int get currentBeat => _currentBeat;
  TimeSignature get timeSignature => _timeSignature;
  int get totalBeats => _totalBeats;

  Future<void> initialize() async {
    try {
      // Pre-load click sounds for minimal latency
      await _clickPlayer.setReleaseMode(ReleaseMode.stop);
      await _accentPlayer.setReleaseMode(ReleaseMode.stop);
      await _clickPlayer.setVolume(0.7);
      await _accentPlayer.setVolume(1.0);

      debugPrint('✅ Metronome initialized');
    } catch (e) {
      debugPrint('❌ Metronome init error: $e');
    }
  }

  void start() {
    if (_isRunning) return;

    _isRunning = true;
    _currentBeat = 0;
    _sessionStart = DateTime.now();

    final intervalMs = (60000 / _bpm).round();

    _timer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) {
      _tick();
    });

    debugPrint('🎵 Metronome started at $_bpm BPM');
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _isRunning = false;
    _currentBeat = 0;

    debugPrint('⏹️ Metronome stopped. Total beats: $_totalBeats');
  }

  void _tick() {
    _currentBeat = (_currentBeat % _timeSignature.beatsPerMeasure) + 1;
    _totalBeats++;

    final isAccent = _accentFirstBeat && _currentBeat == 1;

    // Play sound
    if (!_visualOnly) {
      if (isAccent) {
        _playAccent();
      } else {
        _playClick();
      }
    }

    // Trigger callback for visual feedback
    onBeat?.call(_currentBeat, isAccent);
  }

  Future<void> _playClick() async {
    try {
      // Generate click sound programmatically or use asset
      await _clickPlayer.play(AssetSource('sounds/metronome_click.wav'));
    } catch (e) {
      // Fallback: use system beep or generate tone
      debugPrint('Click sound not found, using silent mode');
    }
  }

  Future<void> _playAccent() async {
    try {
      await _accentPlayer.play(AssetSource('sounds/metronome_accent.wav'));
    } catch (e) {
      debugPrint('Accent sound not found, using click');
      _playClick();
    }
  }

  void setBPM(int newBpm) {
    if (newBpm < 30 || newBpm > 300) return;

    _bpm = newBpm;
    onTempoChange?.call(_bpm);

    // Restart if running to apply new tempo
    if (_isRunning) {
      stop();
      start();
    }
  }

  void adjustBPM(int delta) {
    setBPM(_bpm + delta);
  }

  void setTimeSignature(TimeSignature signature) {
    _timeSignature = signature;
    _currentBeat = 0;
  }

  void setAccentFirstBeat(bool enabled) {
    _accentFirstBeat = enabled;
  }

  void setVisualOnly(bool enabled) {
    _visualOnly = enabled;
  }

  void tapTempo() {
    // Implement tap tempo functionality
    // Store tap times and calculate average BPM
  }

  Map<String, dynamic> getStats() {
    final duration = _sessionStart != null
        ? DateTime.now().difference(_sessionStart!)
        : Duration.zero;

    return {
      'totalBeats': _totalBeats,
      'sessionDuration': duration.inSeconds,
      'currentBPM': _bpm,
      'timeSignature':
          '${_timeSignature.beatsPerMeasure}/${_timeSignature.beatUnit}',
    };
  }

  void reset() {
    stop();
    _totalBeats = 0;
    _sessionStart = null;
  }

  void dispose() {
    stop();
    _clickPlayer.dispose();
    _accentPlayer.dispose();
  }
}

class VisualMetronome extends StatefulWidget {
  final MetronomeService metronome;
  final bool compact;

  const VisualMetronome({
    super.key,
    required this.metronome,
    this.compact = false,
  });

  @override
  State<VisualMetronome> createState() => _VisualMetronomeState();
}

class _VisualMetronomeState extends State<VisualMetronome>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  int _currentBeat = 0;
  bool _isAccent = false;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );

    widget.metronome.onBeat = (beat, isAccent) {
      setState(() {
        _currentBeat = beat;
        _isAccent = isAccent;
      });
      _pulseController.forward().then((_) => _pulseController.reverse());
    };
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  Widget _buildCompactView() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          CupertinoIcons.metronome,
          size: 16,
          color: widget.metronome.isRunning
              ? CupertinoColors.activeGreen
              : CupertinoColors.systemGrey,
        ),
        const SizedBox(width: 8),
        Text(
          '${widget.metronome.bpm}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 12),
        ...List.generate(
          widget.metronome.timeSignature.beatsPerMeasure,
          (index) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _currentBeat == index + 1
                    ? (_isAccent
                        ? CupertinoColors.systemRed
                        : CupertinoColors.activeBlue)
                    : CupertinoColors.systemGrey4,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFullView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            CupertinoColors.systemBlue.withOpacity(0.1),
            CupertinoColors.systemPurple.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          // BPM Display
          ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: _isAccent
                      ? [
                          CupertinoColors.systemRed,
                          CupertinoColors.systemOrange,
                        ]
                      : [
                          CupertinoColors.systemBlue,
                          CupertinoColors.systemIndigo,
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isAccent
                            ? CupertinoColors.systemRed
                            : CupertinoColors.systemBlue)
                        .withOpacity(0.5),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${widget.metronome.bpm}',
                    style: const TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.bold,
                      color: CupertinoColors.white,
                    ),
                  ),
                  const Text(
                    'BPM',
                    style: TextStyle(
                      fontSize: 14,
                      color: CupertinoColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Beat Indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.metronome.timeSignature.beatsPerMeasure,
              (index) {
                final beatNum = index + 1;
                final isActive = _currentBeat == beatNum;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: isActive ? 40 : 32,
                    height: isActive ? 40 : 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isActive
                          ? (beatNum == 1 && _isAccent
                              ? CupertinoColors.systemRed
                              : CupertinoColors.activeBlue)
                          : CupertinoColors.systemGrey5,
                      border: Border.all(
                        color: beatNum == 1
                            ? CupertinoColors.systemRed.withOpacity(0.5)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$beatNum',
                        style: TextStyle(
                          fontSize: isActive ? 16 : 14,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.normal,
                          color: isActive
                              ? CupertinoColors.white
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // Time Signature
          Text(
            '${widget.metronome.timeSignature.beatsPerMeasure}/${widget.metronome.timeSignature.beatUnit}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            widget.metronome.timeSignature.name,
            style: const TextStyle(
              fontSize: 12,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }
}

// Metronome Control Panel
class MetronomeControlPanel extends StatefulWidget {
  final MetronomeService metronome;

  const MetronomeControlPanel({super.key, required this.metronome});

  @override
  State<MetronomeControlPanel> createState() => _MetronomeControlPanelState();
}

class _MetronomeControlPanelState extends State<MetronomeControlPanel> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // BPM Slider
          Row(
            children: [
              const Icon(CupertinoIcons.minus_circle, size: 20),
              Expanded(
                child: Slider(
                  value: widget.metronome.bpm.toDouble(),
                  min: 30,
                  max: 300,
                  divisions: 270,
                  onChanged: (value) {
                    setState(() {
                      widget.metronome.setBPM(value.toInt());
                    });
                  },
                ),
              ),
              const Icon(CupertinoIcons.plus_circle, size: 20),
            ],
          ),

          const SizedBox(height: 16),

          // Quick BPM Presets
          Wrap(
            spacing: 8,
            children: [
              _bpmButton('Largo', 45),
              _bpmButton('Adagio', 70),
              _bpmButton('Andante', 90),
              _bpmButton('Moderato', 110),
              _bpmButton('Allegro', 140),
              _bpmButton('Presto', 180),
            ],
          ),

          const SizedBox(height: 16),

          // Time Signature Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: TimeSignature.values.map((ts) {
              final isSelected = widget.metronome.timeSignature == ts;
              return CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                color: isSelected
                    ? CupertinoColors.activeBlue
                    : CupertinoColors.systemGrey5,
                onPressed: () {
                  setState(() {
                    widget.metronome.setTimeSignature(ts);
                  });
                },
                child: Text(
                  '${ts.beatsPerMeasure}/${ts.beatUnit}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? CupertinoColors.white
                        : CupertinoColors.black,
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          // Start/Stop Button
          SizedBox(
            width: double.infinity,
            child: CupertinoButton.filled(
              onPressed: () {
                setState(() {
                  if (widget.metronome.isRunning) {
                    widget.metronome.stop();
                  } else {
                    widget.metronome.start();
                  }
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.metronome.isRunning
                        ? CupertinoIcons.stop_fill
                        : CupertinoIcons.play_fill,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.metronome.isRunning ? 'Stop' : 'Start',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bpmButton(String label, int bpm) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: CupertinoColors.systemGrey6,
      onPressed: () {
        setState(() {
          widget.metronome.setBPM(bpm);
        });
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: CupertinoColors.black,
            ),
          ),
          Text(
            '$bpm',
            style: const TextStyle(
              fontSize: 10,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }
}
