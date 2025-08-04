import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:xml/xml.dart' as xml;
import '../services/api_service.dart';

class EditableDiagramViewer extends StatefulWidget {
  final String svgContent;
  final String templateName;
  final Function(String) onDiagramUpdated;
  final String originalPrompt;

  const EditableDiagramViewer({
    super.key,
    required this.svgContent,
    required this.templateName,
    required this.onDiagramUpdated,
    required this.originalPrompt,
  });

  @override
  State<EditableDiagramViewer> createState() => _EditableDiagramViewerState();
}

class _EditableDiagramViewerState extends State<EditableDiagramViewer> {
  bool _isFullscreen = false;
  bool _isEditing = false;
  bool _isUpdating = false;
  String _currentSvg = '';
  final ApiService _apiService = ApiService();
  
  // Selected element properties
  String? _selectedElementId;
  String? _selectedElementText;
  Offset? _selectedElementPosition;
  
  // SVG element mapping
  final Map<String, Map<String, dynamic>> _svgElements = {};
  
  // Controllers for editing
  final TextEditingController _textEditingController = TextEditingController();
  
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

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
    });
  }
  

  
  void _clearSelection() {
    setState(() {
      _selectedElementId = null;
      _selectedElementText = null;
      _selectedElementPosition = null;
      _textEditingController.clear();
    });
  }
  
  void _selectElement(String id, String text, Offset position) {
    setState(() {
      _selectedElementId = id;
      _selectedElementText = text;
      _selectedElementPosition = position;
      _textEditingController.text = text;
    });
  }
  
  void _handleTap(Offset position) {
    // First check for blocks that contain the tap position
    String? selectedId;
    String? selectedText;
    Offset? selectedPosition;
    
    // Check for blocks first (they take priority)
    for (final entry in _svgElements.entries) {
      if (entry.value['type'] == 'block-with-text') {
        final blockPosition = entry.value['position'] as Offset;
        final width = entry.value['width'] as double;
        final height = entry.value['height'] as double;
        
        // Check if tap is inside this block
        if (position.dx >= blockPosition.dx - width/2 &&
            position.dx <= blockPosition.dx + width/2 &&
            position.dy >= blockPosition.dy - height/2 &&
            position.dy <= blockPosition.dy + height/2) {
          selectedId = entry.key;
          selectedText = entry.value['text'] as String;
          selectedPosition = blockPosition;
          
          // Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Editing block: "$selectedText"'),
              duration: Duration(seconds: 1),
              backgroundColor: Colors.blue,
            ),
          );
          
          break;
        }
      }
    }
    
    // If no block was tapped, find the closest text element
    if (selectedId == null) {
      double minDistance = double.infinity;
      
      for (final entry in _svgElements.entries) {
        // Skip blocks since we already checked them
        if (entry.value['type'] == 'block-with-text') continue;
        
        final elementPosition = entry.value['position'] as Offset;
        final distance = (elementPosition - position).distance;
        
        // Find the closest element within a reasonable distance (80 pixels)
        if (distance < minDistance && distance < 80) {
          minDistance = distance;
          selectedId = entry.key;
          selectedText = entry.value['text'] as String;
          selectedPosition = elementPosition;
        }
      }
    }
    
    // If we found a selectable element, select it
    if (selectedId != null && selectedText != null && selectedPosition != null) {
      _selectElement(selectedId, selectedText, selectedPosition);
      print('Selected element: $selectedText at position $selectedPosition');
    } else {
      // If no element is close to the tap, create a new text element at that position
      print('No text element found near position $position, creating new one');
      _selectElement(
        'new-text-${DateTime.now().millisecondsSinceEpoch}',
        'New Text',
        position,
      );
    }
  }
  
  void _parseSvgElements() {
    try {
      final document = xml.XmlDocument.parse(_currentSvg);
      _svgElements.clear();
      
      // Find all blocks (rect, circle, ellipse, polygon, path) that might be part of a diagram
      final blockElements = [
        ...document.findAllElements('rect'),
        ...document.findAllElements('circle'),
        ...document.findAllElements('ellipse'),
        ...document.findAllElements('polygon'),
        ...document.findAllElements('path'),
      ];
      
      // Create a map of blocks with their positions and dimensions
      final Map<String, Map<String, dynamic>> blocks = {};
      
      // Process rectangle elements (common in flowcharts and diagrams)
      for (final element in blockElements) {
        final id = element.getAttribute('id') ?? 'block-${blocks.length}';
        final elementName = element.name.local;
        
        // Skip elements that are likely not blocks (very small or decorative elements)
        if (elementName == 'path') {
          final dAttr = element.getAttribute('d');
          if (dAttr == null || dAttr.length < 10) continue; // Skip simple paths
        }
        
        // Extract position and size information
        double x = 0, y = 0, width = 50, height = 30;
        
        if (elementName == 'rect') {
          x = double.tryParse(element.getAttribute('x') ?? '0') ?? 0;
          y = double.tryParse(element.getAttribute('y') ?? '0') ?? 0;
          width = double.tryParse(element.getAttribute('width') ?? '50') ?? 50;
          height = double.tryParse(element.getAttribute('height') ?? '30') ?? 30;
        } else if (elementName == 'circle') {
          final cx = double.tryParse(element.getAttribute('cx') ?? '0') ?? 0;
          final cy = double.tryParse(element.getAttribute('cy') ?? '0') ?? 0;
          final r = double.tryParse(element.getAttribute('r') ?? '20') ?? 20;
          x = cx - r;
          y = cy - r;
          width = r * 2;
          height = r * 2;
        } else if (elementName == 'ellipse') {
          final cx = double.tryParse(element.getAttribute('cx') ?? '0') ?? 0;
          final cy = double.tryParse(element.getAttribute('cy') ?? '0') ?? 0;
          final rx = double.tryParse(element.getAttribute('rx') ?? '25') ?? 25;
          final ry = double.tryParse(element.getAttribute('ry') ?? '15') ?? 15;
          x = cx - rx;
          y = cy - ry;
          width = rx * 2;
          height = ry * 2;
        }
        
        // Store block information
        blocks[id] = {
          'element': element,
          'type': 'block',
          'shape': elementName,
          'position': Offset(x, y),
          'width': width,
          'height': height,
          'center': Offset(x + width / 2, y + height / 2),
        };
      }
      
      // Find text elements
      final textElements = document.findAllElements('text');
      for (final element in textElements) {
        final id = element.getAttribute('id') ?? 'text-${_svgElements.length}';
        final text = element.innerText;
        
        // Skip empty text elements
        if (text.trim().isEmpty) continue;
        
        // Get position from attributes or transform
        double x = 0, y = 0;
        if (element.getAttribute('x') != null) {
          x = double.tryParse(element.getAttribute('x')!) ?? 0;
        }
        if (element.getAttribute('y') != null) {
          y = double.tryParse(element.getAttribute('y')!) ?? 0;
        }
        
        // Handle transform attribute if present
        final transform = element.getAttribute('transform');
        if (transform != null && transform.contains('translate')) {
          final translateRegex = RegExp(r'translate\(\s*([0-9.-]+)(?:\s*,\s*|\s+)([0-9.-]+)\s*\)');
          final match = translateRegex.firstMatch(transform);
          if (match != null && match.groupCount >= 2) {
            x = double.tryParse(match.group(1)!) ?? x;
            y = double.tryParse(match.group(2)!) ?? y;
          }
        }
        
        // Try to associate this text with a block
        String? associatedBlockId;
        double minDistance = double.infinity;
        
        for (final entry in blocks.entries) {
          final blockCenter = entry.value['center'] as Offset;
          final distance = (Offset(x, y) - blockCenter).distance;
          
          // If text is within or very close to a block, associate it
          if (distance < minDistance) {
            minDistance = distance;
            associatedBlockId = entry.key;
          }
        }
        
        final textElement = {
          'element': element,
          'text': text,
          'type': 'text',
          'position': Offset(x, y),
          'associatedBlockId': associatedBlockId,
        };
        
        _svgElements[id] = textElement;
        
        // If this text is associated with a block, update the block with the text info
        if (associatedBlockId != null && blocks.containsKey(associatedBlockId)) {
          blocks[associatedBlockId]!['text'] = text;
          blocks[associatedBlockId]!['textElement'] = element;
          blocks[associatedBlockId]!['textId'] = id;
        }
      }
      
      // Find tspan elements (often used in complex text layouts)
      final tspanElements = document.findAllElements('tspan');
      for (final element in tspanElements) {
        final parentElement = element.parent;
        if (parentElement == null) continue;
        
        final id = element.getAttribute('id') ?? 'tspan-${_svgElements.length}';
        final text = element.innerText;
        
        // Skip empty text elements
        if (text.trim().isEmpty) continue;
        
        // Get position from attributes or transform
        double x = 0, y = 0;
        if (element.getAttribute('x') != null) {
          x = double.tryParse(element.getAttribute('x')!) ?? 0;
        } else if (parentElement is xml.XmlElement && parentElement.getAttribute('x') != null) {
          // If tspan doesn't have x, try to get from parent
          x = double.tryParse(parentElement.getAttribute('x')!) ?? 0;
        }
        
        if (element.getAttribute('y') != null) {
          y = double.tryParse(element.getAttribute('y')!) ?? 0;
        } else if (parentElement is xml.XmlElement && parentElement.getAttribute('y') != null) {
          // If tspan doesn't have y, try to get from parent
          y = double.tryParse(parentElement.getAttribute('y')!) ?? 0;
        }
        
        _svgElements[id] = {
          'element': element,
          'text': text,
          'type': 'tspan',
          'position': Offset(x, y)
        };
      }
      
      // Add blocks with text to the elements map
      for (final entry in blocks.entries) {
        if (entry.value.containsKey('text')) {
          final blockId = 'block-with-text-${_svgElements.length}';
          _svgElements[blockId] = {
            'element': entry.value['element'],
            'text': entry.value['text'],
            'textElement': entry.value['textElement'],
            'type': 'block-with-text',
            'shape': entry.value['shape'],
            'position': entry.value['center'],
            'width': entry.value['width'],
            'height': entry.value['height'],
            'textId': entry.value['textId'],
          };
        }
      }
      
      print('Parsed ${_svgElements.length} elements from SVG (${blocks.length} blocks)');
    } catch (e) {
      print('Error parsing SVG elements: $e');
    }
  }

  Future<void> _updateElementText() async {
    if (_selectedElementId == null || _textEditingController.text == _selectedElementText) {
      return;
    }
    
    try {
      // Parse the SVG content
      final document = xml.XmlDocument.parse(_currentSvg);
      bool updated = false;
      
      // Check if we're updating a block-with-text element
      final selectedElement = _svgElements[_selectedElementId!];
      if (selectedElement != null && selectedElement['type'] == 'block-with-text') {
        print('Updating block-with-text element: $_selectedElementId');
        
        // For block-with-text, we need to update the associated text element
        if (selectedElement.containsKey('textElement') && selectedElement['textElement'] != null) {
          final textElement = selectedElement['textElement'] as xml.XmlElement;
          textElement.children.clear();
          textElement.children.add(xml.XmlText(_textEditingController.text));
          updated = true;
          print('Updated text element directly');
        } else if (selectedElement.containsKey('textId') && selectedElement['textId'] != null) {
          // Try to find the text element by ID
          final textId = selectedElement['textId'] as String;
          final textElements = document.findAllElements('text');
          for (final element in textElements) {
            final id = element.getAttribute('id');
            if (id == textId) {
              element.children.clear();
              element.children.add(xml.XmlText(_textEditingController.text));
              updated = true;
              print('Updated text element by ID: $textId');
              break;
            }
          }
        }
        
        // If we still haven't updated, try to find by text content
        if (!updated && _selectedElementText != null) {
          final textElements = document.findAllElements('text');
          for (final element in textElements) {
            if (element.innerText.trim() == _selectedElementText?.trim()) {
              element.children.clear();
              element.children.add(xml.XmlText(_textEditingController.text));
              updated = true;
              print('Updated text element by content match');
              break;
            }
          }
        }
      } else {
        // Find all text elements
        final textElements = document.findAllElements('text');
        
        // First approach: Try to update by ID
        for (final element in textElements) {
          final id = element.getAttribute('id');
          if (id == _selectedElementId) {
            element.children.clear();
            element.children.add(xml.XmlText(_textEditingController.text));
            updated = true;
            break;
          }
          
          // Check child tspan elements
          final tspans = element.findElements('tspan');
          for (final tspan in tspans) {
            final tspanId = tspan.getAttribute('id');
            if (tspanId == _selectedElementId) {
              tspan.children.clear();
              tspan.children.add(xml.XmlText(_textEditingController.text));
              updated = true;
              break;
            }
          }
          
          if (updated) break;
        }
        
        // Second approach: Try to update by exact content match
        if (!updated) {
          for (final element in textElements) {
            if (element.innerText.trim() == _selectedElementText?.trim()) {
              element.children.clear();
              element.children.add(xml.XmlText(_textEditingController.text));
              updated = true;
              break;
            }
            
            // Check child tspan elements
            final tspans = element.findElements('tspan');
            for (final tspan in tspans) {
              if (tspan.innerText.trim() == _selectedElementText?.trim()) {
                tspan.children.clear();
                tspan.children.add(xml.XmlText(_textEditingController.text));
                updated = true;
                break;
              }
            }
            
            if (updated) break;
          }
        }
        
        // Third approach: Try to update by partial content match
        if (!updated && _selectedElementText != null && _selectedElementText!.isNotEmpty) {
          for (final element in textElements) {
            if (element.innerText.contains(_selectedElementText!)) {
              element.children.clear();
              element.children.add(xml.XmlText(_textEditingController.text));
              updated = true;
              break;
            }
          }
        }
      }
      
      // Fourth approach: If all else fails, just add a new text element
      if (!updated) {
        // Create a new text element at the selected position
        final newTextElement = xml.XmlElement(
          xml.XmlName('text'),
          [
            xml.XmlAttribute(xml.XmlName('id'), 'new-text-${DateTime.now().millisecondsSinceEpoch}'),
            xml.XmlAttribute(xml.XmlName('x'), '${_selectedElementPosition?.dx ?? 100}'),
            xml.XmlAttribute(xml.XmlName('y'), '${_selectedElementPosition?.dy ?? 100}'),
            xml.XmlAttribute(xml.XmlName('font-family'), 'Inter, -apple-system, sans-serif'),
            xml.XmlAttribute(xml.XmlName('font-size'), '14'),
            xml.XmlAttribute(xml.XmlName('fill'), '#000000'),
          ],
          [xml.XmlText(_textEditingController.text)],
        );
        
        // Find the SVG root element and add the new text element
        final svgElement = document.findElements('svg').first;
        svgElement.children.add(newTextElement);
        updated = true;
      }
      
      // Update the SVG content
      final updatedSvg = document.toXmlString();
      setState(() {
        _currentSvg = updatedSvg;
        _selectedElementText = _textEditingController.text;
      });
      
      // Re-parse the SVG elements
      _parseSvgElements();
      
      // Notify parent about the update
      widget.onDiagramUpdated(_currentSvg);
      
      // Clear selection
      _clearSelection();
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diagram updated successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update diagram: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  Future<void> _regenerateDiagram() async {
    setState(() {
      _isUpdating = true;
    });
    
    try {
      // Call API to regenerate the diagram
      final updatedSvg = await _apiService.regenerateDiagram(
        prompt: widget.originalPrompt,
        diagramType: widget.templateName,
        currentSvg: _currentSvg,
      );
      
      setState(() {
        _currentSvg = updatedSvg;
        _isUpdating = false;
      });
      
      // Re-parse the SVG elements
      _parseSvgElements();
      
      // Notify parent about the update
      widget.onDiagramUpdated(_currentSvg);
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Diagram regenerated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUpdating = false;
      });
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to regenerate diagram: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Always start in edit mode for better user experience
    if (!_isEditing) {
      _isEditing = true;
    }
    
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;

        final diagramWidget = Container(
          constraints: BoxConstraints(
            maxHeight: _isFullscreen
                ? MediaQuery.of(context).size.height * 0.8
                : MediaQuery.of(context).size.height * 0.5,
            minHeight: isSmallScreen ? 150 : 200,
          ),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isEditing ? Colors.blue.shade300 : Colors.grey.shade300, 
              width: _isEditing ? 2 : 1
            ),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: _isEditing 
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
                // SVG Viewer
                InteractiveViewer(
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.3,
                  maxScale: 5.0,
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                    child: _isUpdating
                        ? const Center(
                            child: CircularProgressIndicator(),
                          )
                        : GestureDetector(
                            onTapUp: _isEditing
                                ? (details) {
                                    _handleTap(details.localPosition);
                                  }
                                : null,
                            child: SvgPicture.string(
                              _currentSvg,
                              fit: BoxFit.contain,
                              placeholderBuilder: (context) =>
                                  const Center(child: CircularProgressIndicator()),
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
                      // Regenerate button
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: Colors.purple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: Icon(
                            Icons.refresh,
                            color: Colors.white,
                            size: isSmallScreen ? 20 : 24,
                          ),
                          onPressed: _isUpdating ? null : _regenerateDiagram,
                          tooltip: 'Regenerate Diagram',
                        ),
                      ),
                      
                      // Fullscreen button
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: IconButton(
                          icon: Icon(
                            _isFullscreen
                                ? Icons.fullscreen_exit
                                : Icons.fullscreen,
                            color: Colors.white,
                            size: isSmallScreen ? 20 : 24,
                          ),
                          onPressed: _toggleFullscreen,
                          tooltip: _isFullscreen ? 'Exit Fullscreen' : 'Fullscreen',
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Editing instruction overlay
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                        Icon(Icons.touch_app, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Tap any text to edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Highlight editable blocks
                ..._svgElements.entries.where((entry) => 
                  entry.value['type'] == 'block-with-text'
                ).map((entry) {
                  final position = entry.value['position'] as Offset;
                  final text = entry.value['text'] as String;
                  final width = entry.value['width'] as double;
                  final height = entry.value['height'] as double;
                  
                  return Positioned(
                    left: position.dx - width/2,
                    top: position.dy - height/2,
                    child: GestureDetector(
                      onTap: () => _selectElement(entry.key, text, position),
                      child: Container(
                        width: width,
                        height: height,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          border: Border.all(
                            color: Colors.blue.withOpacity(0.5),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.edit,
                            color: Colors.blue.withOpacity(0.7),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
                
                // Highlight other editable text elements
                ..._svgElements.entries.where((entry) => 
                  entry.value['type'] == 'text' || entry.value['type'] == 'tspan'
                ).map((entry) {
                  final position = entry.value['position'] as Offset;
                  final text = entry.value['text'] as String;
                  
                  // Skip text that's already associated with a block
                  if (entry.value.containsKey('associatedBlockId') && 
                      entry.value['associatedBlockId'] != null) {
                    return const SizedBox.shrink();
                  }
                  
                  return Positioned(
                    left: position.dx - 5,
                    top: position.dy - 5,
                    child: GestureDetector(
                      onTap: () => _selectElement(entry.key, text, position),
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  );
                }).toList(),

                // Zoom hint
                if (!_isFullscreen && !_isEditing)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12,
                        vertical: isSmallScreen ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Pinch to zoom • Drag to pan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 10 : 12,
                        ),
                      ),
                    ),
                  ),
                  
                // Edit mode indicator
                if (_isEditing)
                  Positioned(
                    bottom: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12,
                        vertical: isSmallScreen ? 4 : 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Edit Mode • Tap on elements to edit',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 10 : 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  
                // Text editor popup when element is selected
                if (_selectedElementId != null && _selectedElementPosition != null)
                  Builder(
                    builder: (context) {
                      // Get information about the selected element
                      final selectedElement = _svgElements[_selectedElementId!];
                      bool isBlock = selectedElement != null && selectedElement['type'] == 'block-with-text';
                      double? width;
                      double? height;
                      
                      if (isBlock) {
                        width = selectedElement['width'] as double?;
                        height = selectedElement['height'] as double?;
                      }
                      
                      // Calculate popup position
                      double left = _selectedElementPosition!.dx;
                      double top = _selectedElementPosition!.dy;
                      
                      // For blocks, center the popup
                      if (isBlock && width != null && height != null) {
                        left = left - width/2;
                        top = top - height/2;
                      }
                      
                      // Ensure popup is not positioned too far to the right
                      final maxWidth = constraints.maxWidth;
                      if (left > maxWidth - 270) {
                        left = maxWidth - 270;
                      }
                      
                      // For blocks, position the popup on top of the block
                      if (isBlock && height != null) {
                        top = top - 180; // Position above the block
                        if (top < 10) top = 10; // Ensure it's not off-screen
                      }
                      
                      return Positioned(
                        left: left,
                        top: top,
                        child: Material(
                          elevation: 8,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            width: 250,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.blue.shade300, width: 2),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Icon(isBlock ? Icons.edit_note : Icons.edit, size: 18, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text(
                                      isBlock ? 'Edit Block Text' : 'Edit Text',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                    Spacer(),
                                    IconButton(
                                      icon: Icon(Icons.close, size: 18),
                                      onPressed: _clearSelection,
                                      padding: EdgeInsets.zero,
                                      constraints: BoxConstraints(),
                                      splashRadius: 20,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _textEditingController,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      borderSide: BorderSide(color: Colors.blue, width: 2),
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey.shade50,
                                    hintText: 'Enter text here...',
                                  ),
                                  maxLines: 3,
                                  minLines: 1,
                                  autofocus: true,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: _updateElementText,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                        foregroundColor: Colors.white,
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      icon: Icon(Icons.check, size: 18),
                                      label: const Text('Update Text'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                  ),
              ],
            ),
          ),
        );

        if (_isFullscreen) {
          return Dialog(
            insetPadding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade100, Colors.grey.shade200],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.templateName,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: _toggleFullscreen,
                      ),
                    ],
                  ),
                ),
                Expanded(child: diagramWidget),
              ],
            ),
          );
        }

        return diagramWidget;
      },
    );
  }
}