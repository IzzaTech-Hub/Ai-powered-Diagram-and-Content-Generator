import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';

class PermissionHelper {
  /// Check and request storage permissions for Android
  static Future<bool> requestStoragePermission(BuildContext context) async {
    if (!Platform.isAndroid) {
      return true; // No permission needed for other platforms
    }

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
      print('Error requesting storage permission: $e');
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
            'To download diagrams, please enable storage permission in your device settings.\n\n'
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
      final status = await Permission.storage.status;
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }
}
