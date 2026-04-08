import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_debug_log_service.dart';
import 'app_settings_store.dart';
import 'connection_manager_service.dart';
import 'web_transport_capability.dart';
import 'live_midi_note_service.dart';
import 'local_midi_bridge.dart';
import 'web_midi_host.dart';
import 'audio_player_service.dart';

class MidiDeviceInfo {
  final String id;
  final String name;
  final String source;
  final bool isConnected;
  final bool isBluetooth;
  final bool isMidiCompatible;
  final String detail;
  const MidiDeviceInfo({
    required this.id,
    required this.name,
    required this.source,
    required this.isConnected,
    this.isBluetooth = false,
    this.isMidiCompatible = true,
    this.detail = '',
  });
}

enum MidiInputEventType { noteOn, noteOff, sustain }

class MidiInputEvent {
  final MidiInputEventType type;
  final int note;
  final int velocity;
  final bool sustainEnabled;
  final String source;

  const MidiInputEvent.noteOn({
    required this.note,
    required this.velocity,
    required this.source,
  })  : type = MidiInputEventType.noteOn,
        sustainEnabled = false;

  const MidiInputEvent.noteOff({
    required this.note,
    required this.source,
  })  : type = MidiInputEventType.noteOff,
        velocity = 0,
        sustainEnabled = false;

  const MidiInputEvent.sustain({
    required this.sustainEnabled,
    required this.source,
  })  : type = MidiInputEventType.sustain,
        note = 64,
        velocity = 0;
}

class MidiServiceLite {
  MidiServiceLite._();
  static final MidiServiceLite instance = MidiServiceLite._();
  static const String _prefManualTranspose = 'external_midi_manual_transpose';
  static const String _prefDeviceTranspose = 'external_midi_device_transpose';
  static const int _defaultExternalTranspose = -15;

  final MidiCommand _midi = MidiCommand();
  StreamSubscription<MidiPacket>? _sub;
  StreamSubscription<String>? _setupSub;
  StreamSubscription<List<fbp.ScanResult>>? _scanSub;
  final List<MidiDeviceInfo> _devices = [];
  final Map<String, fbp.BluetoothDevice> _bleDevices = {};
  final LocalMidiBridgeClient _bridge = LocalMidiBridgeClient();
  final WebMidiHost _webMidi = WebMidiHost();
  bool _scanning = false;
  MidiDevice? _connected;
  fbp.BluetoothDevice? _bleConnected;
  StreamSubscription<List<int>>? _bleNotifySub;
  bool _autoConnectEnabled = true;
  String? _lastDeviceId;
  String? _lastDeviceName;
  bool _preferBle = false;
  String _bridgeUrl = 'ws://127.0.0.1:8765/midi';
  WebTransportPreference _webTransportPreference = WebTransportPreference.auto;
  int _manualTranspose = 0;
  final Map<String, int> _deviceTranspose = {};
  String? _activeInputDeviceId;
  String? _activeInputDeviceName;
  bool _calibrationArmed = false;
  int _calibrationTargetPitchClass = 0;
  String _calibrationTargetLabel = 'C';
  bool _verboseLogging = false;
  Timer? _autoReconnectTimer;

  final StreamController<List<MidiDeviceInfo>> _deviceStream =
      StreamController.broadcast();
  final StreamController<List<int>> _midiStream = StreamController.broadcast();
  final StreamController<MidiInputEvent> _eventStream =
      StreamController.broadcast();
  final StreamController<String> _statusStream =
      StreamController.broadcast();
  bool _initialized = false;

  Stream<List<MidiDeviceInfo>> get devicesStream => _deviceStream.stream;
  Stream<List<int>> get midiBytes => _midiStream.stream;
  Stream<MidiInputEvent> get events => _eventStream.stream;
  Stream<String> get status => _statusStream.stream;

  bool get isScanning => _scanning;
  List<MidiDeviceInfo> get devices => List.unmodifiable(_devices);
  String? get lastDeviceId => _lastDeviceId;
  String? get lastDeviceName => _lastDeviceName;
  String get bridgeUrl => _bridgeUrl;
  bool get bridgeConnected => _bridge.isConnected;
  String? get bridgeError => _bridge.lastError;
  WebTransportPreference get webTransportPreference => _webTransportPreference;
  int get manualTranspose => _manualTranspose;
  String? get activeInputDeviceId => _activeInputDeviceId;
  String? get activeInputDeviceName => _activeInputDeviceName;
  int get currentDeviceTranspose =>
      _activeInputDeviceId == null ? 0 : (_deviceTranspose[_activeInputDeviceId!] ?? 0);
  int get effectiveTranspose => _defaultExternalTranspose + _manualTranspose + currentDeviceTranspose;
  bool get calibrationArmed => _calibrationArmed;

