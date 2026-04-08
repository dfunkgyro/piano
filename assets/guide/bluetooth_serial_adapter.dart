import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

/// Optional fallback adapter using flutter_bluetooth_serial
/// Use this when flutter_midi_command fails consistently
///
/// Installation:
/// Add to pubspec.yaml:
/// ```yaml
/// dependencies:
///   flutter_bluetooth_serial: ^0.4.0
/// ```

class BluetoothSerialAdapter {
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _dataSubscription;

  bool _isConnected = false;
  Function(List<int>)? onDataReceived;
  Function(String)? onError;
  Function(String)? onLog;

  BluetoothSerialAdapter();

  void _log(String message) {
    debugPrint('🔵 BT Serial: $message');
    onLog?.call(message);
  }

  /// Check if Bluetooth is available and enabled
  Future<bool> isBluetoothAvailable() async {
    try {
      final isAvailable = await _bluetooth.isAvailable ?? false;
      final isEnabled = await _bluetooth.isEnabled ?? false;

      _log('Bluetooth available: $isAvailable, enabled: $isEnabled');
      return isAvailable && isEnabled;
    } catch (e) {
      _log('Error checking Bluetooth: $e');
      return false;
    }
  }

  /// Request to enable Bluetooth
  Future<bool> requestEnable() async {
    try {
      final result = await _bluetooth.requestEnable();
      _log('Bluetooth enable request: $result');
      return result ?? false;
    } catch (e) {
      _log('Error enabling Bluetooth: $e');
      return false;
    }
  }

  /// Get list of bonded (paired) devices
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      final devices = await _bluetooth.getBondedDevices();
      _log('Found ${devices.length} bonded devices');

      for (var device in devices) {
        _log('  - ${device.name ?? "Unknown"} (${device.address})');
      }

      return devices;
    } catch (e) {
      _log('Error getting bonded devices: $e');
      return [];
    }
  }

  /// Find a bonded device by name
  Future<BluetoothDevice?> findDeviceByName(String name) async {
    try {
      final devices = await getBondedDevices();

      // Try exact match first
      BluetoothDevice? device = devices.cast<BluetoothDevice?>().firstWhere(
            (d) => d?.name?.toLowerCase() == name.toLowerCase(),
            orElse: () => null,
          );

      // Try partial match if no exact match
      if (device == null) {
        device = devices.cast<BluetoothDevice?>().firstWhere(
              (d) =>
                  d?.name?.toLowerCase().contains(name.toLowerCase()) ?? false,
              orElse: () => null,
            );
      }

      if (device != null) {
        _log('Found device: ${device.name} (${device.address})');
      } else {
        _log('Device not found: $name');
      }

      return device;
    } catch (e) {
      _log('Error finding device: $e');
      return null;
    }
  }

  /// Connect to a device
  Future<bool> connect(BluetoothDevice device) async {
    try {
      _log('Connecting to ${device.name} (${device.address})...');

      // Close existing connection if any
      await disconnect();

      // Connect to device
      _connection = await BluetoothConnection.toAddress(device.address);

      if (_connection?.isConnected ?? false) {
        _isConnected = true;
        _log('✅ Connected to ${device.name}');

        // Listen for incoming data
        _dataSubscription = _connection!.input!.listen(
          (data) {
            _handleData(data);
          },
          onDone: () {
            _log('Connection closed');
            _isConnected = false;
          },
          onError: (error) {
            _log('Connection error: $error');
            onError?.call('Connection error: $error');
            _isConnected = false;
          },
        );

        return true;
      } else {
        _log('❌ Failed to connect to ${device.name}');
        return false;
      }
    } catch (e, stackTrace) {
      _log('❌ Connection error: $e\n$stackTrace');
      onError?.call('Connection failed: $e');
      _isConnected = false;
      return false;
    }
  }

  /// Disconnect from device
  Future<void> disconnect() async {
    try {
      if (_connection != null) {
        _log('Disconnecting...');
        await _dataSubscription?.cancel();
        await _connection?.close();
        _connection = null;
        _dataSubscription = null;
        _isConnected = false;
        _log('✅ Disconnected');
      }
    } catch (e) {
      _log('Error disconnecting: $e');
    }
  }

  /// Send MIDI data to device
  Future<bool> sendData(List<int> data) async {
    try {
      if (!_isConnected || _connection == null) {
        _log('⚠️ Cannot send data: not connected');
        return false;
      }

      _connection!.output.add(Uint8List.fromList(data));
      await _connection!.output.allSent;

      return true;
    } catch (e) {
      _log('Error sending data: $e');
      return false;
    }
  }

  /// Handle incoming data
  void _handleData(Uint8List data) {
    try {
      _log('Received ${data.length} bytes');

      // Pass to callback
      onDataReceived?.call(data);
    } catch (e) {
      _log('Error handling data: $e');
    }
  }

  /// Perform a connection handshake
  /// Connects briefly to wake up the device, then disconnects
  Future<void> performHandshake(BluetoothDevice device) async {
    try {
      _log('Performing handshake with ${device.name}...');

      final connected = await connect(device);

      if (connected) {
        _log('Handshake: connected, waiting...');
        await Future.delayed(const Duration(milliseconds: 500));

        _log('Handshake: disconnecting...');
        await disconnect();

        _log('✅ Handshake complete');
      } else {
        _log('⚠️ Handshake failed: could not connect');
      }
    } catch (e) {
      _log('Handshake error: $e');
    }
  }

  bool get isConnected => _isConnected;

  void dispose() {
    disconnect();
  }
}

/// Example usage:
///
/// ```dart
/// final adapter = BluetoothSerialAdapter();
///
/// // Setup callbacks
/// adapter.onDataReceived = (data) {
///   print('Received MIDI data: $data');
/// };
///
/// adapter.onError = (error) {
///   print('Error: $error');
/// };
///
/// // Check Bluetooth
/// if (!await adapter.isBluetoothAvailable()) {
///   await adapter.requestEnable();
/// }
///
/// // Find and connect
/// final device = await adapter.findDeviceByName('M-Audio Oxygen 88');
/// if (device != null) {
///   final connected = await adapter.connect(device);
///   if (connected) {
///     print('Connected successfully!');
///   }
/// }
///
/// // Or use for handshake only
/// if (device != null) {
///   await adapter.performHandshake(device);
///   // Now use flutter_midi_command to connect
/// }
/// ```
