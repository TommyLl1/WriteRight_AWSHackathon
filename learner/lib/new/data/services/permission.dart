import 'dart:io';
import 'package:flutter/foundation.dart';

// Packages
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';

// Utils
import 'package:writeright/new/utils/logger.dart';

import 'dart:io' show Platform;


class PermissionService {
  // Future<bool> checkStoragePermission() async {
  //   if (await Permission.storage.isDenied) {
  //     final result = await Permission.storage.request();
  //     return result.isGranted;
  //   }
  //   return true;
  // }

  Future<bool> checkStoragePermission() async {
    // Skip permission check on web platform
    if (kIsWeb) return true;

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (androidInfo.version.sdkInt < 29) {
        final status = await Permission.storage.status;
        if (status.isDenied) {
          final result = await Permission.storage.request();
          return result.isGranted;
        }
        return status.isGranted;
      }
    }
    return true; // No permission needed for API 29+ or iOS
  }

  Future<XFile?> getImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    
    // Check for storage permission if the source is gallery
    if (source == ImageSource.gallery) {
      final hasPermission = await checkStoragePermission();
      if (!hasPermission) {
        AppLogger.error('Storage permission denied');
        return null;
      }
    }
    return await picker.pickImage(
      source: source,
    );
  }
}