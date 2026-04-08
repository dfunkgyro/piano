import 'dart:math' as math;

import 'package:flutter/cupertino.dart';

import 'sheet_music_view.dart';

enum PlayVisualizationMode { classic, notation, tablature, both }
enum PlayTempoMode { adaptive, fixed }
enum PlayPanelStyle { studio, minimal, contrast }
enum PlayPanelLayout { standard, stacked, compact }
enum PlayScoreColorTheme { classic, aurora, ember, neon, ivory, ocean }

PlayVisualizationMode playVisualizationModeFromString(String value) {
  switch (value) {
    case 'classic':
      return PlayVisualizationMode.classic;
    case 'notation':
      return PlayVisualizationMode.notation;
    case 'tablature':
      return PlayVisualizationMode.tablature;
    default:
      return PlayVisualizationMode.both;
  }
}

String playVisualizationModeToString(PlayVisualizationMode mode) {
  switch (mode) {
    case PlayVisualizationMode.classic:
      return 'classic';
    case PlayVisualizationMode.notation:
      return 'notation';
    case PlayVisualizationMode.tablature:
      return 'tablature';
    case PlayVisualizationMode.both:
      return 'both';
  }
}

PlayTempoMode playTempoModeFromString(String value) {
  switch (value) {
    case 'fixed':
      return PlayTempoMode.fixed;
    default:
      return PlayTempoMode.adaptive;
  }
}

String playTempoModeToString(PlayTempoMode mode) {
  switch (mode) {
    case PlayTempoMode.adaptive:
      return 'adaptive';
    case PlayTempoMode.fixed:
      return 'fixed';
  }
}

PlayPanelStyle playPanelStyleFromString(String value) {
  switch (value) {
    case 'minimal':
      return PlayPanelStyle.minimal;
    case 'contrast':
      return PlayPanelStyle.contrast;
    default:
      return PlayPanelStyle.studio;
  }
}

String playPanelStyleToString(PlayPanelStyle style) {
  switch (style) {
    case PlayPanelStyle.studio:
      return 'studio';
    case PlayPanelStyle.minimal:
      return 'minimal';
    case PlayPanelStyle.contrast:
      return 'contrast';
  }
}

PlayPanelLayout playPanelLayoutFromString(String value) {
  switch (value) {
    case 'stacked':
      return PlayPanelLayout.stacked;
    case 'compact':
      return PlayPanelLayout.compact;
    default:
      return PlayPanelLayout.standard;
  }
}

String playPanelLayoutToString(PlayPanelLayout layout) {
  switch (layout) {
    case PlayPanelLayout.standard:
      return 'standard';
    case PlayPanelLayout.stacked:
      return 'stacked';
    case PlayPanelLayout.compact:
      return 'compact';
  }
}

PlayScoreColorTheme playScoreColorThemeFromString(String value) {
  switch (value) {
    case 'aurora':
      return PlayScoreColorTheme.aurora;
    case 'ember':
      return PlayScoreColorTheme.ember;
    case 'neon':
      return PlayScoreColorTheme.neon;
    case 'ivory':
      return PlayScoreColorTheme.ivory;
    case 'ocean':
      return PlayScoreColorTheme.ocean;
    default:
      return PlayScoreColorTheme.classic;
  }
}

String playScoreColorThemeToString(PlayScoreColorTheme theme) {
  switch (theme) {
    case PlayScoreColorTheme.classic:
      return 'classic';
    case PlayScoreColorTheme.aurora:
      return 'aurora';
    case PlayScoreColorTheme.ember:
      return 'ember';
    case PlayScoreColorTheme.neon:
      return 'neon';
    case PlayScoreColorTheme.ivory:
      return 'ivory';
    case PlayScoreColorTheme.ocean:
      return 'ocean';
  }
}

class LivePlayVisualization extends StatelessWidget {
  final List<ScoreNote> notes;
  final Set<int> activeNotes;
  final double currentTime;
  final String timeSignature;
  final String keySignature;
  final Color backgroundColor;
  final Color panelColor;
  final Color textColor;
  final Color accentColor;
  final PlayVisualizationMode mode;
  final bool sustainPedalDown;
  final PlayTempoMode tempoMode;
  final int manualBpm;
  final bool autoDetectKeySignature;
  final String manualKeySignature;
  final bool autoDetectTimeSignature;
  final String manualTimeSignature;
  final PlayPanelStyle panelStyle;
  final PlayPanelLayout panelLayout;
  final PlayScoreColorTheme scoreColorTheme;
  final bool focusMode;
  final double panelHeightFactor;
  final int manualMidiTranspose;
  final int deviceMidiTranspose;
  final int effectiveMidiTranspose;
  final String activeMidiDeviceName;
  final bool midiCalibrationArmed;
  final ValueChanged<PlayTempoMode> onTempoModeChanged;
  final ValueChanged<int> onManualBpmChanged;
  final ValueChanged<bool> onAutoDetectKeyChanged;
  final ValueChanged<String> onManualKeySignatureChanged;
  final ValueChanged<bool> onAutoDetectTimeSignatureChanged;
  final ValueChanged<String> onManualTimeSignatureChanged;
  final ValueChanged<PlayPanelStyle> onPanelStyleChanged;
  final ValueChanged<PlayPanelLayout> onPanelLayoutChanged;
  final ValueChanged<PlayScoreColorTheme> onScoreColorThemeChanged;
  final ValueChanged<bool> onFocusModeChanged;
  final ValueChanged<double> onPanelHeightChanged;
  final ValueChanged<int> onManualMidiTransposeChanged;
  final VoidCallback onArmMidiCalibration;
  final VoidCallback onResetMidiDeviceAlignment;

