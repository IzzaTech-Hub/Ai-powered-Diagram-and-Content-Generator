import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MindMapTemplate {
  final String id;
  final String name;
  final String description;
  final Color previewColor;

  MindMapTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.previewColor,
  });

  factory MindMapTemplate.fromJson(Map<String, dynamic> json) {
    return MindMapTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      previewColor: Color(int.parse(json['preview_color'].substring(1), radix: 16) | 0xFF000000),
    );
  }
}

class MindMapTemplateSelector extends StatefulWidget {
  final Function(String) onTemplateSelected;
  final String initialTemplate;

  const MindMapTemplateSelector({
    super.key,
    required this.onTemplateSelected,
    this.initialTemplate = 'default',
  });

  @override
  State<MindMapTemplateSelector> createState() => _MindMapTemplateSelectorState();
}

class _MindMapTemplateSelectorState extends State<MindMapTemplateSelector> {
  final ApiService _apiService = ApiService();
  List<MindMapTemplate> _templates = [];
  bool _isLoading = true;
  String? _error;
  String _selectedTemplateId = 'default';

  @override
  void initState() {
    super.initState();
    _selectedTemplateId = widget.initialTemplate;
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final templates = await _apiService.getMindMapTemplates();
      
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load templates: $e';
        _isLoading = false;
        
        // Add fallback templates if API fails
        _templates = [
          MindMapTemplate(
            id: 'default',
            name: 'Classic',
            description: 'Traditional mind map with circular nodes',
            previewColor: Colors.deepPurple,
          ),
          MindMapTemplate(
            id: 'modern',
            name: 'Modern',
            description: 'Contemporary design with rectangular nodes',
            previewColor: Colors.blue,
          ),
        ];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null && _templates.isEmpty) {
      return Center(
        child: Text(
          'Error: $_error',
          style: TextStyle(color: Colors.red.shade700),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Row(
            children: [
              const Icon(Icons.style, size: 18),
              const SizedBox(width: 8),
              Text(
                'Select Mind Map Style',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length,
            itemBuilder: (context, index) {
              final template = _templates[index];
              final isSelected = template.id == _selectedTemplateId;
              
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTemplateId = template.id;
                    });
                    widget.onTemplateSelected(template.id);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? template.previewColor : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? template.previewColor.withOpacity(0.3)
                              : Colors.black.withOpacity(0.05),
                          blurRadius: isSelected ? 8 : 4,
                          spreadRadius: isSelected ? 2 : 0,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Preview area
                        Container(
                          height: 80,
                          decoration: BoxDecoration(
                            color: template.previewColor.withOpacity(0.15),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(11),
                              topRight: Radius.circular(11),
                            ),
                          ),
                          child: Center(
                            child: _buildTemplatePreview(template),
                          ),
                        ),
                        
                        // Template info
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    template.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  if (isSelected) ...[
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.check_circle,
                                      color: template.previewColor,
                                      size: 14,
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                template.description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildTemplatePreview(MindMapTemplate template) {
    // Simple preview of the mind map style
    switch (template.id) {
      case 'modern':
        return Stack(
          children: [
            // Central node
            Container(
              width: 30,
              height: 24,
              decoration: BoxDecoration(
                color: template.previewColor,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            // Branches
            Positioned(
              top: 12,
              left: 40,
              child: Container(
                width: 20,
                height: 2,
                color: template.previewColor,
              ),
            ),
            Positioned(
              top: 12,
              right: 40,
              child: Container(
                width: 20,
                height: 2,
                color: template.previewColor,
              ),
            ),
            // Branch nodes
            Positioned(
              top: 6,
              left: 65,
              child: Container(
                width: 20,
                height: 16,
                decoration: BoxDecoration(
                  color: template.previewColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 65,
              child: Container(
                width: 20,
                height: 16,
                decoration: BoxDecoration(
                  color: template.previewColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ],
        );
        
      case 'nature':
        return Stack(
          children: [
            // Central node
            Container(
              width: 30,
              height: 24,
              decoration: BoxDecoration(
                color: template.previewColor,
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            // Curved branches
            CustomPaint(
              size: const Size(100, 60),
              painter: CurvedLinePainter(
                color: template.previewColor,
                startPoint: const Offset(15, 12),
                endPoint: const Offset(65, 6),
                curveHeight: 8,
              ),
            ),
            CustomPaint(
              size: const Size(100, 60),
              painter: CurvedLinePainter(
                color: template.previewColor,
                startPoint: const Offset(15, 12),
                endPoint: const Offset(65, 18),
                curveHeight: -8,
              ),
            ),
            // Branch nodes
            Positioned(
              top: 0,
              left: 65,
              child: Container(
                width: 20,
                height: 16,
                decoration: BoxDecoration(
                  color: template.previewColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 65,
              child: Container(
                width: 20,
                height: 16,
                decoration: BoxDecoration(
                  color: template.previewColor.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        );
        
      case 'dark':
        return Stack(
          children: [
            // Central node
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                shape: BoxShape.circle,
                border: Border.all(color: template.previewColor, width: 2),
              ),
            ),
            // Branches
            Positioned(
              top: 15,
              left: 30,
              child: Container(
                width: 25,
                height: 2,
                color: template.previewColor,
              ),
            ),
            Positioned(
              top: 15,
              right: 30,
              child: Container(
                width: 25,
                height: 2,
                color: template.previewColor,
              ),
            ),
            // Branch nodes
            Positioned(
              top: 8,
              left: 60,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  shape: BoxShape.circle,
                  border: Border.all(color: template.previewColor, width: 1.5),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 60,
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  shape: BoxShape.circle,
                  border: Border.all(color: template.previewColor, width: 1.5),
                ),
              ),
            ),
          ],
        );
        
      case 'pastel':
        return Stack(
          children: [
            // Central node
            Container(
              width: 34,
              height: 26,
              decoration: BoxDecoration(
                color: template.previewColor.withOpacity(0.7),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: template.previewColor, width: 1),
              ),
            ),
            // Branches
            CustomPaint(
              size: const Size(100, 60),
              painter: CurvedLinePainter(
                color: template.previewColor,
                startPoint: const Offset(17, 13),
                endPoint: const Offset(60, 6),
                curveHeight: 5,
                strokeWidth: 1.5,
              ),
            ),
            CustomPaint(
              size: const Size(100, 60),
              painter: CurvedLinePainter(
                color: template.previewColor,
                startPoint: const Offset(17, 13),
                endPoint: const Offset(60, 20),
                curveHeight: -5,
                strokeWidth: 1.5,
              ),
            ),
            // Branch nodes
            Positioned(
              top: 0,
              left: 60,
              child: Container(
                width: 24,
                height: 18,
                decoration: BoxDecoration(
                  color: template.previewColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: template.previewColor, width: 1),
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 60,
              child: Container(
                width: 24,
                height: 18,
                decoration: BoxDecoration(
                  color: template.previewColor.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: template.previewColor, width: 1),
                ),
              ),
            ),
          ],
        );
        
      default: // Classic/default
        return Stack(
          children: [
            // Central node
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: template.previewColor,
                shape: BoxShape.circle,
              ),
            ),
            // Curved branches
            CustomPaint(
              size: const Size(100, 60),
              painter: CurvedLinePainter(
                color: template.previewColor,
                startPoint: const Offset(15, 15),
                endPoint: const Offset(60, 8),
                curveHeight: 10,
              ),
            ),
            CustomPaint(
              size: const Size(100, 60),
              painter: CurvedLinePainter(
                color: template.previewColor,
                startPoint: const Offset(15, 15),
                endPoint: const Offset(60, 22),
                curveHeight: -10,
              ),
            ),
            // Branch nodes
            Positioned(
              top: 0,
              left: 60,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: template.previewColor.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: 14,
              left: 60,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: template.previewColor.withOpacity(0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
    }
  }
}

class CurvedLinePainter extends CustomPainter {
  final Color color;
  final Offset startPoint;
  final Offset endPoint;
  final double curveHeight;
  final double strokeWidth;

  CurvedLinePainter({
    required this.color,
    required this.startPoint,
    required this.endPoint,
    required this.curveHeight,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(startPoint.dx, startPoint.dy);
    
    // Control point for the curve
    final controlX = (startPoint.dx + endPoint.dx) / 2;
    final controlY = (startPoint.dy + endPoint.dy) / 2 + curveHeight;
    
    path.quadraticBezierTo(
      controlX, controlY,
      endPoint.dx, endPoint.dy,
    );
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
} 