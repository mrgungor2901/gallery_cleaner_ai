import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

class PermissionService {
  static Future<bool> requestGalleryPermission() async {
    // Önce mevcut izin durumunu kontrol et
    final hasPermission = await checkGalleryPermission();
    if (hasPermission) {
      debugPrint('Permission already granted, no need to request again');
      return true;
    }

    Permission permission;

    if (Platform.isAndroid) {
      // Android için storage permission kullanıyoruz
      permission = Permission.storage;
    } else {
      // iOS için photos permission
      permission = Permission.photos;
    }

    debugPrint('Requesting permission: $permission');
    final status = await permission.request();
    debugPrint('Permission status: $status');
    debugPrint('Is granted: ${status.isGranted}');

    return status.isGranted;
  }

  static Future<bool> checkGalleryPermission() async {
    Permission permission;

    if (Platform.isAndroid) {
      permission = Permission.storage;
    } else {
      permission = Permission.photos;
    }

    final status = await permission.status;
    debugPrint('Current permission status: $status');
    debugPrint('Is granted: ${status.isGranted}');

    return status.isGranted;
  }

  static Future<void> openSettings() async {
    await openAppSettings();
  }
}
