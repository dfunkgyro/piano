import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../models/complete_songs_library.dart';
import '../models/lesson_note.dart';
import '../utils/app_theme.dart';
import '../widgets/basic_piano_keyboard.dart';
import '../widgets/sheet_music_view.dart';
import '../services/audio_player_service.dart';
import '../services/app_settings_store.dart';
import '../services/live_midi_note_service.dart';
import '../ui/ui_controller.dart';
import '../ui/ui_presets.dart';
import '../ui/ui_switcher.dart';
import '../utils/note_state_controller.dart';
import '../utils/qwerty_midi.dart';

enum HandFilterMode { both, right, left }
enum ScorePageView { single, spread }

class ScoreCompleteSongLessonScreen extends StatefulWidget {
  final CompleteSong song;
  const ScoreCompleteSongLessonScreen({super.key, required this.song});

  @override
  State<ScoreCompleteSongLessonScreen> createState() =>
      _ScoreCompleteSongLessonScreenState();
}

class _ScoreCompleteSongLessonScreenState
    extends State<ScoreCompleteSongLessonScreen> {
  final AudioPlayerService _audioService = AudioPlayerService();
  final Set<int> _activeNotes = {};
  final FocusNode _qwertyFocusNode = FocusNode();
  final QwertyMidiController _qwertyController = QwertyMidiController();
  bool _qwertyEnabled = true;
  late List<LessonNote> _rawNotes;
  List<LessonNote> _notes = [];
  List<ScoreNote> _scoreNotes = [];
  List<LessonNote> _filteredNotes = [];
  List<ScoreNote> _filteredScoreNotes = [];
  int _minNote = 21;
  int _maxNote = 108;
  bool _playing = false;
  bool _autoLoop = true;
  int _score = 0;
  int _misses = 0;
  DateTime? _startTime;
  int _expectedIndex = 0;
  int _guideIndex = 0;
  double _tempoBpm = 60;
  bool _pinchZoom = false;
  double _zoom = 1.0;
  double _zoomStart = 1.0;
  int _targetSpan = 24;
  bool _guideAudio = false;
  double _timingWindow = 0.25;
  bool _listenOnly = false;
  bool _metronomeEnabled = false;
  int _metronomeBpm = 80;
  bool _showControls = false;
  int _lessonTranspose = 0;
  double _staffScale = 1.0;
  bool _loopEnabled = false;
  double _loopStart = 0.0;
  double _loopEnd = 0.0;
  double _timeOffset = 0.0;
  HandFilterMode _handFilter = HandFilterMode.both;
  ScoreLayoutMode _layoutMode = ScoreLayoutMode.scroll;
  ScorePageView _pageView = ScorePageView.single;
  bool _pageFollow = true;
  int _pageIndex = 0;
  int _pageCount = 1;
  double _pageSeconds = 0.0;
  Timer? _guideTimer;
  Timer? _metronomeTimer;
  Stopwatch? _stopwatch;
  Timer? _renderTimer;
  double _currentTime = 0.0;

  Set<int> _mergedActiveNotes(Set<int> externalNotes) =>
      {..._activeNotes, ...externalNotes};

  @override
  void initState() {
    super.initState();
    _rawNotes = _buildLessonNotes(widget.song.notes);
    _tempoBpm = widget.song.bpm.toDouble();
    _applyTempo();
    _computeRange();
    _loadSettings();
    _loadVolume();
    _audioService.initialize();
    _loadPerformanceMode();
    _loadUltraMode();
    _loadQwerty();
  }

  @override
  void dispose() {
    _stopGuide();
    _stopMetronome();
    _stopRenderTicker();
    _stopwatch?.stop();
    _qwertyFocusNode.dispose();
    super.dispose();
  }

  List<LessonNote> _buildLessonNotes(List<SongNote> notes) {
    final mapped = notes
        .map((note) => LessonNote(
              midiNote: note.note,
              time: note.time,
              duration: note.duration,
            ))
        .toList();
    mapped.sort((a, b) => a.time.compareTo(b.time));
    return mapped;
  }

  Future<void> _loadSettings() async {
    final autoLoop = await AppSettingsStore.getAutoLoop();
    final guide = await AppSettingsStore.getGuideAudio();
    final timingMs = await AppSettingsStore.getTimingWindowMs();
    final listenOnly = await AppSettingsStore.getListenOnly();
    final metroEnabled = await AppSettingsStore.getMetronomeEnabled();
    final metroBpm = await AppSettingsStore.getMetronomeBpm();
    setState(() {
      _autoLoop = autoLoop;
      _guideAudio = guide;
      _timingWindow = timingMs / 1000.0;
      _listenOnly = listenOnly;
      _metronomeEnabled = metroEnabled;
      _metronomeBpm = metroBpm;
    });
    await AppSettingsStore.setLastSongId(widget.song.id);
  }

  Future<void> _loadPerformanceMode() async {
    final enabled = await AppSettingsStore.getPerformanceMode();
    _audioService.setPerformanceMode(enabled);
  }

  Future<void> _loadUltraMode() async {
    final value = await AppSettingsStore.getUltraPerformanceMode();
    _audioService.setUltraMode(ultraModeFromString(value));
  }

  Future<void> _loadQwerty() async {
    final enabled = await AppSettingsStore.getQwertyEnabled();
    setState(() => _qwertyEnabled = enabled);
    _qwertyController.enabled = enabled;
  }

  KeyEventResult _handleQwertyEvent(KeyEvent event) {
    return _qwertyController.handleEvent(
      event,
      onNoteOn: (note, velocity) {
        _noteOn(note);
      },
      onNoteOff: (note) {
        _noteOff(note);
      },
    );
  }

  Future<void> _loadVolume() async {
    final v = await AppSettingsStore.getVolume();
    _audioService.setMasterVolume(v);
  }

  void _start() {
    setState(() {
      _score = 0;
      _misses = 0;
      _playing = true;
      _expectedIndex = 0;
      _guideIndex = 0;
      _startTime = DateTime.now();
      _currentTime = _loopEnabled ? _loopStart : 0.0;
      _timeOffset = _currentTime;
    });
    _stopwatch?.stop();
    _stopwatch = Stopwatch()..start();
    _startGuideIfNeeded();
    _startMetronomeIfNeeded();
    _startRenderTicker();
  }

  void _stop() {
    setState(() => _playing = false);
    _stopwatch?.stop();
    _stopwatch = null;
    _stopGuide();
    _stopMetronome();
    _stopRenderTicker();
  }

  void _startRenderTicker() {
    _renderTimer?.cancel();
    _renderTimer = Timer.periodic(const Duration(milliseconds: 33), (_) {
      if (!_playing || _stopwatch == null) return;
      final elapsed = _stopwatch!.elapsedMilliseconds / 1000.0;
      final now = _timeOffset + elapsed;
      if (_loopEnabled && now >= _loopEnd) {
        _seekToTime(_loopStart);
        _timeOffset = _loopStart;
        _stopwatch = Stopwatch()..start();
        setState(() => _currentTime = _loopStart);
        return;
      }
      setState(() {
        _currentTime = now;
        if (_pageFollow && _layoutMode == ScoreLayoutMode.page) {
          _pageIndex =
              (now / _pageSeconds).floor().clamp(0, _pageCount - 1);
        }
      });
      if (_filteredNotes.isNotEmpty && now > _filteredNotes.last.time + 1.0) {
        _onComplete();
      }
    });
  }

  void _stopRenderTicker() {
    _renderTimer?.cancel();
    _renderTimer = null;
  }

  void _onComplete() {
    if (_autoLoop) {
      _stop();
      Future.delayed(const Duration(milliseconds: 600), _start);
    } else {
      _stop();
    }
  }

  void _noteOn(int note) {
    setState(() => _activeNotes.add(note));
    _audioService.playNote(note, 0.9);
    _evaluateHit(note);
  }

  void _noteOff(int note) {
    setState(() => _activeNotes.remove(note));
  }

  void _onMiss(int note) {
    if (_listenOnly) return;
    setState(() => _misses++);
  }

  void _evaluateHit(int note) {
    if (_listenOnly) return;
    if (!_playing || _stopwatch == null) return;
    if (_expectedIndex >= _filteredNotes.length) return;
    final elapsed = _stopwatch!.elapsedMilliseconds / 1000.0;
    final time = _timeOffset + elapsed;
    final window = _timingWindow;

    int bestIndex = -1;
    double bestDelta = 999;

    for (int i = _expectedIndex;
        i <= (_expectedIndex + 1).clamp(0, _filteredNotes.length - 1);
        i++) {
      final expected = _filteredNotes[i];
      if (note != expected.midiNote) continue;
      final delta = (time - expected.time).abs();
      if (delta <= window && delta < bestDelta) {
        bestDelta = delta;
        bestIndex = i;
      }
    }

    if (bestIndex >= 0) {
      setState(() {
        _score++;
        _expectedIndex = bestIndex + 1;
      });
    }
  }

  void _startGuideIfNeeded() {
    _guideTimer?.cancel();
    if (!(_guideAudio || _listenOnly)) return;
    _guideTimer = Timer.periodic(const Duration(milliseconds: 16), (_) {
      if (!_playing || _stopwatch == null) return;
      final elapsed = _stopwatch!.elapsedMilliseconds / 1000.0;
      final time = _timeOffset + elapsed;
      const lookAhead = 0.02;
      while (_guideIndex < _filteredNotes.length &&
          _filteredNotes[_guideIndex].time <= time + lookAhead) {
        final note = _filteredNotes[_guideIndex].midiNote;
        _audioService.playNote(note, 0.55);
        _guideIndex++;
      }
    });
  }

  void _stopGuide() {
    _guideTimer?.cancel();
    _guideTimer = null;
  }

  void _startMetronomeIfNeeded() {
    _metronomeTimer?.cancel();
    if (!_metronomeEnabled) return;
    final intervalMs = (60000 / _metronomeBpm).round().clamp(120, 1500);
    _metronomeTimer = Timer.periodic(
      Duration(milliseconds: intervalMs),
      (_) {
        if (!_playing) return;
        final tickNote = _metronomeRootNote();
        _audioService.playNote(tickNote, 0.35);
      },
    );
  }

  void _stopMetronome() {
    _metronomeTimer?.cancel();
    _metronomeTimer = null;
  }

  void _applyTempo() {
    final base = widget.song.bpm.toDouble().clamp(30, 200);
    final factor = base / _tempoBpm.clamp(30, 200);
    _notes = _rawNotes
        .map((n) => LessonNote(
              midiNote: _transposeNote(n.midiNote),
              time: n.time * factor,
              duration: n.duration * factor,
            ))
        .toList();
    _scoreNotes = widget.song.notes
        .map((n) => ScoreNote(
              midiNote: n.note,
              time: n.time * factor,
              duration: n.duration * factor,
              hand: n.hand,
              velocity: n.velocity,
            ))
        .toList();
    _applyHandFilter();
    _updatePaging();
  }

  void _applyHandFilter() {
    List<ScoreNote> filtered;
    switch (_handFilter) {
      case HandFilterMode.left:
        filtered = _scoreNotes.where((n) => n.hand == 'L').toList();
        break;
      case HandFilterMode.right:
        filtered = _scoreNotes.where((n) => n.hand == 'R').toList();
        break;
      default:
        filtered = List<ScoreNote>.from(_scoreNotes);
        break;
    }
    filtered.sort((a, b) => a.time.compareTo(b.time));
    _filteredScoreNotes = filtered;
    _filteredNotes = filtered
        .map((n) => LessonNote(
              midiNote: n.midiNote,
              time: n.time,
              duration: n.duration,
            ))
        .toList();
  }

  String _timeSignature() => widget.song.timeSignature;

  void _seekToTime(double time) {
    _expectedIndex = 0;
    while (_expectedIndex < _filteredNotes.length &&
        _filteredNotes[_expectedIndex].time < time) {
      _expectedIndex++;
    }
    _guideIndex = _expectedIndex;
  }

  void _toggleLoopBars() {
    final next = !_loopEnabled;
    setState(() => _loopEnabled = next);
    if (!next) {
      return;
    }
    final measureSeconds = _measureSeconds();
    final current = _currentTime;
    _loopStart = (current / measureSeconds).floor() * measureSeconds;
    _loopEnd = _loopStart + measureSeconds * 4;
    _seekToTime(_loopStart);
  }

  void _updatePaging() {
    _pageSeconds = _measureSeconds() * 4;
    if (_pageSeconds <= 0) {
      _pageSeconds = 4.0;
    }
    final total = _filteredNotes.isEmpty
        ? 0.0
        : _filteredNotes.last.time + _filteredNotes.last.duration;
    _pageCount = math.max(1, (total / _pageSeconds).ceil());
    if (_pageFollow) {
      _pageIndex =
          (_currentTime / _pageSeconds).floor().clamp(0, _pageCount - 1);
    } else {
      _pageIndex = _pageIndex.clamp(0, _pageCount - 1);
    }
  }

  void _prevPage() {
    setState(() {
      _pageFollow = false;
      final step =
          (_pageView == ScorePageView.spread && _layoutMode == ScoreLayoutMode.page)
              ? 2
              : 1;
      _pageIndex = (_pageIndex - step).clamp(0, _pageCount - 1);
    });
  }

  void _nextPage() {
    setState(() {
      _pageFollow = false;
      final step =
          (_pageView == ScorePageView.spread && _layoutMode == ScoreLayoutMode.page)
              ? 2
              : 1;
      _pageIndex = (_pageIndex + step).clamp(0, _pageCount - 1);
    });
  }

  void _cycleHandFilter() {
    setState(() {
      if (_handFilter == HandFilterMode.both) {
        _handFilter = HandFilterMode.right;
      } else if (_handFilter == HandFilterMode.right) {
        _handFilter = HandFilterMode.left;
      } else {
        _handFilter = HandFilterMode.both;
      }
      _applyHandFilter();
      _updatePaging();
      _computeRange();
      if (_playing) {
        _stop();
      }
    });
  }

  double _measureSeconds() {
    final parts = _timeSignature().split('/');
    final top = double.tryParse(parts[0]) ?? 4.0;
    final bottom = double.tryParse(parts[1]) ?? 4.0;
    final beat = 60.0 / _tempoBpm.clamp(30, 240);
    final unit = 4.0 / bottom;
    return beat * top * unit;
  }

  int _metronomeRootNote() {
    final key = widget.song.keySignature.trim();
    return _transposeNote(_keyToMidi(key) ?? 60);
  }

  int _transposeNote(int midiNote) => (midiNote + _lessonTranspose).clamp(0, 127);

  int? _keyToMidi(String key) {
    if (key.isEmpty) return null;
    final lower = key.toLowerCase();
    final normalized = lower
        .replaceAll('major', '')
        .replaceAll('minor', '')
        .replaceAll('maj', '')
        .replaceAll('min', '')
        .trim();
    if (normalized.isEmpty) return null;
    final map = <String, int>{
      'c': 60,
      'c#': 61,
      'db': 61,
      'd': 62,
      'd#': 63,
      'eb': 63,
      'e': 64,
      'f': 65,
      'f#': 66,
      'gb': 66,
      'g': 67,
      'g#': 68,
      'ab': 68,
      'a': 69,
      'a#': 70,
      'bb': 70,
      'b': 71,
      'cb': 71,
    };
    final cleaned = normalized
        .replaceAll('â™­', 'b')
        .replaceAll('â™¯', '#')
        .replaceAll('â€“', '')
        .replaceAll('-', '')
        .trim();
    return map[cleaned];
  }

  void _computeRange() {
    if (_filteredNotes.isEmpty) {
      _minNote = 21;
      _maxNote = 108;
      return;
    }
    var minNote = _filteredNotes.first.midiNote;
    var maxNote = _filteredNotes.first.midiNote;
    for (final note in _filteredNotes) {
      minNote = math.min(minNote, note.midiNote);
      maxNote = math.max(maxNote, note.midiNote);
    }

    final targetSpan = _targetSpan;
    var span = maxNote - minNote;
    if (span < targetSpan) {
      final extra = targetSpan - span;
      minNote -= (extra / 2).floor();
      maxNote += (extra - (extra / 2).floor());
    }

    if (minNote < 21) {
      maxNote += (21 - minNote);
      minNote = 21;
    }
    if (maxNote > 108) {
      minNote -= (maxNote - 108);
      maxNote = 108;
    }
    _minNote = minNote.clamp(21, 108);
    _maxNote = maxNote.clamp(21, 108);
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: UiController.config,
      builder: (context, config, _) {
        final style = UiPresets.styles[config.styleIndex];
        final layout = UiPresets.layouts[config.layoutIndex];
        final theme = AppTheme.fromStyle(
          background: style.background,
          surface: style.surface,
          primary: style.primary,
          secondary: style.secondary,
          text: style.text,
          accent: style.accent,
          brightness: style.brightness,
        );
        final background = layout.showGradient
            ? BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    theme.backgroundColor,
                    theme.surfaceColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              )
            : BoxDecoration(color: theme.backgroundColor);

        final content = CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            backgroundColor: theme.surfaceColor,
            middle:
                Text(widget.song.title, style: TextStyle(color: theme.textColor)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    setState(() => _autoLoop = !_autoLoop);
                    AppSettingsStore.setAutoLoop(_autoLoop);
                  },
                  child: Text(
                    _autoLoop ? 'Auto Loop' : 'Stop End',
                    style: TextStyle(color: theme.primaryColor, fontSize: 12),
                  ),
                ),
                const UiSwitcher(),
              ],
            ),
          ),
          child: Container(
            decoration: background,
            child: SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(layout.panelSpacing),
                    child: Row(
                      children: [
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          color: _playing
                              ? CupertinoColors.systemRed
                              : theme.primaryColor,
                          onPressed: _playing ? _stop : _start,
                          child: Text(_playing ? 'Stop' : 'Start'),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Score $_score  |  Misses $_misses',
                            style: TextStyle(color: theme.textColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          color: theme.surfaceColor,
                          onPressed: () {
                            final next = !_guideAudio;
                            setState(() => _guideAudio = next);
                            AppSettingsStore.setGuideAudio(next);
                            if (_playing) {
                              _startGuideIfNeeded();
                            }
                          },
                          child: Text(
                            _guideAudio ? 'Guide: ON' : 'Guide: OFF',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          color: theme.surfaceColor,
                          onPressed: () {
                            final next = !_listenOnly;
                            setState(() {
                              _listenOnly = next;
                              if (_listenOnly) {
                                _guideAudio = true;
                              }
                            });
                            AppSettingsStore.setListenOnly(next);
                            if (_listenOnly) {
                              AppSettingsStore.setGuideAudio(true);
                            }
                            if (_playing) {
                              _startGuideIfNeeded();
                            }
                          },
                          child: Text(
                            _listenOnly ? 'Listen: ON' : 'Listen: OFF',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          color: theme.surfaceColor,
                          onPressed: () => setState(() => _pinchZoom = !_pinchZoom),
                          child: Text(
                            _pinchZoom ? 'Pinch: ON' : 'Pinch: OFF',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          color: theme.surfaceColor,
                          onPressed: () => setState(() => _showControls = !_showControls),
                          child: Text(
                            _showControls ? 'Focus: ON' : 'Focus: OFF',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          color: theme.surfaceColor,
                          onPressed: _cycleHandFilter,
                          child: Text(
                            _handFilter == HandFilterMode.both
                                ? 'Hands: Both'
                                : _handFilter == HandFilterMode.right
                                    ? 'Hands: RH'
                                    : 'Hands: LH',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          color: theme.surfaceColor,
                          onPressed: () => setState(() {
                            _layoutMode = _layoutMode == ScoreLayoutMode.scroll
                                ? ScoreLayoutMode.page
                                : ScoreLayoutMode.scroll;
                            _pageFollow = true;
                            _updatePaging();
                          }),
                          child: Text(
                            _layoutMode == ScoreLayoutMode.scroll
                                ? 'Layout: Scroll'
                                : 'Layout: Page',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showControls)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.contentPadding.horizontal / 2,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Tempo',
                          style: TextStyle(color: theme.textColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CupertinoSlider(
                            value: _tempoBpm,
                            min: 30,
                            max: 200,
                            onChanged: (value) {
                              setState(() {
                                _tempoBpm = value;
                                _applyTempo();
                                _computeRange();
                                if (_loopEnabled) {
                                  final measureSeconds = _measureSeconds();
                                  _loopStart =
                                      (_currentTime / measureSeconds).floor() *
                                          measureSeconds;
                                  _loopEnd = _loopStart + measureSeconds * 4;
                                  _seekToTime(_loopStart);
                                }
                                if (_playing) {
                                  _stop();
                                }
                              });
                            },
                            activeColor: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_tempoBpm.round()} bpm',
                          style: TextStyle(
                            color: theme.textColor.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showControls && _layoutMode == ScoreLayoutMode.page)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.contentPadding.horizontal / 2,
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                color: theme.surfaceColor,
                                onPressed: _prevPage,
                                child: Text(
                                  'Prev',
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                color: theme.surfaceColor,
                                onPressed: _nextPage,
                                child: Text(
                                  'Next',
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                _pageView == ScorePageView.spread
                                    ? 'Pages ${_pageIndex + 1}–${(_pageIndex + 2).clamp(1, _pageCount)} / $_pageCount'
                                    : 'Page ${_pageIndex + 1} / $_pageCount',
                                style: TextStyle(
                                  color: theme.textColor.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                              const Spacer(),
                              CupertinoSegmentedControl<ScorePageView>(
                                groupValue: _pageView,
                                onValueChanged: (value) {
                                  setState(() {
                                    _pageView = value;
                                    _pageIndex =
                                        _pageIndex.clamp(0, _pageCount - 1);
                                  });
                                },
                                children: {
                                  ScorePageView.single: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    child: Text(
                                      'Single',
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  ScorePageView.spread: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 6),
                                    child: Text(
                                      'Spread',
                                      style: TextStyle(
                                        color: theme.textColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                },
                              ),
                              const SizedBox(width: 8),
                              CupertinoButton(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                color: theme.surfaceColor,
                                onPressed: () {
                                  setState(() => _pageFollow = !_pageFollow);
                                },
                                child: Text(
                                  _pageFollow ? 'Follow: ON' : 'Follow: OFF',
                                  style: TextStyle(
                                    color: theme.textColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                'Page',
                                style: TextStyle(
                                  color: theme.textColor.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CupertinoSlider(
                                  value: _pageIndex.toDouble(),
                                  min: 0,
                                  max: math.max(0, _pageCount - 1).toDouble(),
                                  onChanged: (value) {
                                    setState(() {
                                      _pageFollow = false;
                                      _pageIndex = value.round();
                                    });
                                  },
                                  activeColor: theme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (_showControls)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.contentPadding.horizontal / 2,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Timing',
                          style: TextStyle(color: theme.textColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CupertinoSlider(
                            value: _timingWindow,
                            min: 0.12,
                            max: 0.45,
                            onChanged: (value) {
                              setState(() => _timingWindow = value);
                              AppSettingsStore.setTimingWindowMs(value * 1000);
                            },
                            activeColor: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${(_timingWindow * 1000).round()} ms',
                          style: TextStyle(
                            color: theme.textColor.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showControls)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.contentPadding.horizontal / 2,
                      ),
                      child: Row(
                        children: [
                          CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          color: theme.surfaceColor,
                          onPressed: _toggleLoopBars,
                          child: Text(
                            _loopEnabled ? 'Loop 4: ON' : 'Loop 4: OFF',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        CupertinoButton(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          color: theme.surfaceColor,
                          onPressed: () {
                            final next = !_metronomeEnabled;
                            setState(() => _metronomeEnabled = next);
                            AppSettingsStore.setMetronomeEnabled(next);
                            if (_playing) {
                              _startMetronomeIfNeeded();
                            } else {
                              _stopMetronome();
                            }
                          },
                          child: Text(
                            _metronomeEnabled ? 'Metro: ON' : 'Metro: OFF',
                            style: TextStyle(
                              color: theme.textColor,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'BPM',
                          style: TextStyle(color: theme.textColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CupertinoSlider(
                            value: _metronomeBpm.toDouble(),
                            min: 40,
                            max: 200,
                            onChanged: (value) {
                              final next = value.round();
                              setState(() => _metronomeBpm = next);
                              AppSettingsStore.setMetronomeBpm(next);
                              if (_playing && _metronomeEnabled) {
                                _startMetronomeIfNeeded();
                              }
                            },
                            activeColor: theme.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_metronomeBpm',
                          style: TextStyle(
                            color: theme.textColor.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_showControls)
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: layout.contentPadding.horizontal / 2,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Staff',
                            style: TextStyle(color: theme.textColor),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CupertinoSlider(
                              value: _staffScale,
                              min: 0.7,
                              max: 1.4,
                              onChanged: (value) {
                                setState(() => _staffScale = value);
                              },
                              activeColor: theme.primaryColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${_staffScale.toStringAsFixed(2)}x',
                            style: TextStyle(
                              color: theme.textColor.withOpacity(0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_showControls)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: layout.contentPadding.horizontal / 2,
                ),
                child: Row(
                  children: [
                    Text(
                      'Transpose',
                      style: TextStyle(color: theme.textColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CupertinoSlider(
                        value: _lessonTranspose.toDouble(),
                        min: -12,
                        max: 12,
                        divisions: 24,
                        onChanged: (value) {
                          setState(() {
                            _lessonTranspose = value.round();
                            _applyTempo();
                            _computeRange();
                            if (_playing) {
                              _stop();
                            }
                          });
                        },
                        activeColor: theme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _lessonTranspose == 0
                          ? '0 st'
                          : (_lessonTranspose > 0 ? '+${_lessonTranspose} st' : '${_lessonTranspose} st'),
                      style: TextStyle(
                        color: theme.textColor.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onScaleStart: (details) {
                        if (!_pinchZoom) return;
                        _zoomStart = _zoom;
                      },
                      onScaleUpdate: (details) {
                        if (!_pinchZoom) return;
                        final next = (_zoomStart * details.scale)
                            .clamp(0.7, 2.0)
                            .toDouble();
                        final newSpan = (24 / next).round().clamp(12, 48);
                        setState(() {
                          _zoom = next;
                          _targetSpan = newSpan;
                          _computeRange();
                          if (_playing) {
                            _stop();
                          }
                        });
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.symmetric(
                                horizontal:
                                    layout.contentPadding.horizontal / 2,
                              ),
                              decoration: BoxDecoration(
                                color: theme.surfaceColor.withOpacity(0.5),
                                borderRadius:
                                    BorderRadius.circular(layout.cardRadius),
                              ),
                              child: ValueListenableBuilder<NoteState>(
                                valueListenable: LiveMidiNoteService.instance.notifier,
                                builder: (context, noteState, _) {
                                  final activeNotes =
                                      _mergedActiveNotes(noteState.activeNotes);
                                  return LayoutBuilder(
                                    builder: (context, constraints) {
                                      final showSpread = _layoutMode ==
                                              ScoreLayoutMode.page &&
                                          _pageView == ScorePageView.spread &&
                                          constraints.maxWidth >= 900;
                                      if (showSpread) {
                                        final rightIndex = (_pageIndex + 1)
                                            .clamp(0, _pageCount - 1);
                                        return Row(
                                          children: [
                                            Expanded(
                                              child: SheetMusicView(
                                                notes: _filteredScoreNotes,
                                                activeNotes: activeNotes,
                                                currentTime: _currentTime,
                                                bpm: _tempoBpm,
                                                windowSeconds: 8.0 / _zoom,
                                                keySignature:
                                                    widget.song.keySignature,
                                                timeSignature: _timeSignature(),
                                                layoutMode: _layoutMode,
                                                pageIndex: _pageIndex,
                                                pageSeconds: _pageSeconds,
                                                showMeasureNumbers: true,
                                                showSectionMarkers: true,
                                                sectionEveryMeasures: 8,
                                                backgroundColor: theme.surfaceColor
                                                    .withOpacity(0.12),
                                                staffColor: theme.textColor
                                                    .withOpacity(0.5),
                                                noteColor: theme.textColor,
                                                activeColor: theme.primaryColor,
                                                playheadColor: theme.accentColor,
                                                staffScale: _staffScale,
                                              ),
                                            ),
                                            Expanded(
                                              child: SheetMusicView(
                                                notes: _filteredScoreNotes,
                                                activeNotes: activeNotes,
                                                currentTime: _currentTime,
                                                bpm: _tempoBpm,
                                                windowSeconds: 8.0 / _zoom,
                                                keySignature:
                                                    widget.song.keySignature,
                                                timeSignature: _timeSignature(),
                                                layoutMode: _layoutMode,
                                                pageIndex: rightIndex,
                                                pageSeconds: _pageSeconds,
                                                showMeasureNumbers: true,
                                                showSectionMarkers: true,
                                                sectionEveryMeasures: 8,
                                                backgroundColor: theme.surfaceColor
                                                    .withOpacity(0.12),
                                                staffColor: theme.textColor
                                                    .withOpacity(0.5),
                                                noteColor: theme.textColor,
                                                activeColor: theme.primaryColor,
                                                playheadColor: theme.accentColor,
                                                staffScale: _staffScale,
                                              ),
                                            ),
                                          ],
                                        );
                                      }
                                      return SheetMusicView(
                                        notes: _filteredScoreNotes,
                                        activeNotes: activeNotes,
                                        currentTime: _currentTime,
                                        bpm: _tempoBpm,
                                        windowSeconds: 8.0 / _zoom,
                                        keySignature: widget.song.keySignature,
                                        timeSignature: _timeSignature(),
                                        layoutMode: _layoutMode,
                                        pageIndex: _layoutMode ==
                                                ScoreLayoutMode.page
                                            ? _pageIndex
                                            : null,
                                        pageSeconds: _pageSeconds,
                                        showMeasureNumbers: true,
                                        showSectionMarkers: true,
                                        sectionEveryMeasures: 8,
                                        backgroundColor:
                                            theme.surfaceColor.withOpacity(0.12),
                                        staffColor:
                                            theme.textColor.withOpacity(0.5),
                                        noteColor: theme.textColor,
                                        activeColor: theme.primaryColor,
                                        playheadColor: theme.accentColor,
                                        staffScale: _staffScale,
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ),
                          SizedBox(
                            height: layout.keyboardHeight,
                            child: ValueListenableBuilder<NoteState>(
                              valueListenable: LiveMidiNoteService.instance.notifier,
                              builder: (context, noteState, _) {
                                final activeNotes =
                                    _mergedActiveNotes(noteState.activeNotes);
                                return BasicPianoKeyboard(
                                  minNote: _minNote,
                                  maxNote: _maxNote,
                                  fitToWidth: true,
                                  activeNotes: activeNotes,
                                  showNoteLabels: true,
                                  onNoteOn: _noteOn,
                                  onNoteOff: _noteOff,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return Focus(
          autofocus: true,
          focusNode: _qwertyFocusNode,
          onKeyEvent: (node, event) {
            if (!_qwertyEnabled) return KeyEventResult.ignored;
            return _handleQwertyEvent(event);
          },
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _qwertyFocusNode.requestFocus(),
            child: content,
          ),
        );
      },
    );
  }
}