  const LivePlayVisualization({
    super.key,
    required this.notes,
    required this.activeNotes,
    required this.currentTime,
    required this.timeSignature,
    required this.keySignature,
    required this.backgroundColor,
    required this.panelColor,
    required this.textColor,
    required this.accentColor,
    required this.mode,
    this.sustainPedalDown = false,
    required this.tempoMode,
    required this.manualBpm,
    required this.autoDetectKeySignature,
    required this.manualKeySignature,
    required this.autoDetectTimeSignature,
    required this.manualTimeSignature,
    required this.panelStyle,
    required this.panelLayout,
    required this.scoreColorTheme,
    required this.focusMode,
    required this.panelHeightFactor,
    required this.manualMidiTranspose,
    required this.deviceMidiTranspose,
    required this.effectiveMidiTranspose,
    required this.activeMidiDeviceName,
    required this.midiCalibrationArmed,
    required this.onTempoModeChanged,
    required this.onManualBpmChanged,
    required this.onAutoDetectKeyChanged,
    required this.onManualKeySignatureChanged,
    required this.onAutoDetectTimeSignatureChanged,
    required this.onManualTimeSignatureChanged,
    required this.onPanelStyleChanged,
    required this.onPanelLayoutChanged,
    required this.onScoreColorThemeChanged,
    required this.onFocusModeChanged,
    required this.onPanelHeightChanged,
    required this.onManualMidiTransposeChanged,
    required this.onArmMidiCalibration,
    required this.onResetMidiDeviceAlignment,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == PlayVisualizationMode.classic) {
      return const SizedBox.shrink();
    }

    final analysis = _LivePerformanceAnalyzer.analyze(
      notes: notes,
      fallbackKeySignature: keySignature,
      fallbackTimeSignature: timeSignature,
      currentTime: currentTime,
      tempoMode: tempoMode,
      fixedBpm: manualBpm,
      autoDetectKeySignature: autoDetectKeySignature,
      manualKeySignature: manualKeySignature,
      autoDetectTimeSignature: autoDetectTimeSignature,
      manualTimeSignature: manualTimeSignature,
    );
    final showNotation = mode == PlayVisualizationMode.notation ||
        mode == PlayVisualizationMode.both;
    final showTab =
        mode == PlayVisualizationMode.tablature || mode == PlayVisualizationMode.both;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 760;
        final styled = _panelStyleData(
          panelStyle,
          panelColor: panelColor,
          backgroundColor: backgroundColor,
          textColor: textColor,
          accentColor: accentColor,
        );
        final scoreColors = _scoreThemeData(
          scoreColorTheme,
          backgroundColor: styled.scoreBackground,
          textColor: styled.primaryText,
          accentColor: styled.accentText,
        );
        final effectiveCompact = compact || panelLayout == PlayPanelLayout.compact;
        final baseNotationHeight = effectiveCompact
            ? (showTab ? 108.0 : 126.0)
            : (showTab ? 208.0 : 236.0);
        final notationHeight = baseNotationHeight * panelHeightFactor;
        final showControls = !focusMode;
        final showSummary = !focusMode && !effectiveCompact;
        final showTabSection =
            showTab && (!focusMode || panelLayout == PlayPanelLayout.stacked);
        final titleSize = effectiveCompact ? 13.0 : 15.0;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOutCubic,
          margin: EdgeInsets.fromLTRB(
            effectiveCompact ? 8 : 12,
            0,
            effectiveCompact ? 8 : 12,
            effectiveCompact ? 4 : 12,
          ),
          padding: EdgeInsets.all(effectiveCompact ? 6 : 12),
          decoration: BoxDecoration(
            color: styled.panelFill,
            borderRadius: BorderRadius.circular(effectiveCompact ? 14 : 18),
            border: Border.all(color: styled.borderColor),
            boxShadow: styled.shadows,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius:
                          BorderRadius.circular(effectiveCompact ? 14 : 18),
                      gradient: LinearGradient(
                        colors: [
                          styled.accentText.withOpacity(0.08),
                          styled.panelFill.withOpacity(0.0),
                          styled.accentText.withOpacity(0.04),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedOpacity(
                duration: const Duration(milliseconds: 260),
                opacity: focusMode ? 0.92 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Live Performance Score',
                          style: TextStyle(
                            color: styled.primaryText,
                            fontSize: titleSize,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        SizedBox(height: effectiveCompact ? 1 : 2),
                        Text(
                          '${analysis.keySignature}  |  ${analysis.timeSignature}  |  ${analysis.displayBpm} BPM',
                          style: TextStyle(
                            color: styled.secondaryText,
                            fontSize: effectiveCompact ? 10 : 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (sustainPedalDown)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: effectiveCompact ? 8 : 10,
                        vertical: effectiveCompact ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: styled.accentFill,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: styled.accentBorder),
                      ),
                      child: Text(
                        'Sustain',
                        style: TextStyle(
                          color: styled.accentText,
                          fontSize: effectiveCompact ? 10 : 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: effectiveCompact ? 6 : 10),
              if (showNotation)
                SizedBox(
                  height: notationHeight,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(effectiveCompact ? 10 : 14),
                    child: SheetMusicView(
                      notes: analysis.quantizedNotes,
                      activeNotes: activeNotes,
                      currentTime: analysis.quantizedCurrentTime,
                      bpm: analysis.bpm.toDouble(),
                      windowSeconds: panelLayout == PlayPanelLayout.stacked
                          ? 8
                          : effectiveCompact
                              ? 9
                              : 10,
                      playheadFraction: panelLayout == PlayPanelLayout.stacked
                          ? 0.88
                          : effectiveCompact
                              ? 0.86
                              : 0.82,
                      futureWindowFraction: panelLayout == PlayPanelLayout.stacked
                          ? 0.12
                          : effectiveCompact
                              ? 0.14
                              : 0.18,
                      keySignature: analysis.keySignature,
                      timeSignature: analysis.timeSignature,
                      backgroundColor: scoreColors.scoreBackground,
                      staffColor: scoreColors.staffColor,
                      noteColor: scoreColors.noteColor,
                      activeColor: scoreColors.activeColor,
                      playheadColor: scoreColors.playheadColor,
                      showMeasureNumbers: !effectiveCompact,
                      showSectionMarkers: false,
                    ),
                  ),
                ),
              if (showNotation && showTabSection)
                SizedBox(height: effectiveCompact ? 6 : 10),
              if (showTabSection)
                _LiveTablatureStrip(
                  clusters: analysis.clusters,
                  activeNotes: activeNotes,
                  textColor: styled.primaryText,
                  accentColor: styled.accentText,
                  panelColor: styled.chromeFill,
                  compact: effectiveCompact,
                ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PanelStyleData {
  final Color panelFill;
  final Color chromeFill;
  final Color scoreBackground;
  final Color primaryText;
  final Color secondaryText;
  final Color accentText;
  final Color accentFill;
  final Color accentBorder;
  final Color borderColor;
  final List<BoxShadow> shadows;

  const _PanelStyleData({
    required this.panelFill,
    required this.chromeFill,
    required this.scoreBackground,
    required this.primaryText,
    required this.secondaryText,
    required this.accentText,
    required this.accentFill,
    required this.accentBorder,
    required this.borderColor,
    required this.shadows,
  });
}

class _ScoreThemeData {
  final Color scoreBackground;
  final Color staffColor;
  final Color noteColor;
  final Color activeColor;
  final Color playheadColor;

  const _ScoreThemeData({
    required this.scoreBackground,
    required this.staffColor,
    required this.noteColor,
    required this.activeColor,
    required this.playheadColor,
  });
}

_PanelStyleData _panelStyleData(
  PlayPanelStyle style, {
  required Color panelColor,
  required Color backgroundColor,
  required Color textColor,
  required Color accentColor,
}) {
  switch (style) {
    case PlayPanelStyle.minimal:
      return _PanelStyleData(
        panelFill: panelColor.withOpacity(0.58),
        chromeFill: panelColor.withOpacity(0.34),
        scoreBackground: backgroundColor.withOpacity(0.98),
        primaryText: textColor,
        secondaryText: textColor.withOpacity(0.62),
        accentText: accentColor,
        accentFill: accentColor.withOpacity(0.12),
        accentBorder: accentColor.withOpacity(0.34),
        borderColor: textColor.withOpacity(0.08),
        shadows: const [],
      );
    case PlayPanelStyle.contrast:
      return _PanelStyleData(
        panelFill: CupertinoColors.black.withOpacity(0.86),
        chromeFill: CupertinoColors.white.withOpacity(0.08),
        scoreBackground: CupertinoColors.black,
        primaryText: CupertinoColors.white,
        secondaryText: CupertinoColors.systemGrey2,
        accentText: accentColor,
        accentFill: accentColor.withOpacity(0.18),
        accentBorder: accentColor.withOpacity(0.5),
        borderColor: CupertinoColors.white.withOpacity(0.14),
        shadows: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.28),
            blurRadius: 28,
            offset: const Offset(0, 14),
          ),
        ],
      );
    case PlayPanelStyle.studio:
      return _PanelStyleData(
        panelFill: panelColor.withOpacity(0.78),
        chromeFill: panelColor.withOpacity(0.45),
        scoreBackground: backgroundColor,
        primaryText: textColor,
        secondaryText: textColor.withOpacity(0.68),
        accentText: accentColor,
        accentFill: accentColor.withOpacity(0.2),
        accentBorder: accentColor.withOpacity(0.45),
        borderColor: textColor.withOpacity(0.12),
        shadows: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.14),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      );
  }
}

_ScoreThemeData _scoreThemeData(
  PlayScoreColorTheme theme, {
  required Color backgroundColor,
  required Color textColor,
  required Color accentColor,
}) {
  switch (theme) {
    case PlayScoreColorTheme.aurora:
      return _ScoreThemeData(
        scoreBackground: const Color(0xFF08141D),
        staffColor: const Color(0xFFD8F6FF),
        noteColor: const Color(0xFF9DE7FF),
        activeColor: const Color(0xFF67FFC8),
        playheadColor: const Color(0xFFFFE066),
      );
    case PlayScoreColorTheme.ember:
      return _ScoreThemeData(
        scoreBackground: const Color(0xFF1A0F10),
        staffColor: const Color(0xFFFFE7D6),
        noteColor: const Color(0xFFFFB38A),
        activeColor: const Color(0xFFFFD166),
        playheadColor: const Color(0xFFFF6B6B),
      );
    case PlayScoreColorTheme.neon:
      return _ScoreThemeData(
        scoreBackground: const Color(0xFF0A0A16),
        staffColor: const Color(0xFFC4CCFF),
        noteColor: const Color(0xFF8CFFED),
        activeColor: const Color(0xFFFF59D6),
        playheadColor: const Color(0xFF6AF7FF),
      );
    case PlayScoreColorTheme.ivory:
      return _ScoreThemeData(
        scoreBackground: const Color(0xFFFFFBF2),
        staffColor: const Color(0xFF40362D),
        noteColor: const Color(0xFF5E4B3C),
        activeColor: const Color(0xFFC8863D),
        playheadColor: const Color(0xFF8F5C2C),
      );
    case PlayScoreColorTheme.ocean:
      return _ScoreThemeData(
        scoreBackground: const Color(0xFF071B25),
        staffColor: const Color(0xFFB9E9FF),
        noteColor: const Color(0xFF7FD1FF),
        activeColor: const Color(0xFF7BFFB2),
        playheadColor: const Color(0xFFFFD36E),
      );
    case PlayScoreColorTheme.classic:
      return _ScoreThemeData(
        scoreBackground: backgroundColor,
        staffColor: textColor,
        noteColor: textColor,
        activeColor: accentColor,
        playheadColor: accentColor.withOpacity(0.85),
      );
  }
}

class _PanelViewControls extends StatelessWidget {
  final bool compact;
  final Color textColor;
  final Color secondaryTextColor;
  final Color panelColor;
  final Color accentColor;
  final PlayPanelStyle panelStyle;
  final PlayPanelLayout panelLayout;
  final PlayScoreColorTheme scoreColorTheme;
  final bool focusMode;
  final double panelHeightFactor;
  final int manualMidiTranspose;
  final int deviceMidiTranspose;
  final int effectiveMidiTranspose;
  final String activeMidiDeviceName;
  final bool midiCalibrationArmed;
  final ValueChanged<PlayPanelStyle> onPanelStyleChanged;
  final ValueChanged<PlayPanelLayout> onPanelLayoutChanged;
  final ValueChanged<PlayScoreColorTheme> onScoreColorThemeChanged;
  final ValueChanged<bool> onFocusModeChanged;
  final ValueChanged<double> onPanelHeightChanged;
  final ValueChanged<int> onManualMidiTransposeChanged;
  final VoidCallback onArmMidiCalibration;
  final VoidCallback onResetMidiDeviceAlignment;

  const _PanelViewControls({
    required this.compact,
    required this.textColor,
    required this.secondaryTextColor,
    required this.panelColor,
    required this.accentColor,
    required this.panelStyle,
    required this.panelLayout,
    required this.scoreColorTheme,
    required this.focusMode,
    required this.panelHeightFactor,
    required this.manualMidiTranspose,
    required this.deviceMidiTranspose,
    required this.effectiveMidiTranspose,
    required this.activeMidiDeviceName,
    required this.midiCalibrationArmed,
    required this.onPanelStyleChanged,
    required this.onPanelLayoutChanged,
    required this.onScoreColorThemeChanged,
    required this.onFocusModeChanged,
    required this.onPanelHeightChanged,
    required this.onManualMidiTransposeChanged,
    required this.onArmMidiCalibration,
    required this.onResetMidiDeviceAlignment,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: [
          _viewControlChip(
            label: focusMode ? 'Focus ON' : 'Focus OFF',
            child: CupertinoSwitch(
              value: focusMode,
              activeColor: accentColor,
              onChanged: onFocusModeChanged,
            ),
          ),
          _viewControlChip(
            label: 'Style',
            width: compact ? 212 : 236,
            child: _miniSegmentedControl<PlayPanelStyle>(
              groupValue: panelStyle,
              onChanged: onPanelStyleChanged,
              children: const {
                PlayPanelStyle.studio: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text('Studio'),
                ),
                PlayPanelStyle.minimal: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text('Minimal'),
                ),
                PlayPanelStyle.contrast: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text('Contrast'),
                ),
              },
            ),
          ),
          _viewControlChip(
            label: 'Layout',
            width: compact ? 198 : 222,
            child: _miniSegmentedControl<PlayPanelLayout>(
              groupValue: panelLayout,
              onChanged: onPanelLayoutChanged,
              children: const {
                PlayPanelLayout.standard: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text('Std'),
                ),
                PlayPanelLayout.stacked: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text('Stack'),
                ),
                PlayPanelLayout.compact: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  child: Text('Mini'),
                ),
              },
            ),
          ),
          _viewControlChip(
            label: 'Score Color',
            width: compact ? 286 : 320,
            child: _miniSegmentedControl<PlayScoreColorTheme>(
              groupValue: scoreColorTheme,
              onChanged: onScoreColorThemeChanged,
              children: const {
                PlayScoreColorTheme.classic: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: Text('Classic'),
                ),
                PlayScoreColorTheme.aurora: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: Text('Aurora'),
                ),
                PlayScoreColorTheme.ember: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: Text('Ember'),
                ),
                PlayScoreColorTheme.neon: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: Text('Neon'),
                ),
                PlayScoreColorTheme.ivory: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: Text('Ivory'),
                ),
                PlayScoreColorTheme.ocean: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: Text('Ocean'),
                ),
              },
            ),
          ),
          _viewControlChip(
            label: 'Height ${panelHeightFactor.toStringAsFixed(2)}x',
            width: compact ? 176 : 196,
            child: CupertinoSlider(
              value: panelHeightFactor,
              min: 0.75,
              max: 1.6,
              divisions: 17,
              activeColor: accentColor,
              onChanged: onPanelHeightChanged,
            ),
          ),
          _viewControlChip(
            label: 'Transpose ${effectiveMidiTranspose >= 0 ? "+" : ""}$effectiveMidiTranspose',
            width: compact ? 286 : 340,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  activeMidiDeviceName.isEmpty
                      ? 'No external device active'
                      : '$activeMidiDeviceName  dev ${deviceMidiTranspose >= 0 ? "+" : ""}$deviceMidiTranspose  man ${manualMidiTranspose >= 0 ? "+" : ""}$manualMidiTranspose',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: compact ? 10 : 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: compact ? 4 : 6),
                CupertinoSlider(
                  value: manualMidiTranspose.toDouble(),
                  min: -12,
                  max: 12,
                  divisions: 24,
                  activeColor: accentColor,
                  onChanged: (value) =>
                      onManualMidiTransposeChanged(value.round()),
                ),
                Text(
                  midiCalibrationArmed
                      ? 'Calibration armed in Settings: play C on the external keyboard.'
                      : 'Use as transpose. Device correction is applied automatically when available.',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: compact ? 10 : 11,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _viewControlChip({
    required String label,
    required Widget child,
    double? width,
  }) {
    return Container(
      width: width,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 6 : 8,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            panelColor.withOpacity(0.62),
            panelColor.withOpacity(0.36),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 14),
        border: Border.all(color: accentColor.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.08),
            blurRadius: 18,
            spreadRadius: -10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: secondaryTextColor,
              fontSize: compact ? 9 : 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          child,
        ],
      ),
    );
  }

  Widget _miniSegmentedControl<T extends Object>({
    required T groupValue,
    required ValueChanged<T> onChanged,
    required Map<T, Widget> children,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: CupertinoSlidingSegmentedControl<T>(
          backgroundColor: panelColor.withOpacity(0.72),
          thumbColor: accentColor.withOpacity(0.88),
          groupValue: groupValue,
          onValueChanged: (value) {
            if (value != null) onChanged(value);
          },
          children: children,
        ),
      ),
    );
  }
}

