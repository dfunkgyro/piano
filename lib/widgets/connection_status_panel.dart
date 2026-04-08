// ============================================
// connection_status_panel.dart - Bluetooth Device Manager
// ============================================

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../services/midi_service.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/permission_helper.dart';
import 'bluetooth_debug_panel.dart';

class ConnectionStatusPanel extends StatefulWidget {
  final MidiService midiService;
  final bool isConnected;
  final String deviceName;
  final String deviceType;
  final VoidCallback onClose;

  const ConnectionStatusPanel({
    super.key,
    required this.midiService,
    required this.isConnected,
    required this.deviceName,
    required this.deviceType,
    required this.onClose,
  });

  @override
  State<ConnectionStatusPanel> createState() => _ConnectionStatusPanelState();
}

class _ConnectionStatusPanelState extends State<ConnectionStatusPanel> {
  List<Map<String, dynamic>> _devices = [];
  bool _isScanning = false;
  String? _selectedDeviceId;

  @override
  void initState() {
    super.initState();
    if (!widget.isConnected) {
      _ensurePermissionsAndScan();
    }
  }

  Future<void> _ensurePermissionsAndScan() async {
    final granted =
        await PermissionHelper.requestBluetoothPermissions(context);
    if (!granted) {
      setState(() {});
      return;
    }

    final ok = await widget.midiService.ensurePermissionsAndServices();
    if (!ok) {
      setState(() {});
      return;
    }
    await _startScan();
  }

  Future<void> _startScan() async {
    setState(() => _isScanning = true);

    try {
      final devices = await widget.midiService.scanForDevices();
      setState(() {
        _devices = devices;
        _isScanning = false;
      });
    } catch (e) {
      setState(() => _isScanning = false);
      _showError('Scan failed: $e');
    }
  }

  Future<void> _connectToDevice(String deviceId, String deviceName) async {
    final device = _devices.firstWhere(
      (d) => d['id'] == deviceId,
      orElse: () => {},
    );
    final isBleOnly = device['isBleOnly'] == true;
    if (isBleOnly) {
      final proceed = await _confirmBleConnect(deviceName);
      if (!proceed) return;
    }

    setState(() => _selectedDeviceId = deviceId);

    try {
      final bleDeviceId = device['bleDeviceId'] as String?;
      await widget.midiService.connectToDevice(
        deviceId,
        deviceName,
        bleDeviceId: bleDeviceId,
        nameOnly: isBleOnly,
      );
      // Connection successful, close panel
      await Future.delayed(const Duration(milliseconds: 500));
      widget.onClose();
    } catch (e) {
      setState(() => _selectedDeviceId = null);
      _showError('Connection failed: $e');
    }
  }

