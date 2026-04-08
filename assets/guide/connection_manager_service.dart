import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_midi_command/flutter_midi_command.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as fbp;
import 'dart:convert';

class SavedDevice {
  final String id;
  final String name;
  final String type;
  final DateTime lastConnected;
  final int connectionCount;
  bool autoConnect;

  SavedDevice({
    required this.id,
    required this.name,
    required this.type,
    required this.lastConnected,
    required this.connectionCount,
    this.autoConnect = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'lastConnected': lastConnected.toIso8601String(),
        'connectionCount': connectionCount,
        'autoConnect': autoConnect,
      };

  factory SavedDevice.fromJson(Map<String, dynamic> json) {
    return SavedDevice(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'Unknown',
      lastConnected: DateTime.parse(json['lastConnected'] as String),
      connectionCount: json['connectionCount'] as int? ?? 1,
      autoConnect: json['autoConnect'] as bool? ?? false,
    );
  }
}

class ConnectionManagerService {
  static const String _storageKey = 'saved_bluetooth_devices';
  static List<SavedDevice> _savedDevices = [];
  static bool _autoConnectEnabled = true;

  // Two-stage connection parameters
  final MidiCommand _midiCommand = MidiCommand();
  final Duration osRecognitionRetryInterval = const Duration(milliseconds: 500);
  final Duration osRecognitionTimeout = const Duration(seconds: 10);
  final Duration handshakeDelay = const Duration(milliseconds: 800);

  static Future<void> initialize() async {
    await _loadSavedDevices();
    await _loadAutoConnectPreference();
  }

  static Future<void> _loadSavedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);

