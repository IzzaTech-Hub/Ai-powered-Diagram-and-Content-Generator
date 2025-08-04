
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class NapkinDiagramViewer extends StatefulWidget {
  final String svgContent;
  final String diagramType;
  final Map<String, dynamic> options;
  final bool isDynamic;

  const NapkinDiagramViewer({
    super.key,
    required this.svgContent,
    required this.diagramType,
    this.options = const {},
    this.isDynamic = false,
  });

  @override
  State<NapkinDiagramViewer> createState() => _NapkinDiagramViewerState();
}

class _NapkinDiagramViewerState extends State<NapkinDiagramViewer> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TransformationController _transformationController;
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  double _currentScale = 1.0;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
      if (_animation != null) {
        _transformationController.value = _animation!.value;
      }
    });
    
    // Simulate loading the SVG
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void didUpdateWidget(NapkinDiagramViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the SVG content changed and we're in dynamic mode, animate the transition
    if (widget.svgContent != oldWidget.svgContent && widget.isDynamic) {
      // Brief loading state
      setState(() {
        _isLoading = true;
      });
      
      // Show loading briefly then reveal new diagram
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _resetView() {
    final Matrix4 identity = Matrix4.identity();
    _animateMatrix(identity);
    _currentScale = 1.0;
  }

  void _animateMatrix(Matrix4 end) {
    _animation = Matrix4Tween(
      begin: _transformationController.value,
      end: end,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return LayoutBuilder(
      builder: (context, constraints) {
        // Determine screen size categories for better responsiveness
        final screenWidth = constraints.maxWidth;
        final isSmallScreen = screenWidth < 600;
        final isVerySmallScreen = screenWidth < 350;
        
        // Calculate responsive dimensions based on available space
        final paddingSize = isSmallScreen ? (isVerySmallScreen ? 4.0 : 6.0) : 8.0;
        
        if (_isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: isSmallScreen ? (isVerySmallScreen ? 24 : 30) : 40,
                  height: isSmallScreen ? (isVerySmallScreen ? 24 : 30) : 40,
                  child: const CircularProgressIndicator(),
                ),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  'Loading diagram...',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 14 : 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          );
        }

        if (_errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: isSmallScreen ? 40 : 48),
                SizedBox(height: isSmallScreen ? 12 : 16),
                Text(
                  'Error loading diagram',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                    fontSize: isSmallScreen ? 16 : 18,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 6 : 8),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: isSmallScreen ? 12 : 14,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Diagram controls - Responsive layout
            Padding(
              padding: EdgeInsets.only(bottom: paddingSize),
              child: isVerySmallScreen
                  ? Column(
                      children: [
                        _buildControlsRow(isSmallScreen, firstHalf: true),
                        const SizedBox(height: 4),
                        _buildControlsRow(isSmallScreen, firstHalf: false),
                      ],
                    )
                  : _buildControlsRow(isSmallScreen),
            ),
            
            // Diagram container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      InteractiveViewer(
                        transformationController: _transformationController,
                        minScale: 0.5,
                        maxScale: 4.0,
                        boundaryMargin: const EdgeInsets.all(double.infinity),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            transitionBuilder: (Widget child, Animation<double> animation) {
                              return FadeTransition(opacity: animation, child: child);
                            },
                            child: SvgPicture.string(
                              widget.svgContent,
                              key: ValueKey<String>(widget.svgContent), // Key for animation
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                      ),
                      
                      // Dynamic indicator (small icon in corner)
                      if (widget.isDynamic)
                        Positioned(
                                            top: isSmallScreen ? 6 : 8,
                  right: isSmallScreen ? 6 : 8,
                          child: Container(
                            padding: EdgeInsets.all(isSmallScreen ? 3 : 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.sync,
                                  size: isSmallScreen ? (isVerySmallScreen ? 12 : 14) : 14,
                                  color: Colors.purple.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Auto',
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? (isVerySmallScreen ? 8 : 10) : 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.purple.shade700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Diagram type indicator
            Padding(
              padding: EdgeInsets.only(top: isSmallScreen ? 6.0 : 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _getDiagramIcon(),
                    size: isSmallScreen ? (isVerySmallScreen ? 12 : 14) : 16,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getDiagramTypeName(),
                    style: TextStyle(
                      fontSize: isSmallScreen ? (isVerySmallScreen ? 9 : 10) : 12,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }
    );
  }
  
  Widget _buildControlsRow(bool isSmallScreen, {bool firstHalf = true}) {
    // Use the responsive sizes passed from the parent build method
    final buttonSize = isSmallScreen ? (firstHalf ? 32.0 : 30.0) : 36.0;
    final actualIconSize = isSmallScreen ? (firstHalf ? 18.0 : 16.0) : 20.0;
    
    if (firstHalf) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Reset zoom button
          _buildControlButton(
            onPressed: _resetView,
            icon: Icons.restart_alt,
            tooltip: 'Reset view',
            iconSize: actualIconSize,
            buttonSize: buttonSize,
          ),
          // Zoom out button
          _buildControlButton(
            onPressed: () {
              if (_currentScale > 0.5) {
                _currentScale -= 0.25;
                final Matrix4 newMatrix = Matrix4.identity()..scale(_currentScale);
                _animateMatrix(newMatrix);
              }
            },
            icon: Icons.zoom_out,
            tooltip: 'Zoom out',
            iconSize: actualIconSize,
            buttonSize: buttonSize,
          ),
          // Zoom in button
          _buildControlButton(
            onPressed: () {
              if (_currentScale < 3.0) {
                _currentScale += 0.25;
                final Matrix4 newMatrix = Matrix4.identity()..scale(_currentScale);
                _animateMatrix(newMatrix);
              }
            },
            icon: Icons.zoom_in,
            tooltip: 'Zoom in',
            iconSize: actualIconSize,
            buttonSize: buttonSize,
          ),
        ],
      );
    } else {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Download button
          _buildControlButton(
            onPressed: () {
              // Download functionality would be implemented here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Downloading diagram...')),
              );
            },
            icon: Icons.download,
            tooltip: 'Download diagram',
            iconSize: actualIconSize,
            buttonSize: buttonSize,
          ),
          // Share button
          _buildControlButton(
            onPressed: () {
              // Share functionality would be implemented here
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing diagram...')),
              );
            },
            icon: Icons.share,
            tooltip: 'Share diagram',
            iconSize: actualIconSize,
            buttonSize: buttonSize,
          ),
        ],
      );
    }
  }
  
  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String tooltip,
    required double iconSize,
    required double buttonSize,
  }) {
    return Container(
      width: buttonSize,
      height: buttonSize,
      margin: const EdgeInsets.only(left: 4),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: iconSize),
        tooltip: tooltip,
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
        constraints: BoxConstraints(
          minWidth: buttonSize,
          minHeight: buttonSize,
        ),
      ),
    );
  }
  
  IconData _getDiagramIcon() {
    switch (widget.diagramType.toLowerCase()) {
      case 'flowchart':
        return Icons.account_tree_outlined;
      case 'sequence':
        return Icons.swap_calls_outlined;
      case 'class':
        return Icons.view_module_outlined;
      case 'erd':
        return Icons.schema_outlined;
      case 'state':
        return Icons.loop_outlined;
      case 'gantt':
        return Icons.date_range_outlined;
      case 'network':
        return Icons.router_outlined;
      case 'journey':
        return Icons.person_pin_circle_outlined;
      case 'architecture':
        return Icons.architecture_outlined;
      default:
        return Icons.design_services_outlined;
    }
  }
  
  String _getDiagramTypeName() {
    switch (widget.diagramType.toLowerCase()) {
      case 'flowchart':
        return 'Flowchart Diagram';
      case 'sequence':
        return 'Sequence Diagram';
      case 'class':
        return 'Class Diagram';
      case 'erd':
        return 'Entity Relationship Diagram';
      case 'state':
        return 'State Diagram';
      case 'gantt':
        return 'Gantt Chart';
      case 'network':
        return 'Network Diagram';
      case 'journey':
        return 'User Journey Map';
      case 'architecture':
        return 'Architecture Diagram';
      default:
        return 'Napkin AI Diagram';
    }
  }
} 