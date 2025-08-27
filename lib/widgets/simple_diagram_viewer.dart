import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/generated_content.dart';
import '../models/napkin_template.dart';
import '../screens/diagram_editing_screen.dart';

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
  
  // Check if SVG is safe to render
  bool _isSvgSafe(String svgContent) {
    if (svgContent.isEmpty) return false;
    if (!svgContent.startsWith('<svg')) return false;
    
    // Check for known problematic patterns
    final problematicPatterns = [
      RegExp(r'#[0-9A-Fa-f]{6}'), // Hex colors
      RegExp(r'fill="[^"]*"'), // Fill attributes
      RegExp(r'stroke="[^"]*"'), // Stroke attributes
    ];
    
    for (final pattern in problematicPatterns) {
      if (pattern.hasMatch(svgContent)) {
        print('⚠️ SVG contains potentially problematic pattern: $pattern');
        return false;
      }
    }
    
    return true;
  }
  
  // Create a safe fallback SVG
  String _createSafeFallbackSvg(String originalContent, String diagramType) {
    final fallbackSvg = '''
<svg viewBox="0 0 200 120" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#f3f4f6;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#e5e7eb;stop-opacity:1" />
    </linearGradient>
  </defs>
  <rect width="200" height="120" fill="url(#grad1)" stroke="#d1d5db" stroke-width="2" rx="8"/>
  <circle cx="100" cy="40" r="15" fill="#3b82f6" opacity="0.8"/>
  <text x="100" y="50" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#1f2937" font-weight="bold">
    ${diagramType.split(' ').first}
  </text>
  <text x="100" y="70" text-anchor="middle" font-family="Arial, sans-serif" font-size="10" fill="#6b7280">
    Diagram Preview
  </text>
  <text x="100" y="85" text-anchor="middle" font-family="Arial, sans-serif" font-size="8" fill="#9ca3af">
    (Original: ${originalContent.length} chars)
  </text>
</svg>
    ''';
    
    print('🔧 Created safe fallback SVG for $diagramType');
    return fallbackSvg;
  }

  @override
  void initState() {
    super.initState();
    _currentSvg = _isSvgSafe(widget.generatedContent.content) 
        ? widget.generatedContent.content 
        : _createSafeFallbackSvg(widget.generatedContent.content, widget.template.name);
  }
  
  @override
  void didUpdateWidget(SimpleDiagramViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.generatedContent.content != widget.generatedContent.content) {
      setState(() {
        _currentSvg = _isSvgSafe(widget.generatedContent.content) 
            ? widget.generatedContent.content 
            : _createSafeFallbackSvg(widget.generatedContent.content, widget.template.name);
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
            
            // Check if SVG is safe to render
            if (!_isSvgSafe(_currentSvg)) {
              print('⚠️ SVG not safe, using fallback for preview');
              _currentSvg = _createSafeFallbackSvg(
                widget.generatedContent.content, 
                widget.template.name
              );
            }
            
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
                    print('🔧 Using safe fallback SVG');
                    
                    final safeSvg = _createSafeFallbackSvg(
                      widget.generatedContent.content, 
                      widget.template.name
                    );
                    
                    return SvgPicture.string(
                      safeSvg,
                      fit: BoxFit.contain,
                      width: 200,
                      height: 120,
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