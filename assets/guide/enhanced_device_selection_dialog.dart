import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class EnhancedDeviceSelectionDialog extends StatefulWidget {
  final Function(String deviceId, String deviceName) onConnect;
  final Function() onScan;
  final List<Map<String, dynamic>> availableDevices;
  final bool isScanning;
  final bool autoConnectEnabled;
  final Function(bool) onAutoConnectChanged;
  final String? lastConnectedDevice;

  const EnhancedDeviceSelectionDialog({
    super.key,
    required this.onConnect,
    required this.onScan,
    required this.availableDevices,
    required this.isScanning,
    required this.autoConnectEnabled,
    required this.onAutoConnectChanged,
    this.lastConnectedDevice,
  });

  @override
  State<EnhancedDeviceSelectionDialog> createState() =>
      _EnhancedDeviceSelectionDialogState();
}

class _EnhancedDeviceSelectionDialogState
    extends State<EnhancedDeviceSelectionDialog> {
  String? _connectingDeviceId;
  String _connectionStatus = '';
  double _connectionProgress = 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 650,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (widget.lastConnectedDevice != null) _buildLastDeviceBanner(),
          if (_connectingDeviceId != null) _buildConnectionProgress(),
          Expanded(
            child: widget.isScanning
                ? _buildScanningView()
                : widget.availableDevices.isEmpty
                    ? _buildEmptyView()
                    : _buildDeviceList(),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.bluetooth,
            color: CupertinoColors.activeBlue,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Select MIDI Device',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Auto-Connect',
                style: TextStyle(
                  fontSize: 11,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              CupertinoSwitch(
                value: widget.autoConnectEnabled,
                onChanged: _connectingDeviceId == null
                    ? widget.onAutoConnectChanged
                    : null,
              ),
            ],
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: _connectingDeviceId == null
                ? () => Navigator.pop(context)
                : null,
            child: Icon(
              CupertinoIcons.xmark_circle_fill,
              color: _connectingDeviceId == null
                  ? CupertinoColors.systemGrey
                  : CupertinoColors.systemGrey3,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLastDeviceBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBlue,
        border: Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.arrow_clockwise_circle_fill,
            color: CupertinoColors.white,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Last connected: ${widget.lastConnectedDevice}',
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemBlue.withOpacity(0.1),
        border: const Border(
          bottom: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CupertinoActivityIndicator(radius: 12),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Connecting...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _connectionStatus.isEmpty
                          ? 'Please wait'
                          : _connectionStatus,
                      style: const TextStyle(
                        fontSize: 13,
                        color: CupertinoColors.systemGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(_connectionProgress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: CupertinoColors.systemBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: _connectionProgress,
                backgroundColor: CupertinoColors.systemGrey5,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  CupertinoColors.systemBlue,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScanningView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const CupertinoActivityIndicator(radius: 14),
              const SizedBox(height: 16),
              const Text(
                'Scanning for all nearby devices...',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              const Text(
                'MIDI compatible devices will be selectable.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: widget.availableDevices.isEmpty
              ? _buildScanningTips()
              : _buildDeviceList(isScanning: true),
        ),
      ],
    );
  }

  Widget _buildScanningTips() {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 20),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CupertinoColors.systemBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      CupertinoIcons.lightbulb,
                      color: CupertinoColors.systemBlue,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Scanning Tips',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Text(
                  '• Keep device within 10 meters\n'
                  '• Ensure Bluetooth is enabled\n'
                  '• Turn device off and on if not found\n'
                  '• Check device is not connected elsewhere',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              CupertinoIcons.bluetooth,
              size: 80,
              color: CupertinoColors.systemGrey3,
            ),
            const SizedBox(height: 24),
            const Text(
              'No Devices Found',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tap "Scan Again" to search for devices nearby.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 32),
            CupertinoButton(
              padding: EdgeInsets.zero,
              onPressed: () => openAppSettings(),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.settings, size: 16),
                  SizedBox(width: 6),
                  Text(
                    'Open System Settings',
                    style: TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceList({bool isScanning = false}) {
    final isConnecting = _connectingDeviceId != null;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              const Icon(
                CupertinoIcons.device_laptop,
                size: 18,
                color: CupertinoColors.systemGrey,
              ),
              const SizedBox(width: 8),
              Text(
                '${widget.availableDevices.length} device(s) found',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: CupertinoColors.systemGrey,
                ),
              ),
              if (isConnecting) ...[
                const Spacer(),
                const Text(
                  'Please wait...',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemOrange,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: widget.availableDevices.length,
            itemBuilder: (context, index) {
              final device = widget.availableDevices[index];
              final isConnected = device['connected'] == true;
              final bool isMidi = device['isMidi'] ?? false;
              final isConnectable = isMidi;
              final deviceId = device['id'] as String;
              final deviceName = device['name'] as String;
              final isThisDeviceConnecting = _connectingDeviceId == deviceId;

              // Disable all devices when any connection is in progress
              final isDisabled = isConnecting && !isThisDeviceConnecting;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Opacity(
                  opacity: isDisabled ? 0.5 : 1.0,
                  child: CupertinoButton(
                    padding: EdgeInsets.zero,
                    onPressed: (!isConnectable || isDisabled)
                        ? null
                        : () => _handleDeviceConnect(deviceId, deviceName),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isThisDeviceConnecting
                            ? CupertinoColors.systemBlue.withOpacity(0.1)
                            : (isConnectable
                                ? CupertinoColors.white
                                : CupertinoColors.systemGrey6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isThisDeviceConnecting
                              ? CupertinoColors.systemBlue
                              : (isConnected
                                  ? CupertinoColors.systemGreen
                                  : (isMidi
                                      ? CupertinoColors.systemBlue
                                      : CupertinoColors.systemGrey5)),
                          width:
                              (isConnected || isMidi || isThisDeviceConnecting)
                                  ? 2
                                  : 1,
                        ),
                        boxShadow: isDisabled
                            ? []
                            : [
                                BoxShadow(
                                  color: CupertinoColors.systemGrey
                                      .withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: isThisDeviceConnecting
                                  ? CupertinoColors.systemBlue.withOpacity(0.2)
                                  : (isConnected
                                      ? CupertinoColors.systemGreen
                                          .withOpacity(0.2)
                                      : (isMidi
                                          ? CupertinoColors.systemBlue
                                              .withOpacity(0.1)
                                          : CupertinoColors.systemGrey5)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: isThisDeviceConnecting
                                ? const Center(
                                    child: CupertinoActivityIndicator(
                                      radius: 12,
                                    ),
                                  )
                                : Icon(
                                    isConnected
                                        ? CupertinoIcons.checkmark_circle_fill
                                        : (isMidi
                                            ? CupertinoIcons.music_note_2
                                            : CupertinoIcons.bluetooth),
                                    size: 28,
                                    color: isConnected
                                        ? CupertinoColors.systemGreen
                                        : (isMidi
                                            ? CupertinoColors.systemBlue
                                            : CupertinoColors.systemGrey),
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  deviceName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isMidi
                                          ? CupertinoIcons.music_note_2
                                          : CupertinoIcons.tag_fill,
                                      size: 12,
                                      color: CupertinoColors.systemGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        device['type'] as String,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: CupertinoColors.systemGrey,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isThisDeviceConnecting) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.systemBlue
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        SizedBox(
                                          width: 12,
                                          height: 12,
                                          child: CupertinoActivityIndicator(
                                            radius: 6,
                                          ),
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'CONNECTING...',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: CupertinoColors.systemBlue,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else if (isConnected) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.systemGreen
                                          .withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          CupertinoIcons.checkmark_circle_fill,
                                          size: 12,
                                          color: CupertinoColors.systemGreen,
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          'CONNECTED',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: CupertinoColors.systemGreen,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Icon(
                            isConnectable && !isDisabled
                                ? CupertinoIcons.chevron_right
                                : CupertinoIcons.lock_fill,
                            color: CupertinoColors.systemGrey,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _handleDeviceConnect(String deviceId, String deviceName) async {
    setState(() {
      _connectingDeviceId = deviceId;
      _connectionStatus = 'Initializing...';
      _connectionProgress = 0.0;
    });

    try {
      // Call the connection function
      await widget.onConnect(deviceId, deviceName);

      // Success - dialog will be closed by parent
    } catch (e) {
      // Error occurred
      setState(() {
        _connectingDeviceId = null;
        _connectionStatus = '';
        _connectionProgress = 0.0;
      });

      // Show error
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Connection Failed'),
          content: Text(e.toString()),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildFooter() {
    final isConnecting = _connectingDeviceId != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        border: Border(
          top: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton(
              padding: const EdgeInsets.symmetric(vertical: 14),
              color: CupertinoColors.systemGrey5,
              borderRadius: BorderRadius.circular(12),
              onPressed:
                  (widget.isScanning || isConnecting) ? null : widget.onScan,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    CupertinoIcons.arrow_clockwise,
                    size: 20,
                    color: (widget.isScanning || isConnecting)
                        ? CupertinoColors.systemGrey
                        : CupertinoColors.activeBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (widget.isScanning || isConnecting)
                        ? 'Please Wait...'
                        : 'Scan Again',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: (widget.isScanning || isConnecting)
                          ? CupertinoColors.systemGrey
                          : CupertinoColors.activeBlue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
