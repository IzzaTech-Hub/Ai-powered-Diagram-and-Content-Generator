import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class DiagramExportService {
  static Future<void> exportAsPNG({
    required GlobalKey diagramKey,
    required String templateName,
    required BuildContext context,
    double pixelRatio = 3.0,
  }) async {
    try {
      final RenderRepaintBoundary boundary = 
          diagramKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      
      // Save to device
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${templateName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pngBytes);
      
      // Show success message with share option
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PNG exported: $fileName'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Share',
              onPressed: () => _sharePNG(pngBytes, fileName),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PNG: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  static Future<void> exportAsPDF({
    required GlobalKey diagramKey,
    required String templateName,
    required String originalPrompt,
    required BuildContext context,
    double pixelRatio = 2.0,
  }) async {
    try {
      final RenderRepaintBoundary boundary = 
          diagramKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      
      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final Uint8List pngBytes = byteData!.buffer.asUint8List();
      
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(pngBytes);
      
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Container(
                  padding: const pw.EdgeInsets.only(bottom: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
                    ),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        templateName,
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blue800,
                        ),
                      ),
                      pw.SizedBox(height: 8),
                      pw.Text(
                        'AI-Generated Diagram',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey600,
                          fontStyle: pw.FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Original prompt
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'Original Prompt:',
                        style: pw.TextStyle(
                          fontSize: 12,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.grey700,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        originalPrompt,
                        style: pw.TextStyle(
                          fontSize: 11,
                          color: PdfColors.grey800,
                        ),
                      ),
                    ],
                  ),
                ),
                
                pw.SizedBox(height: 30),
                
                // Diagram
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Container(
                      decoration: pw.BoxDecoration(
                        border: pw.Border.all(color: PdfColors.grey300, width: 1),
                      ),
                      child: pw.ClipRRect(
                       
                        child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                
                pw.SizedBox(height: 20),
                
                // Footer
                pw.Container(
                  padding: const pw.EdgeInsets.only(top: 20),
                  decoration: const pw.BoxDecoration(
                    border: pw.Border(
                      top: pw.BorderSide(color: PdfColors.grey300, width: 1),
                    ),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Generated by AI Content Generator',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        'Created: ${DateTime.now().toString().split('.')[0]}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
      
      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final fileName = '${templateName.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(await pdf.save());
      
      // Show success message with share option
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF exported: $fileName'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'Share',
              onPressed: () async => _sharePDF(await pdf.save(), fileName),
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  static Future<void> _sharePNG(Uint8List pngBytes, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pngBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out this AI-generated diagram!',
        subject: 'AI Diagram - $fileName',
      );
    } catch (e) {
      print('Error sharing PNG: $e');
    }
  }
  
  static Future<void> _sharePDF(Uint8List pdfBytes, String fileName) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName');
      await file.writeAsBytes(pdfBytes);
      
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out this AI-generated diagram!',
        subject: 'AI Diagram - $fileName',
      );
    } catch (e) {
      print('Error sharing PDF: $e');
    }
  }
}
