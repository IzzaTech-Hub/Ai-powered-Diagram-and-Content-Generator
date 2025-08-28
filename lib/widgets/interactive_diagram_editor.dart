import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart' as xml;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

/// Normalizes SVG colors to 6-digit hex format for Flutter SVG compatibility
/// Handles #RGB, #RRGGBB, rgb(r,g,b), rgba(#hex,alpha), and other color formats
String normalizeSvgColors(String svg) {
  if (svg.isEmpty) return svg;
  
  try {
    String normalized = svg;
    
    // 0. Fix problematic rgba(#hex,alpha) patterns that Flutter SVG can't handle
    // Convert rgba(#10B981, 0.1) to rgba(16, 185, 129, 0.1)
    final rgbaHexRegex = RegExp(r'rgba\(#([0-9A-Fa-f]{6}),\s*([0-9.]+)\)');
    normalized = normalized.replaceAllMapped(rgbaHexRegex, (match) {
      try {
        String hexColor = '#${match.group(1)}';
        String alpha = match.group(2)!;
        
        // Convert hex to RGB values
        int r = int.parse(hexColor.substring(1, 3), radix: 16);
        int g = int.parse(hexColor.substring(3, 5), radix: 16);
        int b = int.parse(hexColor.substring(5, 7), radix: 16);
        
        return 'rgba($r, $g, $b, $alpha)';
      } catch (e) {
        print('💥 Error converting rgba hex: $e');
        return 'rgba(107, 114, 128, 0.1)'; // Safe fallback
      }
    });
    
    // 1. Convert rgb(r,g,b) format to hex
    final rgbRegex = RegExp(r'rgb\((\d+),\s*(\d+),\s*(\d+)\)');
    normalized = normalized.replaceAllMapped(rgbRegex, (match) {
      try {
        int r = int.parse(match.group(1)!);
        int g = int.parse(match.group(2)!);
        int b = int.parse(match.group(3)!);
        
        // Ensure values are in valid range
        r = r.clamp(0, 255);
        g = g.clamp(0, 255);
        b = b.clamp(0, 255);
        
        String hex = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
        return hex.toUpperCase();
      } catch (e) {
        print('💥 Error parsing RGB values: $e');
        return '#6B7280'; // Safe fallback
      }
    });
    
    // 2. Convert 3-digit hex (#RGB) to 6-digit hex (#RRGGBB)
    final shortHexRegex = RegExp(r'#([0-9A-Fa-f])([0-9A-Fa-f])([0-9A-Fa-f])(?![0-9A-Fa-f])');
    normalized = normalized.replaceAllMapped(shortHexRegex, (match) {
      try {
        String r = match.group(1)!;
        String g = match.group(2)!;
        String b = match.group(3)!;
        
        // Duplicate each character: #RGB -> #RRGGBB
        String longHex = '#$r$r$g$g$b$b';
        return longHex.toUpperCase();
      } catch (e) {
        print('💥 Error converting short hex: $e');
        return '#6B7280'; // Safe fallback
      }
    });
    
    // 3. Ensure all 6-digit hex colors are uppercase and valid
    final hexRegex = RegExp(r'#([0-9A-Fa-f]{6})');
    normalized = normalized.replaceAllMapped(hexRegex, (match) {
      try {
        String hex = match.group(1)!;
        // Validate hex and convert to uppercase
        if (RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(hex)) {
          return '#${hex.toUpperCase()}';
        } else {
          print('⚠️ Invalid hex color found: #$hex');
          return '#6B7280'; // Safe fallback
        }
      } catch (e) {
        print('💥 Error processing hex color: $e');
        return '#6B7280'; // Safe fallback
      }
    });
    
    // 4. Handle fill and stroke attributes specifically
    // Convert rgb() in fill attributes
    normalized = normalized.replaceAllMapped(RegExp(r'fill="([^"]*)"'), (match) {
      String value = match.group(1)!;
      if (value.startsWith('rgb(')) {
        // Convert rgb to hex
        final rgbMatch = RegExp(r'rgb\((\d+),\s*(\d+),\s*(\d+)\)').firstMatch(value);
        if (rgbMatch != null) {
          try {
            int r = int.parse(rgbMatch.group(1)!);
            int g = int.parse(rgbMatch.group(2)!);
            int b = int.parse(rgbMatch.group(3)!);
            
            r = r.clamp(0, 255);
            g = g.clamp(0, 255);
            b = b.clamp(0, 255);
            
            String hex = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
            return 'fill="${hex.toUpperCase()}"';
          } catch (e) {
            print('💥 Error converting fill RGB: $e');
            return 'fill="#6B7280"';
          }
        }
      }
      return match.group(0)!;
    });
    
    // Convert rgb() in stroke attributes
    normalized = normalized.replaceAllMapped(RegExp(r'stroke="([^"]*)"'), (match) {
      String value = match.group(1)!;
      if (value.startsWith('rgb(')) {
        // Convert rgb to hex
        final rgbMatch = RegExp(r'rgb\((\d+),\s*(\d+),\s*(\d+)\)').firstMatch(value);
        if (rgbMatch != null) {
          try {
            int r = int.parse(rgbMatch.group(1)!);
            int g = int.parse(rgbMatch.group(2)!);
            int b = int.parse(rgbMatch.group(3)!);
            
            r = r.clamp(0, 255);
            g = g.clamp(0, 255);
            b = b.clamp(0, 255);
            
            String hex = '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}';
            return 'stroke="${hex.toUpperCase()}"';
          } catch (e) {
            print('💥 Error converting stroke RGB: $e');
            return 'stroke="#374151"';
          }
        }
      }
      return match.group(0)!;
    });
    
    print('🔧 SVG colors normalized: ${svg.length} -> ${normalized.length} chars');
    return normalized;
    
  } catch (e) {
    print('💥 Error normalizing SVG colors: $e');
    return svg; // Return original if normalization fails
  }
}