class LivePlayAdjustmentPanel extends StatefulWidget {
  final Color textColor;
  final Color panelColor;
  final Color accentColor;
  final PlayTempoMode tempoMode;
  final int manualBpm;
  final bool autoDetectKeySignature;
  final String manualKeySignature;
  final bool autoDetectTimeSignature;
  final String manualTimeSignature;
  final PlayPanelStyle panelStyle;
  final PlayPanelLayout panelLayout;
  final PlayScoreColorTheme scoreColorTheme;
  final bool focusMode;
  final double panelHeightFactor;
  final int manualMidiTranspose;
  final int deviceMidiTranspose;
  final int effectiveMidiTranspose;
  final String activeMidiDeviceName;
  final bool midiCalibrationArmed;
  final ValueChanged<PlayTempoMode> onTempoModeChanged;
  final ValueChanged<int> onManualBpmChanged;
  final ValueChanged<bool> onAutoDetectKeyChanged;
  final ValueChanged<String> onManualKeySignatureChanged;
  final ValueChanged<bool> onAutoDetectTimeSignatureChanged;
  final ValueChanged<String> onManualTimeSignatureChanged;
  final ValueChanged<PlayPanelStyle> onPanelStyleChanged;
  final ValueChanged<PlayPanelLayout> onPanelLayoutChanged;
  final ValueChanged<PlayScoreColorTheme> onScoreColorThemeChanged;
  final ValueChanged<bool> onFocusModeChanged;
  final ValueChanged<double> onPanelHeightChanged;
  final ValueChanged<int> onManualMidiTransposeChanged;
  final VoidCallback onArmMidiCalibration;
  final VoidCallback onResetMidiDeviceAlignment;

