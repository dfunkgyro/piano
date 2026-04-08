// ============================================
// debug_logs_viewer.dart - Troubleshooting Panel
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/midi_service.dart';
import '../services/audio_player_service.dart';
import '../services/aws_service.dart';
import 'dart:io' show Platform;

class DebugLogsViewer extends StatefulWidget {
  final MidiService midiService;
  final AudioPlayerService audioService;
  final AwsService cloudService;
  final bool isAIReady;
  final VoidCallback onClose;

  const DebugLogsViewer({
    super.key,
    required this.midiService,
    required this.audioService,
    required this.cloudService,
    required this.isAIReady,
    required this.onClose,
  });

  @override
  State<DebugLogsViewer> createState() => _DebugLogsViewerState();
}

class _DebugLogsViewerState extends State<DebugLogsViewer> {
  int _selectedTab = 0;
  String _backendStatus = 'Checking...';
  String? _backendError;

  @override
  void initState() {
    super.initState();
    _refreshBackendStatus();
  }

  Future<void> _refreshBackendStatus() async {
    final result = await widget.cloudService.checkBackend();
    final ok = result['ok'] == true;
    final statusCode = result['statusCode'];
    final error = result['error'] as String?;

    setState(() {
      if (statusCode != null) {
        _backendStatus = ok ? 'OK (HTTP $statusCode)' : 'HTTP $statusCode';
      } else {
        _backendStatus = ok ? 'OK' : 'Offline';
      }
      _backendError = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          _buildTabBar(),
          Expanded(
            child: _buildTabContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.wrench_fill,
            size: 24,
            color: CupertinoColors.systemOrange,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Debug & Diagnostics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.onClose,
            child: const Icon(CupertinoIcons.xmark_circle_fill),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      padding: const EdgeInsets.all(8),
      child: CupertinoSlidingSegmentedControl<int>(
        groupValue: _selectedTab,
        children: const {
          0: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('Status', style: TextStyle(fontSize: 13)),
          ),
          1: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('MIDI', style: TextStyle(fontSize: 13)),
          ),
          2: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Text('System', style: TextStyle(fontSize: 13)),
          ),
        },
        onValueChanged: (value) {
          setState(() => _selectedTab = value ?? 0);
        },
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildStatusTab();
      case 1:
        return _buildMidiTab();
      case 2:
        return _buildSystemTab();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildStatusTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatusSection('MIDI Connection', [
          _buildStatusItem(
            'Status',
            widget.midiService.isConnected ? 'Connected' : 'Disconnected',
            widget.midiService.isConnected
                ? CupertinoColors.systemGreen
                : CupertinoColors.systemRed,
          ),
          if (widget.midiService.isConnected) ...[
            _buildStatusItem(
              'Device',
              widget.midiService.connectedDevice?.name ?? 'Unknown',
              CupertinoColors.label,
            ),
            _buildStatusItem(
              'Type',
              widget.midiService.deviceType,
              CupertinoColors.label,
            ),
          ],
          _buildStatusItem(
            'Bluetooth',
            widget.midiService.bluetoothState.toString().split('.').last,
            widget.midiService.bluetoothState.toString().contains('poweredOn')
                ? CupertinoColors.systemGreen
                : CupertinoColors.systemOrange,
          ),
        ]),
        const SizedBox(height: 16),
        _buildStatusSection('Performance', [
          _buildStatusItem(
            'Queue Size',
            '${widget.midiService.queueSize} packets',
            widget.midiService.queueSize > 100
                ? CupertinoColors.systemOrange
                : CupertinoColors.systemGreen,
          ),
          _buildStatusItem(
            'Dropped Packets',
            '${widget.midiService.droppedPackets}',
            widget.midiService.droppedPackets > 0
                ? CupertinoColors.systemRed
                : CupertinoColors.systemGreen,
          ),
          _buildStatusItem(
            'Initialized',
            widget.midiService.isInitialized ? 'Yes' : 'No',
            widget.midiService.isInitialized
                ? CupertinoColors.systemGreen
                : CupertinoColors.systemRed,
          ),
        ]),
        const SizedBox(height: 16),
        _buildStatusSection('Services', [
          _buildStatusItem(
            'AI Tutor',
            widget.isAIReady ? 'Ready' : 'Offline',
            widget.isAIReady
                ? CupertinoColors.systemGreen
                : CupertinoColors.systemGrey,
          ),
          _buildStatusItem(
            'AWS Backend',
            _backendStatus,
            _backendStatus.startsWith('OK')
                ? CupertinoColors.systemGreen
                : CupertinoColors.systemOrange,
          ),
          if (_backendError != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SelectableText(
                'Backend error: $_backendError',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          _buildStatusItem(
            'Audio',
            'Active',
            CupertinoColors.systemGreen,
          ),
        ]),
        const SizedBox(height: 16),
        _buildStatusSection('Audio Engine', [
          _buildStatusItem(
            'Plays',
            '${widget.audioService.getPerformanceStats()['audioPlayCount']}',
            CupertinoColors.activeBlue,
          ),
          _buildStatusItem(
            'Errors',
            '${widget.audioService.getPerformanceStats()['audioErrorCount']}',
            CupertinoColors.systemRed,
          ),
        ]),
        const SizedBox(height: 24),
        _buildActionButtons(),
      ],
    );
  }

  Widget _buildMidiTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'MIDI Performance',
          CupertinoIcons.gauge,
          [
            'Queue Size: ${widget.midiService.queueSize}',
            'Dropped Packets: ${widget.midiService.droppedPackets}',
            'Connection: ${widget.midiService.isConnected ? "Active" : "Inactive"}',
            'MIDI Messages: ${widget.midiService.midiMessageCount}',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Audio Diagnostics',
          CupertinoIcons.volume_up,
          [
            'Engine: ${widget.audioService.getPerformanceStats()['audioEngine']}',
            'Last Audio Note: ${widget.audioService.getPerformanceStats()['lastAudioNote'] ?? "None"}',
            'Last Audio Start (ms): ${widget.audioService.getPerformanceStats()['lastAudioStartLatencyMs'] ?? "n/a"}',
            'Last Audio Error: ${widget.audioService.getPerformanceStats()['lastAudioError'] ?? "None"}',
            'WebAudio Buffers: ${widget.audioService.getPerformanceStats()['webAudioBuffers']}',
            'WebAudio Active: ${widget.audioService.getPerformanceStats()['webAudioActiveSources']}',
            'WebAudio Last Error: ${widget.audioService.getPerformanceStats()['webAudioLastError'] ?? "None"}',
            'WebAudio Last Latency (ms): ${widget.audioService.getPerformanceStats()['webAudioLastLatencyMs'] ?? "n/a"}',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Bluetooth State',
          CupertinoIcons.antenna_radiowaves_left_right,
          [
            'State: ${widget.midiService.bluetoothState.toString().split('.').last}',
            'Initialized: ${widget.midiService.isInitialized}',
            'Web MIDI Inputs: ${widget.midiService.webMidiInputs.length}',
            'Last MIDI: ${widget.midiService.lastMidiMessage ?? "None"}',
          ],
        ),
        const SizedBox(height: 16),
        if (widget.midiService.isConnected)
          _buildInfoCard(
            'Connected Device',
            CupertinoIcons.device_desktop,
            [
              'Name: ${widget.midiService.connectedDevice?.name ?? "Unknown"}',
              'Type: ${widget.midiService.deviceType}',
              'ID: ${widget.midiService.connectedDevice?.id ?? "N/A"}',
            ],
          ),
        const SizedBox(height: 16),
        _buildTroubleshootingSection(),
      ],
    );
  }

  Widget _buildSystemTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildInfoCard(
          'Platform',
          CupertinoIcons.device_phone_portrait,
          [
            'OS: ${Platform.operatingSystem}',
            'Version: ${Platform.operatingSystemVersion}',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'App Info',
          CupertinoIcons.info_circle,
          [
            'Version: 3.1.0',
            'Build: Enhanced',
            'MIDI Service: v2.0',
          ],
        ),
        const SizedBox(height: 16),
        _buildInfoCard(
          'Features',
          CupertinoIcons.checkmark_seal,
          [
            'Enhanced MIDI: ✅',
            'Adaptive Processing: ✅',
            'Device Profiles: ✅',
            'Smart Queue: ✅',
            'Performance Monitoring: ✅',
          ],
        ),
        const SizedBox(height: 24),
        _buildCopySystemInfoButton(),
      ],
    );
  }

  Widget _buildStatusSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatusItem(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, IconData icon, List<String> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemGrey5,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: CupertinoColors.activeBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  item,
                  style: const TextStyle(
                    fontSize: 13,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemYellow.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: CupertinoColors.systemYellow.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                CupertinoIcons.lightbulb,
                size: 20,
                color: CupertinoColors.systemYellow,
              ),
              const SizedBox(width: 8),
              const Text(
                'Troubleshooting Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTipItem('High Queue Size',
              'If queue size >100, try closing other apps or restart the device'),
          _buildTipItem('Dropped Packets',
              'Dropped packets indicate high MIDI traffic. Check for excessive CC messages'),
          _buildTipItem('Connection Fails',
              'Ensure device is in pairing mode and within 10 meters'),
          _buildTipItem('Bluetooth Off', 'Enable Bluetooth in System Settings'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• $title',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              description,
              style: const TextStyle(
                fontSize: 12,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.activeBlue,
            onPressed: _copyDebugInfo,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.doc_on_clipboard, size: 18),
                SizedBox(width: 8),
                Text('Copy Debug Info'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.systemGrey5,
            onPressed: _shareDebugInfo,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.share,
                    size: 18, color: CupertinoColors.label),
                SizedBox(width: 8),
                Text('Share Debug Info',
                    style: TextStyle(color: CupertinoColors.label)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: CupertinoButton(
            color: CupertinoColors.systemGrey4,
            onPressed: _refreshBackendStatus,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.refresh, size: 18),
                SizedBox(width: 8),
                Text('Refresh Backend Status'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopySystemInfoButton() {
    return SizedBox(
      width: double.infinity,
      child: CupertinoButton(
        color: CupertinoColors.activeBlue,
        onPressed: _copySystemInfo,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.doc_on_clipboard, size: 18),
            SizedBox(width: 8),
            Text('Copy System Info'),
          ],
        ),
      ),
    );
  }

  Future<void> _copyDebugInfo() async {
    final info = _generateDebugInfo();
    await Clipboard.setData(ClipboardData(text: info));

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Copied'),
          content: const Text('Debug information copied to clipboard'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _copySystemInfo() async {
    final info = _generateSystemInfo();
    await Clipboard.setData(ClipboardData(text: info));

    if (mounted) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Copied'),
          content: const Text('System information copied to clipboard'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _shareDebugInfo() async {
    // In a real app, you'd use share_plus package
    await _copyDebugInfo();
  }

  String _generateDebugInfo() {
    return '''
MIDI Piano Pro - Debug Information
Generated: ${DateTime.now()}

=== MIDI CONNECTION ===
Status: ${widget.midiService.isConnected ? "Connected" : "Disconnected"}
Device: ${widget.midiService.connectedDevice?.name ?? "None"}
Type: ${widget.midiService.deviceType}
Bluetooth: ${widget.midiService.bluetoothState.toString().split('.').last}
Initialized: ${widget.midiService.isInitialized}

=== PERFORMANCE ===
Queue Size: ${widget.midiService.queueSize}
Dropped Packets: ${widget.midiService.droppedPackets}
MIDI Messages: ${widget.midiService.midiMessageCount}
Last MIDI: ${widget.midiService.lastMidiMessage ?? "None"}
Web MIDI Inputs: ${widget.midiService.webMidiInputs.length}

=== SERVICES ===
AI Tutor: ${widget.isAIReady ? "Ready" : "Offline"}
AWS Backend: $_backendStatus
Audio: Active

=== SYSTEM ===
Platform: ${Platform.operatingSystem}
Version: ${Platform.operatingSystemVersion}
App Version: 3.1.0
MIDI Service: v2.0 (Enhanced)
''';
  }

  String _generateSystemInfo() {
    return '''
MIDI Piano Pro - System Information
Generated: ${DateTime.now()}

=== PLATFORM ===
OS: ${Platform.operatingSystem}
Version: ${Platform.operatingSystemVersion}
Number of Processors: ${Platform.numberOfProcessors}

=== APP ===
Version: 3.1.0
Build: Enhanced
MIDI Service: v2.0

=== FEATURES ===
✅ Enhanced MIDI
✅ Adaptive Processing
✅ Device Profiles
✅ Smart Queue Management
✅ Performance Monitoring
✅ Bluetooth State Tracking
✅ Connection Auto-Retry
✅ Device-Specific Optimization

=== DEVICE PROFILES SUPPORTED ===
• WIDI (Uhost, Bud, Bud Pro)
• Yamaha (P-series, Clavinova)
• Roland (FP, RD series)
• Kawai (ES, MP series)
• Casio (Privia, CDP)
• Korg (B2, D1)
• Generic BLE-MIDI devices
''';
  }
}
