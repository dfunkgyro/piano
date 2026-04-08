// ============================================
// bluetooth_debug_panel.dart - BLE/MIDI Diagnostics
// ============================================

import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../services/midi_service.dart';

class BluetoothDebugPanel extends StatefulWidget {
  final MidiService midiService;
  final VoidCallback onClose;

  const BluetoothDebugPanel({
    super.key,
    required this.midiService,
    required this.onClose,
  });

  @override
  State<BluetoothDebugPanel> createState() => _BluetoothDebugPanelState();
}

class _BluetoothDebugPanelState extends State<BluetoothDebugPanel> {
  Timer? _refreshTimer;
  List<Map<String, dynamic>> _bleDevices = [];
  List<Map<String, dynamic>> _midiDevices = [];

  @override
  void initState() {
    super.initState();
    _refresh();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _refresh() {
    setState(() {
      _bleDevices = widget.midiService.getBleScanSnapshot();
      _midiDevices = widget.midiService.getMidiDeviceSnapshot();
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
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildStatusCard(),
                const SizedBox(height: 16),
                _buildLogSection(),
                const SizedBox(height: 16),
                _buildSectionTitle('BLE Scan Results'),
                const SizedBox(height: 8),
                if (_bleDevices.isEmpty)
                  _buildEmptyCard('No BLE devices captured yet.')
                else
                  ..._bleDevices.map(_buildBleCard),
                const SizedBox(height: 16),
                _buildSectionTitle('Web MIDI Inputs'),
                const SizedBox(height: 8),
                if (widget.midiService.webMidiInputs.isEmpty)
                  _buildEmptyCard('No Web MIDI inputs detected.')
                else
                  ...widget.midiService.webMidiInputs.map(_buildWebMidiCard),
                const SizedBox(height: 16),
                _buildSectionTitle('OS MIDI Devices'),
                const SizedBox(height: 8),
                if (_midiDevices.isEmpty)
                  _buildEmptyCard('No OS MIDI devices registered yet.')
                else
                  ..._midiDevices.map(_buildMidiCard),
              ],
            ),
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
            CupertinoIcons.ant_fill,
            size: 22,
            color: CupertinoColors.systemOrange,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Bluetooth Debug',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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

  Widget _buildStatusCard() {
    final state =
        widget.midiService.bluetoothState.toString().split('.').last;
    final webHint =
        'Web Bluetooth: HTTPS + Chrome/Edge required. Click Scan to select a device.';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Connection State',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text('Bluetooth State: $state'),
          if (kIsWeb) Text(webHint),
          Text('Last Scan Error: ${widget.midiService.lastScanError ?? "None"}'),
          if (widget.midiService.lastScanErrorDetail != null)
            Text('Error Detail: ${widget.midiService.lastScanErrorDetail}'),
          Text('Connected: ${widget.midiService.isConnected}'),
          Text(
            'Last MIDI: ${widget.midiService.lastMidiMessage ?? "None"}',
          ),
          Text(
            'MIDI Count: ${widget.midiService.midiMessageCount}',
          ),
          Text(
            'BLE MIDI Subscribed: ${widget.midiService.getDebugStats()['bleMidiSubscribed'] ?? false}',
          ),
        ],
      ),
    );
  }

  Widget _buildLogSection() {
    final log = widget.midiService.getDebugLog().join('\n');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Debug Log',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (log.isEmpty)
            const Text('No debug logs yet.')
          else
            SelectableText(
              log,
              style: const TextStyle(fontSize: 12),
            ),
          const SizedBox(height: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: log.isEmpty
                ? null
                : () => Clipboard.setData(ClipboardData(text: log)),
            child: const Text('Copy Log'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message),
    );
  }

  Widget _buildBleCard(Map<String, dynamic> device) {
    final services = (device['services'] as List?)?.join(', ') ?? '';
    final isMidiByUuid = device['isMidiByUuid'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isMidiByUuid
              ? CupertinoColors.systemGreen.withOpacity(0.4)
              : CupertinoColors.systemGrey5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            device['name']?.toString().isNotEmpty == true
                ? device['name']
                : 'Unnamed BLE Device',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('ID: ${device['id']}'),
          Text('RSSI: ${device['rssi'] ?? "n/a"}'),
          Text('Source: ${device['source']}'),
          Text('MIDI UUID: ${isMidiByUuid ? "yes" : "no"}'),
          if (services.isNotEmpty) Text('Services: $services'),
        ],
      ),
    );
  }

  Widget _buildWebMidiCard(Map<String, String> device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            device['name'] ?? 'MIDI Input',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('ID: ${device['id'] ?? ''}'),
        ],
      ),
    );
  }
  Widget _buildMidiCard(Map<String, dynamic> device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CupertinoColors.systemGrey5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            device['name']?.toString().isNotEmpty == true
                ? device['name']
                : 'Unnamed MIDI Device',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text('ID: ${device['id']}'),
          Text('Type: ${device['type']}'),
          Text('Connected: ${device['connected'] == true ? "yes" : "no"}'),
        ],
      ),
    );
  }
}

