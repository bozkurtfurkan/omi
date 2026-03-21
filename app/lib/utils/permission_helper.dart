import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

class PermissionHelper {
  static List<Permission> get requiredPermissions => [
        Permission.microphone,
        if (Platform.isAndroid) ...[
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
        ],
        if (Platform.isIOS) Permission.speech,
      ];

  /// Request all required permissions.
  /// Returns true if all granted.
  static Future<bool> requestAll() async {
    final statuses = await requiredPermissions.request();
    return statuses.values.every((s) => s.isGranted);
  }
}