      if (data != null) {
        final List<dynamic> jsonList = jsonDecode(data);
        _savedDevices = jsonList
            .map((json) => SavedDevice.fromJson(json as Map<String, dynamic>))
            .toList();

        _savedDevices
            .sort((a, b) => b.lastConnected.compareTo(a.lastConnected));

        debugPrint('📱 Loaded ${_savedDevices.length} saved devices');
      }
    } catch (e) {
      debugPrint('❌ Error loading saved devices: $e');
    }
  }

  static Future<void> _saveSavedDevices() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = _savedDevices.map((d) => d.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
      debugPrint('💾 Saved ${_savedDevices.length} devices to storage');
    } catch (e) {
      debugPrint('❌ Error saving devices: $e');
    }
  }

  static Future<void> _loadAutoConnectPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _autoConnectEnabled = prefs.getBool('auto_connect_enabled') ?? true;
      debugPrint(
          '🔄 Auto-connect: ${_autoConnectEnabled ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('❌ Error loading auto-connect preference: $e');
    }
  }

  static Future<void> setAutoConnectEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('auto_connect_enabled', enabled);
      _autoConnectEnabled = enabled;
      debugPrint('🔄 Auto-connect ${enabled ? "enabled" : "disabled"}');
    } catch (e) {
      debugPrint('❌ Error setting auto-connect: $e');
    }
  }

  static Future<void> saveConnection(
      String id, String name, String type) async {
    try {
      final existingIndex = _savedDevices.indexWhere((d) => d.id == id);

      if (existingIndex >= 0) {
        final existing = _savedDevices[existingIndex];
        _savedDevices[existingIndex] = SavedDevice(
          id: id,
          name: name,
          type: type,
          lastConnected: DateTime.now(),
          connectionCount: existing.connectionCount + 1,
          autoConnect: existing.autoConnect,
        );
        debugPrint(
            '📝 Updated saved device: $name (${existing.connectionCount + 1} connections)');
      } else {
        _savedDevices.add(SavedDevice(
          id: id,
          name: name,
          type: type,
          lastConnected: DateTime.now(),
          connectionCount: 1,
          autoConnect: false,
        ));
        debugPrint('➕ Added new saved device: $name');
      }

      _savedDevices.sort((a, b) => b.lastConnected.compareTo(a.lastConnected));

      await _saveSavedDevices();
    } catch (e) {
      debugPrint('❌ Error saving connection: $e');
    }
  }

  static Future<void> setDeviceAutoConnect(
      String deviceId, bool autoConnect) async {
    try {
      final index = _savedDevices.indexWhere((d) => d.id == deviceId);

      if (index >= 0) {
        for (var device in _savedDevices) {
          device.autoConnect = false;
        }

        _savedDevices[index].autoConnect = autoConnect;

        await _saveSavedDevices();
        debugPrint(
            '🔄 Set auto-connect for ${_savedDevices[index].name}: $autoConnect');
      }
    } catch (e) {
      debugPrint('❌ Error setting device auto-connect: $e');
    }
  }

  static Future<void> removeDevice(String deviceId) async {
    try {
      _savedDevices.removeWhere((d) => d.id == deviceId);
      await _saveSavedDevices();
      debugPrint('🗑️ Removed device: $deviceId');
    } catch (e) {
      debugPrint('❌ Error removing device: $e');
    }
  }

  static Future<void> clearAllDevices() async {
    try {
      _savedDevices.clear();
      await _saveSavedDevices();
      debugPrint('🗑️ Cleared all saved devices');
    } catch (e) {
      debugPrint('❌ Error clearing devices: $e');
    }
  }

  static SavedDevice? getAutoConnectDevice() {
    if (!_autoConnectEnabled) return null;

    try {
      return _savedDevices.firstWhere((d) => d.autoConnect);
    } catch (e) {
      return null;
    }
  }

  static SavedDevice? getMostRecentDevice() {
    if (_savedDevices.isEmpty) return null;
    return _savedDevices.first;
  }

  static List<SavedDevice> get savedDevices => List.from(_savedDevices);
  static bool get autoConnectEnabled => _autoConnectEnabled;
  static bool get hasSavedDevices => _savedDevices.isNotEmpty;

  // ============ TWO-STAGE CONNECTION SYSTEM ============

  /// Main two-stage connection method
  /// Stage 1: BLE handshake to wake up the device
  /// Stage 2: Patient wait for OS MIDI registration, then connect
  Future<bool> connectToMidiDevice(
    String deviceId,
    String deviceName, {
    void Function(String status)? onStatus,
    void Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('🔌 Starting two-stage connection to: $deviceName');
      onStatus?.call('Initializing connection...');
      onProgress?.call(0.0);

      // Stage 1: BLE Handshake
      final bleDevice = await _performBleHandshake(
        deviceName,
        onStatus: onStatus,
        onProgress: onProgress,
      );

      if (bleDevice != null) {
        onStatus?.call('Handshake complete, waiting for OS...');
        onProgress?.call(0.3);
      } else {
        debugPrint('⚠️ BLE handshake failed, but continuing to stage 2');
        onStatus?.call('Direct connection attempt...');
      }

      // Small delay to let OS process
      await Future.delayed(handshakeDelay);

      // Stage 2: Patient MIDI Connection
      onStatus?.call('Waiting for MIDI registration...');
      final success = await _patientMidiConnect(
        deviceId,
        deviceName,
        onStatus: onStatus,
        onProgress: onProgress,
      );

      if (success) {
        onStatus?.call('Connected successfully!');
        onProgress?.call(1.0);
        await saveConnection(deviceId, deviceName, 'MIDI Device');
        return true;
      } else {
        onStatus?.call('Connection timeout');
        return false;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ Two-stage connection error: $e\n$stackTrace');
      onStatus?.call('Connection failed: $e');
      return false;
    }
  }

  /// Stage 1: BLE Handshake - Wake up the device
  Future<fbp.BluetoothDevice?> _performBleHandshake(
    String deviceName, {
    void Function(String status)? onStatus,
    void Function(double progress)? onProgress,
  }) async {
    try {
      debugPrint('🔵 Stage 1: BLE Handshake for $deviceName');
      onStatus?.call('Searching for Bluetooth device...');

      // Quick scan to find the BLE device
      final bleDevice = await _findBleDevice(deviceName);

      if (bleDevice == null) {
        debugPrint('⚠️ BLE device not found in scan');
        return null;
      }

      debugPrint('✅ Found BLE device: ${bleDevice.platformName}');
      onStatus?.call('Establishing Bluetooth connection...');
      onProgress?.call(0.15);

      // Check if already connected
      final isConnected = await bleDevice.isConnected;

      if (isConnected) {
        debugPrint('🔄 Device already connected, cycling connection...');
        await bleDevice.disconnect();
        await Future.delayed(const Duration(milliseconds: 300));
      }

      // Connect briefly to trigger OS MIDI registration
      onStatus?.call('Performing handshake...');
      await bleDevice.connect(timeout: const Duration(seconds: 5));
      await Future.delayed(const Duration(milliseconds: 600));

      // Disconnect to let MidiCommand take over
      await bleDevice.disconnect();
      debugPrint('✅ BLE handshake complete');

      return bleDevice;
    } catch (e) {
      debugPrint('⚠️ BLE handshake error (non-fatal): $e');
      return null;
    }
  }

  /// Find BLE device by name
  Future<fbp.BluetoothDevice?> _findBleDevice(String targetName) async {
    final completer = Completer<fbp.BluetoothDevice?>();
    final seenDevices = <String>{};

    debugPrint('🔍 Scanning for BLE device: $targetName');

    try {
      final subscription = fbp.FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          final device = result.device;
          final name = device.platformName.isNotEmpty
              ? device.platformName
              : result.advertisementData.advName;

          if (name.isEmpty || seenDevices.contains(device.remoteId.str)) {
            continue;
          }

          seenDevices.add(device.remoteId.str);

          // Match by name (exact or contains)
          if (name.toLowerCase() == targetName.toLowerCase() ||
              name.toLowerCase().contains(targetName.toLowerCase()) ||
              targetName.toLowerCase().contains(name.toLowerCase())) {
            debugPrint('✅ Matched BLE device: $name');
            if (!completer.isCompleted) {
              completer.complete(device);
            }
          }
        }
      });

      // Start scan
      await fbp.FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 3),
        androidUsesFineLocation: true,
      );

      // Wait for result or timeout
      final device = await completer.future.timeout(
        const Duration(seconds: 3),
        onTimeout: () => null,
      );

      await subscription.cancel();
      await fbp.FlutterBluePlus.stopScan();

      return device;
    } catch (e) {
      debugPrint('⚠️ BLE scan error: $e');
      return null;
    }
  }

  /// Stage 2: Patient MIDI Connection - Wait for OS to register device
  Future<bool> _patientMidiConnect(
    String deviceId,
    String deviceName, {
    void Function(String status)? onStatus,
    void Function(double progress)? onProgress,
  }) async {
    debugPrint('🎹 Stage 2: Patient MIDI Connection');

    final maxAttempts = (osRecognitionTimeout.inMilliseconds /
            osRecognitionRetryInterval.inMilliseconds)
        .ceil();

    int attempt = 0;

    while (attempt < maxAttempts) {
      attempt++;

      try {
        // Refresh MIDI device list from OS
        final devices = await _midiCommand.devices;

        if (devices == null || devices.isEmpty) {
          debugPrint('⏳ Attempt $attempt/$maxAttempts: No MIDI devices yet');
        } else {
          debugPrint(
              '🔍 Attempt $attempt/$maxAttempts: Found ${devices.length} MIDI devices');

          // Try to find our device
          MidiDevice? targetDevice;

          // Try exact ID match first
          try {
            targetDevice = devices.firstWhere((d) => d.id == deviceId);
            debugPrint('✅ Found by ID: ${targetDevice.name}');
          } catch (_) {
            // Try name match as fallback
            try {
              targetDevice = devices.firstWhere(
                (d) =>
                    d.name.toLowerCase() == deviceName.toLowerCase() ||
                    d.name.toLowerCase().contains(deviceName.toLowerCase()) ||
                    deviceName.toLowerCase().contains(d.name.toLowerCase()),
              );
              debugPrint('✅ Found by name: ${targetDevice.name}');
            } catch (_) {
              debugPrint('⚠️ Device not in OS MIDI list yet');
            }
          }

          // If found, try to connect
          if (targetDevice != null) {
            onStatus?.call('Device ready, connecting...');
            debugPrint('🔌 Attempting MidiCommand connection...');

            try {
              await _midiCommand.connectToDevice(targetDevice);
              debugPrint('✅ Successfully connected to ${targetDevice.name}');
              return true;
            } catch (e) {
              debugPrint('❌ MidiCommand connection failed: $e');
              onStatus?.call('Connection failed: $e');
              return false;
            }
          }
        }

        // Update progress
        final progressValue = 0.3 + (attempt / maxAttempts * 0.7);
        onProgress?.call(progressValue);
        onStatus?.call('Waiting for device ($attempt/$maxAttempts)...');

        // Wait before retry
        await Future.delayed(osRecognitionRetryInterval);
      } catch (e) {
        debugPrint('⚠️ Attempt $attempt error: $e');
      }
    }

    debugPrint('❌ Timeout: Device not registered after $maxAttempts attempts');
    onStatus?.call('Timeout: Device not detected by system');
    return false;
  }
}
