import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:universal_ble/universal_ble.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BridgeApp());
}

class BridgeApp extends StatelessWidget {
  const BridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF13B39A),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Gyro MIDI Bridge',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: scheme,
        scaffoldBackgroundColor: const Color(0xFF091015),
        cardTheme: CardThemeData(
          color: const Color(0xFF101A20),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: Colors.white.withOpacity(0.06)),
          ),
        ),
      ),
      home: const BridgeHome(),
    );
  }
}

class _BridgeDevice {
  final String id;
  final String name;
  final bool midiCompatible;
  final int rssi;
  final DateTime seenAt;

  const _BridgeDevice({
    required this.id,
    required this.name,
    required this.midiCompatible,
    required this.rssi,
    required this.seenAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'midiCompatible': midiCompatible,
        'rssi': rssi,
        'seenAt': seenAt.toIso8601String(),
      };
}

class BridgeHome extends StatefulWidget {
  const BridgeHome({super.key});

  @override
  State<BridgeHome> createState() => _BridgeHomeState();
}

class _BridgeHomeState extends State<BridgeHome> {
  static const String _appVersion = '1.1.0';
  static const int _port = 8765;
  static const String _midiServiceUuid =
      '03b80e5a-ede8-4b33-a751-6ce34ec4c700';
  static const String _midiCharacteristicUuid =
      '7772e5db-3868-4112-a1a9-f2669d106bf3';
  static const String _prefLastId = 'last_device_id';
  static const String _prefLastName = 'last_device_name';
  static const String _prefAuto = 'auto_connect';

  final Map<String, _BridgeDevice> _devices = {};
  final List<WebSocket> _clients = [];
  final List<String> _logs = [];

  HttpServer? _server;
  bool _serverRunning = false;
  bool _scanning = false;
  bool _autoConnect = true;
  bool _bleMidiSubscribed = false;
  bool _permissionsGranted = false;

  String _availability = 'unknown';
  String _permissionStatus = 'Unknown';
  String? _connectingDeviceId;
  String? _connectedDeviceId;
  String? _connectedDeviceName;
  String? _lastDeviceId;
  String? _lastDeviceName;

  int _midiCount = 0;
  String _lastMidi = 'None';

  String get _serverBaseUrl => 'http://127.0.0.1:$_port';
  String get _socketUrl => 'ws://127.0.0.1:$_port/midi';

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _loadPrefs();
    _setupBleCallbacks();
    await _ensurePermissions();
    await _startServer();
    if (_autoConnect && _lastDeviceId != null && _permissionsGranted) {
      unawaited(_startScan());
    }
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _lastDeviceId = prefs.getString(_prefLastId);
    _lastDeviceName = prefs.getString(_prefLastName);
    _autoConnect = prefs.getBool(_prefAuto) ?? true;
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _savePrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (_connectedDeviceId != null) {
      await prefs.setString(_prefLastId, _connectedDeviceId!);
    }
    if (_connectedDeviceName != null) {
      await prefs.setString(_prefLastName, _connectedDeviceName!);
    }
    await prefs.setBool(_prefAuto, _autoConnect);
  }


