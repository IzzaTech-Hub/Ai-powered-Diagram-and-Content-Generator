import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart' as xml;
import '../models/napkin_template.dart';
import '../services/api_service.dart';

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

class EditableText {
  final String id;
  final String originalText;
  String currentText;
  final TextEditingController controller;

  EditableText({
    required this.id,
    required this.originalText,
    required this.currentText,
  }) : controller = TextEditingController(text: currentText);

  void dispose() {
    controller.dispose();
  }
}

class DiagramEditingScreen extends StatefulWidget {
  final NapkinTemplate template;
  final String svgContent;
  final String originalPrompt;

  const DiagramEditingScreen({
    super.key,
    required this.template,
    required this.svgContent,
    required this.originalPrompt,
  });

  @override
  State<DiagramEditingScreen> createState() => _DiagramEditingScreenState();
}

class _DiagramEditingScreenState extends State<DiagramEditingScreen>
    with SingleTickerProviderStateMixin {
  late String _currentSvg;
  final List<EditableText> _editableTexts = [];
  bool _isRegenerating = false;
  bool _showEditMode = false;
  
  final TransformationController _transformationController = TransformationController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _currentSvg = widget.svgContent;
    
    // Initialize animation for regenerate button
    _animationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    
    // Parse SVG to find all text elements
    _parseTextElements();
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    for (final editableText in _editableTexts) {
      editableText.dispose();
    }
    super.dispose();
  }

  /// Parse SVG content to extract all text elements
  void _parseTextElements() {
    _editableTexts.clear();

    try {
      if (_currentSvg.isEmpty) {
        print('SVG content is empty');
        _createDefaultTextElements();
        return;
      }

      print('Parsing SVG content for text elements...');
      final document = xml.XmlDocument.parse(_currentSvg);
      
      // Find all text and tspan elements
      final textElements = document.findAllElements('text');
      final tspanElements = document.findAllElements('tspan');
      
      print('Found ${textElements.length} text elements and ${tspanElements.length} tspan elements');

      int index = 0;
      final Set<String> addedTexts = {}; // Avoid duplicates
      
      // Parse text elements
      for (final element in textElements) {
        try {
          final text = element.innerText.trim();
          
          if (text.isEmpty || addedTexts.contains(text)) continue;

          _editableTexts.add(EditableText(
            id: 'text_$index',
            originalText: text,
            currentText: text,
          ));

          addedTexts.add(text);
          index++;
        } catch (e) {
          print('Error parsing text element: $e');
          continue;
        }
      }

      // Parse tspan elements
      for (final element in tspanElements) {
        try {
          final text = element.innerText.trim();
          
          if (text.isEmpty || addedTexts.contains(text)) continue;

          _editableTexts.add(EditableText(
            id: 'tspan_$index',
            originalText: text,
            currentText: text,
          ));

          addedTexts.add(text);
          index++;
        } catch (e) {
          print('Error parsing tspan element: $e');
          continue;
        }
      }

      // Create some default elements if none found
      if (_editableTexts.isEmpty) {
        print('No text elements found, creating defaults');
        _createDefaultTextElements();
      } else {
        print('Successfully found ${_editableTexts.length} text elements to edit');
      }

    } catch (e) {
      print('Error parsing SVG document: $e');
      _createDefaultTextElements();
    }
    
    setState(() {});
  }

  /// Create default text elements for testing
  void _createDefaultTextElements() {
    _editableTexts.addAll([
      EditableText(
        id: 'default_1',
        originalText: 'Title Text',
        currentText: 'Title Text',
      ),
      EditableText(
        id: 'default_2',
        originalText: 'Main Content',
        currentText: 'Main Content',
      ),
      EditableText(
        id: 'default_3',
        originalText: 'Footer Text',
        currentText: 'Footer Text',
      ),
      EditableText(
        id: 'default_4',
        originalText: 'Process Step',
        currentText: 'Process Step',
      ),
      EditableText(
        id: 'default_5',
        originalText: 'Label',
        currentText: 'Label',
      ),
    ]);
  }



  /// Check if any text has been changed
  bool _hasChanges() {
    return _editableTexts.any((text) => text.controller.text.trim() != text.originalText);
  }

  /// Update current text values from controllers
  void _updateTextValues() {
    for (final editableText in _editableTexts) {
      editableText.currentText = editableText.controller.text.trim();
    }
  }

  /// Show message to user
  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Regenerate diagram with changes
  Future<void> _regenerateDiagram() async {
    if (!_hasChanges() || _isRegenerating) return;

    // Update all text values from controllers first
    _updateTextValues();

    setState(() {
      _isRegenerating = true;
    });

    try {
      // Build modified prompt
      final modifiedPrompt = _buildModifiedPrompt();
      
      print('Modified prompt being sent: $modifiedPrompt');
      _showMessage('Regenerating diagram with your changes...', Colors.blue);

      final apiService = ApiService();
      final newSvg = await apiService.regenerateDiagram(
        prompt: modifiedPrompt,
        diagramType: widget.template.name,
        currentSvg: _currentSvg,
      );

      // Update the SVG content
      _currentSvg = newSvg;
      
      // Re-parse the new SVG to get updated text elements
      _parseTextElements();
      
      _showMessage('Diagram regenerated successfully! Text fields updated with new content.', Colors.green);
      
      // Stay in edit mode to show the updated text fields
      setState(() {
        _showEditMode = true;
      });
      
    } catch (e) {
      print('Error regenerating diagram: $e');
      
      // Provide more specific error messages
      String errorMessage = 'Error regenerating diagram';
      if (e.toString().contains('AI service is currently unavailable')) {
        errorMessage = 'AI service unavailable. Please check backend configuration.';
      } else if (e.toString().contains('Connection error')) {
        errorMessage = 'Cannot connect to backend. Please ensure it\'s running.';
      } else if (e.toString().contains('Backend error')) {
        errorMessage = 'Backend error. Please try again or check server logs.';
      }
      
      _showMessage(errorMessage, Colors.red);
    } finally {
      setState(() {
        _isRegenerating = false;
      });
    }
  }

  /// Build modified prompt with text changes
  String _buildModifiedPrompt() {
    String prompt = widget.originalPrompt;
    
    for (final editableText in _editableTexts) {
      final currentValue = editableText.controller.text.trim();
      if (currentValue != editableText.originalText && currentValue.isNotEmpty) {
        prompt += '\n- Change "${editableText.originalText}" to "$currentValue"';
        print('Adding change: "${editableText.originalText}" -> "$currentValue"');
      }
    }
    
    return prompt;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Return the updated SVG when leaving the screen
        Navigator.pop(context, {
          'updated': true,
          'svg': _currentSvg,
        });
        return false; // Prevent default pop behavior
      },
      child: Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(
          widget.template.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: widget.template.color,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Save button
          IconButton(
            onPressed: () {
              Navigator.pop(context, {
                'updated': true,
                'svg': _currentSvg,
              });
            },
            icon: const Icon(Icons.check),
            tooltip: 'Save and Return',
          ),
          // View/Edit toggle button
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Zoom View button
                GestureDetector(
                  onTap: () => setState(() => _showEditMode = false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: !_showEditMode ? Colors.white : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.zoom_in,
                          color: !_showEditMode ? widget.template.color : Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Zoom',
                          style: TextStyle(
                            color: !_showEditMode ? widget.template.color : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Edit button
                GestureDetector(
                  onTap: () => setState(() => _showEditMode = true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: _showEditMode ? Colors.white : Colors.transparent,
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(20),
                        bottomRight: Radius.circular(20),
                      ),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.edit_note,
                          color: _showEditMode ? widget.template.color : Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Edit',
                          style: TextStyle(
                            color: _showEditMode ? widget.template.color : Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: _showEditMode ? _buildEditMode() : _buildZoomMode(),
      floatingActionButton: _showEditMode && _hasChanges()
          ? FloatingActionButton.extended(
              onPressed: _isRegenerating ? null : _regenerateDiagram,
              backgroundColor: widget.template.color,
              foregroundColor: Colors.white,
              icon: _isRegenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(_isRegenerating ? 'Regenerating...' : 'Regenerate Diagram'),
            )
          : null,
      ),
    );
  }

  /// Build the zoom view mode
  Widget _buildZoomMode() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InteractiveViewer(
          transformationController: _transformationController,
          minScale: 0.5,
          maxScale: 4.0,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
            child: Center(
              child: SvgPicture.string(
                normalizeSvgColors(_currentSvg),
                fit: BoxFit.contain,
                width: 800,
                height: 600,
                placeholderBuilder: (context) => const CircularProgressIndicator(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Build the edit mode with text fields
  Widget _buildEditMode() {
    return Column(
      children: [
        // Info banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade400],
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.edit_note, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Diagram Text',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Found ${_editableTexts.length} text elements to edit',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: Colors.white),
            ],
          ),
        ),

        // Text editing list
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: _editableTexts.isEmpty
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _editableTexts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final editableText = _editableTexts[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Header with original text
                            Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: widget.template.color,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Original Text:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '"${editableText.originalText}"',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            
                            // Text editing field
                            TextField(
                              controller: editableText.controller,
                              decoration: InputDecoration(
                                labelText: 'Edit Text ${index + 1}',
                                hintText: 'Enter new text...',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide(color: widget.template.color, width: 2),
                                ),
                                prefixIcon: Icon(Icons.text_fields, color: widget.template.color),
                                suffixIcon: editableText.controller.text != editableText.originalText
                                    ? Icon(Icons.edit, color: Colors.orange.shade600)
                                    : null,
                              ),
                              style: const TextStyle(fontSize: 16),
                              maxLines: 2,
                              onChanged: (value) {
                                setState(() {}); // Trigger rebuild to show/hide regenerate button
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ),

        // Help message when no changes
        if (!_hasChanges())
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Make changes to the text fields above, then tap the regenerate button to update your diagram.',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}