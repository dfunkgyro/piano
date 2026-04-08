import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';

import '../services/connection_manager_service.dart';
import '../services/external_link.dart';
import '../services/midi_service_lite.dart';
import '../services/web_transport_capability.dart';

class ConnectionWizardButton extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;

  const ConnectionWizardButton({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.24),
            blurRadius: 18,
            spreadRadius: -6,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        color: backgroundColor.withOpacity(0.9),
        borderRadius: BorderRadius.circular(999),
        onPressed: () => showCupertinoModalPopup<void>(
          context: context,
          builder: (context) => ConnectionWizardSheet(
            backgroundColor: backgroundColor,
            textColor: textColor,
            accentColor: accentColor,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.dot_radiowaves_left_right, color: accentColor, size: 18),
            const SizedBox(width: 8),
            Text(
              'Connect',
              style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ConnectionWizardSheet extends StatefulWidget {
  final Color backgroundColor;
  final Color textColor;
  final Color accentColor;

  const ConnectionWizardSheet({
    super.key,
    required this.backgroundColor,
    required this.textColor,
    required this.accentColor,
  });

  @override
  State<ConnectionWizardSheet> createState() => _ConnectionWizardSheetState();
}

class _ConnectionWizardSheetState extends State<ConnectionWizardSheet> {
  final MidiServiceLite _midi = MidiServiceLite.instance;
  StreamSubscription<List<MidiDeviceInfo>>? _devicesSub;
  StreamSubscription<String>? _statusSub;
  List<MidiDeviceInfo> _devices = const [];
  List<SavedDevice> _savedDevices = const [];
  String _status = 'Ready';
  bool _autoConnect = true;
  bool _preferBle = true;
  bool _loading = true;
  bool _busy = false;
  WebTransportCapability? _webCapability;
  bool _bridgeReachable = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await ConnectionManagerService.initialize();
    _devices = _midi.devices;
    _autoConnect = _midi.autoConnectEnabled;
    _preferBle = _midi.preferBle;
    _savedDevices = ConnectionManagerService.savedDevices;
    _webCapability = await detectWebTransportCapability(
      bridgeConnected: _midi.bridgeConnected,
    );
    _bridgeReachable = await _midi.probeBridge();
    _devicesSub = _midi.devicesStream.listen((devices) {
      if (!mounted) return;
      setState(() => _devices = devices);
    });
    _statusSub = _midi.status.listen((status) async {
      final capability = await detectWebTransportCapability(
        bridgeConnected: _midi.bridgeConnected,
      );
      final bridgeReachable = await _midi.probeBridge();
      if (!mounted) return;
      setState(() {
        _status = status;
        _webCapability = capability;
        _bridgeReachable = bridgeReachable;
      });
    });
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _devicesSub?.cancel();
    _statusSub?.cancel();
    super.dispose();
  }

  Future<void> _scan() async {
    await _midi.scan();
    await ConnectionManagerService.initialize();
    final capability = await detectWebTransportCapability(
      bridgeConnected: _midi.bridgeConnected,
    );
    final bridgeReachable = await _midi.probeBridge();
    if (!mounted) return;
    setState(() {
      _savedDevices = ConnectionManagerService.savedDevices;
      _webCapability = capability;
      _bridgeReachable = bridgeReachable;
    });
  }

  Future<void> _connect(String deviceId) async {
    setState(() => _busy = true);
    await _midi.connect(deviceId);
    await ConnectionManagerService.initialize();
    final capability = await detectWebTransportCapability(
      bridgeConnected: _midi.bridgeConnected,
    );
    final bridgeReachable = await _midi.probeBridge();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _savedDevices = ConnectionManagerService.savedDevices;
      _webCapability = capability;
      _bridgeReachable = bridgeReachable;
    });
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    await _midi.disconnect();
    final capability = await detectWebTransportCapability(
      bridgeConnected: _midi.bridgeConnected,
    );
    final bridgeReachable = await _midi.probeBridge();
    if (!mounted) return;
    setState(() {
      _busy = false;
      _webCapability = capability;
      _bridgeReachable = bridgeReachable;
    });
  }

  Future<void> _setAutoConnect(bool value) async {
    await _midi.setAutoConnect(value);
    await ConnectionManagerService.setAutoConnectEnabled(value);
    if (!mounted) return;
    setState(() => _autoConnect = value);
  }

  Future<void> _setPreferBle(bool value) async {
    await _midi.setPreferBle(value);
    if (!mounted) return;
    setState(() => _preferBle = value);
  }

  Future<void> _setWebTransportPreference(WebTransportPreference value) async {
    await _midi.setWebTransportPreference(value);
    final capability = await detectWebTransportCapability(
      bridgeConnected: _midi.bridgeConnected,
    );
    if (!mounted) return;
    setState(() => _webCapability = capability);
  }

  Future<void> _setDeviceAutoConnect(String id, bool value) async {
    await ConnectionManagerService.setDeviceAutoConnect(id, value);
    if (!mounted) return;
    setState(() => _savedDevices = ConnectionManagerService.savedDevices);
  }

  Future<void> _removeSavedDevice(String id) async {
    await ConnectionManagerService.removeDevice(id);
    if (!mounted) return;
    setState(() => _savedDevices = ConnectionManagerService.savedDevices);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final midiDevices =
        _devices.where((d) => d.isMidiCompatible && d.id != 'bridge').toList();
    final bluetoothDevices = _devices.where((d) => d.isBluetooth).toList();
    final otherDevices = _devices
        .where((d) => !d.isBluetooth && !d.isMidiCompatible && d.id != 'bridge')
        .toList();
    final savedHardwareDevices =
        _savedDevices.where((device) => device.id != 'bridge').toList();

    return CupertinoPopupSurface(
      isSurfacePainted: false,
      child: Container(
        color: widget.backgroundColor.withOpacity(0.98),
        padding: EdgeInsets.only(bottom: bottomInset),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 680,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bluetooth / MIDI Wizard',
                              style: TextStyle(
                                color: widget.textColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _status,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: widget.textColor.withOpacity(0.7),
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              kIsWeb
                                  ? 'Web app: connect to the real MIDI device directly with Web MIDI or Web Bluetooth. The bridge is a localhost helper, not a Bluetooth target.'
                                  : 'APK/native app: Bluetooth and USB work directly. Wi-Fi bridge is optional.',
                              style: TextStyle(
                                color: widget.textColor.withOpacity(0.56),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        onPressed: () => Navigator.of(context).pop(),
                        child: Icon(
                          CupertinoIcons.clear_circled_solid,
                          color: widget.textColor.withOpacity(0.7),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _toggleChip(
                        label: _autoConnect ? 'Auto Connect: ON' : 'Auto Connect: OFF',
                        value: _autoConnect,
                        onChanged: _setAutoConnect,
                      ),
                      const SizedBox(width: 8),
                      _toggleChip(
                        label: _preferBle ? 'Prefer BLE: ON' : 'Prefer BLE: OFF',
                        value: _preferBle,
                        onChanged: _setPreferBle,
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: widget.accentColor.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _busy ? null : _scan,
                        child: Text(
                          _busy || _midi.isScanning ? 'Scanning...' : 'Scan Devices',
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      CupertinoButton(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: widget.textColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        onPressed: _busy ? null : _disconnect,
                        child: Text(
                          'Disconnect',
                          style: TextStyle(
                            color: widget.textColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _loading
                      ? const Center(child: CupertinoActivityIndicator())
                      : ListView(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          children: [
                            if (kIsWeb && _webCapability != null) ...[
                              _sectionTitle('Web Transport'),
                              _webTransportCard(_webCapability!),
                              const SizedBox(height: 12),
                              _sectionTitle('Local Bridge Helper'),
                              _bridgeHelperCard(),
                              const SizedBox(height: 12),
                            ],
                            _sectionTitle('Quick Reconnect'),
                            if (savedHardwareDevices.isEmpty)
                              _emptyText('No remembered devices yet.')
                            else
                              ...savedHardwareDevices.take(3).map(_savedDeviceCard),
                            const SizedBox(height: 12),
                            _sectionTitle('MIDI-Compatible Devices'),
                            if (midiDevices.isEmpty)
                              _emptyText('No MIDI-compatible devices found yet.')
                            else
                              ...midiDevices.map(_availableDeviceCard),
                            const SizedBox(height: 12),
                            _sectionTitle('All Bluetooth Devices'),
                            if (bluetoothDevices.isEmpty)
                              _emptyText('No Bluetooth LE devices found. Grant Bluetooth and location permission, then scan again.')
                            else
                              ...bluetoothDevices.map(_availableDeviceCard),
                            if (otherDevices.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              _sectionTitle('Other Available Devices'),
                              ...otherDevices.map(_availableDeviceCard),
                            ],
                            const SizedBox(height: 12),
                            _sectionTitle('Remembered Devices'),
                            if (savedHardwareDevices.isEmpty)
                              _emptyText('Saved devices will appear here after connecting.')
                            else
                              ...savedHardwareDevices.map(_savedDeviceDetailCard),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _toggleChip({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: widget.textColor.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.textColor.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: widget.textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(
            value: value,
            activeColor: widget.accentColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: widget.textColor,
          fontSize: 15,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: TextStyle(
          color: widget.textColor.withOpacity(0.64),
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _webTransportCard(WebTransportCapability capability) {
    final recommendationColor = switch (capability.recommendation) {
      WebTransportRecommendation.nativeWeb => CupertinoColors.systemGreen,
      WebTransportRecommendation.bridgeRecommended => CupertinoColors.systemOrange,
      WebTransportRecommendation.bridgeRequired => CupertinoColors.systemRed,
    };

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.textColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${capability.browserLabel} on ${capability.osLabel}',
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: recommendationColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  switch (capability.recommendation) {
                    WebTransportRecommendation.nativeWeb => 'Direct Device Access',
                    WebTransportRecommendation.bridgeRecommended => 'Bridge Recommended',
                    WebTransportRecommendation.bridgeRequired => 'Bridge Required',
                  },
                  style: TextStyle(
                    color: recommendationColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            capability.reason,
            style: TextStyle(
              color: widget.textColor.withOpacity(0.72),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _transportPrefButton(
                'Auto',
                _midi.webTransportPreference == WebTransportPreference.auto,
                () => _setWebTransportPreference(WebTransportPreference.auto),
              ),
              _transportPrefButton(
                'Direct Device',
                _midi.webTransportPreference == WebTransportPreference.webBluetooth,
                () => _setWebTransportPreference(WebTransportPreference.webBluetooth),
              ),
              _transportPrefButton(
                'Bridge',
                _midi.webTransportPreference == WebTransportPreference.bridge,
                () => _setWebTransportPreference(WebTransportPreference.bridge),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Detected: Web Bluetooth ${capability.bluetoothSupported ? "yes" : "no"}  •  Web MIDI ${capability.webMidiSupported ? "yes" : "no"}  •  Web Serial ${capability.webSerialSupported ? "yes" : "no"}',
            style: TextStyle(
              color: widget.textColor.withOpacity(0.62),
              fontSize: 11,
            ),
          ),
          if (capability.downloadLinks.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Install the local companion app, launch it, connect the real MIDI device there, then return here and use `Connect Bridge`.',
              style: TextStyle(
                color: widget.textColor.withOpacity(0.62),
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: capability.downloadLinks.map((link) {
                return CupertinoButton(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  color: widget.accentColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: () => openExternalLink(link.url),
                  child: Text(
                    link.label,
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                );
              }).toList(),
            ),
            if (capability.downloadLinks.first.version != null) ...[
              const SizedBox(height: 6),
              Text(
                'Recommended bridge version: ${capability.downloadLinks.first.version}',
                style: TextStyle(
                  color: widget.textColor.withOpacity(0.56),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _bridgeHelperCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.textColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Use the bridge only as a localhost helper.',
            style: TextStyle(
              color: widget.textColor,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'The bridge should connect to the real external MIDI device itself, then expose that device to the browser over localhost. It should not appear in Bluetooth scan as if it were the controller.',
            style: TextStyle(
              color: widget.textColor.withOpacity(0.72),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Expected flow: 1) install and launch bridge, 2) connect WIDI/device inside bridge, 3) return to web app, 4) connect bridge over localhost.',
            style: TextStyle(
              color: widget.textColor.withOpacity(0.62),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _bridgeReachable
                ? 'Bridge helper detected on localhost.'
                : 'No bridge helper detected on localhost.',
            style: TextStyle(
              color: _bridgeReachable
                  ? CupertinoColors.systemGreen
                  : widget.textColor.withOpacity(0.62),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  color: widget.accentColor.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(12),
                  onPressed: _busy ? null : () => _connect('bridge'),
                  child: Text(
                    _midi.bridgeConnected ? 'Bridge Connected' : 'Connect Bridge',
                    style: TextStyle(
                      color: widget.textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                color: widget.textColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                onPressed: _busy ? null : _disconnect,
                child: Text(
                  'Disconnect',
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Bridge status: ${_midi.bridgeConnected ? "connected" : "idle"}',
            style: TextStyle(
              color: widget.textColor.withOpacity(0.62),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transportPrefButton(String label, bool active, VoidCallback onPressed) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      color: active
          ? widget.accentColor.withOpacity(0.22)
          : widget.textColor.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: widget.textColor,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _availableDeviceCard(MidiDeviceInfo device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: device.isConnected
              ? widget.accentColor.withOpacity(0.42)
              : widget.textColor.withOpacity(0.08),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${device.source}  •  ${device.id}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: widget.textColor.withOpacity(0.62),
                    fontSize: 11,
                  ),
                ),
                if (device.detail.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    device.detail,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: widget.textColor.withOpacity(0.54),
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: device.isConnected
                ? widget.accentColor.withOpacity(0.16)
                : widget.accentColor,
            borderRadius: BorderRadius.circular(10),
            onPressed: _busy ? null : () => _connect(device.id),
            child: Text(
              device.isConnected ? 'Connected' : 'Connect',
              style: TextStyle(
                color: device.isConnected ? widget.textColor : CupertinoColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedDeviceCard(SavedDevice device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            widget.accentColor.withOpacity(0.18),
            widget.accentColor.withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.accentColor.withOpacity(0.28)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  device.name,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${device.type}  •  ${device.connectionCount} connections',
                  style: TextStyle(
                    color: widget.textColor.withOpacity(0.66),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          CupertinoButton(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: widget.accentColor,
            borderRadius: BorderRadius.circular(10),
            onPressed: _busy ? null : () => _connect(device.id),
            child: const Text(
              'Reconnect',
              style: TextStyle(
                color: CupertinoColors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _savedDeviceDetailCard(SavedDevice device) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.textColor.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  device.name,
                  style: TextStyle(
                    color: widget.textColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: () => _removeSavedDevice(device.id),
                child: Icon(
                  CupertinoIcons.delete_solid,
                  color: CupertinoColors.systemRed.withOpacity(0.9),
                  size: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${device.type}  •  last used ${device.lastConnected.toLocal()}',
            style: TextStyle(
              color: widget.textColor.withOpacity(0.62),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  device.autoConnect ? 'Preferred reconnect device' : 'Set as preferred reconnect device',
                  style: TextStyle(
                    color: widget.textColor.withOpacity(0.72),
                    fontSize: 12,
                  ),
                ),
              ),
              CupertinoSwitch(
                value: device.autoConnect,
                activeColor: widget.accentColor,
                onChanged: (value) => _setDeviceAutoConnect(device.id, value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