  const LivePlayAdjustmentPanel({
    super.key,
    required this.textColor,
    required this.panelColor,
    required this.accentColor,
    required this.tempoMode,
    required this.manualBpm,
    required this.autoDetectKeySignature,
    required this.manualKeySignature,
    required this.autoDetectTimeSignature,
    required this.manualTimeSignature,
    required this.panelStyle,
    required this.panelLayout,
    required this.scoreColorTheme,
    required this.focusMode,
    required this.panelHeightFactor,
    required this.manualMidiTranspose,
    required this.deviceMidiTranspose,
    required this.effectiveMidiTranspose,
    required this.activeMidiDeviceName,
    required this.midiCalibrationArmed,
    required this.onTempoModeChanged,
    required this.onManualBpmChanged,
    required this.onAutoDetectKeyChanged,
    required this.onManualKeySignatureChanged,
    required this.onAutoDetectTimeSignatureChanged,
    required this.onManualTimeSignatureChanged,
    required this.onPanelStyleChanged,
    required this.onPanelLayoutChanged,
    required this.onScoreColorThemeChanged,
    required this.onFocusModeChanged,
    required this.onPanelHeightChanged,
    required this.onManualMidiTransposeChanged,
    required this.onArmMidiCalibration,
    required this.onResetMidiDeviceAlignment,
  });

  @override
  State<LivePlayAdjustmentPanel> createState() =>
      _LivePlayAdjustmentPanelState();
}

class _LivePlayAdjustmentPanelState extends State<LivePlayAdjustmentPanel> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.of(context).size.width < 760;
    final secondaryTextColor = widget.textColor.withOpacity(0.68);

    return Container(
      margin: EdgeInsets.fromLTRB(
        compact ? 8 : 12,
        0,
        compact ? 8 : 12,
        compact ? 4 : 12,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            minSize: 0,
            onPressed: () => setState(() => _isOpen = !_isOpen),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 10 : 12,
                vertical: compact ? 8 : 10,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    widget.panelColor.withOpacity(0.62),
                    widget.panelColor.withOpacity(0.36),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: widget.accentColor.withOpacity(0.18)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isOpen
                        ? CupertinoIcons.chevron_down
                        : CupertinoIcons.slider_horizontal_3,
                    size: compact ? 14 : 16,
                    color: widget.accentColor,
                  ),
                  SizedBox(width: compact ? 6 : 8),
                  Text(
                    'Adjustment',
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isOpen) ...[
            SizedBox(height: compact ? 6 : 10),
            _PanelViewControls(
              compact: compact,
              textColor: widget.textColor,
              secondaryTextColor: secondaryTextColor,
              panelColor: widget.panelColor,
              accentColor: widget.accentColor,
              panelStyle: widget.panelStyle,
              panelLayout: widget.panelLayout,
              scoreColorTheme: widget.scoreColorTheme,
              focusMode: widget.focusMode,
              panelHeightFactor: widget.panelHeightFactor,
              manualMidiTranspose: widget.manualMidiTranspose,
              deviceMidiTranspose: widget.deviceMidiTranspose,
              effectiveMidiTranspose: widget.effectiveMidiTranspose,
              activeMidiDeviceName: widget.activeMidiDeviceName,
              midiCalibrationArmed: widget.midiCalibrationArmed,
              onPanelStyleChanged: widget.onPanelStyleChanged,
              onPanelLayoutChanged: widget.onPanelLayoutChanged,
              onScoreColorThemeChanged: widget.onScoreColorThemeChanged,
              onFocusModeChanged: widget.onFocusModeChanged,
              onPanelHeightChanged: widget.onPanelHeightChanged,
              onManualMidiTransposeChanged:
                  widget.onManualMidiTransposeChanged,
              onArmMidiCalibration: widget.onArmMidiCalibration,
              onResetMidiDeviceAlignment: widget.onResetMidiDeviceAlignment,
            ),
            SizedBox(height: compact ? 6 : 10),
            _PerformanceControls(
              textColor: widget.textColor,
              panelColor: widget.panelColor,
              accentColor: widget.accentColor,
              tempoMode: widget.tempoMode,
              manualBpm: widget.manualBpm,
              autoDetectKeySignature: widget.autoDetectKeySignature,
              manualKeySignature: widget.manualKeySignature,
              autoDetectTimeSignature: widget.autoDetectTimeSignature,
              manualTimeSignature: widget.manualTimeSignature,
              onTempoModeChanged: widget.onTempoModeChanged,
              onManualBpmChanged: widget.onManualBpmChanged,
              onAutoDetectKeyChanged: widget.onAutoDetectKeyChanged,
              onManualKeySignatureChanged:
                  widget.onManualKeySignatureChanged,
              onAutoDetectTimeSignatureChanged:
                  widget.onAutoDetectTimeSignatureChanged,
              onManualTimeSignatureChanged:
                  widget.onManualTimeSignatureChanged,
              compact: compact,
            ),
          ],
        ],
      ),
    );
  }
}

