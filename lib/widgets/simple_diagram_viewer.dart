import 'package:flutter/material.dart';
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

  const SimpleDiagramViewer({
    super.key,
    required this.generatedContent,
    required this.template,
    required this.onDiagramUpdated,
    required this.originalPrompt,
  });

  @override
  State<SimpleDiagramViewer> createState() => _SimpleDiagramViewerState();
}

class _SimpleDiagramViewerState extends State<SimpleDiagramViewer> {
  final TransformationController _transformationController = TransformationController();
  late String _currentSvg;
  bool _isFullscreen = false;

  @override
  void initState() {
    super.initState();
    _currentSvg = widget.generatedContent.content;
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
    
    return _buildNormalView();
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