class InteractiveDiagramEditor extends StatefulWidget {
  final String svgContent;
  final String templateName;
  final Function(String) onDiagramUpdated;
  final String originalPrompt;

  const InteractiveDiagramEditor({
    super.key,
    required this.svgContent,
    required this.templateName,
    required this.onDiagramUpdated,
    required this.originalPrompt,
  });

  @override
  State<InteractiveDiagramEditor> createState() =>
      _InteractiveDiagramEditorState();
}

class _InteractiveDiagramEditorState extends State<InteractiveDiagramEditor> {
  final GlobalKey _diagramKey = GlobalKey();
  String _currentSvg = '';
  bool _isEditing = true;
  bool _isExporting = false;

  // Selected element properties
  String? _selectedElementId;
  String? _selectedElementText;
  Color? _selectedElementColor;
  Offset? _selectedElementPosition;

  // SVG element mapping
  final Map<String, Map<String, dynamic>> _svgElements = {};

  // Controllers for editing
  final TextEditingController _textEditingController = TextEditingController();
  Color _selectedColor = Colors.blue;

  // Color palette for editing
  final List<Color> _colorPalette = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    Colors.amber,
    Colors.cyan,
    Colors.lime,
    Colors.deepOrange,
  ];

  @override
  void initState() {
    super.initState();
    _currentSvg = widget.svgContent;
    _parseSvgElements();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  void _parseSvgElements() {
    try {
      final document = xml.XmlDocument.parse(_currentSvg);
      _svgElements.clear();

      // Find all editable elements (text, shapes)
      final textElements = document.findAllElements('text');
      final shapeElements = [
        ...document.findAllElements('rect'),
        ...document.findAllElements('circle'),
        ...document.findAllElements('ellipse'),
        ...document.findAllElements('polygon'),
        ...document.findAllElements('path'),
      ];

      // Process text elements
      for (final element in textElements) {
        final id = element.getAttribute('id') ?? 'text-${_svgElements.length}';
        final text = element.innerText;

        if (text.trim().isEmpty) continue;

        double x = double.tryParse(element.getAttribute('x') ?? '0') ?? 0;
        double y = double.tryParse(element.getAttribute('y') ?? '0') ?? 0;

        // Handle transform attribute
        final transform = element.getAttribute('transform');
        if (transform != null && transform.contains('translate')) {
          final translateRegex = RegExp(
            r'translate$$\s*([0-9.-]+)(?:\s*,\s*|\s+)([0-9.-]+)\s*$$',
          );
          final match = translateRegex.firstMatch(transform);
          if (match != null && match.groupCount >= 2) {
            x = double.tryParse(match.group(1)!) ?? x;
            y = double.tryParse(match.group(2)!) ?? y;
          }
        }

        final fillColor = element.getAttribute('fill') ?? '#000000';

        _svgElements[id] = {
          'element': element,
          'text': text,
          'type': 'text',
          'position': Offset(x, y),
          'color': _parseColor(fillColor),
        };
      }

      // Process shape elements
      for (final element in shapeElements) {
        final id =
            element.getAttribute('id') ??
            '${element.name.local}-${_svgElements.length}';
        final fillColor =
            element.getAttribute('fill') ??
            element.getAttribute('stroke') ??
            '#000000';

        double x = 0, y = 0;
        if (element.name.local == 'rect') {
          x = double.tryParse(element.getAttribute('x') ?? '0') ?? 0;
          y = double.tryParse(element.getAttribute('y') ?? '0') ?? 0;
        } else if (element.name.local == 'circle') {
          x = double.tryParse(element.getAttribute('cx') ?? '0') ?? 0;
          y = double.tryParse(element.getAttribute('cy') ?? '0') ?? 0;
        } else if (element.name.local == 'ellipse') {
          x = double.tryParse(element.getAttribute('cx') ?? '0') ?? 0;
          y = double.tryParse(element.getAttribute('cy') ?? '0') ?? 0;
        }

        _svgElements[id] = {
          'element': element,
          'type': 'shape',
          'shape': element.name.local,
          'position': Offset(x, y),
          'color': _parseColor(fillColor),
        };
      }

      print('Parsed ${_svgElements.length} editable elements from SVG');
    } catch (e) {
      print('Error parsing SVG elements: $e');
    }
  }

  Color _parseColor(String colorString) {
    try {
      if (colorString.startsWith('#')) {
        return Color(
          int.parse(colorString.substring(1), radix: 16) | 0xFF000000,
        );
      } else if (colorString.startsWith('rgb')) {
        final rgbMatch = RegExp(
          r'rgb$$(\d+),\s*(\d+),\s*(\d+)$$',
        ).firstMatch(colorString);
        if (rgbMatch != null) {
          final r = int.parse(rgbMatch.group(1)!);
          final g = int.parse(rgbMatch.group(2)!);
          final b = int.parse(rgbMatch.group(3)!);
          return Color.fromARGB(255, r, g, b);
        }
      }
      return Colors.black;
    } catch (e) {
      return Colors.black;
    }
  }

  String _colorToHex(Color color) {
    return '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
  }

  void _handleTap(Offset position) {
    String? selectedId;
    String? selectedText;
    Color? selectedColor;
    Offset? selectedPosition;

    // Find the closest editable element
    double minDistance = double.infinity;

    for (final entry in _svgElements.entries) {
      final elementPosition = entry.value['position'] as Offset;
      final distance = (elementPosition - position).distance;

      if (distance < minDistance && distance < 80) {
        minDistance = distance;
        selectedId = entry.key;
        selectedText = entry.value['text'] as String?;
        selectedColor = entry.value['color'] as Color?;
        selectedPosition = elementPosition;
      }
    }

    if (selectedId != null && selectedPosition != null) {
      setState(() {
        _selectedElementId = selectedId;
        _selectedElementText = selectedText ?? '';
        _selectedElementColor = selectedColor ?? Colors.black;
        _selectedElementPosition = selectedPosition;
        _selectedColor = selectedColor ?? Colors.black;
        _textEditingController.text = selectedText ?? '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected element: ${selectedText ?? 'Shape'}'),
          duration: const Duration(seconds: 1),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _clearSelection() {
    setState(() {
      _selectedElementId = null;
      _selectedElementText = null;
      _selectedElementColor = null;
      _selectedElementPosition = null;
      _textEditingController.clear();
    });
  }

  Future<void> _updateElement() async {
    if (_selectedElementId == null) return;

    try {
      final document = xml.XmlDocument.parse(_currentSvg);
      final selectedElement = _svgElements[_selectedElementId!];

      if (selectedElement == null) return;

      final element = selectedElement['element'] as xml.XmlElement;
      final elementType = selectedElement['type'] as String;

      if (elementType == 'text' &&
          _textEditingController.text != _selectedElementText) {
        // Update text content
        element.children.clear();
        element.children.add(xml.XmlText(_textEditingController.text));

        // Update color if changed
        if (_selectedColor != _selectedElementColor) {
          element.setAttribute('fill', _colorToHex(_selectedColor));
        }
      } else if (elementType == 'shape' &&
          _selectedColor != _selectedElementColor) {
        // Update shape color
        if (element.getAttribute('fill') != null) {
          element.setAttribute('fill', _colorToHex(_selectedColor));
        } else if (element.getAttribute('stroke') != null) {
          element.setAttribute('stroke', _colorToHex(_selectedColor));
        }
      }

      final updatedSvg = document.toXmlString();
      setState(() {
        _currentSvg = updatedSvg;
        _selectedElementText = _textEditingController.text;
        _selectedElementColor = _selectedColor;
      });

      _parseSvgElements();
      widget.onDiagramUpdated(_currentSvg);
      _clearSelection();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Element updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update element: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _exportAsPNG() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final RenderRepaintBoundary boundary =
          _diagramKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      // Save to device
      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/diagram_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PNG saved to: ${file.path}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => _sharePNG(pngBytes),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export PNG: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  Future<void> _exportAsPDF() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final RenderRepaintBoundary boundary =
          _diagramKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      final ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List pngBytes = byteData!.buffer.asUint8List();

      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(pngBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  widget.templateName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Generated from: ${widget.originalPrompt}',
                  style: pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.SizedBox(height: 20),
                pw.Expanded(
                  child: pw.Center(
                    child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
                  ),
                ),
                pw.SizedBox(height: 20),
                pw.Text(
                  'Created on: ${DateTime.now().toString().split('.')[0]}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              ],
            );
          },
        ),
      );

      final directory = await getApplicationDocumentsDirectory();
      final file = File(
        '${directory.path}/diagram_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await file.writeAsBytes(await pdf.save());

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to: ${file.path}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Share',
            onPressed: () async => _sharePDF(await pdf.save()),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to export PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isExporting = false;
      });
    }
  }

  void _sharePNG(Uint8List pngBytes) {
    // Implement sharing functionality using share_plus package
    // This would require adding share_plus to pubspec.yaml
    print('Sharing PNG with ${pngBytes.length} bytes');
  }

  void _sharePDF(Uint8List pdfBytes) {
    // Implement sharing functionality using share_plus package
    print('Sharing PDF with ${pdfBytes.length} bytes');
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
            minHeight: isSmallScreen ? 200 : 300,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isEditing ? Colors.blue.shade300 : Colors.grey.shade300,
              width: _isEditing ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color:
                    _isEditing
                        ? Colors.blue.withOpacity(0.2)
                        : Colors.black.withOpacity(0.1),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // SVG Viewer with RepaintBoundary for export
                RepaintBoundary(
                  key: _diagramKey,
                  child: InteractiveViewer(
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.3,
                    maxScale: 5.0,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                      color: Colors.white,
                      child: GestureDetector(
                        onTapUp:
                            _isEditing
                                ? (details) {
                                  _handleTap(details.localPosition);
                                }
                                : null,
                                                    child: SvgPicture.string(
                              normalizeSvgColors(_currentSvg),
                              fit: BoxFit.contain,
                              placeholderBuilder:
                                  (context) => const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                      ),
                    ),
                  ),
                ),

                // Control buttons
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      // Export buttons
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: PopupMenuButton<String>(
                          icon: Icon(
                            _isExporting
                                ? Icons.hourglass_empty
                                : Icons.download,
                            color: Colors.white,
                            size: isSmallScreen ? 20 : 24,
                          ),
                          enabled: !_isExporting,
                          onSelected: (value) {
                            if (value == 'png') {
                              _exportAsPNG();
                            } else if (value == 'pdf') {
                              _exportAsPDF();
                            }
                          },
                          itemBuilder:
                              (context) => [
                                const PopupMenuItem(
                                  value: 'png',
                                  child: Row(
                                    children: [
                                      Icon(Icons.image, size: 16),
                                      SizedBox(width: 8),
                                      Text('Export as PNG'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'pdf',
                                  child: Row(
                                    children: [
                                      Icon(Icons.picture_as_pdf, size: 16),
                                      SizedBox(width: 8),
                                      Text('Export as PDF'),
                                    ],
                                  ),
                                ),
                              ],
                        ),
                      ),

                      // Edit mode toggle
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        decoration: BoxDecoration(
                          color: _isEditing ? Colors.orange : Colors.grey,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isEditing ? Icons.edit : Icons.edit_off,
                            color: Colors.white,
                            size: isSmallScreen ? 20 : 24,
                          ),
                          onPressed: () {
                            setState(() {
                              _isEditing = !_isEditing;
                              if (!_isEditing) {
                                _clearSelection();
                              }
                            });
                          },
                          tooltip:
                              _isEditing ? 'Disable Editing' : 'Enable Editing',
                        ),
                      ),
                    ],
                  ),
                ),

                // Editing instruction overlay
                if (_isEditing)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.touch_app,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Tap elements to edit',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: isSmallScreen ? 11 : 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Element editor popup
                if (_selectedElementId != null &&
                    _selectedElementPosition != null)
                  Positioned(
                    left: _selectedElementPosition!.dx.clamp(
                      10,
                      constraints.maxWidth - 280,
                    ),
                    top: (_selectedElementPosition!.dy - 200).clamp(
                      10,
                      constraints.maxHeight - 250,
                    ),
                    child: Material(
                      elevation: 8,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 270,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade300,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Header
                            Row(
                              children: [
                                Icon(Icons.edit, size: 18, color: Colors.blue),
                                const SizedBox(width: 8),
                                Text(
                                  'Edit Element',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: _clearSelection,
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  splashRadius: 20,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Text editing (if text element)
                            if (_selectedElementText != null) ...[
                              const Text(
                                'Text:',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              TextField(
                                controller: _textEditingController,
                                decoration: InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.blue,
                                      width: 2,
                                    ),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  hintText: 'Enter text here...',
                                ),
                                maxLines: 2,
                                minLines: 1,
                              ),
                              const SizedBox(height: 12),
                            ],

                            // Color picker
                            const Text(
                              'Color:',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children:
                                  _colorPalette.map((color) {
                                    final isSelected = _selectedColor == color;
                                    return GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          _selectedColor = color;
                                        });
                                      },
                                      child: Container(
                                        width: 32,
                                        height: 32,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color:
                                                isSelected
                                                    ? Colors.black
                                                    : Colors.grey.shade300,
                                            width: isSelected ? 3 : 1,
                                          ),
                                          boxShadow:
                                              isSelected
                                                  ? [
                                                    BoxShadow(
                                                      color: color.withOpacity(
                                                        0.5,
                                                      ),
                                                      blurRadius: 4,
                                                      spreadRadius: 1,
                                                    ),
                                                  ]
                                                  : null,
                                        ),
                                        child:
                                            isSelected
                                                ? const Icon(
                                                  Icons.check,
                                                  color: Colors.white,
                                                  size: 16,
                                                )
                                                : null,
                                      ),
                                    );
                                  }).toList(),
                            ),

                            const SizedBox(height: 16),

                            // Action buttons
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: _clearSelection,
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  onPressed: _updateElement,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  icon: const Icon(Icons.check, size: 18),
                                  label: const Text('Apply'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