  Future<bool> _ensurePermissions() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      _permissionsGranted = true;
      _permissionStatus = 'Not required';
      if (mounted) setState(() {});
      return true;
    }

    final permissions = <Permission>[
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    final statuses = <String>[];
    var granted = true;
    for (final permission in permissions) {
      try {
        var status = await permission.status;
        if (!status.isGranted) {
          status = await permission.request();
        }
        statuses.add('$permission=$status');
        if (!status.isGranted && !status.isLimited) {
          granted = false;
        }
      } catch (error) {
        statuses.add('$permission=error:$error');
      }
    }

    _permissionsGranted = granted;
    _permissionStatus = statuses.join('  ?  ');
    _log('Permission status: $_permissionStatus');
    if (mounted) setState(() {});
    return granted;
  }

  void _setupBleCallbacks() {
    UniversalBle.onAvailabilityChange = (state) {
      _availability = '$state';
      _log('Bluetooth availability: $state');
      if (mounted) {
        setState(() {});
      }
      _broadcastStatus();
    };

    UniversalBle.onScanResult = (result) {
      final device = _mapScanResult(result);
      _devices[device.id] = device;
      if (_autoConnect &&
          _lastDeviceId != null &&
          _lastDeviceId == device.id &&
          _connectedDeviceId != device.id &&
          _connectingDeviceId != device.id) {
        unawaited(_connectToDevice(device.id));
      }
      if (mounted) {
        setState(() {});
      }
      _broadcastDeviceList();
    };

    UniversalBle.onConnectionChanged = (deviceId, state) {
      _log('Connection state: $deviceId $state');
      final disconnected = '$state'.toLowerCase().contains('disconnect');
      if (disconnected && _connectedDeviceId == deviceId) {
        _connectedDeviceId = null;
        _connectedDeviceName = null;
        _bleMidiSubscribed = false;
      }
      if (mounted) {
        setState(() {});
      }
      _broadcastStatus();
    };

    UniversalBle.onValueChanged = (deviceId, characteristic, value) {
      if (characteristic.toLowerCase() !=
          _midiCharacteristicUuid.toLowerCase()) {
        return;
      }
      final messages = _extractBleMidiMessages(value);
      if (messages.isNotEmpty) {
        _log('BLE MIDI received: ${messages.length} message(s)');
      }
      for (final msg in messages) {
        _midiCount += 1;
        _lastMidi = msg.join(',');
        _broadcast({
          'type': 'midi',
          'data': msg,
          'ts': DateTime.now().millisecondsSinceEpoch,
        });
      }
      if (messages.isNotEmpty && mounted) {
        setState(() {});
      }
      if (messages.isNotEmpty) {
        _broadcastStatus();
      }
    };
  }

  _BridgeDevice _mapScanResult(BleScanResult result) {
    final rawName = result.name?.trim();
    final name =
        rawName == null || rawName.isEmpty ? result.deviceId : rawName;
    final lower = name.toLowerCase();
    final advertisedServices =
        result.services.map((value) => value.toLowerCase()).toList();

    final midiCompatible = advertisedServices.any(
          (uuid) => uuid.contains(_midiServiceUuid),
        ) ||
        lower.contains('widi') ||
        lower.contains('midi');

    return _BridgeDevice(
      id: result.deviceId,
      name: name,
      midiCompatible: midiCompatible,
      rssi: result.rssi ?? 0,
      seenAt: DateTime.now(),
    );
  }

  Future<void> _startServer() async {
    if (_serverRunning) {
      return;
    }

    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, _port);
    _serverRunning = true;
    _log('Local bridge server listening on $_serverBaseUrl');

    _server!.listen((request) async {
      try {
        final path = request.uri.path;
        if (WebSocketTransformer.isUpgradeRequest(request) && path == '/midi') {
          final socket = await WebSocketTransformer.upgrade(request);
          _clients.add(socket);
          _log('Web app connected (${_clients.length})');
          _sendInitialState(socket);
          socket.done.whenComplete(() {
            _clients.remove(socket);
            _log('Web app disconnected (${_clients.length})');
            if (mounted) {
              setState(() {});
            }
            _broadcastStatus();
          });
          if (mounted) {
            setState(() {});
          }
          _broadcastStatus();
          return;
        }

        if (request.method == 'GET' && path == '/status') {
          _jsonResponse(request, _statusPayload());
          return;
        }
        if (request.method == 'GET' && path == '/devices') {
          _jsonResponse(request, {
            'devices': _sortedDevices().map((device) => device.toJson()).toList(),
          });
          return;
        }
        if (request.method == 'GET' && path == '/logs') {
          _jsonResponse(request, {'logs': _logs});
          return;
        }
        if (request.method == 'POST' && path == '/scan') {
          await _startScan();
          _jsonResponse(request, {
            'ok': true,
            'devices': _sortedDevices().map((device) => device.toJson()).toList(),
          });
          return;
        }
        if (request.method == 'POST' && path == '/connect') {
          final body = await utf8.decoder.bind(request).join();
          final data = body.trim().isEmpty
              ? <String, dynamic>{}
              : jsonDecode(body) as Map<String, dynamic>;
          final deviceId = '${data['deviceId'] ?? ''}'.trim();
          if (deviceId.isEmpty) {
            _jsonResponse(
              request,
              {'ok': false, 'error': 'deviceId_required'},
              statusCode: HttpStatus.badRequest,
            );
            return;
          }
          await _connectToDevice(deviceId);
          _jsonResponse(request, _statusPayload());
          return;
        }
        if (request.method == 'POST' && path == '/disconnect') {
          await _disconnect();
          _jsonResponse(request, _statusPayload());
          return;
        }

        _jsonResponse(
          request,
          {'ok': false, 'error': 'not_found'},
          statusCode: HttpStatus.notFound,
        );
      } catch (error) {
        _log('HTTP bridge error: $error');
        _jsonResponse(
          request,
          {'ok': false, 'error': '$error'},
          statusCode: HttpStatus.internalServerError,
        );
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _stopServer() async {
    await _server?.close(force: true);
    _server = null;
    _serverRunning = false;
    _log('Local bridge server stopped');
    if (mounted) {
      setState(() {});
    }
    _broadcastStatus();
  }

  void _jsonResponse(
    HttpRequest request,
    Map<String, dynamic> payload, {
    int statusCode = HttpStatus.ok,
  }) {
    request.response
      ..statusCode = statusCode
      ..headers.contentType = ContentType.json
      ..headers.set('Access-Control-Allow-Origin', '*')
      ..headers.set('Access-Control-Allow-Headers', '*')
      ..write(jsonEncode(payload));
    request.response.close();
  }

  Map<String, dynamic> _statusPayload() {
    return {
      'ok': true,
      'name': 'Gyro MIDI Bridge',
      'version': _appVersion,
      'serverRunning': _serverRunning,
      'serverUrl': _socketUrl,
      'httpUrl': _serverBaseUrl,
      'clientCount': _clients.length,
      'availability': _availability,
      'connected': _connectedDeviceId != null,
      'connectedDeviceId': _connectedDeviceId,
      'connectedDeviceName': _connectedDeviceName,
      'bleMidiSubscribed': _bleMidiSubscribed,
      'autoConnect': _autoConnect,
      'lastDeviceId': _lastDeviceId,
      'lastDeviceName': _lastDeviceName,
      'midiCount': _midiCount,
      'lastMidi': _lastMidi,
      'scanning': _scanning,
    };
  }

  void _sendInitialState(WebSocket socket) {
    socket.add(jsonEncode({'type': 'status', ..._statusPayload()}));
    socket.add(jsonEncode({
      'type': 'device_list',
      'devices': _sortedDevices().map((device) => device.toJson()).toList(),
    }));
  }

  void _broadcastStatus() {
    _broadcast({'type': 'status', ..._statusPayload()});
  }

  void _broadcastDeviceList() {
    _broadcast({
      'type': 'device_list',
      'devices': _sortedDevices().map((device) => device.toJson()).toList(),
    });
  }

  void _broadcast(Map<String, dynamic> payload) {
    final data = jsonEncode(payload);
    for (final client in List<WebSocket>.from(_clients)) {
      try {
        client.add(data);
      } catch (_) {
        _clients.remove(client);
      }
    }
  }

  Future<void> _startScan() async {
    if (_scanning) {
      return;
    }
    final allowed = await _ensurePermissions();
    if (!allowed) {
      _log('Scan blocked: Bluetooth permissions not granted');
      return;
    }
    _devices.clear();
    _scanning = true;
    _log('Scanning for Bluetooth LE devices...');
    if (mounted) {
      setState(() {});
    }
    _broadcastStatus();
    try {
      await UniversalBle.startScan();
      await Future<void>.delayed(const Duration(seconds: 8));
      await UniversalBle.stopScan();
    } catch (error) {
      _log('Scan failed: $error');
    } finally {
      _scanning = false;
      if (mounted) {
        setState(() {});
      }
      _broadcastStatus();
      _broadcastDeviceList();
    }
  }

  Future<void> _connectToDevice(String deviceId) async {
    if (_connectingDeviceId == deviceId) {
      return;
    }
    final device = _devices[deviceId];
    if (device == null) {
      _log('Connect skipped: unknown device $deviceId');
      return;
    }
    final allowed = await _ensurePermissions();
    if (!allowed) {
      _log('Connect blocked: Bluetooth permissions not granted');
      return;
    }
    _connectingDeviceId = deviceId;
    _log('Connecting to ${device.name}...');
    if (mounted) {
      setState(() {});
    }

    try {
      if (_connectedDeviceId != null && _connectedDeviceId != device.id) {
        await _disconnect();
      }
      await UniversalBle.connect(device.id);
      await Future<void>.delayed(const Duration(milliseconds: 600));
      try {
        final mtu = await UniversalBle.requestMtu(device.id, 247);
        _log('Requested MTU -> $mtu');
      } catch (error) {
        _log('MTU request skipped: $error');
      }
      _connectedDeviceId = device.id;
      _connectedDeviceName = device.name;
      await _subscribeMidi(device.id);
      await _savePrefs();
      _log('Connected to ${device.name}');
    } catch (error) {
      _log('Connect failed: $error');
    } finally {
      _connectingDeviceId = null;
      if (mounted) {
        setState(() {});
      }
      _broadcastStatus();
    }
  }

  Future<void> _disconnect() async {
    if (_connectedDeviceId == null) {
      return;
    }
    final deviceId = _connectedDeviceId!;
    _log('Disconnecting $deviceId');
    try {
      await UniversalBle.disconnect(deviceId);
    } catch (error) {
      _log('Disconnect warning: $error');
    }
    _connectedDeviceId = null;
    _connectedDeviceName = null;
    _bleMidiSubscribed = false;
    if (mounted) {
      setState(() {});
    }
    _broadcastStatus();
  }

  Future<void> _subscribeMidi(String deviceId) async {
    try {
      final services = await UniversalBle.discoverServices(deviceId);
      _log('BLE services: ${services.map((s) => s.uuid).join(', ')}');
      final service = services.firstWhere(
        (service) => service.uuid.toLowerCase() == _midiServiceUuid,
        orElse: () => services.firstWhere(
          (service) => service.characteristics.any((c) => c.properties.contains(CharacteristicProperty.notify) || c.properties.contains(CharacteristicProperty.indicate)),
          orElse: () => services.first,
        ),
      );
      _log('Using service: ${service.uuid}');
      final characteristic = service.characteristics.firstWhere(
        (characteristic) => characteristic.uuid.toLowerCase() == _midiCharacteristicUuid,
        orElse: () => service.characteristics.firstWhere(
          (characteristic) => characteristic.properties.contains(CharacteristicProperty.notify) || characteristic.properties.contains(CharacteristicProperty.indicate),
          orElse: () => service.characteristics.first,
        ),
      );
      _log('Using characteristic: ${characteristic.uuid} notify=${characteristic.properties.contains(CharacteristicProperty.notify)} indicate=${characteristic.properties.contains(CharacteristicProperty.indicate)}');
      try {
        await UniversalBle.setNotifiable(
          deviceId,
          service.uuid,
          characteristic.uuid,
          BleInputProperty.notification,
        );
      } catch (_) {
        await UniversalBle.setNotifiable(
          deviceId,
          service.uuid,
          characteristic.uuid,
          BleInputProperty.indication,
        );
      }
      _bleMidiSubscribed = true;
      _log('Subscribed to BLE MIDI input');
    } catch (error) {
      _bleMidiSubscribed = false;
      _log('BLE MIDI subscribe failed: $error');
    }
  }

  List<List<int>> _extractBleMidiMessages(List<int> packet) {
    final messages = <List<int>>[];
    if (packet.isEmpty) return messages;

    int i = 1; // byte 0 is BLE-MIDI header
    int? runningStatus;

    while (i < packet.length) {
      if (packet[i] & 0x80 != 0) {
        i += 1;
      }
      if (i >= packet.length) break;

      int status;
      final first = packet[i];
      if (first & 0x80 != 0) {
        status = first;
        i += 1;
        if (status < 0xF0) {
          runningStatus = status;
        }
      } else {
        if (runningStatus == null) {
          i += 1;
          continue;
        }
        status = runningStatus;
      }

      final statusType = status & 0xF0;
      if (status >= 0xF8) {
        messages.add([status]);
        continue;
      }

      final dataLength = (statusType == 0xC0 || statusType == 0xD0) ? 1 : 2;
      if (i + dataLength > packet.length) break;

      final dataBytes = packet.sublist(i, i + dataLength);
      if (dataBytes.any((value) => value & 0x80 != 0)) {
        i += 1;
        continue;
      }

      messages.add([status, ...dataBytes]);
      i += dataLength;
    }
    return messages;
  }

  List<_BridgeDevice> _sortedDevices() {
    final list = _devices.values.toList()
      ..sort((left, right) {
        if (left.midiCompatible != right.midiCompatible) {
          return left.midiCompatible ? -1 : 1;
        }
        return left.name.toLowerCase().compareTo(right.name.toLowerCase());
      });
    return list;
  }

  void _log(String message) {
    final line = '[${DateTime.now().toString().substring(11, 19)}] $message';
    _logs.add(line);
    if (_logs.length > 500) {
      _logs.removeAt(0);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _copyText(String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    _log('Copied $label');
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1100;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gyro MIDI Bridge'),
        actions: [
          Row(
            children: [
              Text(
                'Auto-connect',
                style: TextStyle(color: Colors.white.withOpacity(0.72)),
              ),
              Switch(
                value: _autoConnect,
                onChanged: (value) {
                  setState(() => _autoConnect = value);
                  _savePrefs();
                  _broadcastStatus();
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeroCard(context),
              const SizedBox(height: 16),
              Expanded(
                child: isDesktop
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              children: [
                                Expanded(child: _buildDevicePanel()),
                                const SizedBox(height: 16),
                                _buildApiPanel(),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(flex: 5, child: _buildLogPanel()),
                        ],
                      )
                    : ListView(
                        children: [
                          SizedBox(height: 460, child: _buildDevicePanel()),
                          const SizedBox(height: 16),
                          _buildApiPanel(),
                          const SizedBox(height: 16),
                          SizedBox(height: 360, child: _buildLogPanel()),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    final connectedDevice = _connectedDeviceName ?? 'None';
    final connectionLabel = _connectedDeviceId == null
        ? 'Idle'
        : _bleMidiSubscribed
            ? 'Streaming'
            : 'Connected';
    final connectionColor = _connectedDeviceId == null
        ? Colors.white70
        : _bleMidiSubscribed
            ? Theme.of(context).colorScheme.primary
            : Colors.orangeAccent;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                      const Text(
                        'Local companion for browser MIDI access',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This app connects to the real Bluetooth MIDI device, then exposes it to the web app over localhost. The browser should connect to this bridge over 127.0.0.1, not over Bluetooth.',
                        style: TextStyle(color: Colors.white.withOpacity(0.72)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: connectionColor.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        connectionLabel,
                        style: TextStyle(
                          color: connectionColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        connectedDevice,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _metricChip('Version', _appVersion),
                _metricChip('HTTP', _serverBaseUrl),
                _metricChip('WebSocket', _socketUrl),
                _metricChip('Browser Clients', '${_clients.length}'),
                _metricChip('Bluetooth', _availability),
                _metricChip('Device', connectedDevice),
                _metricChip('MIDI', '$_midiCount'),
                _metricChip('Subscription', _bleMidiSubscribed ? 'On' : 'Off'),
                _metricChip('Permissions', _permissionsGranted ? 'Granted' : 'Required'),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Permissions: $_permissionStatus',
              style: TextStyle(color: Colors.white.withOpacity(0.68), fontSize: 12),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                FilledButton.icon(
                  onPressed: _scanning ? null : _startScan,
                  icon: const Icon(Icons.radar_rounded),
                  label: Text(_scanning ? 'Scanning...' : 'Scan Devices'),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _ensurePermissions(),
                  icon: const Icon(Icons.bluetooth_searching_rounded),
                  label: const Text('Grant Bluetooth'),
                ),
                FilledButton.tonalIcon(
                  onPressed:
                      _connectedDeviceId == null ? null : _disconnect,
                  icon: const Icon(Icons.link_off_rounded),
                  label: const Text('Disconnect Device'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _lastDeviceId == null
                      ? null
                      : () => _connectToDevice(_lastDeviceId!),
                  icon: const Icon(Icons.refresh_rounded),
                  label: Text(
                    _lastDeviceName == null
                        ? 'Reconnect Last'
                        : 'Reconnect $_lastDeviceName',
                  ),
                ),
                FilledButton.tonalIcon(
                  onPressed: () => _copyText(_serverBaseUrl, 'bridge HTTP URL'),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy HTTP URL'),
                ),
                FilledButton.tonalIcon(
                  onPressed: _serverRunning ? _stopServer : _startServer,
                  icon: Icon(
                    _serverRunning
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_outline,
                  ),
                  label: Text(_serverRunning ? 'Stop Server' : 'Start Server'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.56),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _buildDevicePanel() {
    final devices = _sortedDevices();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bluetooth MIDI Devices',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                Text(
                  '${devices.length} visible',
                  style: TextStyle(color: Colors.white.withOpacity(0.6)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Scan, connect, and keep one device active. The bridge forwards its MIDI stream to any browser client connected to localhost.',
              style: TextStyle(color: Colors.white.withOpacity(0.68)),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: devices.isEmpty
                  ? Center(
                      child: Text(
                        _scanning
                            ? 'Scanning for nearby Bluetooth LE devices...'
                            : 'No devices discovered yet. Start a scan.',
                        style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      ),
                    )
                  : ListView.separated(
                      itemCount: devices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final device = devices[index];
                        final connected = device.id == _connectedDeviceId;
                        final connecting = device.id == _connectingDeviceId;
                        return Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.04),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: connected
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withOpacity(0.55)
                                  : Colors.white.withOpacity(0.06),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      device.name,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  _pill(
                                    device.midiCompatible ? 'MIDI' : 'BLE',
                                    device.midiCompatible
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.white70,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                device.id,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.56),
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  _tinyMeta('RSSI ${device.rssi}'),
                                  const SizedBox(width: 8),
                                  _tinyMeta(
                                    'Seen ${device.seenAt.toLocal().toString().substring(11, 19)}',
                                  ),
                                  const Spacer(),
                                  FilledButton(
                                    onPressed: connected || connecting
                                        ? null
                                        : () => _connectToDevice(device.id),
                                    child: Text(
                                      connected
                                          ? 'Connected'
                                          : connecting
                                              ? 'Connecting...'
                                              : 'Connect',
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bridge API',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Web app clients should probe HTTP status on localhost, then connect to the WebSocket MIDI stream.',
              style: TextStyle(color: Colors.white.withOpacity(0.68)),
            ),
            const SizedBox(height: 14),
            _apiRow('GET', '$_serverBaseUrl/status'),
            _apiRow('GET', '$_serverBaseUrl/devices'),
            _apiRow('GET', '$_serverBaseUrl/logs'),
            _apiRow('POST', '$_serverBaseUrl/scan'),
            _apiRow('POST', '$_serverBaseUrl/connect'),
            _apiRow('POST', '$_serverBaseUrl/disconnect'),
            _apiRow('WS', _socketUrl),
          ],
        ),
      ),
    );
  }

  Widget _apiRow(String method, String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              method,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              url,
              style: TextStyle(color: Colors.white.withOpacity(0.76)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogPanel() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Diagnostics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton.icon(
                  onPressed: _logs.isEmpty
                      ? null
                      : () => _copyText(_logs.join('\n'), 'bridge logs'),
                  icon: const Icon(Icons.copy_all_rounded),
                  label: const Text('Copy'),
                ),
                TextButton.icon(
                  onPressed: () => setState(() => _logs.clear()),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Use these logs to diagnose Bluetooth discovery, device connection, BLE MIDI subscription, and web client issues.',
              style: TextStyle(color: Colors.white.withOpacity(0.68)),
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: _logs.isEmpty
                    ? Center(
                        child: Text(
                          'No diagnostics yet.',
                          style: TextStyle(color: Colors.white.withOpacity(0.55)),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _logs.length,
                        itemBuilder: (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            _logs[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _tinyMeta(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
      ),
    );
  }
}
