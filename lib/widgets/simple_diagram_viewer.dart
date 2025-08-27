import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/generated_content.dart';
import '../models/napkin_template.dart';
import '../screens/diagram_editing_screen.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:convert';

/// Normalizes SVG colors to 6-digit hex format for Flutter SVG compatibility
/// Handles #RGB, #RRGGBB, rgb(r,g,b), and other color formats
String normalizeSvgColors(String svg) {
  if (svg.isEmpty) return svg;
  
  try {
    String normalized = svg;
    
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

/// Simple diagram viewer with edit button that opens dedicated editing screen
class SimpleDiagramViewer extends StatefulWidget {
  final GeneratedContent generatedContent;
  final NapkinTemplate template;
  final Function(GeneratedContent) onDiagramUpdated;
  final String originalPrompt;
  final String? svgContent;
  final bool isPreview;

  const SimpleDiagramViewer({
    super.key,
    required this.generatedContent,
    required this.template,
    required this.onDiagramUpdated,
    required this.originalPrompt,
    required this.svgContent,
    this.isPreview = false,
  });

  @override
  State<SimpleDiagramViewer> createState() => _SimpleDiagramViewerState();
}

class _SimpleDiagramViewerState extends State<SimpleDiagramViewer> {
  final TransformationController _transformationController = TransformationController();
  late String _currentSvg;
  bool _isFullscreen = false;
  bool _svgRenderingFailed = false;
  


  @override
  void initState() {
    super.initState();
    // Normalize SVG colors for Flutter SVG compatibility
    _currentSvg = normalizeSvgColors(widget.generatedContent.content);
  }
  
  @override
  void didUpdateWidget(SimpleDiagramViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generatedContent.content != widget.generatedContent.content) {
      setState(() {
        _currentSvg = normalizeSvgColors(widget.generatedContent.content);
        _svgRenderingFailed = false; // Reset failure flag
      });
    }
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  /// Open dedicated editing screen
  void _openEditingScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DiagramEditingScreen(
          template: widget.template,
          svgContent: _currentSvg,
          originalPrompt: widget.originalPrompt,
        ),
      ),
    ).then((result) {
      // If changes were made, refresh the current diagram
      if (result != null && result['updated'] == true) {
        setState(() {
          _currentSvg = result['svg'];
        });
        
        // Update the parent with new content
        final updatedContent = GeneratedContent(
          templateName: widget.generatedContent.templateName,
          content: result['svg'],
          isDiagram: widget.generatedContent.isDiagram,
          timestamp: DateTime.now(),
          originalPrompt: widget.generatedContent.originalPrompt,
        );
        widget.onDiagramUpdated(updatedContent);
      }
    });
  }

  /// Toggle fullscreen
  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }



  @override
  Widget build(BuildContext context) {
    if (_isFullscreen) {
      return _buildFullscreenDialog();
    }
    
    // If this is a preview mode, return simplified view
    if (widget.isPreview) {
      return _buildPreviewView();
    }
    
    return _buildNormalView();
  }

  Widget _buildPreviewView() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: Colors.white,
      child: Center(
        child: Builder(
          builder: (context) {
            // Debug: Print SVG content info
            if (kDebugMode) {
              print('🔍 SimpleDiagramViewer Preview:');
              print('   SVG length: ${_currentSvg.length}');
              print('   SVG starts with: ${_currentSvg.startsWith('<svg') ? 'Yes' : 'No'}');
              print('   SVG preview: ${_currentSvg.length > 100 ? _currentSvg.substring(0, 100) + '...' : _currentSvg}');
            }
            
            // Always try to render the original SVG first
            print('🔍 Attempting to render original SVG (${_currentSvg.length} chars)');
            
            return FutureBuilder<String>(
              future: Future.delayed(const Duration(seconds: 5), () => _currentSvg),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    width: 200,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(strokeWidth: 2),
                          SizedBox(height: 4),
                          Text(
                            'Loading...',
                            style: TextStyle(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return SvgPicture.string(
                  _currentSvg,
                  fit: BoxFit.contain,
                  width: 200, // Fixed width for consistent thumbnails
                  height: 120, // Fixed height for consistent thumbnails
                  placeholderBuilder: (context) => Container(
                    width: 200,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    ),
                  ),
                  errorBuilder: (context, error, stackTrace) {
                    print('💥 SVG Error in preview: $error');
                    print('🔧 Trying with additional color normalization...');
                    
                    // Try with more aggressive color normalization
                    final aggressiveNormalized = normalizeSvgColors(widget.generatedContent.content);
                    
                    return SvgPicture.string(
                      aggressiveNormalized,
                      fit: BoxFit.contain,
                      width: 200,
                      height: 120,
                      placeholderBuilder: (context) => Container(
                        width: 200,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(strokeWidth: 2, color: Colors.blue),
                              SizedBox(height: 4),
                              Text(
                                'Retrying SVG',
                                style: TextStyle(
                                  color: Colors.blue,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      errorBuilder: (context, retryError, stackTrace) {
                        print('💥 Retry also failed: $retryError');
                        return Container(
                          width: 200,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, color: Colors.red, size: 24),
                                SizedBox(height: 4),
                                Text(
                                  'SVG Error',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Color format issue',
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontSize: 8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNormalView() {
    return Container(
      height: 500, // Good height for visibility
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 2),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: _buildDiagramContent(),
      ),
    );
  }

  Widget _buildDiagramContent() {
    return Stack(
      children: [
        // Main diagram with zoom
        InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 3.0,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
            child: Center(
              child: SvgPicture.string(
                _currentSvg,
                fit: BoxFit.contain,
                width: 600, // Large size for readability
                height: 450,
                placeholderBuilder: (context) => const CircularProgressIndicator(),
                errorBuilder: (context, error, stackTrace) {
                  print('💥 SVG Error in normal view: $error');
                  return Container(
                    width: 600,
                    height: 450,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.warning, color: Colors.orange, size: 40),
                          SizedBox(height: 16),
                          Text(
                            'SVG Rendering Error',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'The diagram could not be displayed',
                            style: TextStyle(
                              color: Colors.orange,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Control buttons
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Edit button - opens dedicated editing screen
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade600, Colors.blue.shade400],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _openEditingScreen,
                  icon: const Icon(
                    Icons.edit_note,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'Edit Diagram',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFullscreenDialog() {
    return Dialog(
      insetPadding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.maxFinite,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: widget.template.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.template.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _toggleFullscreen,
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                height: 600,
                child: _buildDiagramContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}