class _AdjustmentPanelSection extends StatefulWidget {
  final bool compact;
  final Color textColor;
  final Color secondaryTextColor;
  final Color panelColor;
  final Color accentColor;
  final PlayPanelStyle panelStyle;
  final PlayPanelLayout panelLayout;
  final PlayScoreColorTheme scoreColorTheme;
  final bool focusMode;
  final double panelHeightFactor;
  final int manualMidiTranspose;
  final int deviceMidiTranspose;
  final int effectiveMidiTranspose;
  final String activeMidiDeviceName;
  final bool midiCalibrationArmed;
  final ValueChanged<PlayPanelStyle> onPanelStyleChanged;
  final ValueChanged<PlayPanelLayout> onPanelLayoutChanged;
  final ValueChanged<PlayScoreColorTheme> onScoreColorThemeChanged;
  final ValueChanged<bool> onFocusModeChanged;
  final ValueChanged<double> onPanelHeightChanged;
  final ValueChanged<int> onManualMidiTransposeChanged;
  final VoidCallback onArmMidiCalibration;
  final VoidCallback onResetMidiDeviceAlignment;

  const _AdjustmentPanelSection({
    required this.compact,
    required this.textColor,
    required this.secondaryTextColor,
    required this.panelColor,
    required this.accentColor,
    required this.panelStyle,
    required this.panelLayout,
    required this.scoreColorTheme,
    required this.focusMode,
    required this.panelHeightFactor,
    required this.manualMidiTranspose,
    required this.deviceMidiTranspose,
    required this.effectiveMidiTranspose,
    required this.activeMidiDeviceName,
    required this.midiCalibrationArmed,
    required this.onPanelStyleChanged,
    required this.onPanelLayoutChanged,
    required this.onScoreColorThemeChanged,
    required this.onFocusModeChanged,
    required this.onPanelHeightChanged,
    required this.onManualMidiTransposeChanged,
    required this.onArmMidiCalibration,
    required this.onResetMidiDeviceAlignment,
  });

  @override
  State<_AdjustmentPanelSection> createState() =>
      _AdjustmentPanelSectionState();
}

class _AdjustmentPanelSectionState extends State<_AdjustmentPanelSection> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoButton(
          padding: EdgeInsets.zero,
          minSize: 0,
          onPressed: () => setState(() => _isOpen = !_isOpen),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: widget.compact ? 10 : 12,
              vertical: widget.compact ? 8 : 10,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.panelColor.withOpacity(0.62),
                  widget.panelColor.withOpacity(0.36),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: widget.accentColor.withOpacity(0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isOpen
                      ? CupertinoIcons.chevron_down
                      : CupertinoIcons.slider_horizontal_3,
                  size: widget.compact ? 14 : 16,
                  color: widget.accentColor,
                ),
                SizedBox(width: widget.compact ? 6 : 8),
                Text(
                  'Adjustment',
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: widget.compact ? 11 : 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_isOpen) ...[
          SizedBox(height: widget.compact ? 6 : 10),
          _PanelViewControls(
            compact: widget.compact,
            textColor: widget.textColor,
            secondaryTextColor: widget.secondaryTextColor,
            panelColor: widget.panelColor,
            accentColor: widget.accentColor,
            panelStyle: widget.panelStyle,
            panelLayout: widget.panelLayout,
            scoreColorTheme: widget.scoreColorTheme,
            focusMode: widget.focusMode,
            panelHeightFactor: widget.panelHeightFactor,
            manualMidiTranspose: widget.manualMidiTranspose,
            deviceMidiTranspose: widget.deviceMidiTranspose,
            effectiveMidiTranspose: widget.effectiveMidiTranspose,
            activeMidiDeviceName: widget.activeMidiDeviceName,
            midiCalibrationArmed: widget.midiCalibrationArmed,
            onPanelStyleChanged: widget.onPanelStyleChanged,
            onPanelLayoutChanged: widget.onPanelLayoutChanged,
            onScoreColorThemeChanged: widget.onScoreColorThemeChanged,
            onFocusModeChanged: widget.onFocusModeChanged,
            onPanelHeightChanged: widget.onPanelHeightChanged,
            onManualMidiTransposeChanged: widget.onManualMidiTransposeChanged,
            onArmMidiCalibration: widget.onArmMidiCalibration,
            onResetMidiDeviceAlignment: widget.onResetMidiDeviceAlignment,
          ),
        ],
      ],
    );
  }
}

class _PerformanceControls extends StatelessWidget {
  static const List<String> _timeSignatures = ['4/4', '3/4', '6/8', '2/4', '12/8'];
  static const List<String> _keySignatures = [
    'C Major',
    'G Major',
    'D Major',
    'A Major',
    'E Major',
    'F Major',
    'Bb Major',
    'Eb Major',
    'A Minor',
    'E Minor',
    'D Minor',
    'G Minor',
  ];

  final Color textColor;
  final Color panelColor;
  final Color accentColor;
  final PlayTempoMode tempoMode;
  final int manualBpm;
  final bool autoDetectKeySignature;
  final String manualKeySignature;
  final bool autoDetectTimeSignature;
  final String manualTimeSignature;
  final ValueChanged<PlayTempoMode> onTempoModeChanged;
  final ValueChanged<int> onManualBpmChanged;
  final ValueChanged<bool> onAutoDetectKeyChanged;
  final ValueChanged<String> onManualKeySignatureChanged;
  final ValueChanged<bool> onAutoDetectTimeSignatureChanged;
  final ValueChanged<String> onManualTimeSignatureChanged;
  final bool compact;

