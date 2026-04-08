import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'connection_manager_service.dart';

class ConnectionHistoryScreen extends StatefulWidget {
  final Function(String deviceId, String deviceName)? onDeviceSelected;

  const ConnectionHistoryScreen({
    super.key,
    this.onDeviceSelected,
  });

  @override
  State<ConnectionHistoryScreen> createState() =>
      _ConnectionHistoryScreenState();
}

class _ConnectionHistoryScreenState extends State<ConnectionHistoryScreen> {
  bool _autoConnectEnabled = true;

  @override
  void initState() {
    super.initState();
    _autoConnectEnabled = ConnectionManagerService.autoConnectEnabled;
  }

  Future<void> _toggleAutoConnect(bool enabled) async {
    await ConnectionManagerService.setAutoConnectEnabled(enabled);
    setState(() => _autoConnectEnabled = enabled);

    _showMessage(
      enabled
          ? 'Auto-connect enabled. Will connect to selected device on startup.'
          : 'Auto-connect disabled.',
    );
  }

  Future<void> _setDeviceAutoConnect(
      SavedDevice device, bool autoConnect) async {
    await ConnectionManagerService.setDeviceAutoConnect(device.id, autoConnect);
    setState(() {});

    if (autoConnect) {
      _showMessage('${device.name} will auto-connect on startup');
    } else {
      _showMessage('Auto-connect disabled for ${device.name}');
    }
  }

  Future<void> _removeDevice(SavedDevice device) async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Remove Device'),
        content: Text('Remove ${device.name} from connection history?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ConnectionManagerService.removeDevice(device.id);
      setState(() {});
      _showMessage('${device.name} removed from history');
    }
  }

  Future<void> _clearAllDevices() async {
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Clear All History'),
        content: const Text(
          'This will remove all saved devices and auto-connect settings. Are you sure?',
        ),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ConnectionManagerService.clearAllDevices();
      setState(() {});
      _showMessage('All connection history cleared');
    }
  }

  void _showMessage(String message) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    return '${(diff.inDays / 30).floor()}mo ago';
  }

  @override
  Widget build(BuildContext context) {
    final savedDevices = ConnectionManagerService.savedDevices;

    return CupertinoPageScaffold(
      backgroundColor: const Color(0xFF1C1C1E),
      navigationBar: CupertinoNavigationBar(
        backgroundColor: const Color(0xFF2C2C2E),
        middle: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.clock_fill, size: 20, color: Colors.white),
            SizedBox(width: 8),
            Text('Connection History', style: TextStyle(color: Colors.white)),
          ],
        ),
        trailing: savedDevices.isNotEmpty
            ? CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _clearAllDevices,
                child: const Icon(
                  CupertinoIcons.trash,
                  color: CupertinoColors.systemRed,
                ),
              )
            : null,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Auto-Connect Toggle
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: CupertinoColors.systemBlue.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      CupertinoIcons.bolt_fill,
                      color: CupertinoColors.systemBlue,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Auto-Connect',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Automatically connect to selected device on startup',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  CupertinoSwitch(
                    value: _autoConnectEnabled,
                    onChanged: _toggleAutoConnect,
                    activeColor: CupertinoColors.systemBlue,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Saved Devices
            if (savedDevices.isEmpty)
              _buildEmptyState()
            else ...[
              const Row(
                children: [
                  Icon(
                    CupertinoIcons.memories,
                    size: 20,
                    color: Colors.white70,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Saved Devices',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ...savedDevices.map((device) => _buildDeviceCard(device)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Icon(
            CupertinoIcons.bluetooth,
            size: 80,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'No Saved Devices',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Connect to a MIDI device to see it here',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceCard(SavedDevice device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF2C2C2E),
        borderRadius: BorderRadius.circular(12),
        border: device.autoConnect
            ? Border.all(color: CupertinoColors.systemBlue, width: 2)
            : null,
      ),
      child: Column(
        children: [
          CupertinoButton(
            padding: EdgeInsets.zero,
            onPressed: widget.onDeviceSelected != null
                ? () => widget.onDeviceSelected!(device.id, device.name)
                : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: device.autoConnect
                          ? CupertinoColors.systemBlue.withOpacity(0.2)
                          : CupertinoColors.systemGrey.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      device.autoConnect
                          ? CupertinoIcons.bolt_circle_fill
                          : CupertinoIcons.music_note_2,
                      color: device.autoConnect
                          ? CupertinoColors.systemBlue
                          : CupertinoColors.systemGrey,
                      size: 24,
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
                                device.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            if (device.autoConnect)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemBlue
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      CupertinoIcons.bolt_fill,
                                      size: 10,
                                      color: CupertinoColors.systemBlue,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'AUTO',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: CupertinoColors.systemBlue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              device.type,
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '•',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDate(device.lastConnected),
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              '•',
                              style: TextStyle(
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${device.connectionCount}× connected',
                              style: const TextStyle(
                                fontSize: 12,
                                color: CupertinoColors.systemGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (widget.onDeviceSelected != null)
                    const Icon(
                      CupertinoIcons.chevron_right,
                      color: CupertinoColors.systemGrey,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          Container(
            height: 1,
            color: Colors.white.withOpacity(0.1),
          ),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  onPressed: () =>
                      _setDeviceAutoConnect(device, !device.autoConnect),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        device.autoConnect
                            ? CupertinoIcons.bolt_slash
                            : CupertinoIcons.bolt_fill,
                        size: 16,
                        color: device.autoConnect
                            ? CupertinoColors.systemOrange
                            : CupertinoColors.systemBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        device.autoConnect ? 'Disable Auto' : 'Enable Auto',
                        style: TextStyle(
                          fontSize: 13,
                          color: device.autoConnect
                              ? CupertinoColors.systemOrange
                              : CupertinoColors.systemBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: Colors.white.withOpacity(0.1),
              ),
              Expanded(
                child: CupertinoButton(
                  onPressed: () => _removeDevice(device),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        CupertinoIcons.trash,
                        size: 16,
                        color: CupertinoColors.systemRed,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Remove',
                        style: TextStyle(
                          fontSize: 13,
                          color: CupertinoColors.systemRed,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
