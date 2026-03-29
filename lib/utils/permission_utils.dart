import 'package:permission_handler/permission_handler.dart';

class PermissionUtils {
  static Future<bool> requestAllPermissions() async {
    final permissions = [
      Permission.phone,
      Permission.storage,
      Permission.location,
    ];

    final statuses = await Future.wait(
      permissions.map((p) => p.request()),
    );

    return statuses.every((status) => status.isGranted);
  }

  static Future<bool> checkStoragePermission() async {
    final status = await Permission.storage.status;
    return status.isGranted;
  }

  static Future<bool> checkPhonePermission() async {
    final status = await Permission.phone.status;
    return status.isGranted;
  }

  static Future<bool> checkLocationPermission() async {
    final status = await Permission.location.status;
    return status.isGranted;
  }
}

