
// ============================================
// midi_service.dart - Guide-Based Bluetooth MIDI
// ============================================

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'connection_manager_service.dart';
import 'package:universal_ble/universal_ble.dart' as ub;
import 'web_midi.dart';
import 'local_midi_bridge.dart';

class MidiService {
  final MidiCommand _midiCommand = MidiCommand();
  final ConnectionManagerService _connectionManager =
      ConnectionManagerService();

  // MIDI subscriptions
  StreamSubscription<MidiPacket>? _midiSubscription;
  StreamSubscription<String>? _setupChangeSubscription;

  // flutter_blue_plus for scanning
  StreamSubscription<List<fbp.ScanResult>>? _scanSubscription;
  StreamSubscription<fbp.BluetoothAdapterState>? _adapterStateSubscription;

  MidiDevice? _connectedDevice;
  bool _isConnected = false;
  String _deviceType = '';
  bool _isInitialized = false;
  bool _isScanning = false;
  bool _isConnecting = false;

  // Bluetooth state (from MidiCommand)
  BluetoothState _bluetoothState = BluetoothState.unknown;

  // Enhanced device tracking
  final Map<fbp.DeviceIdentifier, fbp.ScanResult> _bleScanResults = {};
  final List<ub.BleScanResult> _universalBleResults = [];
  final List<MidiDevice> _midiDevices = [];
  Timer? _scanningTimer;
  Timer? _autoConnectTimer;
  Timer? _rescanTimer;
  Timer? _bridgeStatusTimer;

  // Connection memory
  static const String _lastDeviceIdKey = 'last_connected_device_id';
  static const String _lastDeviceNameKey = 'last_connected_device_name';
  static const String _autoConnectKey = 'auto_connect_enabled';
  bool _autoConnectEnabled = true;
  String? _lastConnectedDeviceId;
  String? _lastConnectedDeviceName;
  String? _connectedBleDeviceId;

  // MIDI tracking
  final Set<int> _activeNotes = {};
  final List<String> _debugLog = [];
  int _totalPacketsReceived = 0;
  int _droppedPackets = 0;

  // Callbacks
  Function(List<int>)? onMidiDataReceived;
  Function(bool, String, String)? onConnectionStatusChanged;
  Function(String)? onErrorOccurred;
  Function(String)? onDebugLog;
  Function(List<Map<String, dynamic>>)? onDevicesUpdated;
  Function(bool)? onScanStatusChanged;
  Function(bool)? onConnectionProgressChanged;

  // Packet queue
  final List<List<int>> _packetQueue = [];
  Timer? _packetProcessingTimer;
  static const int maxPacketQueueSize = 200;

  // Diagnostics
  String? _lastScanError;
  String? _lastScanErrorDetail;
  static const String _midiServiceUuid =
      '03b80e5a-ede8-4b33-a751-6ce34ec4c700';
  static const String _bleMidiCharUuid =
      '7772e5db-3868-4112-a1a9-f2669d106bf3';
  final WebMidiAdapter _webMidi = WebMidiAdapter();
  int _midiMessageCount = 0;
  String? _lastMidiMessage;
  DateTime? _lastMidiMessageAt;
  List<Map<String, String>> _webMidiInputs = [];
  final LocalMidiBridgeClient _bridge = LocalMidiBridgeClient();
  bool _bridgeConnected = false;
  String? _bridgeError;
  bool _bleMidiSubscribed = false;

  MidiService() {
    _initialize();
  }