  void _log(String message) {
    _statusStream.add(message);
    AppDebugLogService.instance.add('MIDI', message);
  }

  Future<void> _panicTransport(String reason) async {
    LiveMidiNoteService.instance.clear();
    try {
      await AudioPlayerService().panic(reason: reason);
    } catch (_) {}
    _eventStream.add(
      MidiInputEvent.sustain(sustainEnabled: false, source: reason),
    );
    _log('Transport panic: $reason');
  }

  Future<bool> _connectWithRetry(
    String deviceId,
    String? name, {
    int attempts = 3,
    bool allowBluetooth = true,
  }) async {
    final trimmedName = name?.trim();
    for (int attempt = 1; attempt <= attempts; attempt++) {
      _log('Connect attempt $attempt/$attempts: ${trimmedName ?? deviceId}');

      final direct = await _findMidiDeviceById(deviceId) ??
          (trimmedName == null || trimmedName.isEmpty
              ? null
              : await _findMidiDeviceByName(trimmedName));
      if (direct != null) {
        await _connectMidiDevice(direct);
        return true;
      }

      if (!kIsWeb && allowBluetooth && trimmedName != null && trimmedName.isNotEmpty) {
        final nativeOk = await _connectNativeBluetoothMidi(deviceId, trimmedName);
        if (nativeOk) return true;

        await _scanBle(
          targetDeviceId: deviceId,
          targetName: trimmedName,
          timeout: const Duration(seconds: 2),
        );

        final postScan = await _findMidiDeviceById(deviceId) ??
            await _findMidiDeviceByName(trimmedName);
        if (postScan != null) {
          await _connectMidiDevice(postScan);
          return true;
        }
      }

      if (attempt < attempts) {
        await Future.delayed(Duration(milliseconds: 350 * attempt));
      }
    }
    return false;
  }

