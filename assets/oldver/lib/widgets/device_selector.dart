import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class DeviceSelector extends StatefulWidget {
  final List<Map<String, dynamic>> devices;
  final String? favoriteDeviceId;
  final bool autoConnectEnabled;
  final Function(String deviceId, String deviceName) onConnect;
  final Function() onScan;
  final Function(bool enabled) onAutoConnectChanged;
  final Function(String deviceId) onSetFavorite;
  final bool isScanning;

  const DeviceSelector({
    super.key,
    required this.devices,
    required this.onConnect,
    required this.onScan,
    required this.onAutoConnectChanged,
    required this.onSetFavorite,
    this.favoriteDeviceId,
    this.autoConnectEnabled = true,
    this.isScanning = false,
  });

  @override
  State<DeviceSelector> createState() => _DeviceSelectorState();
}

class _DeviceSelectorState extends State<DeviceSelector> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 600,
      decoration: const BoxDecoration(
        color: CupertinoColors.systemBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          _buildHeader(),
          if (widget.favoriteDeviceId != null) _buildFavoriteBanner(),
          Expanded(
            child: widget.isScanning
                ? _buildScanningView()
                : widget.devices.isEmpty
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
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.bluetooth,
            color: CupertinoColors.activeBlue,
            size: 28,
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
                onChanged: widget.onAutoConnectChanged,
              ),
            ],
          ),
          const SizedBox(width: 8),
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: () => Navigator.pop(context),
            child: const Icon(
              CupertinoIcons.xmark_circle_fill,
              color: CupertinoColors.systemGrey,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriteBanner() {
    final favDevice = widget.devices.firstWhere(
      (d) => d['id'] == widget.favoriteDeviceId,
      orElse: () => {'name': 'Unknown Device'},
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: CupertinoColors.activeBlue.withOpacity(0.1),
      child: Row(
        children: [
          const Icon(
            CupertinoIcons.star_fill,
            color: CupertinoColors.activeBlue,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Favorite Device',
                  style: TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
                Text(
                  favDevice['name'] ?? 'Unknown',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Make sure your device is powered on and in pairing mode',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: CupertinoColors.systemGrey,
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildScanningTips(),
        ],
      ),
    );
  }

  Widget _buildScanningTips() {
    return Container(
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
                color: CupertinoColors.activeBlue,
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
            '• Check device isn\'t connected elsewhere',
            style: TextStyle(fontSize: 12),
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
            const SizedBox(height: 8),
            const Text(
              'Tap scan to search for MIDI devices',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: CupertinoColors.systemGrey,
              ),
            ),
            const SizedBox(height: 32),
            _buildTroubleshootingCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CupertinoColors.systemGrey6,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                CupertinoIcons.wrench,
                color: CupertinoColors.systemOrange,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Troubleshooting',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTroubleshootItem(
            '1. Check Bluetooth',
            'Ensure Bluetooth is enabled in System Settings',
          ),
          _buildTroubleshootItem(
            '2. Device Power',
            'Make sure your MIDI device is powered on',
          ),
          _buildTroubleshootItem(
            '3. Pairing Mode',
            'Put device in pairing/discovery mode',
          ),
          _buildTroubleshootItem(
            '4. Permissions',
            'Grant Bluetooth and Location permissions',
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootItem(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            CupertinoIcons.checkmark_circle,
            size: 18,
            color: CupertinoColors.systemGreen,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: CupertinoColors.systemGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceList() {
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
                '${widget.devices.length} device(s) found',
                style: const TextStyle(
                  fontSize: 13,
                  color: CupertinoColors.systemGrey,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: widget.devices.length,
            itemBuilder: (context, index) {
              final device = widget.devices[index];
              final isFavorite = device['id'] == widget.favoriteDeviceId;
              final isConnected = device['connected'] == true;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isConnected
                      ? CupertinoColors.activeGreen.withOpacity(0.1)
                      : CupertinoColors.systemGrey6,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isConnected
                        ? CupertinoColors.activeGreen
                        : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: CupertinoButton(
                  padding: const EdgeInsets.all(16),
                  onPressed: isConnected
                      ? null
                      : () => widget.onConnect(device['id'], device['name']),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isConnected
                              ? CupertinoColors.activeGreen
                              : CupertinoColors.activeBlue,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getDeviceIcon(device['type']),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    device['name'] ?? 'Unknown Device',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: CupertinoColors.black,
                                    ),
                                  ),
                                ),
                                if (isFavorite)
                                  const Icon(
                                    CupertinoIcons.star_fill,
                                    color: CupertinoColors.systemYellow,
                                    size: 18,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${device['type'] ?? 'MIDI'} • ${device['rssi'] ?? 'BLE'}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isConnected)
                        const Icon(
                          CupertinoIcons.checkmark_circle_fill,
                          color: CupertinoColors.activeGreen,
                          size: 24,
                        )
                      else
                        CupertinoButton(
                          padding: EdgeInsets.zero,
                          onPressed: () => widget.onSetFavorite(device['id']),
                          child: Icon(
                            isFavorite
                                ? CupertinoIcons.star_fill
                                : CupertinoIcons.star,
                            color: isFavorite
                                ? CupertinoColors.systemYellow
                                : CupertinoColors.systemGrey,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: CupertinoColors.systemGrey5,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoButton.filled(
              onPressed: widget.isScanning ? null : widget.onScan,
              child: widget.isScanning
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CupertinoActivityIndicator(
                            color: Colors.white, radius: 10),
                        SizedBox(width: 8),
                        Text('Scanning...'),
                      ],
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.arrow_clockwise, size: 20),
                        SizedBox(width: 8),
                        Text('Scan for Devices'),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String? type) {
    switch (type?.toLowerCase()) {
      case 'ble':
      case 'bluetooth':
        return CupertinoIcons.bluetooth;
      case 'usb':
        return CupertinoIcons.device_laptop;
      case 'widi':
        return CupertinoIcons.wifi;
      default:
        return CupertinoIcons.music_note_2;
    }
  }
}
