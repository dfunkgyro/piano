import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  /// Request all Bluetooth permissions required for MIDI device scanning
  static Future<bool> requestBluetoothPermissions(BuildContext context) async {
    print('📋 Requesting Bluetooth permissions...');

    if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return await _requestApplePermissions(context);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return await _requestAndroidPermissions(context);
    }

    return true;
  }

  static Future<bool> _requestApplePermissions(BuildContext context) async {
    final bluetoothStatus = await Permission.bluetooth.status;

    if (bluetoothStatus.isGranted) {
      print('✅ Bluetooth permission already granted');
      return true;
    }

    if (bluetoothStatus.isPermanentlyDenied) {
      await _showPermissionDialog(
        context,
        'Bluetooth Permission Required',
        'Bluetooth access is permanently denied. Please enable it in System Settings > Privacy & Security > Bluetooth.',
        canOpenSettings: true,
      );
      return false;
    }

    final result = await Permission.bluetooth.request();

    if (result.isGranted) {
      print('✅ Bluetooth permission granted');
      return true;
    } else {
      await _showPermissionDialog(
        context,
        'Bluetooth Permission Required',
        'MIDI Piano Pro needs Bluetooth access to connect to your MIDI devices.',
        canOpenSettings: true,
      );
      return false;
    }
  }

  static Future<bool> _requestAndroidPermissions(BuildContext context) async {
    final permissions = {
      Permission.bluetoothScan: 'Bluetooth Scan',
      Permission.bluetoothConnect: 'Bluetooth Connect',
      Permission.location: 'Location',
    };

    final statuses = await permissions.keys
        .map((p) => p.request())
        .fold<Future<List<PermissionStatus>>>(
      Future.value([]),
      (prev, request) async {
        final list = await prev;
        list.add(await request);
        return list;
      },
    );

    final deniedPermissions = <String>[];
    final entries = permissions.entries.toList();

    for (var i = 0; i < statuses.length; i++) {
      final status = statuses[i];
      final permName = entries[i].value;

      print('📋 $permName: $status');

      if (status.isDenied || status.isPermanentlyDenied) {
        deniedPermissions.add(permName);
      }
    }

    if (deniedPermissions.isEmpty) {
      print('✅ All Android permissions granted');
      return true;
    }

    await _showPermissionDialog(
      context,
      'Permissions Required',
      'The following permissions are required for Bluetooth scanning:\n\n${deniedPermissions.join(", ")}\n\nPlease grant these permissions in Settings.',
      canOpenSettings: true,
    );

    return false;
  }

  static Future<void> _showPermissionDialog(
    BuildContext context,
    String title,
    String message, {
    bool canOpenSettings = false,
  }) async {
    return showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(message),
        ),
        actions: [
          if (canOpenSettings)
            CupertinoDialogAction(
              onPressed: () {
                openAppSettings();
                Navigator.pop(context);
              },
              child: const Text('Open Settings'),
            ),
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            isDefaultAction: !canOpenSettings,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Check if all required permissions are granted
  static Future<bool> hasAllPermissions() async {
    if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return (await Permission.bluetooth.status).isGranted;
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      final scan = await Permission.bluetoothScan.status;
      final connect = await Permission.bluetoothConnect.status;
      final location = await Permission.location.status;

      return scan.isGranted && connect.isGranted && location.isGranted;
    }

    return true;
  }
}