  void _log(String message) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final logEntry = '[$timestamp] $message';
    _debugLog.add(logEntry);
    if (_debugLog.length > 1000) _debugLog.removeAt(0);
    debugPrint('?? $message');
    onDebugLog?.call(logEntry);
  }

  Future<void> _initialize() async {
    if (_isInitialized) return;

    try {
      _log('?? Initializing MIDI service (guide method)...');
      if (kIsWeb) {
        _log('?? Web: Bluetooth requires HTTPS and a user gesture');
      }
      await ConnectionManagerService.initialize();
      await _loadConnectionMemory();
      await _requestPermissions();
      await _initializeBluetoothAdapter();

      if (kIsWeb) {
        _webMidi.setOnData((data) {
          _handleMidiBytes(data);
        });
        _webMidi.setOnStateChanged(() {
          _webMidiInputs = _webMidi.inputs;
        });
        ub.UniversalBle.onValueChanged =
            (deviceId, characteristic, value) {
          if (characteristic.toLowerCase() ==
              _bleMidiCharUuid.toLowerCase()) {
            final bytes = _parseBleMidi(value);
            if (bytes.isNotEmpty) {
              _handleMidiBytes(bytes);
              onMidiDataReceived?.call(bytes);
            }
          }
        };
      }

      if (defaultTargetPlatform == TargetPlatform.macOS) {
        try {
          await _midiCommand.startBluetoothCentral();
          _log('? MIDI Bluetooth Central started');
        } catch (e) {
          _log('?? MIDI Bluetooth init failed: $e');
        }
      }

      if (!kIsWeb) {
        _midiSubscription = _midiCommand.onMidiDataReceived?.listen(
          _handleMidiPacket,
          onError: (error) {
            _log('? MIDI data error: $error');
            onErrorOccurred?.call('MIDI data error: $error');
          },
        );

        _setupChangeSubscription =
            _midiCommand.onMidiSetupChanged?.listen((_) {
          _log('?? MIDI setup changed');
          _refreshMidiDevices();
        });

        try {
          _bluetoothState = await _midiCommand.bluetoothState;
        } catch (_) {}
      }

      _startPacketProcessing();
      _isInitialized = true;
      _log('? MIDI service initialized');
      _log('?? Auto-connect: $_autoConnectEnabled');
      _log('?? Last device: ${_lastConnectedDeviceName ?? "None"}');

      if (!kIsWeb) {
        await _performComprehensiveScan();
      } else {
        _lastScanError =
            'Web Bluetooth requires a user gesture. Tap Scan to choose a device.';
      }
    } catch (e) {
      _log('? Initialization error: $e');
      onErrorOccurred?.call('Failed to initialize: $e');
    }
  }

  Future<void> _initializeBluetoothAdapter() async {
    if (kIsWeb) {
      _log('?? Web: Bluetooth adapter state not available');
      return;
    }
    try {
      _log('?? Initializing flutter_blue_plus adapter...');
      _adapterStateSubscription =
          fbp.FlutterBluePlus.adapterState.listen((state) {
        _log('?? Bluetooth adapter state: $state');
        if (state == fbp.BluetoothAdapterState.on) {
          _log('? Bluetooth is ON');
        } else if (state == fbp.BluetoothAdapterState.off) {
          _lastScanError = 'Bluetooth is off';
          _log('?? Bluetooth is OFF');
          onErrorOccurred?.call('Bluetooth is off. Please enable Bluetooth.');
        }
      });

      final currentState = await fbp.FlutterBluePlus.adapterState.first;
      _log('?? Current Bluetooth state: $currentState');

      if (currentState != fbp.BluetoothAdapterState.on) {
        _lastScanError = 'Bluetooth is off';
        _log('?? Bluetooth not enabled');
      }
    } catch (e) {
      _log('?? Bluetooth adapter init failed: $e');
    }
  }

  Future<void> _loadConnectionMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _lastConnectedDeviceId = prefs.getString(_lastDeviceIdKey);
      _lastConnectedDeviceName = prefs.getString(_lastDeviceNameKey);
      _autoConnectEnabled = prefs.getBool(_autoConnectKey) ?? true;
      if (_lastConnectedDeviceId != null) {
        _log('?? Found previous device: $_lastConnectedDeviceName');
      }
    } catch (e) {
      _log('?? Failed to load connection memory: $e');
    }
  }

  Future<void> _saveConnectionMemory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_connectedDevice != null) {
        await prefs.setString(_lastDeviceIdKey, _connectedDevice!.id);
        await prefs.setString(_lastDeviceNameKey, _connectedDevice!.name);
        _lastConnectedDeviceId = _connectedDevice!.id;
        _lastConnectedDeviceName = _connectedDevice!.name;
        _log('?? Saved connection: ${_connectedDevice!.name}');
      }
      await prefs.setBool(_autoConnectKey, _autoConnectEnabled);
    } catch (e) {
      _log('?? Failed to save connection memory: $e');
    }
  }

  Future<void> setAutoConnect(bool enabled) async {
    _autoConnectEnabled = enabled;
    await _saveConnectionMemory();
    _log('?? Auto-connect: ${enabled ? "enabled" : "disabled"}');
  }

  Future<void> _requestPermissions() async {
    if (kIsWeb) {
      _log('?? Web: browser manages Bluetooth permissions');
      return;
    }
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      _log('? macOS permissions via entitlements');
      return;
    }

    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    for (var permission in permissions) {
      final status = await permission.status;
      if (!status.isGranted) {
        final result = await permission.request();
        _log('?? Permission $permission: $result');
        if (!result.isGranted) {
          _lastScanError = 'Permission denied: ${permission.toString()}';
          _log('?? Permission $permission denied');
        }
      }
    }
  }

  Future<bool> ensurePermissionsAndServices() async {
    if (kIsWeb) {
      return true;
    }
    await _requestPermissions();

    if (defaultTargetPlatform == TargetPlatform.macOS) return true;

    final permissionsOk = await Permission.bluetoothScan.isGranted &&
        await Permission.bluetoothConnect.isGranted &&
        await Permission.location.isGranted;

    if (!permissionsOk) {
      _lastScanError = 'Bluetooth or Location permission not granted';
      onErrorOccurred?.call(
          'Please grant Bluetooth + Location permissions in Settings.');
      return false;
    }

    try {
      _bluetoothState = await _midiCommand.bluetoothState;
      if (_bluetoothState == BluetoothState.poweredOff) {
        _lastScanError = 'Bluetooth is turned off';
        onErrorOccurred?.call('Bluetooth is off. Please turn it on.');
        return false;
      }
    } catch (_) {}

    return true;
  }

  Future<void> _performComprehensiveScan() async {
    _log('?? Starting comprehensive scan...');
    await _refreshMidiDevices();
    await _startBluetoothScanning();
    _setupPeriodicRescan();
  }

  Future<void> _refreshMidiDevices() async {
    if (kIsWeb) {
      _log('?? Web: OS MIDI device list not available');
      return;
    }
    try {
      final devices = await _midiCommand.devices;
      _log('?? MIDI devices from OS: ${devices?.length ?? 0}');
      if (devices != null) {
        _midiDevices.clear();
        _midiDevices.addAll(devices);
      }
    } catch (e) {
      _log('?? Refresh MIDI devices failed: $e');
    }
  }

  Future<void> _startBluetoothScanning() async {
    if (_isScanning) {
      _log('?? Already scanning');
      return;
    }

    if (kIsWeb) {
      _log('?? Web: using Universal BLE scan');
      _isScanning = true;
      onScanStatusChanged?.call(true);
      _bleScanResults.clear();
      await _scanUniversalBleFallback(userInitiated: true);
      _mergeDeviceLists();
      _isScanning = false;
      onScanStatusChanged?.call(false);
      return;
    }

    try {
      _log('?? Starting flutter_blue_plus scan...');
      _isScanning = true;
      onScanStatusChanged?.call(true);
      _bleScanResults.clear();

      _scanSubscription =
          fbp.FlutterBluePlus.scanResults.listen((results) async {
        bool listChanged = false;

        for (var result in results) {
          final device = result.device;
          var name = device.platformName.isNotEmpty
              ? device.platformName
              : result.advertisementData.advName;

          if (name.isEmpty) {
            final hasMidiService = result.advertisementData.serviceUuids
                .any((uuid) =>
                    uuid.toString().toLowerCase() == _midiServiceUuid);
            if (hasMidiService) {
              name = 'BLE MIDI Device';
            } else {
              continue;
            }
          }

          if (!_bleScanResults.containsKey(device.remoteId)) {
            _log('?? Found BLE device: $name (${device.remoteId.str})');
            listChanged = true;
          }

          _bleScanResults[device.remoteId] = result;
        }

        if (listChanged) {
          await _refreshMidiDevices();
          _mergeDeviceLists();
        }
      }, onError: (e) {
        _lastScanError = 'Scan error: $e';
        _log('? Scan error: $e');
      });

      await fbp.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 12),
        androidUsesFineLocation: true,
      );

      _log('? Bluetooth scanning started');
      _scanUniversalBleFallback();

      _scanningTimer?.cancel();
      _scanningTimer =
          Timer(const Duration(seconds: 12), _stopBluetoothScanning);
    } catch (e) {
      _lastScanError = 'Scan start failed: $e';
      _log('? Scan start failed: $e');
      _isScanning = false;
      onScanStatusChanged?.call(false);
    }
  }

  Future<void> _stopBluetoothScanning() async {
    if (!_isScanning) return;

    try {
      await fbp.FlutterBluePlus.stopScan();
      _scanSubscription?.cancel();
      _scanningTimer?.cancel();
      _isScanning = false;
      onScanStatusChanged?.call(false);
      _log('? Bluetooth scanning stopped');
    } catch (e) {
      _log('?? Scan stop failed: $e');
    }
  }

  List<Map<String, dynamic>> _mergeDeviceLists() {
    final Map<String, Map<String, dynamic>> unifiedDevices = {};
    const midiServiceUuid = _midiServiceUuid;

    final Map<String, MidiDevice> midiDeviceMap = {
      for (var device in _midiDevices) device.name.toLowerCase(): device
    };
    final Map<String, MidiDevice> midiDeviceNormalized = {
      for (var device in _midiDevices) _normalizeName(device.name): device
    };

    for (final result in _bleScanResults.values) {
      final bleDevice = result.device;
      final advData = result.advertisementData;
      var name = bleDevice.platformName.isNotEmpty
          ? bleDevice.platformName
          : advData.advName;
      if (name.isEmpty) {
        name = advData.serviceUuids
                .any((uuid) => uuid.toString().toLowerCase() == midiServiceUuid)
            ? 'BLE MIDI Device'
            : 'Bluetooth Device';
      }
      final id = bleDevice.remoteId.str;

      final bool isMidiByUuid = advData.serviceUuids
          .any((uuid) => uuid.toString().toLowerCase() == midiServiceUuid);
      final lowerName = name.toLowerCase();
      final normalizedName = _normalizeName(lowerName);
      final bool isMidiByName = lowerName.contains('midi') ||
          lowerName.contains('widi') ||
          lowerName.contains('keyboard') ||
          lowerName.contains('piano');
      final bool isPotentiallyMidi = isMidiByUuid || isMidiByName;

      MidiDevice? matchingMidiDevice = midiDeviceMap[lowerName];
      matchingMidiDevice ??= midiDeviceNormalized[normalizedName];
      if (matchingMidiDevice == null) {
        for (final entry in midiDeviceNormalized.entries) {
          if (entry.key.contains(normalizedName) ||
              normalizedName.contains(entry.key)) {
            matchingMidiDevice = entry.value;
            break;
          }
        }
      }

      unifiedDevices[id] = {
        'id': matchingMidiDevice?.id ?? id,
        'name': name,
        'type': _identifyDeviceType(name, isMidi: isPotentiallyMidi),
        'isMidi': isPotentiallyMidi,
        'isConnectable': matchingMidiDevice != null || isPotentiallyMidi,
        'source': 'Bluetooth',
        'connected': _connectedDevice?.id == matchingMidiDevice?.id,
        'bleDevice': bleDevice,
        'bleDeviceId': id,
        'midiDevice': matchingMidiDevice,
        'midiDeviceId': matchingMidiDevice?.id,
        'isReliable': isPotentiallyMidi,
        'isBleOnly': matchingMidiDevice == null,
      };

      if (matchingMidiDevice != null) {
        midiDeviceMap.remove(matchingMidiDevice.name.toLowerCase());
        midiDeviceNormalized.remove(_normalizeName(matchingMidiDevice.name));
      }
    }

    for (final entry in _universalBleResults) {
      final name =
          (entry.name?.isNotEmpty ?? false) ? entry.name! : 'Bluetooth Device';
      final id = entry.deviceId;
      if (unifiedDevices.containsKey(id)) {
        continue;
      }

      final lowerName = name.toLowerCase();
      final normalizedName = _normalizeName(lowerName);
      final bool isMidiByUuid = entry.services
          .any((uuid) => uuid.toLowerCase() == midiServiceUuid);
      final bool isMidiByName = lowerName.contains('midi') ||
          lowerName.contains('widi') ||
          lowerName.contains('keyboard') ||
          lowerName.contains('piano');
      final bool isPotentiallyMidi = isMidiByUuid || isMidiByName;

      MidiDevice? matchingMidiDevice = midiDeviceMap[lowerName];
      matchingMidiDevice ??= midiDeviceNormalized[normalizedName];
      if (matchingMidiDevice == null) {
        for (final entryName in midiDeviceNormalized.entries) {
          if (entryName.key.contains(normalizedName) ||
              normalizedName.contains(entryName.key)) {
            matchingMidiDevice = entryName.value;
            break;
          }
        }
      }

      unifiedDevices[id] = {
        'id': matchingMidiDevice?.id ?? id,
        'name': name,
        'type': _identifyDeviceType(name, isMidi: isPotentiallyMidi),
        'isMidi': isPotentiallyMidi,
        'isConnectable': matchingMidiDevice != null || isPotentiallyMidi,
        'source': 'Universal BLE',
        'connected': _connectedDevice?.id == matchingMidiDevice?.id,
        'bleDevice': null,
        'bleDeviceId': id,
        'midiDevice': matchingMidiDevice,
        'midiDeviceId': matchingMidiDevice?.id,
        'isReliable': isPotentiallyMidi,
        'isBleOnly': matchingMidiDevice == null,
      };

      if (matchingMidiDevice != null) {
        midiDeviceMap.remove(matchingMidiDevice.name.toLowerCase());
        midiDeviceNormalized.remove(_normalizeName(matchingMidiDevice.name));
      }
    }

    for (final midiDevice in midiDeviceMap.values) {
      unifiedDevices[midiDevice.id] = {
        'id': midiDevice.id,
        'name': midiDevice.name,
        'type': _identifyDeviceType(midiDevice.name, isMidi: true),
        'isMidi': true,
        'isConnectable': true,
        'source': midiDevice.type,
        'connected': _connectedDevice?.id == midiDevice.id,
        'bleDevice': null,
        'bleDeviceId': null,
        'midiDevice': midiDevice,
        'midiDeviceId': midiDevice.id,
        'isReliable': true,
        'isBleOnly': false,
      };
    }

    final deviceList = unifiedDevices.values.toList();
    deviceList.sort((a, b) {
      if (a['connected'] == true && b['connected'] != true) return -1;
      if (a['connected'] != true && b['connected'] == true) return 1;
      if (a['isMidi'] == true && b['isMidi'] != true) return -1;
      if (a['isMidi'] != true && b['isMidi'] == true) return 1;
      return (a['name'] as String).compareTo(b['name'] as String);
    });

    onDevicesUpdated?.call(deviceList);
    return deviceList;
  }

  String _normalizeName(String name) {
    return name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  String _identifyDeviceType(String name, {bool isMidi = false}) {
    final lower = name.toLowerCase();
    if (lower.contains('oxygen 88')) return 'M-Audio Oxygen 88';
    if (lower.contains('oxygen')) return 'M-Audio Oxygen';
    if (lower.contains('widi')) return 'WIDI MIDI Adapter';
    if (lower.contains('piano') || lower.contains('keyboard')) {
      return 'Piano/Keyboard';
    }
    if (lower.contains('midi')) return 'MIDI Device';
    if (isMidi) return 'MIDI Device';
    return 'Bluetooth Device';
  }

  void _setupPeriodicRescan() {
    _rescanTimer?.cancel();
    _rescanTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (!_isConnected && !_isScanning && !_isConnecting) {
        _log('?? Periodic rescan...');
        _refreshMidiDevices();
        _mergeDeviceLists();
      }
    });
  }

  void _scheduleAutoConnect() {
    _autoConnectTimer?.cancel();
    _autoConnectTimer = Timer(const Duration(seconds: 2), _attemptAutoConnect);
  }

  Future<void> _attemptAutoConnect() async {
    if (!_autoConnectEnabled ||
        _isConnected ||
        _isConnecting ||
        _lastConnectedDeviceId == null) {
      return;
    }

    try {
      _log('?? Attempting auto-connect to: $_lastConnectedDeviceName');
      await _refreshMidiDevices();

      final midiDevice = _midiDevices.firstWhere(
        (d) => d.id == _lastConnectedDeviceId,
        orElse: () =>
            throw Exception('Previous device not found in OS MIDI list'),
      );

      await connectToDevice(midiDevice.id, midiDevice.name);
    } catch (e) {
      _log('?? Auto-connect failed: $e');
    }
  }

  /// Two-stage connection (guide method)
  Future<void> connectToDevice(
    String deviceId,
    String deviceName, {
    String? bleDeviceId,
    bool nameOnly = false,
  }) async {
    if (_isConnecting) {
      _log('?? Connection already in progress');
      return;
    }

    try {
      _isConnecting = true;
      onConnectionProgressChanged?.call(true);
      _log('?? Connecting to: $deviceName ($deviceId)');

      if (kIsWeb) {
        final targetId = bleDeviceId ?? deviceId;
        _connectedBleDeviceId = targetId;
        try {
          await ub.UniversalBle.connect(targetId);
          await _setupWebBleMidi(targetId);
          _isConnected = true;
          _deviceType = _identifyDeviceType(deviceName, isMidi: true);
          onConnectionStatusChanged?.call(true, deviceName, _deviceType);
          _log('? Web Bluetooth connected to: $deviceName');
          return;
        } catch (e) {
          _log('?? Web Bluetooth connect failed: $e');
          onErrorOccurred?.call('Web Bluetooth connect failed: $e');
          rethrow;
        }
      }

      // Disconnect existing connection
      if (_connectedDevice != null) {
        _midiCommand.disconnectDevice(_connectedDevice!);
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Use two-stage connection
      final success = await _connectionManager.connectToMidiDevice(
        deviceId,
        deviceName,
        bleDeviceId: bleDeviceId,
        nameOnly: nameOnly,
        onStatus: (status) {
          _log('?? Connection: $status');
        },
        onProgress: (progress) {
          _log('?? Progress: ${(progress * 100).toStringAsFixed(0)}%');
        },
      );

      if (success) {
        // Verify connection by getting device
        await _refreshMidiDevices();
        final device = _midiDevices.firstWhere(
          (d) => d.id == deviceId || d.name == deviceName,
          orElse: () => throw Exception('Device not found after connection'),
        );

        _connectedDevice = device;
        _isConnected = true;
        _deviceType = _identifyDeviceType(deviceName, isMidi: true);
        _activeNotes.clear();
        _packetQueue.clear();
        _droppedPackets = 0;

        await _saveConnectionMemory();
        await ConnectionManagerService.saveConnection(
            deviceId, deviceName, _deviceType);

        onConnectionStatusChanged?.call(true, deviceName, _deviceType);
        _log('? Connected to: $deviceName');
      } else {
        throw Exception('Two-stage connection failed');
      }
    } catch (e, stackTrace) {
      _log('❌ Connection failed: $e\\n$stackTrace');
      _isConnected = false;
      onConnectionStatusChanged?.call(false, '', '');
      onErrorOccurred?.call('Connection failed: $e');
      rethrow;
    } finally {
      _isConnecting = false;
      onConnectionProgressChanged?.call(false);
    }
  }

  void _startPacketProcessing() {
    _packetProcessingTimer = Timer.periodic(
      const Duration(milliseconds: 5),
      (_) => _processPacketQueue(),
    );
  }

  void _processPacketQueue() {
    if (_packetQueue.isEmpty) return;

    final batchSize = (_packetQueue.length / 2).ceil().clamp(1, 20);

    for (var i = 0; i < batchSize && _packetQueue.isNotEmpty; i++) {
      final packet = _packetQueue.removeAt(0);
      onMidiDataReceived?.call(packet);
    }
  }

  void _handleMidiPacket(MidiPacket packet) {
    _handleMidiBytes(packet.data);
  }

  void _handleMidiBytes(List<int> data) {
    try {
      if (data.isEmpty) return;

      _totalPacketsReceived++;
      final messages = _parseMidiPacket(data);

      for (final data in messages) {
        if (data.length < 2) continue;

        final status = data[0];
        final statusType = status & 0xF0;

        if (statusType == 0x90 || statusType == 0x80) {
          if (data.length >= 3) {
            final note = data[1];
            final velocity = data[2];

            if (note >= 21 && note <= 108) {
              if (statusType == 0x90 && velocity > 0) {
                _activeNotes.add(note);
              } else {
                _activeNotes.remove(note);
              }

              if (_packetQueue.length < maxPacketQueueSize) {
                _packetQueue.add(data);
              } else {
                _droppedPackets++;
              }
            }
          }
        } else if (statusType == 0xB0 && data.length >= 3) {
          if (_packetQueue.length < maxPacketQueueSize) {
            _packetQueue.add(data);
          }
        }
      }

      _midiMessageCount++;
      _lastMidiMessageAt = DateTime.now();
      _lastMidiMessage = messages.isNotEmpty ? messages.first.join(',') : null;
      if (kIsWeb && !_isConnected) {
        final name =
            _webMidiInputs.isNotEmpty ? _webMidiInputs.first['name'] ?? '' : '';
        _isConnected = true;
        _deviceType = 'MIDI Device';
        onConnectionStatusChanged?.call(true, name, _deviceType);
      }
    } catch (e) {
      _log('? Packet handler error: $e');
    }
  }

  Future<void> _setupWebBleMidi(String deviceId) async {
    try {
      final services = await ub.UniversalBle.discoverServices(deviceId);
      final service = services.firstWhere(
        (s) => s.uuid.toLowerCase() == _midiServiceUuid.toLowerCase(),
        orElse: () => services.first,
      );
      final characteristic = service.characteristics.firstWhere(
        (c) => c.uuid.toLowerCase() == _bleMidiCharUuid.toLowerCase(),
        orElse: () => service.characteristics.first,
      );
      await ub.UniversalBle.setNotifiable(
        deviceId,
        service.uuid,
        characteristic.uuid,
        ub.BleInputProperty.notification,
      );
      _bleMidiSubscribed = true;
      _log('?? BLE MIDI notifications enabled');
    } catch (e) {
      _bleMidiSubscribed = false;
      _lastScanError = 'BLE MIDI subscribe failed';
      _lastScanErrorDetail = e.toString();
      _log('?? BLE MIDI subscribe failed: $e');
    }
  }

  List<int> _parseBleMidi(List<int> packet) {
    // BLE MIDI packets contain timestamp bytes (0x80+) that must be stripped.
    final result = <int>[];
    int i = 0;
    while (i < packet.length) {
      final b = packet[i];
      // Timestamp high byte (0x80-0xBF) followed by timestamp low (0x80-0xFF)
      if (b >= 0x80 && b <= 0xBF && i + 1 < packet.length && packet[i + 1] >= 0x80) {
        i += 2;
        continue;
      }
      // If byte looks like a timestamp-only byte (0x80-0xBF) and next is data,
      // skip it.
      if (b >= 0x80 && b <= 0xBF && i + 1 < packet.length && packet[i + 1] < 0x80) {
        i += 1;
        continue;
      }
      result.add(b);
      i += 1;
    }
    return result;
  }

  List<List<int>> _parseMidiPacket(List<int> packet) {
    final messages = <List<int>>[];

    for (int i = 0; i < packet.length; i++) {
      if (packet[i] >= 0x80 && packet[i] <= 0xEF) {
        final status = packet[i];
        final statusType = status & 0xF0;

        if (statusType >= 0x80 && statusType <= 0xE0) {
          if (i + 2 < packet.length &&
              packet[i + 1] < 0x80 &&
              packet[i + 2] < 0x80) {
            messages.add([packet[i], packet[i + 1], packet[i + 2]]);
            i += 2;
          }
        } else if (statusType == 0xC0 || statusType == 0xD0) {
          if (i + 1 < packet.length && packet[i + 1] < 0x80) {
            messages.add([packet[i], packet[i + 1]]);
            i += 1;
          }
        }
      }
    }

    return messages;
  }

  Future<List<Map<String, dynamic>>> scanForDevices() async {
    _log('?? Manual scan requested...');
    if (kIsWeb) {
      await _webMidi.requestAccess(log: _log);
      _webMidiInputs = _webMidi.inputs;
      await _scanUniversalBleFallback(userInitiated: true);
    } else {
      await _refreshMidiDevices();
      await _startBluetoothScanning();
      await Future.delayed(const Duration(seconds: 4));
      await _stopBluetoothScanning();
      await _scanUniversalBleFallback();
    }

    final list = _mergeDeviceLists();
    if (list.isEmpty) {
      _provideScanHelp();
    }
    return list;
  }

  void _provideScanHelp() {
    if (kIsWeb) {
      if (_webMidiInputs.isEmpty) {
        _lastScanError =
            'No Web MIDI inputs detected. Pair the MIDI device in OS settings or use a USB MIDI device, then click Scan again.';
      } else {
        _lastScanError =
            'No devices found. On web, tap Scan and select a device in the browser prompt.';
      }
    } else {
      _lastScanError =
          'No devices found. Ensure device is on, in pairing mode, and within range.';
    }
    onErrorOccurred?.call(_lastScanError!);
  }

  Future<void> _scanUniversalBleFallback({bool userInitiated = false}) async {
    if (defaultTargetPlatform == TargetPlatform.macOS) return;

    try {
      if (kIsWeb && !userInitiated) {
        _lastScanError =
            'Web Bluetooth requires a user gesture. Tap Scan to choose a device.';
        _lastScanErrorDetail = 'userGestureRequired';
        _log('?? Web Bluetooth requires user gesture');
        return;
      }

      _universalBleResults.clear();
      ub.UniversalBle.onScanResult = (result) {
        _universalBleResults.add(result);
      };
      await ub.UniversalBle.startScan(
        scanFilter:
            kIsWeb ? null : ub.ScanFilter(withServices: [_midiServiceUuid]),
      );
      await Future.delayed(const Duration(seconds: 4));
      await ub.UniversalBle.stopScan();
      _log('?? Universal BLE results: ${_universalBleResults.length}');
    } catch (e) {
      _lastScanError = 'Universal BLE scan failed';
      _lastScanErrorDetail = e.toString();
      if (kIsWeb) {
        try {
          final availability =
              await ub.UniversalBle.getBluetoothAvailabilityState();
          _lastScanErrorDetail =
              '${_lastScanErrorDetail ?? ""} availability=$availability';
        } catch (err) {
          _lastScanErrorDetail =
              '${_lastScanErrorDetail ?? ""} availabilityError=$err';
        }
      }
      _log('?? Universal BLE scan failed: $e');
    } finally {
      ub.UniversalBle.onScanResult = null;
    }
  }

  List<Map<String, dynamic>> getBleScanSnapshot() {
    const midiServiceUuid = _midiServiceUuid;
    final results = <Map<String, dynamic>>[];

    for (final entry in _bleScanResults.values) {
      final adv = entry.advertisementData;
      final hasMidiService = adv.serviceUuids
          .any((uuid) => uuid.toString().toLowerCase() == midiServiceUuid);
      results.add({
        'id': entry.device.remoteId.str,
        'name': entry.device.platformName.isNotEmpty
            ? entry.device.platformName
            : adv.advName,
        'rssi': entry.rssi,
        'services': adv.serviceUuids.map((e) => e.toString()).toList(),
        'isMidiByUuid': hasMidiService,
        'source': 'flutter_blue_plus',
      });
    }

    for (final entry in _universalBleResults) {
      final hasMidiService = entry.services
          .any((uuid) => uuid.toLowerCase() == midiServiceUuid);
      results.add({
        'id': entry.deviceId,
        'name': entry.name ?? '',
        'rssi': entry.rssi,
        'services': entry.services,
        'isMidiByUuid': hasMidiService,
        'source': 'universal_ble',
      });
    }

    return results;
  }

  List<Map<String, dynamic>> getMidiDeviceSnapshot() {
    return _midiDevices
        .map((device) => {
              'id': device.id,
              'name': device.name,
              'type': device.type,
              'connected': device.connected,
            })
        .toList();
  }


  Future<void> disconnect() async {
    try {
      if (kIsWeb && _connectedBleDeviceId != null) {
        _log('?? Web Bluetooth disconnecting...');
        await ub.UniversalBle.disconnect(_connectedBleDeviceId!);
        _connectedBleDeviceId = null;
      }
      if (_connectedDevice != null) {
        _log('?? Disconnecting...');
        _midiCommand.disconnectDevice(_connectedDevice!);
        _connectedDevice = null;
      }

      _isConnected = false;
      _deviceType = '';
      _packetQueue.clear();
      _activeNotes.clear();
      onConnectionStatusChanged?.call(false, '', '');
      _log('? Disconnected');
    } catch (e) {
      _log('? Disconnect error: $e');
    }
  }

  void sendMidiData(List<int> data) {
    if (kIsWeb) {
      _log('?? Web: sendMidiData not supported');
      return;
    }
    if (!_isConnected || _connectedDevice == null) return;
    try {
      _midiCommand.sendData(Uint8List.fromList(data));
    } catch (e) {
      _log('? Error sending MIDI: $e');
    }
  }

  Map<String, dynamic> getDebugStats() {
    return {
      'connected': _isConnected,
      'connecting': _isConnecting,
      'deviceType': _deviceType,
      'totalPackets': _totalPacketsReceived,
      'droppedPackets': _droppedPackets,
      'queueSize': _packetQueue.length,
      'activeNotes': _activeNotes.length,
      'activeNotesList': _activeNotes.toList(),
      'bluetoothDevices': _bleScanResults.length,
      'midiDevices': _midiDevices.length,
      'isScanning': _isScanning,
      'autoConnect': _autoConnectEnabled,
      'lastDevice': _lastConnectedDeviceName,
      'connectedBleDeviceId': _connectedBleDeviceId,
      'webMidiInputs': _webMidiInputs.length,
      'midiMessageCount': _midiMessageCount,
      'lastMidiMessageAt': _lastMidiMessageAt?.toIso8601String(),
      'bleMidiSubscribed': _bleMidiSubscribed,
    };
  }

  List<String> getDebugLog() => List.from(_debugLog);
  bool get isConnected => _isConnected;
  bool get isScanning => _isScanning;
  bool get isConnecting => _isConnecting;
  bool get autoConnectEnabled => _autoConnectEnabled;
  bool get isInitialized => _isInitialized;
  String get deviceType => _deviceType;
  String? get lastConnectedDeviceName => _lastConnectedDeviceName;
  Set<int> get activeNotes => Set.from(_activeNotes);
  MidiDevice? get connectedDevice => _connectedDevice;
  BluetoothState get bluetoothState => _bluetoothState;
  int get queueSize => _packetQueue.length;
  int get droppedPackets => _droppedPackets;
  String? get lastScanError => _lastScanError;
  String? get lastScanErrorDetail => _lastScanErrorDetail;
  int get midiMessageCount => _midiMessageCount;
  String? get lastMidiMessage => _lastMidiMessage;
  DateTime? get lastMidiMessageAt => _lastMidiMessageAt;
  List<Map<String, String>> get webMidiInputs => List.from(_webMidiInputs);

  void dispose() {
    _scanningTimer?.cancel();
    _autoConnectTimer?.cancel();
    _rescanTimer?.cancel();
    _packetProcessingTimer?.cancel();
    _midiSubscription?.cancel();
    _setupChangeSubscription?.cancel();
    _scanSubscription?.cancel();
    _adapterStateSubscription?.cancel();

    if (_connectedDevice != null) {
      _midiCommand.disconnectDevice(_connectedDevice!);
    }

    _log('? MIDI service disposed');
  }
}




