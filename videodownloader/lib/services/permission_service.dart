import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  static Future<bool> requestMediaPermissions() async {
    if (kIsWeb) {
      return true;
    }

    List<Permission> permissions = [];

    if (await _isAndroid13OrHigher()) {
      permissions.addAll([
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ]);
    } else {
      permissions.add(Permission.storage);
    }

    Map<Permission, PermissionStatus> statuses = await permissions.request();

    return statuses.values.every((status) =>
        status == PermissionStatus.granted ||
        status == PermissionStatus.limited);
  }

  static Future<bool> checkMediaPermissions() async {
    if (kIsWeb) {
      return true;
    }

    List<Permission> permissions = [];

    if (await _isAndroid13OrHigher()) {
      permissions.addAll([
        Permission.photos,
        Permission.videos,
        Permission.audio,
      ]);
    } else {
      permissions.add(Permission.storage);
    }

    for (Permission permission in permissions) {
      PermissionStatus status = await permission.status;
      if (status != PermissionStatus.granted && status != PermissionStatus.limited) {
        return false;
      }
    }

    return true;
  }

  static Future<bool> _isAndroid13OrHigher() async {
    try {
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestNotificationPermission() async {
    if (kIsWeb) {
      return true;
    }

    final status = await Permission.notification.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> checkNotificationPermission() async {
    if (kIsWeb) {
      return true;
    }

    final status = await Permission.notification.status;
    return status == PermissionStatus.granted;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}