import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String> saveSvgToDownloads(String svgContent, String fileName) async {
  try {
    if (io.Platform.isAndroid) {
      // Try to save directly first (for modern Android with proper permissions)
      try {
        return await _saveToDownloads(svgContent, fileName);
      } catch (e) {
        print('Direct save failed, trying alternative method: $e');
        // Fallback to sharing method for Android 11+
        return await _shareFile(svgContent, fileName);
      }
    } else {
      // For other platforms, use a simple file save
      return await _saveToDocuments(svgContent, fileName);
    }
  } catch (e) {
    return 'Error preparing file for download: ${e.toString()}';
  }
}

/// Alternative method using sharing for modern Android
Future<String> _shareFile(String svgContent, String fileName) async {
  try {
    // Create temporary file
    final tempDir = await getTemporaryDirectory();
    final tempFile = io.File('${tempDir.path}/$fileName');
    await tempFile.writeAsString(svgContent);
    
    // Share the file - this allows user to save it wherever they want
    await Share.shareXFiles(
      [XFile(tempFile.path)],
      text: 'Generated SVG Diagram',
      subject: 'AI Generated Diagram',
    );
    
    return 'File shared successfully! You can save it from the share dialog.';
  } catch (e) {
    return 'Error sharing file: ${e.toString()}';
  }
}

Future<bool> _requestStoragePermission() async {
  try {
    // Check current permission status
    PermissionStatus status = await Permission.storage.status;
    
    if (status.isGranted) {
      return true;
    }
    
    // Request permission if not granted
    if (status.isDenied) {
      status = await Permission.storage.request();
      return status.isGranted;
    }
    
    // Handle permanently denied
    if (status.isPermanentlyDenied) {
      return false;
    }
    
    return false;
  } catch (e) {
    // Log error silently in production
    return false;
  }
}

Future<String> _saveToDownloads(String svgContent, String fileName) async {
  try {
    // Method 1: Try to save to the standard Downloads directory
    final downloadsPath = '/storage/emulated/0/Download';
    final downloadsDirectory = io.Directory(downloadsPath);
    
    if (await downloadsDirectory.exists()) {
      final file = io.File('$downloadsPath/$fileName');
      await file.writeAsString(svgContent);
      return 'SVG diagram saved to Downloads folder!\nLocation: $downloadsPath/$fileName';
    }
    
    // Method 2: Try external storage directory
    final externalDir = await getExternalStorageDirectory();
    if (externalDir != null) {
      final downloadsDir = io.Directory('${externalDir.path}/Download');
      if (!await downloadsDir.exists()) {
        await downloadsDir.create(recursive: true);
      }
      final file = io.File('${downloadsDir.path}/$fileName');
      await file.writeAsString(svgContent);
      return 'SVG diagram saved!\nLocation: ${downloadsDir.path}/$fileName';
    }
    
    // Method 3: Fallback to app documents
    return await _saveToDocuments(svgContent, fileName);
    
  } catch (e) {
    return 'Error saving to Downloads: ${e.toString()}';
  }
}

Future<String> _saveToDocuments(String svgContent, String fileName) async {
  try {
    final directory = await getApplicationDocumentsDirectory();
    final file = io.File('${directory.path}/$fileName');
    await file.writeAsString(svgContent);
    return 'SVG diagram saved!\nLocation: ${directory.path}/$fileName';
  } catch (e) {
    return 'Error saving file: ${e.toString()}';
  }
}