  void _scheduleAutoReconnectRetries(String deviceId, String? deviceName) {
    _autoReconnectTimer?.cancel();
    if (!_autoConnectEnabled) return;
    var remaining = 3;
    _autoReconnectTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (_activeInputDeviceId != null || remaining <= 0) {
        timer.cancel();
        return;
      }
      remaining -= 1;
      final ok = await _connectWithRetry(
        deviceId,
        deviceName,
        attempts: 2,
        allowBluetooth: true,
      );
      if (ok) {
        timer.cancel();
      }
    });
  }

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    _bridge.setOnMidi((data) {
      _emitMidiBytes(data, source: 'Wi-Fi Bridge');
    });
    _bridge.setOnStatus((message) => _log(message));
    _webMidi.setOnMidi((data) {
      _emitMidiBytes(data, source: 'Web MIDI');
    });
    _webMidi.setOnStatus((message) => _log(message));
    if (kIsWeb) {
      await _loadPrefs();
      await _loadWebDevices();
      if (_autoConnectEnabled) {
        await _attemptAutoConnectWeb();
      }
      _log('Web transport ready');
      return;
    }
    await _loadPrefs();
    await ConnectionManagerService.initialize();
    try {
      await _midi.startBluetoothCentral();
      _setupSub = _midi.onMidiSetupChanged?.listen((_) async {
        await _loadMidiDevices();
      });
    } catch (e) {
      _log('Native Bluetooth MIDI init skipped: $e');
    }
    _sub = _midi.onMidiDataReceived?.listen((packet) {
      _emitMidiBytes(packet.data, source: 'OS MIDI');
    });
    await _loadMidiDevices();
    if (_autoConnectEnabled) {
      await _attemptAutoConnect();
      if (_activeInputDeviceId == null && _lastDeviceId != null) {
        _scheduleAutoReconnectRetries(_lastDeviceId!, _lastDeviceName);
      }
    }
  }

  Future<void> scan() async {
    if (kIsWeb) {
      _log('Refreshing web transports...');
      await _loadWebDevices(includeBluetoothScan: _shouldUseWebBluetooth());
      return;
    }
    if (_scanning) return;
    _scanning = true;
    _log('Scanning for OS MIDI and all Bluetooth LE devices...');
    _removeBluetoothDevicesFromList();
    _bleDevices.clear();
    _deviceStream.add(List.from(_devices));
    await _requestPermissions();
    await _startNativeBluetoothDiscovery();
    await _loadMidiDevices();
    await _scanBle();
    _scanning = false;
    _log('Scan complete: ${_devices.length} devices visible');
    _deviceStream.add(List.from(_devices));
  }

  Future<void> connect(String deviceId) async {
    if (_scanning) {
      await _stopBleScan();
      _scanning = false;
      _log('Bluetooth scan interrupted by user selection');
    }
    if (deviceId == 'bridge') {
      _log('Connecting Wi-Fi MIDI bridge...');
      await _bridge.connect(url: _bridgeUrl);
      _setActiveInputDevice('bridge', 'Wi-Fi MIDI Bridge');
      await _savePrefs('bridge', 'Wi-Fi MIDI Bridge');
      await ConnectionManagerService.saveConnection(
        'bridge',
        'Wi-Fi MIDI Bridge',
        'Wi-Fi',
      );
      if (kIsWeb) {
        await _loadWebDevices();
      } else {
        await _loadMidiDevices();
      }
      return;
    }
    if (kIsWeb && deviceId.startsWith('webmidi:')) {
      final inputId = deviceId.substring('webmidi:'.length);
      final ok = await _webMidi.connect(inputId);
      if (ok) {
        final name = _webMidi.connectedInputName ?? 'Web MIDI Input';
        _setActiveInputDevice(deviceId, name);
        await _savePrefs(deviceId, name);
        await ConnectionManagerService.saveConnection(deviceId, name, 'Web MIDI');
        await _loadWebDevices();
      }
      return;
    }
    try {
      final info = _devices.firstWhere(
        (d) => d.id == deviceId,
        orElse: () => MidiDeviceInfo(
          id: deviceId,
          name: '',
          source: 'Bluetooth',
          isConnected: false,
          isBluetooth: true,
          isMidiCompatible: false,
        ),
      );

      if (!kIsWeb) {
        final ok = await _connectWithRetry(
          deviceId,
          info.name,
          attempts: info.isBluetooth ? 4 : 2,
          allowBluetooth: info.isBluetooth,
        );
        if (!ok && info.isBluetooth) {
          _log('Bluetooth device is visible, but Android did not complete native MIDI registration. The app kept retrying automatically; raw BLE fallback stays disabled to avoid corruption.');
        }
        return;
      } else if (kIsWeb && info.isBluetooth) {
        final ok = await _connectBleMidi(deviceId, info.name);
        if (ok) return;
      }

      final target = await _findMidiDeviceById(deviceId);
      if (target != null) {
        await _connectMidiDevice(target);
        return;
      }
    } catch (e) {
      _log('Connect failed: $e');
    }
  }

  Future<void> disconnect() async {
    if (kIsWeb) {
      await _bridge.disconnect();
      await _webMidi.disconnect();
      await _disconnectBle();
      _clearActiveInputDevice();
      await _panicTransport('web_disconnect');
      await _loadWebDevices();
      return;
    }
    final wasBridgeActive = _activeInputDeviceId == 'bridge';
    await _bridge.disconnect();
    if (wasBridgeActive) {
      _clearActiveInputDevice();
    }
    if (_connected != null) {
      _midi.disconnectDevice(_connected!);
      _connected = null;
      _log('Disconnected from OS MIDI device');
      _clearActiveInputDevice();
      await _loadMidiDevices();
    }
    await _disconnectBle();
    await _panicTransport('disconnect');
  }

  Future<bool> probeBridge() async {
    return _bridge.probe(url: _bridgeUrl);
  }

  Future<void> _connectMidiDevice(MidiDevice device) async {
    if (_connected != null) {
      _midi.disconnectDevice(_connected!);
    }
    await _midi.connectToDevice(device);
    _connected = device;
    _setActiveInputDevice(device.id, device.name);
    _log('Connected to OS MIDI device: ${device.name}');
    await _savePrefs(device.id, device.name);
    await ConnectionManagerService.saveConnection(
      device.id,
      device.name,
      'OS MIDI',
    );
    await _loadMidiDevices();
  }

  Future<void> _loadMidiDevices() async {
    final list = <MidiDeviceInfo>[];
    final devices = await _midi.devices;
    if (devices != null) {
      for (final d in devices) {
        final lowerType = d.type.toLowerCase();
        final lowerName = d.name.toLowerCase();
        final isBluetooth = lowerType.contains('ble') ||
            lowerType.contains('bluetooth') ||
            lowerName.contains('widi') ||
            lowerName.contains('ble');
        list.add(MidiDeviceInfo(
          id: d.id,
          name: d.name,
          source: 'OS MIDI',
          isConnected: _connected?.id == d.id,
          isBluetooth: isBluetooth,
          isMidiCompatible: true,
          detail: isBluetooth
              ? 'Native Bluetooth MIDI endpoint exposed by the operating system'
              : 'Detected by the operating system as a MIDI endpoint',
        ));
      }
    }
    _devices
      ..clear()
      ..addAll(list);
    _deviceStream.add(List.from(_devices));
  }

  Future<void> _startNativeBluetoothDiscovery({
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (kIsWeb) return;
    try {
      await _midi.startBluetoothCentral();
      await _midi.startScanningForBluetoothDevices();
      await Future.delayed(timeout);
    } catch (e) {
      _log('Native Bluetooth MIDI scan failed: $e');
    } finally {
      try {
        _midi.stopScanningForBluetoothDevices();
      } catch (_) {}
    }
  }

  Future<bool> _connectNativeBluetoothMidi(String deviceId, String name) async {
    final deviceName = name.trim();
    if (deviceName.isEmpty) return false;
    _log('Trying native Bluetooth MIDI path for $deviceName');
    await _requestPermissions();
    await _startNativeBluetoothDiscovery(timeout: const Duration(seconds: 3));

    final direct = await _findMidiDeviceById(deviceId) ??
        await _findMidiDeviceByName(deviceName);
    if (direct != null) {
      await _connectMidiDevice(direct);
      return true;
    }

    final ok = await ConnectionManagerService().connectToMidiDevice(
      deviceId,
      deviceName,
      bleDeviceId: deviceId,
      nameOnly: true,
      onStatus: _log,
    );
    if (!ok) {
      _log('Native Bluetooth MIDI path did not expose $deviceName as an OS MIDI device');
      return false;
    }

    await _loadMidiDevices();
    final connected = await _findMidiDeviceById(deviceId) ??
        await _findMidiDeviceByName(deviceName);
    if (connected == null) {
      _log('Native Bluetooth MIDI connected, but no matching OS MIDI endpoint was available yet');
      return false;
    }
    await _connectMidiDevice(connected);
    return true;
  }

  Future<void> _loadWebDevices({bool includeBluetoothScan = false}) async {
    _devices.clear();
    final webMidiInputs = await _webMidi.listInputs();
    for (final input in webMidiInputs) {
      _devices.add(
        MidiDeviceInfo(
          id: 'webmidi:${input.id}',
          name: input.name,
          source: 'Web MIDI',
          isConnected: _webMidi.connectedInputId == input.id,
          isMidiCompatible: true,
          detail: 'Browser access to OS MIDI input',
        ),
      );
    }
    if (includeBluetoothScan) {
      _bleDevices.clear();
      _log('Scanning direct Web Bluetooth devices...');
      await _scanBle();
    }
    _deviceStream.add(List.from(_devices));
  }

  Future<void> _scanBle({
    String? targetDeviceId,
    String? targetName,
    Duration timeout = const Duration(seconds: 6),
  }) async {
    final discovered = <String, MidiDeviceInfo>{};
    try {
      final normalizedTargetName = targetName?.toLowerCase();
      final completer = Completer<void>();
      try {
        await fbp.FlutterBluePlus.stopScan();
      } catch (_) {}
      await _scanSub?.cancel();
      _scanSub = null;
      _removeBluetoothDevicesFromList();
      _bleDevices.clear();
      _deviceStream.add(List.from(_devices));

      _scanSub = fbp.FlutterBluePlus.scanResults.listen((results) {
        var changed = false;
        for (final r in results) {
          final rawName = r.device.platformName.isNotEmpty
              ? r.device.platformName
              : r.advertisementData.advName;
          final name = rawName.isEmpty
              ? 'Bluetooth Device ${r.device.remoteId.str.substring(0, 6)}'
              : rawName;
          _bleDevices[r.device.remoteId.str] = r.device;
          final serviceUuids = [
            ...r.advertisementData.serviceUuids.map((e) => e.toString().toLowerCase()),
          ];
          final manufacturerData =
              r.advertisementData.manufacturerData.values.expand((e) => e).toList();
          final isMidi = serviceUuids.any(
                (uuid) =>
                    uuid.contains('03b80e5a-ede8-4b33-a751-6ce34ec4c700'),
              ) ||
              name.toLowerCase().contains('widi') ||
              name.toLowerCase().contains('midi') ||
              manufacturerData.contains(0x03);
          discovered[r.device.remoteId.str] = MidiDeviceInfo(
            id: r.device.remoteId.str,
            name: name,
            source: 'Bluetooth',
            isConnected: false,
            isBluetooth: true,
            isMidiCompatible: isMidi,
            detail: isMidi
                ? (kIsWeb
                    ? 'Bluetooth LE MIDI device can be connected directly in supported browsers'
                    : 'Bluetooth LE MIDI device detected; Android will use native MIDI if the OS exposes it')
                : 'Bluetooth LE device detected',
          );
          changed = true;
          final matchesTarget =
              (targetDeviceId != null && r.device.remoteId.str == targetDeviceId) ||
                  (normalizedTargetName != null &&
                      normalizedTargetName.isNotEmpty &&
                      name.toLowerCase() == normalizedTargetName);
          if (matchesTarget && !completer.isCompleted) {
            completer.complete();
          }
        }
        if (changed) {
          _removeBluetoothDevicesFromList();
          _devices.addAll(discovered.values);
          _deviceStream.add(List.from(_devices));
        }
      });

      await fbp.FlutterBluePlus.startScan(
        timeout: timeout,
        androidUsesFineLocation: true,
      );
      if (targetDeviceId != null || normalizedTargetName != null) {
        await Future.any([
          completer.future,
          Future.delayed(timeout),
        ]);
      } else {
        await Future.delayed(timeout);
      }
    } catch (e) {
      _log('Bluetooth scan failed: $e');
    } finally {
      await _stopBleScan();
      _removeBluetoothDevicesFromList();
      _devices.addAll(discovered.values);
      _deviceStream.add(List.from(_devices));
    }
  }

  Future<void> _stopBleScan() async {
    try {
      await fbp.FlutterBluePlus.stopScan();
    } catch (_) {}
    await _scanSub?.cancel();
    _scanSub = null;
  }

  void _removeBluetoothDevicesFromList() {
    _devices.removeWhere((device) => device.source == 'Bluetooth');
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      return;
    }
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];
    for (final p in permissions) {
      if (!await p.isGranted) {
        final result = await p.request();
        AppDebugLogService.instance.add('MIDI', 'Permission $p -> $result');
      }
    }
  }

  Future<bool> _connectBleMidi(String deviceId, String name) async {
    try {
      final device = _bleDevices[deviceId];
      if (device == null) {
        _log('BLE MIDI connect failed: device not found');
        return false;
      }
      _log('BLE MIDI connect...');
      await device.connect(timeout: const Duration(seconds: 6));
      _bleConnected = device;
      _setActiveInputDevice(deviceId, name);
      try {
        await device.requestConnectionPriority(
          connectionPriorityRequest: fbp.ConnectionPriority.high,
        );
      } catch (_) {}
      try {
        await device.requestMtu(247, predelay: 0);
      } catch (_) {}
      final services = await device.discoverServices();
      _log(
        'BLE services: ${services.map((s) => s.uuid.toString()).join(", ")}',
      );
      final midiService = services.firstWhere(
        (s) => s.uuid.toString().toLowerCase() ==
            '03b80e5a-ede8-4b33-a751-6ce34ec4c700',
        orElse: () => services.first,
      );
      _log(
        'BLE service characteristics: ${midiService.characteristics.map((c) => "${c.uuid} notify=${c.properties.notify} indicate=${c.properties.indicate} write=${c.properties.write}").join(" | ")}',
      );
      final midiChar = midiService.characteristics.firstWhere(
        (c) =>
            c.uuid.toString().toLowerCase() ==
            '7772e5db-3868-4112-a1a9-f2669d106bf3',
        orElse: () => midiService.characteristics.firstWhere(
          (c) => c.properties.notify || c.properties.indicate,
          orElse: () => midiService.characteristics.first,
        ),
      );
      _log('BLE MIDI characteristic selected: ${midiChar.uuid}');
      await midiChar.setNotifyValue(true);
      _bleNotifySub?.cancel();
      _bleNotifySub = midiChar.onValueReceived.listen((value) {
        if (_verboseLogging) {
          AppDebugLogService.instance.add('MIDI', 'BLE raw packet: $value');
        }
        final messages = _extractBleMidiMessages(value);
        if (_verboseLogging) {
          AppDebugLogService.instance.add(
            'MIDI',
            'BLE parsed messages: ${messages.length}',
          );
        }
        for (final message in messages) {
          _emitMidiBytes(message, source: 'BLE MIDI');
        }
      });
      _log('BLE MIDI connected');
      await _savePrefs(deviceId, name);
      await ConnectionManagerService.saveConnection(
        deviceId,
        name,
        'Bluetooth',
      );
      await _loadMidiDevices();
      return true;
    } catch (e) {
      _log('BLE MIDI failed: $e');
      return false;
    }
  }

  Future<void> _disconnectBle() async {
    try {
      await _bleNotifySub?.cancel();
      _bleNotifySub = null;
      if (_bleConnected != null) {
        await _bleConnected!.disconnect();
        _log('Disconnected from BLE MIDI device');
        _bleConnected = null;
        _clearActiveInputDevice();
      }
    } catch (_) {}
  }

  Future<MidiDevice?> _findMidiDeviceById(String deviceId) async {
    final devices = await _midi.devices;
    if (devices == null) return null;
    for (final d in devices) {
      if (d.id == deviceId) return d;
    }
    return null;
  }

  Future<MidiDevice?> _findMidiDeviceByName(String name) async {
    final devices = await _midi.devices;
    if (devices == null || name.isEmpty) return null;
    final target = name.toString().toLowerCase();
    for (final d in devices) {
      final dname = d.name.toString().toLowerCase();
      if (dname == target ||
          dname.contains(target) ||
          target.contains(dname)) {
        return d;
      }
    }
    return null;
  }

  Future<void> _bleHandshake(String deviceId, String deviceName) async {
    try {
      _log('BLE handshake...');
      fbp.BluetoothDevice? ble;
      final sub = fbp.FlutterBluePlus.scanResults.listen((results) {
        for (final r in results) {
          if (r.device.remoteId.str == deviceId ||
              r.device.platformName.toString().toLowerCase() ==
                  deviceName.toString().toLowerCase()) {
            ble = r.device;
          }
        }
      });
      await fbp.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 4),
        androidUsesFineLocation: true,
      );
      await Future.delayed(const Duration(seconds: 4));
      await fbp.FlutterBluePlus.stopScan();
      await sub.cancel();

      if (ble == null) {
        _log('BLE handshake could not find device');
        return;
      }
      try {
        await ble!.connect(timeout: const Duration(seconds: 4));
        await Future.delayed(const Duration(milliseconds: 600));
        await ble!.disconnect();
      } catch (_) {}
    } catch (_) {}
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _autoConnectEnabled = prefs.getBool('auto_connect_enabled') ?? true;
    _lastDeviceId = prefs.getString('last_device_id');
    _lastDeviceName = prefs.getString('last_device_name');
    _bridgeUrl = _normalizeBridgeUrl(
      prefs.getString('midi_bridge_url') ?? 'ws://127.0.0.1:8765/midi',
    );
    _verboseLogging = await AppSettingsStore.getAudioDebugLogging();
    await _migrateLegacyWidiOffsets();
    _webTransportPreference = _webTransportPreferenceFromString(
      await AppSettingsStore.getWebTransportPreference(),
    );
    _manualTranspose = (prefs.getInt(_prefManualTranspose) ?? 0).clamp(-24, 24);
    _deviceTranspose.clear();
    for (final entry in prefs.getStringList(_prefDeviceTranspose) ?? const <String>[]) {
      final parts = entry.split('::');
      if (parts.length != 2) continue;
      final value = int.tryParse(parts[1]);
      if (value == null) continue;
      _deviceTranspose[parts[0]] = value.clamp(-24, 24);
    }
  }

  Future<void> _savePrefs(String id, String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('last_device_id', id);
    await prefs.setString('last_device_name', name);
  }

  Future<void> setAutoConnect(bool enabled) async {
    _autoConnectEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_connect_enabled', enabled);
  }

  bool get autoConnectEnabled => _autoConnectEnabled;
  bool get preferBle => _preferBle;

  Future<void> _attemptAutoConnect() async {
    final preferred =
        ConnectionManagerService.getAutoConnectDevice() ??
            ConnectionManagerService.getMostRecentDevice();
    final targetId = preferred?.id ?? _lastDeviceId;
    final targetName = preferred?.name ?? _lastDeviceName;
    if (targetId == null) return;

    _statusStream.add('Auto-connecting...');
    AppDebugLogService.instance.add(
      'MIDI',
      'Auto-connecting to $targetId (${targetName ?? "Unknown"})',
    );

    await _requestPermissions();
    await _loadMidiDevices();

    if (targetId == 'bridge') {
      await connect('bridge');
      return;
    }

    final ok = await _connectWithRetry(
      targetId,
      targetName,
      attempts: 4,
      allowBluetooth: true,
    );
    if (ok) {
      return;
    }

    _log('Auto-reconnect could not restore the previous device immediately; background retries will continue');
  }

  Future<void> _attemptAutoConnectWeb() async {
    await _loadWebDevices(includeBluetoothScan: _shouldUseWebBluetooth());

    if (_lastDeviceId == null) return;
    if (_lastDeviceId == 'bridge' &&
        _webTransportPreference == WebTransportPreference.bridge) {
      await connect('bridge');
      return;
    }
    if (_lastDeviceId!.startsWith('webmidi:')) {
      await connect(_lastDeviceId!);
      return;
    }
    if (_shouldUseWebBluetooth()) {
      final device = _devices.where((d) => d.id == _lastDeviceId).toList();
      if (device.isNotEmpty) {
        await connect(device.first.id);
      }
    }
  }

  fbp.BluetoothDevice? _findBleDeviceByName(String? name) {
    if (name == null || name.isEmpty) return null;
    final target = name.toLowerCase();
    for (final entry in _bleDevices.entries) {
      final deviceName = entry.value.platformName.toLowerCase();
      if (deviceName == target ||
          deviceName.contains(target) ||
          target.contains(deviceName)) {
        return entry.value;
      }
    }
    return null;
  }

  void _emitMidiBytes(List<int> data, {required String source}) {
    final isExternalTransport = source == 'OS MIDI' || source == 'Wi-Fi Bridge' || source == 'BLE MIDI';
    if (isExternalTransport) {
      AudioPlayerService().setExternalMidiPerformanceActive(true);
    }
    _midiStream.add(data);
    if (_verboseLogging) {
      AppDebugLogService.instance.add('MIDI', '$source bytes: $data');
    }
    if (data.length < 2) return;
    final status = data[0] & 0xF0;
    if (status == 0x90 && data.length >= 3) {
      final rawNote = data[1];
      final velocity = data[2];
      if (velocity > 0) {
        if (_calibrationArmed && _activeInputDeviceId != null) {
          final deviceOffset = _signedMod12Distance(
            rawNote % 12,
            _calibrationTargetPitchClass,
          );
          _deviceTranspose[_activeInputDeviceId!] = deviceOffset;
          _calibrationArmed = false;
          LiveMidiNoteService.instance.clear();
          _persistDeviceTranspose();
          _log(
            'Calibrated ${_activeInputDeviceName ?? _activeInputDeviceId}: target ${_calibrationTargetLabel}, raw note=$rawNote, device align ${_signed(deviceOffset)}, effective ${_signed(effectiveTranspose)}',
          );
        }
        final note = _applyTranspose(rawNote);
        LiveMidiNoteService.instance.noteOn(note, velocity / 127.0);
        _eventStream.add(
          MidiInputEvent.noteOn(note: note, velocity: velocity, source: source),
        );
        if (_verboseLogging) {
          AppDebugLogService.instance.add(
            'MIDI',
            '$source note on: raw=$rawNote mapped=$note velocity=$velocity align=${_signed(effectiveTranspose)}',
          );
        }
      } else {
        final note = _applyTranspose(rawNote);
        LiveMidiNoteService.instance.noteOff(note);
        _eventStream.add(MidiInputEvent.noteOff(note: note, source: source));
        if (_verboseLogging) {
          AppDebugLogService.instance.add(
            'MIDI',
            '$source note off: raw=$rawNote mapped=$note align=${_signed(effectiveTranspose)}',
          );
        }
      }
    } else if (status == 0x80 && data.length >= 3) {
      final rawNote = data[1];
      final note = _applyTranspose(rawNote);
      LiveMidiNoteService.instance.noteOff(note);
      _eventStream.add(MidiInputEvent.noteOff(note: note, source: source));
      if (_verboseLogging) {
        AppDebugLogService.instance.add(
          'MIDI',
          '$source note off: raw=$rawNote mapped=$note align=${_signed(effectiveTranspose)}',
        );
      }
    } else if (status == 0xB0 && data.length >= 3) {
      final controller = data[1];
      final value = data[2];
      if (controller == 64) {
        final enabled = value >= 64;
        _eventStream.add(
          MidiInputEvent.sustain(sustainEnabled: enabled, source: source),
        );
        if (_verboseLogging) {
          AppDebugLogService.instance.add(
            'MIDI',
            '$source sustain: ${enabled ? "on" : "off"}',
          );
        }
      } else if (controller == 120 || controller == 123) {
        unawaited(_panicTransport('$source controller_$controller'));
      } else if (controller == 121) {
        _eventStream.add(
          MidiInputEvent.sustain(sustainEnabled: false, source: source),
        );
        LiveMidiNoteService.instance.clear();
        if (_verboseLogging) {
          AppDebugLogService.instance.add(
            'MIDI',
            '$source reset controllers',
          );
        }
      }
    }
  }


  Future<void> setPreferBle(bool enabled) async {
    _preferBle = enabled;
  }

  Future<void> setManualTranspose(int value) async {
    _manualTranspose = value.clamp(-24, 24);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefManualTranspose, _manualTranspose);
    LiveMidiNoteService.instance.clear();
    _log('Manual MIDI transpose set to ${_signed(_manualTranspose)} semitones');
  }

  Future<void> armCalibration({
    int targetPitchClass = 0,
    String targetLabel = 'C',
  }) async {
    _calibrationArmed = true;
    _calibrationTargetPitchClass = targetPitchClass % 12;
    _calibrationTargetLabel = targetLabel;
    _log('Calibration armed. Play ${_calibrationTargetLabel} on the external keyboard.');
  }

  Future<void> clearCurrentDeviceTranspose() async {
    if (_activeInputDeviceId == null) return;
    _deviceTranspose.remove(_activeInputDeviceId!);
    await _persistDeviceTranspose();
    LiveMidiNoteService.instance.clear();
    _log('Cleared saved alignment for ${_activeInputDeviceName ?? _activeInputDeviceId}');
  }

  void _setActiveInputDevice(String id, String name) {
    _activeInputDeviceId = id;
    _activeInputDeviceName = name;
    final deviceOffset = _deviceTranspose[id] ?? 0;
    _log(
      'Active input device: $name | device align ${_signed(deviceOffset)} | effective ${_signed(effectiveTranspose)}',
    );
  }

  void _clearActiveInputDevice() {
    _activeInputDeviceId = null;
    _activeInputDeviceName = null;
  }

  Future<void> _persistDeviceTranspose() async {
    final prefs = await SharedPreferences.getInstance();
    final entries = _deviceTranspose.entries
        .map((entry) => '${entry.key}::${entry.value}')
        .toList()
      ..sort();
    await prefs.setStringList(_prefDeviceTranspose, entries);
  }


  Future<void> _migrateLegacyWidiOffsets() async {
    final keysToRemove = <String>[];
    _deviceTranspose.forEach((key, value) {
      if (value == -15) {
        keysToRemove.add(key);
      }
    });
    if (keysToRemove.isEmpty) return;
    for (final key in keysToRemove) {
      _deviceTranspose.remove(key);
    }
    await _persistDeviceTranspose();
    LiveMidiNoteService.instance.clear();
    _log('Removed legacy forced device alignment for ${keysToRemove.length} saved device(s)');
  }

  int _applyTranspose(int note) => (note + effectiveTranspose).clamp(0, 127);

  int _signedMod12Distance(int fromPitchClass, int toPitchClass) {
    var diff = (toPitchClass - fromPitchClass) % 12;
    if (diff > 6) diff -= 12;
    return diff;
  }

  String _signed(int value) => value >= 0 ? '+$value' : '$value';

  Future<void> setBridgeUrl(String url) async {
    _bridgeUrl = _normalizeBridgeUrl(url);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('midi_bridge_url', _bridgeUrl);
  }

  Future<void> setWebTransportPreference(WebTransportPreference value) async {
    _webTransportPreference = value;
    await AppSettingsStore.setWebTransportPreference(
      _webTransportPreferenceToString(value),
    );
    if (kIsWeb) {
      await _loadWebDevices(includeBluetoothScan: _shouldUseWebBluetooth());
    }
  }

  bool _shouldUseWebBluetooth() {
    if (!kIsWeb) return false;
    switch (_webTransportPreference) {
      case WebTransportPreference.webBluetooth:
        return true;
      case WebTransportPreference.bridge:
        return false;
      case WebTransportPreference.auto:
        return !_shouldPreferBridgeOnWeb();
    }
  }

  bool _shouldPreferBridgeOnWeb() {
    return _bridge.isConnected ||
        _lastDeviceId == 'bridge' ||
        _webTransportPreference == WebTransportPreference.bridge;
  }

  WebTransportPreference _webTransportPreferenceFromString(String value) {
    switch (value) {
      case 'webBluetooth':
        return WebTransportPreference.webBluetooth;
      case 'bridge':
        return WebTransportPreference.bridge;
      default:
        return WebTransportPreference.auto;
    }
  }

  String _webTransportPreferenceToString(WebTransportPreference value) {
    switch (value) {
      case WebTransportPreference.webBluetooth:
        return 'webBluetooth';
      case WebTransportPreference.bridge:
        return 'bridge';
      case WebTransportPreference.auto:
        return 'auto';
    }
  }

  String _normalizeBridgeUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      return 'ws://127.0.0.1:8765/midi';
    }
    return trimmed.endsWith('/midi') ? trimmed : '$trimmed/midi';
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
  void dispose() {
    _autoReconnectTimer?.cancel();
    _scanSub?.cancel();
    _bleNotifySub?.cancel();
    _sub?.cancel();
    _setupSub?.cancel();
  }

}
