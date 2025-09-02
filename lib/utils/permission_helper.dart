import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PermissionHelper {
  /// Check and request storage permissions for Android - simplified for SVG downloads
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true; // No permission needed for other platforms
    }

    try {
      // Get Android version info
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      int sdkInt = androidInfo.version.sdkInt;
      
      print('🔍 Android SDK version: $sdkInt');
      
      // For Android 10+ (API 29+), scoped storage handles downloads automatically
      // No special permissions needed for downloading to app-specific or Downloads folder
      if (sdkInt >= 29) {
        return true; // Scoped storage automatically handles file downloads
      } 
      // For Android 6-9 (API 23-28), we need WRITE_EXTERNAL_STORAGE
      else if (sdkInt >= 23) {
        return await _requestLegacyStoragePermission(context);
      } 
      // For Android 5 and below, no runtime permissions needed
      else {
        return true;
      }
    } catch (e) {
      print('Error requesting storage permission: $e');
      // Fallback to legacy permission request for safety
      return await _requestLegacyStoragePermission(context);
    }
  }

  /// Request legacy storage permission for Android 6-9 (API 23-28)
  static Future<bool> _requestLegacyStoragePermission(BuildContext context) async {
    try {
      PermissionStatus status = await Permission.storage.status;
      
      if (status.isGranted) {
        return true;
      }
      
      if (status.isDenied) {
        status = await Permission.storage.request();
        if (status.isGranted) {
          return true;
        }
      }
      
      if (status.isPermanentlyDenied) {
        _showPermissionDialog(context);
        return false;
      }
      
      return status.isGranted;
    } catch (e) {
      print('Error requesting legacy storage permission: $e');
      return false;
    }
  }

  /// Show dialog to guide user to settings for permanent permission denial
  static void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Storage Permission Required'),
          content: const Text(
            'To download SVG files, please enable storage permission in your device settings.\\n\\n'
            'Go to: Settings > Apps > AI Diagram Generator > Permissions > Storage',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  /// Check if app has necessary permissions for downloading
  static Future<bool> hasDownloadPermission() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      // Get Android version info
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      int sdkInt = androidInfo.version.sdkInt;
      
      // For Android 10+, scoped storage handles downloads automatically
      if (sdkInt >= 29) {
        return true;
      } 
      // For Android 6-9, check storage permission
      else if (sdkInt >= 23) {
        final status = await Permission.storage.status;
        return status.isGranted;
      } 
      // For older versions, no permission needed
      else {
        return true;
      }
    } catch (e) {
      print('Error checking download permission: $e');
      return false;
    }
  }
}