  const _PerformanceControls({
    required this.textColor,
    required this.panelColor,
    required this.accentColor,
    required this.tempoMode,
    required this.manualBpm,
    required this.autoDetectKeySignature,
    required this.manualKeySignature,
    required this.autoDetectTimeSignature,
    required this.manualTimeSignature,
    required this.onTempoModeChanged,
    required this.onManualBpmChanged,
    required this.onAutoDetectKeyChanged,
    required this.onManualKeySignatureChanged,
    required this.onAutoDetectTimeSignatureChanged,
    required this.onManualTimeSignatureChanged,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          _compactCard(
            child: CupertinoSlidingSegmentedControl<PlayTempoMode>(
              backgroundColor: panelColor.withOpacity(0.55),
              thumbColor: accentColor.withOpacity(0.9),
              groupValue: tempoMode,
              onValueChanged: (value) {
                if (value != null) onTempoModeChanged(value);
              },
              children: const {
                PlayTempoMode.adaptive: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: Text('Adaptive'),
                ),
                PlayTempoMode.fixed: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                  child: Text('Fixed'),
                ),
              },
            ),
          ),
          _compactCard(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  tempoMode == PlayTempoMode.fixed ? 'BPM' : 'Live BPM',
                  style: TextStyle(
                    color: textColor.withOpacity(0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 6),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: panelColor.withOpacity(0.6),
                  onPressed: tempoMode == PlayTempoMode.fixed
                      ? () => onManualBpmChanged(manualBpm - 5)
                      : null,
                  child: Text('-', style: TextStyle(color: textColor, fontSize: 12)),
                ),
                const SizedBox(width: 4),
                Text(
                  '$manualBpm',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 4),
                CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: panelColor.withOpacity(0.6),
                  onPressed: tempoMode == PlayTempoMode.fixed
                      ? () => onManualBpmChanged(manualBpm + 5)
                      : null,
                  child: Text('+', style: TextStyle(color: textColor, fontSize: 12)),
                ),
              ],
            ),
          ),
          _compactToggleRow(
            label: 'Key',
            autoEnabled: autoDetectKeySignature,
            autoLabel: 'Auto',
            manualValue: manualKeySignature,
            manualOptions: _keySignatures,
            onAutoChanged: onAutoDetectKeyChanged,
            onManualChanged: onManualKeySignatureChanged,
          ),
          _compactToggleRow(
            label: 'Time',
            autoEnabled: autoDetectTimeSignature,
            autoLabel: 'Auto',
            manualValue: manualTimeSignature,
            manualOptions: _timeSignatures,
            onAutoChanged: onAutoDetectTimeSignatureChanged,
            onManualChanged: onManualTimeSignatureChanged,
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CupertinoSlidingSegmentedControl<PlayTempoMode>(
          backgroundColor: panelColor.withOpacity(0.55),
          thumbColor: accentColor.withOpacity(0.9),
          groupValue: tempoMode,
          onValueChanged: (value) {
            if (value != null) onTempoModeChanged(value);
          },
          children: const {
            PlayTempoMode.adaptive: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text('Adaptive Tempo'),
            ),
            PlayTempoMode.fixed: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text('Fixed Tempo'),
            ),
          },
        ),
        SizedBox(height: compact ? 8 : 10),
        Row(
          children: [
            Text(
              tempoMode == PlayTempoMode.fixed ? 'Manual BPM' : 'Follow player BPM',
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            CupertinoButton(
              padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
              color: panelColor.withOpacity(0.6),
              onPressed: tempoMode == PlayTempoMode.fixed
                  ? () => onManualBpmChanged(manualBpm - 5)
                  : null,
              child: Text(
                compact ? '-' : '-5',
                style: TextStyle(color: textColor, fontSize: compact ? 12 : 14),
              ),
            ),
            SizedBox(width: compact ? 4 : 6),
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: compact ? 8 : 10,
                vertical: compact ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: panelColor.withOpacity(0.45),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$manualBpm BPM',
                style: TextStyle(
                  color: textColor,
                  fontSize: compact ? 11 : 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            SizedBox(width: compact ? 4 : 6),
            CupertinoButton(
              padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: 4),
              color: panelColor.withOpacity(0.6),
              onPressed: tempoMode == PlayTempoMode.fixed
                  ? () => onManualBpmChanged(manualBpm + 5)
                  : null,
              child: Text(
                compact ? '+' : '+5',
                style: TextStyle(color: textColor, fontSize: compact ? 12 : 14),
              ),
            ),
          ],
        ),
        SizedBox(height: compact ? 8 : 10),
        _toggleRow(
          label: 'Key signature',
          autoEnabled: autoDetectKeySignature,
          autoLabel: 'Auto detect',
          manualValue: manualKeySignature,
          manualOptions: _keySignatures,
          onAutoChanged: onAutoDetectKeyChanged,
          onManualChanged: onManualKeySignatureChanged,
        ),
        SizedBox(height: compact ? 8 : 10),
        _toggleRow(
          label: 'Time signature',
          autoEnabled: autoDetectTimeSignature,
          autoLabel: 'Auto detect',
          manualValue: manualTimeSignature,
          manualOptions: _timeSignatures,
          onAutoChanged: onAutoDetectTimeSignatureChanged,
          onManualChanged: onManualTimeSignatureChanged,
        ),
      ],
    );
  }

  Widget _toggleRow({
    required String label,
    required bool autoEnabled,
    required String autoLabel,
    required String manualValue,
    required List<String> manualOptions,
    required ValueChanged<bool> onAutoChanged,
    required ValueChanged<String> onManualChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                color: textColor.withOpacity(0.8),
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              autoLabel,
              style: TextStyle(
                color: textColor.withOpacity(0.65),
                fontSize: compact ? 10 : 11,
              ),
            ),
            SizedBox(width: compact ? 6 : 8),
            CupertinoSwitch(
              value: autoEnabled,
              activeColor: accentColor,
              onChanged: onAutoChanged,
            ),
          ],
        ),
        if (!autoEnabled)
          SizedBox(
            height: compact ? 30 : 34,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemBuilder: (context, index) {
                final option = manualOptions[index];
                final selected = option == manualValue;
                return GestureDetector(
                  onTap: () => onManualChanged(option),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 10,
                      vertical: compact ? 6 : 8,
                    ),
                    decoration: BoxDecoration(
                      color: selected
                          ? accentColor.withOpacity(0.22)
                          : panelColor.withOpacity(0.42),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: selected
                            ? accentColor.withOpacity(0.5)
                            : textColor.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      option,
                      style: TextStyle(
                        color: textColor,
                        fontSize: compact ? 10 : 11,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
              separatorBuilder: (_, __) => SizedBox(width: compact ? 6 : 8),
              itemCount: manualOptions.length,
            ),
          ),
      ],
    );
  }

  Widget _compactCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: panelColor.withOpacity(0.32),
        borderRadius: BorderRadius.circular(10),
      ),
      child: child,
    );
  }

  Widget _compactToggleRow({
    required String label,
    required bool autoEnabled,
    required String autoLabel,
    required String manualValue,
    required List<String> manualOptions,
    required ValueChanged<bool> onAutoChanged,
    required ValueChanged<String> onManualChanged,
  }) {
    final preview = autoEnabled ? autoLabel : manualValue;
    return _compactCard(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: textColor.withOpacity(0.8),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            preview,
            style: TextStyle(
              color: textColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          CupertinoSwitch(
            value: autoEnabled,
            activeColor: accentColor,
            onChanged: onAutoChanged,
          ),
          if (!autoEnabled) ...[
            const SizedBox(width: 6),
            SizedBox(
              width: 124,
              height: 28,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final option = manualOptions[index];
                  final selected = option == manualValue;
                  return GestureDetector(
                    onTap: () => onManualChanged(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: selected
                            ? accentColor.withOpacity(0.22)
                            : panelColor.withOpacity(0.42),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? accentColor.withOpacity(0.5)
                              : textColor.withOpacity(0.08),
                        ),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 9,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemCount: manualOptions.length,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PerformanceSummaryRow extends StatelessWidget {
  final _PerformanceAnalysis analysis;
  final Color textColor;
  final Color panelColor;
  final Color accentColor;
  final bool compact;

  const _PerformanceSummaryRow({
    required this.analysis,
    required this.textColor,
    required this.panelColor,
    required this.accentColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: compact ? 6 : 8,
      runSpacing: compact ? 6 : 8,
      children: [
        _chip('Quantized ${analysis.gridLabel}', accentColor.withOpacity(0.18)),
        _chip(
          analysis.tempoMode == PlayTempoMode.adaptive
              ? 'Adaptive ${analysis.displayBpm} BPM'
              : 'Fixed ${analysis.displayBpm} BPM',
          panelColor.withOpacity(0.4),
        ),
        _chip('Bars ${analysis.measureCount}', panelColor.withOpacity(0.4)),
        _chip('Notes ${analysis.quantizedNotes.length}', panelColor.withOpacity(0.4)),
        _chip('Chords ${analysis.clusters.where((c) => c.notes.length > 1).length}',
            panelColor.withOpacity(0.4)),
      ],
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: textColor.withOpacity(0.08)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor.withOpacity(0.82),
          fontSize: compact ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _LiveTablatureStrip extends StatelessWidget {
  final List<_NoteCluster> clusters;
  final Set<int> activeNotes;
  final Color textColor;
  final Color accentColor;
  final Color panelColor;
  final bool compact;

  const _LiveTablatureStrip({
    required this.clusters,
    required this.activeNotes,
    required this.textColor,
    required this.accentColor,
    required this.panelColor,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final recent = clusters.reversed.take(12).toList().reversed.toList();
    if (recent.isEmpty) {
      return Container(
        height: compact ? 54 : 104,
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
        decoration: BoxDecoration(
          color: panelColor.withOpacity(0.38),
          borderRadius: BorderRadius.circular(compact ? 10 : 14),
        ),
        child: Text(
          'Play notes or chords to generate live piano tab and grouped transcription.',
          style: TextStyle(
            color: textColor.withOpacity(0.65),
            fontSize: compact ? 9 : 12,
          ),
        ),
      );
    }

    return SizedBox(
      height: compact ? 58 : 104,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: recent.length,
        separatorBuilder: (_, __) => SizedBox(width: compact ? 6 : 8),
        itemBuilder: (context, index) {
          final cluster = recent[index];
          final isActive =
              cluster.notes.any((note) => activeNotes.contains(note.midiNote));
          return Container(
            width: compact ? 90 : 132,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 8 : 12,
              vertical: compact ? 6 : 10,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? accentColor.withOpacity(0.22)
                  : panelColor.withOpacity(0.34),
              borderRadius: BorderRadius.circular(compact ? 10 : 14),
              border: Border.all(
                color: isActive
                    ? accentColor.withOpacity(0.55)
                    : textColor.withOpacity(0.08),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cluster.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor,
                    fontSize: compact ? 11 : 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: compact ? 1 : 4),
                Text(
                  cluster.keyNumbers,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: textColor.withOpacity(0.72),
                    fontSize: compact ? 9 : 11,
                  ),
                ),
                const Spacer(),
                Text(
                  cluster.rhythmLabel,
                  style: TextStyle(
                    color: isActive ? accentColor : textColor.withOpacity(0.8),
                    fontSize: compact ? 9 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (cluster.notes.length > 1)
                  Text(
                    '${cluster.notes.length}-note chord',
                    style: TextStyle(
                      color: textColor.withOpacity(0.6),
                      fontSize: compact ? 8 : 10,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LivePerformanceAnalyzer {
  static const double _adaptiveDecaySeconds = 5.0;

  static _PerformanceAnalysis analyze({
    required List<ScoreNote> notes,
    required String fallbackKeySignature,
    required String fallbackTimeSignature,
    required double currentTime,
    required PlayTempoMode tempoMode,
    required int fixedBpm,
    required bool autoDetectKeySignature,
    required String manualKeySignature,
    required bool autoDetectTimeSignature,
    required String manualTimeSignature,
  }) {
    if (notes.isEmpty) {
      return _PerformanceAnalysis(
        bpm: tempoMode == PlayTempoMode.fixed ? fixedBpm : 80,
        displayBpm: tempoMode == PlayTempoMode.fixed ? fixedBpm : 0,
        tempoMode: tempoMode,
        timeSignature:
            autoDetectTimeSignature ? fallbackTimeSignature : manualTimeSignature,
        keySignature:
            autoDetectKeySignature ? fallbackKeySignature : manualKeySignature,
        quantizedNotes: const [],
        quantizedCurrentTime: currentTime,
        clusters: const [],
        gridLabel: '1/16',
        measureCount: 0,
      );
    }

    final sorted = [...notes]..sort((a, b) => a.time.compareTo(b.time));
    final detectedBpm = _inferBpm(sorted);
    final adaptiveTimeline = _adaptiveTimeline(
      sorted,
      detectedBpm: detectedBpm,
      currentTime: currentTime,
    );
    final bpm = tempoMode == PlayTempoMode.fixed ? fixedBpm : detectedBpm;
    final detectedTimeSignature =
        _inferTimeSignature(sorted, bpm, fallbackTimeSignature);
    final timeSignature =
        autoDetectTimeSignature ? detectedTimeSignature : manualTimeSignature;
    final detectedKeySignature = _inferKeySignature(sorted, fallbackKeySignature);
    final keySignature =
        autoDetectKeySignature ? detectedKeySignature : manualKeySignature;
    final quantized = _quantizeNotes(sorted, bpm, timeSignature);
    final clusters = _clusterNotes(quantized);
    final currentQuantized = _quantizeTime(
      tempoMode == PlayTempoMode.fixed
          ? currentTime
          : adaptiveTimeline.effectiveCurrentTime,
      _gridStepSeconds(bpm, timeSignature),
    );
    final measureCount = _measureCount(
      quantized,
      bpm: bpm,
      timeSignature: timeSignature,
    );

    return _PerformanceAnalysis(
      bpm: bpm,
      displayBpm: tempoMode == PlayTempoMode.fixed
          ? bpm
          : adaptiveTimeline.displayBpm,
      tempoMode: tempoMode,
      timeSignature: timeSignature,
      keySignature: keySignature,
      quantizedNotes: quantized,
      quantizedCurrentTime: currentQuantized,
      clusters: clusters,
      gridLabel: _gridLabel(timeSignature),
      measureCount: measureCount,
    );
  }

  static int _inferBpm(List<ScoreNote> notes) {
    final onsets = notes.map((e) => e.time).toList()..sort();
    final gaps = <double>[];
    for (int i = 1; i < onsets.length; i++) {
      final gap = onsets[i] - onsets[i - 1];
      if (gap >= 0.18 && gap <= 1.2) {
        gaps.add(gap);
      }
    }
    if (gaps.isEmpty) return 80;
    gaps.sort();
    var beatSeconds = gaps[gaps.length ~/ 2];
    while (beatSeconds < 0.32) {
      beatSeconds *= 2;
    }
    while (beatSeconds > 1.1) {
      beatSeconds /= 2;
    }
    return (60.0 / beatSeconds).round().clamp(54, 172);
  }

  static _AdaptiveTimelineResult _adaptiveTimeline(
    List<ScoreNote> notes, {
    required int detectedBpm,
    required double currentTime,
  }) {
    if (notes.isEmpty) {
      return const _AdaptiveTimelineResult(
        displayBpm: 0,
        effectiveCurrentTime: 0,
      );
    }
    final lastActivity = notes
        .map((note) => note.time + math.max(0.08, note.duration))
        .reduce((a, b) => a > b ? a : b);
    final silence = math.max(0.0, currentTime - lastActivity);
    if (silence <= 0) {
      return _AdaptiveTimelineResult(
        displayBpm: detectedBpm,
        effectiveCurrentTime: currentTime,
      );
    }
    final clampedSilence = silence.clamp(0.0, _adaptiveDecaySeconds);
    final factor = 1.0 - (clampedSilence / _adaptiveDecaySeconds);
    final decayedTravel =
        clampedSilence - ((clampedSilence * clampedSilence) / (2 * _adaptiveDecaySeconds));
    return _AdaptiveTimelineResult(
      displayBpm: (detectedBpm * factor).round().clamp(0, detectedBpm),
      effectiveCurrentTime: lastActivity + decayedTravel,
    );
  }

  static String _inferTimeSignature(
    List<ScoreNote> notes,
    int bpm,
    String fallback,
  ) {
    if (notes.length < 8) return fallback;
    const candidates = ['4/4', '3/4', '6/8'];
    final scores = <String, double>{};
    for (final candidate in candidates) {
      final barSeconds = _measureSecondsFor(bpm, candidate);
      final step = _gridStepSeconds(bpm, candidate);
      double score = 0;
      for (final note in notes) {
        final withinBar = note.time % barSeconds;
        final snapped = _quantizeTime(withinBar, step);
        score += (withinBar - snapped).abs();
      }
      if (candidate == '4/4') {
        score *= 0.98;
      }
      scores[candidate] = score;
    }
    return scores.entries.reduce((a, b) => a.value <= b.value ? a : b).key;
  }

  static String _inferKeySignature(List<ScoreNote> notes, String fallback) {
    const majorProfile = [
      6.35, 2.23, 3.48, 2.33, 4.38, 4.09,
      2.52, 5.19, 2.39, 3.66, 2.29, 2.88,
    ];
    const minorProfile = [
      6.33, 2.68, 3.52, 5.38, 2.60, 3.53,
      2.54, 4.75, 3.98, 2.69, 3.34, 3.17,
    ];
    if (notes.length < 5) return fallback;
    final pitchWeights = List<double>.filled(12, 0);
    for (final note in notes) {
      pitchWeights[note.midiNote % 12] += math.max(0.25, note.duration) *
          (0.5 + note.velocity / 127.0);
    }

    double bestScore = -double.infinity;
    String bestKey = fallback;
    for (int root = 0; root < 12; root++) {
      final major = _correlate(pitchWeights, majorProfile, root);
      if (major > bestScore) {
        bestScore = major;
        bestKey = '${_pitchClassName(root)} Major';
      }
      final minor = _correlate(pitchWeights, minorProfile, root);
      if (minor > bestScore) {
        bestScore = minor;
        bestKey = '${_pitchClassName(root)} Minor';
      }
    }
    return bestKey;
  }

  static double _correlate(List<double> pitches, List<double> profile, int root) {
    double score = 0;
    for (int i = 0; i < 12; i++) {
      score += pitches[i] * profile[(i - root) % 12];
    }
    return score;
  }

  static List<ScoreNote> _quantizeNotes(
    List<ScoreNote> notes,
    int bpm,
    String timeSignature,
  ) {
    final step = _gridStepSeconds(bpm, timeSignature);
    return notes.map((note) {
      final quantizedTime = _quantizeTime(note.time, step);
      final quantizedDuration = math.max(
        step,
        _quantizeTime(note.duration, step),
      );
      return ScoreNote(
        midiNote: note.midiNote,
        time: quantizedTime,
        duration: quantizedDuration,
        hand: note.hand,
        velocity: note.velocity,
      );
    }).toList()
      ..sort((a, b) {
        final byTime = a.time.compareTo(b.time);
        if (byTime != 0) return byTime;
        return a.midiNote.compareTo(b.midiNote);
      });
  }

  static List<_NoteCluster> _clusterNotes(List<ScoreNote> notes) {
    if (notes.isEmpty) return const [];
    final clusters = <_NoteCluster>[];
    List<ScoreNote> current = [notes.first];
    for (int i = 1; i < notes.length; i++) {
      final note = notes[i];
      if ((note.time - current.first.time).abs() <= 0.001) {
        current.add(note);
      } else {
        clusters.add(_NoteCluster.fromNotes(current));
        current = [note];
      }
    }
    clusters.add(_NoteCluster.fromNotes(current));
    return clusters;
  }

  static int _measureCount(
    List<ScoreNote> notes, {
    required int bpm,
    required String timeSignature,
  }) {
    if (notes.isEmpty) return 0;
    final barSeconds = _measureSecondsFor(bpm, timeSignature);
    final last = notes
        .map((e) => e.time + e.duration)
        .reduce((a, b) => a > b ? a : b);
    return math.max(1, (last / barSeconds).ceil());
  }

  static double _measureSecondsFor(int bpm, String timeSignature) {
    final parts = timeSignature.split('/');
    final top = parts.length == 2 ? double.tryParse(parts[0]) ?? 4 : 4;
    final bottom = parts.length == 2 ? double.tryParse(parts[1]) ?? 4 : 4;
    final beat = 60.0 / bpm.clamp(30, 240);
    return beat * top * (4.0 / bottom);
  }

  static double _gridStepSeconds(int bpm, String timeSignature) {
    final parts = timeSignature.split('/');
    final bottom = parts.length == 2 ? double.tryParse(parts[1]) ?? 4 : 4;
    final beat = 60.0 / bpm.clamp(30, 240);
    final unit = beat * (4.0 / bottom);
    final step = bottom == 8 ? unit / 2 : unit / 4;
    return step.clamp(0.08, 0.4);
  }

  static double _quantizeTime(double value, double step) {
    return (value / step).roundToDouble() * step;
  }

  static String _gridLabel(String timeSignature) {
    final bottom = int.tryParse(timeSignature.split('/').last) ?? 4;
    return bottom == 8 ? '1/32' : '1/16';
  }

  static String _pitchClassName(int pitchClass) {
    switch (pitchClass % 12) {
      case 0:
        return 'C';
      case 1:
        return 'C#';
      case 2:
        return 'D';
      case 3:
        return 'Eb';
      case 4:
        return 'E';
      case 5:
        return 'F';
      case 6:
        return 'F#';
      case 7:
        return 'G';
      case 8:
        return 'Ab';
      case 9:
        return 'A';
      case 10:
        return 'Bb';
      default:
        return 'B';
    }
  }
}

class _PerformanceAnalysis {
  final int bpm;
  final int displayBpm;
  final PlayTempoMode tempoMode;
  final String timeSignature;
  final String keySignature;
  final List<ScoreNote> quantizedNotes;
  final double quantizedCurrentTime;
  final List<_NoteCluster> clusters;
  final String gridLabel;
  final int measureCount;

  const _PerformanceAnalysis({
    required this.bpm,
    required this.displayBpm,
    required this.tempoMode,
    required this.timeSignature,
    required this.keySignature,
    required this.quantizedNotes,
    required this.quantizedCurrentTime,
    required this.clusters,
    required this.gridLabel,
    required this.measureCount,
  });
}

class _AdaptiveTimelineResult {
  final int displayBpm;
  final double effectiveCurrentTime;

  const _AdaptiveTimelineResult({
    required this.displayBpm,
    required this.effectiveCurrentTime,
  });
}

class _NoteCluster {
  final List<ScoreNote> notes;
  final String displayName;
  final String keyNumbers;
  final String rhythmLabel;

  const _NoteCluster({
    required this.notes,
    required this.displayName,
    required this.keyNumbers,
    required this.rhythmLabel,
  });

  factory _NoteCluster.fromNotes(List<ScoreNote> notes) {
    final sorted = [...notes]..sort((a, b) => a.midiNote.compareTo(b.midiNote));
    final names = sorted.map((n) => _noteName(n.midiNote)).join(' ');
    final keys = sorted.map((n) => n.midiNote.toString()).join('-');
    final longestDuration = sorted
        .map((n) => n.duration)
        .reduce((a, b) => a > b ? a : b);
    return _NoteCluster(
      notes: sorted,
      displayName: names,
      keyNumbers: 'Keys $keys',
      rhythmLabel: _durationLabel(longestDuration),
    );
  }

  static String _noteName(int midiNote) {
    const names = ['C', 'C#', 'D', 'Eb', 'E', 'F', 'F#', 'G', 'Ab', 'A', 'Bb', 'B'];
    final octave = (midiNote ~/ 12) - 1;
    return '${names[midiNote % 12]}$octave';
  }

  static String _durationLabel(double seconds) {
    if (seconds >= 1.4) return 'Whole';
    if (seconds >= 0.7) return 'Half';
    if (seconds >= 0.32) return 'Quarter';
    if (seconds >= 0.18) return 'Eighth';
    return 'Grace';
  }
}
