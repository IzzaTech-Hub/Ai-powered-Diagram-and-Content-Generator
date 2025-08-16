import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

Future<String> saveSvgToDownloads(String svgContent, String fileName) async {
  var status = await Permission.storage.request();
  if (status.isGranted) {
    final directory = await getApplicationDocumentsDirectory();
    final downloadsDirectory = io.Directory('${directory.path}/Downloads');
    if (!await downloadsDirectory.exists()) {
      await downloadsDirectory.create(recursive: true);
    }
    final path = '${downloadsDirectory.path}/$fileName';
    final file = io.File(path);
    await file.writeAsString(svgContent);
    return 'Diagram saved to Downloads folder as "$fileName"';
  } else {
    throw 'Storage permission denied. Cannot download diagram.';
  }
}
