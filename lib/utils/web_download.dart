import 'dart:html' as html;

Future<String> saveSvgToDownloads(String svgContent, String fileName) async {
  final blob = html.Blob([svgContent], 'image/svg+xml');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor =
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
  html.Url.revokeObjectUrl(url);
  return 'Download started successfully!';
}
