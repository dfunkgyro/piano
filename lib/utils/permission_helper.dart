import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static Future<bool> requestBluetoothPermissions(
      BuildContext context) async {
    if (kIsWeb) {
      return true;
    }
    if (defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      return _requestApplePermissions(context);
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      return _requestAndroidPermissions(context);
    }

    return true;
  }

  static Future<bool> _requestApplePermissions(BuildContext context) async {
    final bluetoothStatus = await Permission.bluetooth.status;

    if (bluetoothStatus.isGranted) {
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
      return true;
    }

    await _showPermissionDialog(
      context,
      'Bluetooth Permission Required',
      'Bluetooth access is required to connect to MIDI devices.',
      canOpenSettings: true,
    );
    return false;
  }

  static Future<bool> _requestAndroidPermissions(
      BuildContext context) async {
    final permissions = {
      Permission.bluetoothScan: 'Bluetooth Scan',
      Permission.bluetoothConnect: 'Bluetooth Connect',
      Permission.location: 'Location',
    };

    final statuses = <PermissionStatus>[];
    for (final permission in permissions.keys) {
      statuses.add(await permission.request());
    }

    final deniedPermissions = <String>[];
    final entries = permissions.entries.toList();
    for (var i = 0; i < statuses.length; i++) {
      final status = statuses[i];
      final permName = entries[i].value;

      if (status.isDenied || status.isPermanentlyDenied) {
        deniedPermissions.add(permName);
      }
    }

    if (deniedPermissions.isEmpty) {
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
}
