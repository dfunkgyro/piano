import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';

class DebugLogPanel extends StatefulWidget {
  final Function() getDebugStats;
  final Function() getDebugLog;
  final Function()? onClearLog;
  final Function(bool)? onToggleRawMode;
  final bool? rawMidiMode;

  const DebugLogPanel({
    super.key,
    required this.getDebugStats,
    required this.getDebugLog,
    this.onClearLog,
    this.onToggleRawMode,
    this.rawMidiMode,
  });

  @override
  State<DebugLogPanel> createState() => _DebugLogPanelState();
}

class _DebugLogPanelState extends State<DebugLogPanel> {
  Timer? _refreshTimer;
  bool _autoScroll = true;
  bool _showOnlyErrors = false;
  final ScrollController _scrollController = ScrollController();
  late List<String> _logEntries;
  late Map<String, dynamic> _stats;

  @override
  void initState() {
    super.initState();
    _refreshLog();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        _refreshLog();
      }
    });
  }

  void _refreshLog() {
    setState(() {
      _logEntries = List<String>.from(widget.getDebugLog());
      _stats = Map<String, dynamic>.from(widget.getDebugStats());
    });

    if (_autoScroll && _scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _copyLogToClipboard() {
    final logText = _logEntries.join('\n');
    Clipboard.setData(ClipboardData(text: logText));

    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Icon(
          CupertinoIcons.checkmark_circle_fill,
          color: CupertinoColors.systemGreen,
          size: 48,
        ),
        content: const Padding(
          padding: EdgeInsets.only(top: 16),
          child: Text('Log copied to clipboard'),
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _clearLog() {
    widget.onClearLog?.call();
    _refreshLog();
  }

  List<String> get _filteredLogs {
    if (!_showOnlyErrors) return _logEntries;
    return _logEntries
        .where((log) =>
            log.contains('❌') || log.contains('⚠️') || log.contains('ERROR'))
        .toList();
  }

  Color _getLogColor(String log) {
    if (log.contains('❌') || log.contains('ERROR')) {
      return CupertinoColors.systemRed;
    } else if (log.contains('⚠️') || log.contains('WARNING')) {
      return CupertinoColors.systemOrange;
    } else if (log.contains('✅') || log.contains('SUCCESS')) {
      return CupertinoColors.systemGreen;
    } else if (log.contains('🎵') || log.contains('Note')) {
      return CupertinoColors.systemBlue;
    }
    return CupertinoColors.label;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF2C2C2E),
        middle: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.chart_bar_alt_fill,
                size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text('Debug & Diagnostics', style: TextStyle(color: Colors.white)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _copyLogToClipboard,
              child: const Icon(
                CupertinoIcons.doc_on_clipboard,
                color: CupertinoColors.activeBlue,
              ),
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _clearLog,
              child: const Icon(
                CupertinoIcons.trash,
                color: CupertinoColors.systemRed,
              ),
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Stats Panel
            Container(
              padding: const EdgeInsets.all(16),
              color: const Color(0xFF2C2C2E),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: CupertinoIcons.link,
                          label: 'Connection',
                          value: _stats['connected'] == true
                              ? 'Connected'
                              : 'Disconnected',
                          color: _stats['connected'] == true
                              ? CupertinoColors.systemGreen
                              : CupertinoColors.systemRed,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: CupertinoIcons.device_laptop,
                          label: 'Device',
                          value: _stats['deviceType'] ?? 'None',
                          color: CupertinoColors.systemBlue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: CupertinoIcons.music_note_2,
                          label: 'Active Notes',
                          value: '${_stats['activeNotes'] ?? 0}',
                          color: CupertinoColors.systemPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: CupertinoIcons.waveform,
                          label: 'Packets',
                          value: '${_stats['totalPackets'] ?? 0}',
                          color: CupertinoColors.systemTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: CupertinoIcons.xmark_circle,
                          label: 'Dropped',
                          value: '${_stats['droppedPackets'] ?? 0}',
                          color: _stats['droppedPackets'] != null &&
                                  _stats['droppedPackets'] > 0
                              ? CupertinoColors.systemOrange
                              : CupertinoColors.systemGrey,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: CupertinoIcons.layers_alt,
                          label: 'Queue',
                          value: '${_stats['queueSize'] ?? 0}',
                          color: CupertinoColors.systemIndigo,
                        ),
                      ),
                    ],
                  ),

                  // Note Range Display
                  if (_stats['activeNotesList'] != null &&
                      (_stats['activeNotesList'] as List).isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: CupertinoColors.systemBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: CupertinoColors.systemBlue.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                CupertinoIcons.music_note_list,
                                size: 16,
                                color: CupertinoColors.systemBlue,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Active Notes',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: CupertinoColors.systemBlue,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: (_stats['activeNotesList'] as List)
                                .map((note) => _NoteChip(note: note as int))
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFF2C2C2E),
              child: Column(
                children: [
                  Row(
                    children: [
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        color: _autoScroll
                            ? CupertinoColors.activeBlue
                            : CupertinoColors.systemGrey,
                        onPressed: () {
                          setState(() => _autoScroll = !_autoScroll);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _autoScroll
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.circle,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Text('Auto-scroll',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        color: _showOnlyErrors
                            ? CupertinoColors.systemOrange
                            : CupertinoColors.systemGrey,
                        onPressed: () {
                          setState(() => _showOnlyErrors = !_showOnlyErrors);
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showOnlyErrors
                                  ? CupertinoIcons.exclamationmark_triangle_fill
                                  : CupertinoIcons.exclamationmark_triangle,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            const Text('Errors Only',
                                style: TextStyle(fontSize: 12)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_filteredLogs.length} entries',
                        style: const TextStyle(
                          fontSize: 12,
                          color: CupertinoColors.systemGrey,
                        ),
                      ),
                    ],
                  ),

                  // Raw MIDI Mode Toggle
                  if (widget.onToggleRawMode != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.rawMidiMode == true
                            ? CupertinoColors.systemRed.withOpacity(0.2)
                            : CupertinoColors.systemBlue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: widget.rawMidiMode == true
                              ? CupertinoColors.systemRed
                              : CupertinoColors.systemBlue,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.rawMidiMode == true
                                ? CupertinoIcons.bolt_fill
                                : CupertinoIcons.waveform,
                            color: widget.rawMidiMode == true
                                ? CupertinoColors.systemRed
                                : CupertinoColors.systemBlue,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.rawMidiMode == true
                                      ? 'RAW MIDI MODE (No BLE Parsing)'
                                      : 'BLE-MIDI Parsing Enabled',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: widget.rawMidiMode == true
                                        ? CupertinoColors.systemRed
                                        : Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.rawMidiMode == true
                                      ? 'Using packets as-is - try if notes not detected'
                                      : 'Parsing BLE-MIDI headers - default mode',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          CupertinoSwitch(
                            value: widget.rawMidiMode ?? false,
                            onChanged: (value) {
                              widget.onToggleRawMode?.call(value);
                              setState(() {});
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Log Display
            Expanded(
              child: Container(
                color: const Color(0xFF000000),
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: _filteredLogs.length,
                  itemBuilder: (context, index) {
                    final log = _filteredLogs[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: SelectableText(
                        log,
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'Courier',
                          color: _getLogColor(log),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Performance Metrics
            Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFF2C2C2E),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Performance Metrics',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _MetricIndicator(
                        label: 'Packet Loss',
                        value: _calculatePacketLoss(),
                        good: _calculatePacketLoss() < 1,
                      ),
                      _MetricIndicator(
                        label: 'Queue Health',
                        value: _calculateQueueHealth(),
                        good: _calculateQueueHealth() < 50,
                      ),
                      _MetricIndicator(
                        label: 'Connection',
                        value: _stats['connected'] == true ? 100 : 0,
                        good: _stats['connected'] == true,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _calculatePacketLoss() {
    final total = _stats['totalPackets'] ?? 0;
    final dropped = _stats['droppedPackets'] ?? 0;
    if (total == 0) return 0;
    return (dropped / total * 100).clamp(0, 100);
  }

  double _calculateQueueHealth() {
    final queueSize = _stats['queueSize'] ?? 0;
    return (queueSize / 200 * 100).clamp(0, 100); // Max queue is 200
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF3A3A3C),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              color: CupertinoColors.systemGrey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NoteChip extends StatelessWidget {
  final int note;

  const _NoteChip({required this.note});

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
    final octave = (midiNote - 12) ~/ 12;
    final noteIndex = (midiNote - 21) % 12;
    return '${noteNames[noteIndex]}$octave';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: CupertinoColors.systemBlue,
          width: 1,
        ),
      ),
      child: Text(
        '${_getNoteName(note)} ($note)',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _MetricIndicator extends StatelessWidget {
  final String label;
  final double value;
  final bool good;

  const _MetricIndicator({
    required this.label,
    required this.value,
    required this.good,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: CupertinoColors.systemGrey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${value.toStringAsFixed(1)}%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color:
                good ? CupertinoColors.systemGreen : CupertinoColors.systemRed,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: CupertinoColors.systemGrey5,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: value / 100,
            child: Container(
              decoration: BoxDecoration(
                color: good
                    ? CupertinoColors.systemGreen
                    : CupertinoColors.systemRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