  Future<bool> _confirmBleConnect(String deviceName) async {
    bool proceed = false;
    await showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Connect via BLE'),
        content: Text(
          'This device is listed as BLE only. The app will perform a BLE '
          'handshake and then wait for the OS MIDI device to appear.\n\n'
          'Continue connecting to "$deviceName"?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            onPressed: () {
              proceed = true;
              Navigator.pop(context);
            },
            isDefaultAction: true,
            child: const Text('Connect'),
          ),
        ],
      ),
    );
    return proceed;
  }

  Future<void> _disconnect() async {
    try {
      await widget.midiService.disconnect();
      setState(() {});
    } catch (e) {
      _showError('Disconnect failed: $e');
    }
  }

  void _showError(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            child: const Text('OK'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
          if (widget.isConnected)
            _buildConnectedView()
          else
            Expanded(child: _buildDeviceList()),
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
            CupertinoIcons.bluetooth,
            size: 24,
            color: CupertinoColors.activeBlue,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'MIDI Devices',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (!widget.isConnected && !_isScanning)
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: _ensurePermissionsAndScan,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: CupertinoColors.activeBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.refresh,
                      size: 16,
                      color: Colors.white,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => _showBluetoothDebug(),
            child: const Icon(CupertinoIcons.ant_fill),
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

  void _showBluetoothDebug() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => BluetoothDebugPanel(
        midiService: widget.midiService,
        onClose: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildConnectedView() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: CupertinoColors.systemGreen.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Icon(
                CupertinoIcons.checkmark_circle_fill,
                size: 80,
                color: CupertinoColors.systemGreen,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Connected',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: CupertinoColors.systemGreen,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.deviceName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: CupertinoColors.systemGrey5,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                widget.deviceType,
                style: const TextStyle(
                  fontSize: 14,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildConnectionStats(),
            const SizedBox(height: 32),
            CupertinoButton(
              color: CupertinoColors.destructiveRed,
              onPressed: _disconnect,
              child: const Text('Disconnect'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildStatRow(
            'Queue Size',
            '${widget.midiService.queueSize}',
            CupertinoIcons.list_bullet,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Dropped Packets',
            '${widget.midiService.droppedPackets}',
            CupertinoIcons.exclamationmark_triangle,
          ),
          const Divider(height: 24),
          _buildStatRow(
            'Bluetooth State',
            widget.midiService.bluetoothState.toString().split('.').last,
            CupertinoIcons.antenna_radiowaves_left_right,
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: CupertinoColors.systemGrey),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: CupertinoColors.activeBlue,
          ),
        ),
      ],
    );
  }

  Widget _buildDeviceList() {
    if (_isScanning) {
      return _buildScanningView();
    }

    if (_devices.isEmpty) {
      return _buildEmptyView();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _devices.length,
      itemBuilder: (context, index) {
        final device = _devices[index];
        return _buildDeviceCard(device);
      },
    );
  }

  Widget _buildScanningView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CupertinoActivityIndicator(radius: 20),
          const SizedBox(height: 24),
          const Text(
            'Scanning for MIDI devices...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Make sure your device is powered on\nand in pairing mode',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: CupertinoColors.systemGrey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    final lastError = widget.midiService.lastScanError;
    final needsSettings = lastError != null &&
        (lastError.toLowerCase().contains('permission') ||
            lastError.toLowerCase().contains('location') ||
            lastError.toLowerCase().contains('bluetooth'));

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.exclamationmark_circle,
              size: 64,
              color: CupertinoColors.systemGrey,
            ),
            const SizedBox(height: 24),
            const Text(
              'No devices found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Make sure your MIDI device is:\n'
              '• Powered on\n'
              '• In pairing mode\n'
              '• Within range (10 meters)\n'
              '• Not connected to another device',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 32),
            CupertinoButton.filled(
              onPressed: _ensurePermissionsAndScan,
              child: const Text('Scan Again'),
            ),
            if (needsSettings) ...[
              const SizedBox(height: 12),
              CupertinoButton(
                onPressed: () => openAppSettings(),
                child: const Text('Open Settings'),
              ),
              const SizedBox(height: 4),
              const Text(
                'Allow Nearby Devices + Location',
                style: TextStyle(fontSize: 12),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(Map<String, dynamic> device) {
    final deviceId = device['id'] as String;
    final deviceName = device['name'] as String;
    final deviceType = device['type'] as String;
    final isReliable = device['isReliable'] as bool? ?? false;
    final isBleOnly = device['isBleOnly'] as bool? ?? false;
    final isConnecting = _selectedDeviceId == deviceId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: CupertinoButton(
        padding: EdgeInsets.zero,
        onPressed:
            isConnecting ? null : () => _connectToDevice(deviceId, deviceName),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CupertinoColors.systemBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isReliable
                  ? CupertinoColors.systemGreen.withOpacity(0.3)
                  : CupertinoColors.systemGrey5,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isReliable
                      ? CupertinoColors.systemGreen.withOpacity(0.1)
                      : CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getDeviceIcon(deviceType),
                  size: 28,
                  color: isReliable
                      ? CupertinoColors.systemGreen
                      : CupertinoColors.systemGrey,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            deviceName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isReliable)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  CupertinoColors.systemGreen.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'VERIFIED',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.systemGreen,
                              ),
                            ),
                          ),
                        if (isBleOnly)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: CupertinoColors.systemOrange
                                  .withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'BLE ONLY',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: CupertinoColors.systemOrange,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isBleOnly
                          ? '$deviceType (not MIDI)'
                          : deviceType,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isConnecting)
                const CupertinoActivityIndicator()
              else
                const Icon(
                  CupertinoIcons.arrow_right_circle_fill,
                  color: CupertinoColors.activeBlue,
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getDeviceIcon(String deviceType) {
    final typeLower = deviceType.toLowerCase();

    if (typeLower.contains('widi')) {
      return CupertinoIcons.antenna_radiowaves_left_right;
    } else if (typeLower.contains('yamaha') ||
        typeLower.contains('roland') ||
        typeLower.contains('kawai')) {
      return CupertinoIcons.music_note_2;
    } else if (typeLower.contains('piano') || typeLower.contains('keyboard')) {
      return CupertinoIcons.music_note;
    }

    return CupertinoIcons.device_desktop;
  }
}
