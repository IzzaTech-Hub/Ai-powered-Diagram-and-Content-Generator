import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/generated_content.dart';
import '../models/napkin_template.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../widgets/simple_diagram_viewer.dart';
import '../utils/platform_download.dart';
import 'diagram_editing_screen.dart';

class DiagramVariationsScreen extends StatefulWidget {
  final String userInput;
  final String diagramType;
  final NapkinTemplate template;

  const DiagramVariationsScreen({
    super.key,
    required this.userInput,
    required this.diagramType,
    required this.template,
  });

  @override
  State<DiagramVariationsScreen> createState() => _DiagramVariationsScreenState();
}

class _DiagramVariationsScreenState extends State<DiagramVariationsScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  List<GeneratedContent> _variations = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _selectedVariationIndex = 0;
  int? _hoveredVariationIndex;

  late AnimationController _animationController;
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _generateVariations();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.elasticOut),
    );

    _loadingController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _generateVariations() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _apiService.generateDiagramVariations(
        userInput: widget.userInput,
        diagramType: widget.diagramType,
      );
      
      final variations = response['variations'] as List<dynamic>;
      
      setState(() {
        _variations = variations.map((variation) {
          return GeneratedContent(
            templateName: variation['templateName'] ?? 'Untitled',
            content: variation['content'] ?? '',
            isDiagram: true,
            timestamp: DateTime.parse(
              variation['timestamp'] ?? DateTime.now().toIso8601String(),
            ),
            originalPrompt: widget.userInput,
            diagramType: variation['diagramType'],
          );
        }).toList();
        _isLoading = false;
      });

      _animationController.forward();
      
      ErrorHandler.showSuccessSnackBar(
        context,
        '🎉 Generated ${_variations.length} diagram variations!',
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = ErrorHandler.getFriendlyErrorMessage(e.toString());
      });
      
      ErrorHandler.showErrorSnackBar(
        context,
        _errorMessage!,
        onRetry: _generateVariations,
      );
    }
  }

  void _selectVariation(int index) {
    setState(() {
      _selectedVariationIndex = index;
    });
    HapticFeedback.selectionClick();
  }

  void _hoverVariation(int? index) {
    setState(() {
      _hoveredVariationIndex = index;
    });
  }

  Future<void> _editSelectedDiagram() async {
    if (_selectedVariationIndex < _variations.length) {
      final selectedDiagram = _variations[_selectedVariationIndex];
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DiagramEditingScreen(
            template: widget.template,
            svgContent: selectedDiagram.content,
            originalPrompt: widget.userInput,
          ),
        ),
      );
    }
  }

      Future<void> _handleDownload(GeneratedContent content) async {

    try {
      final fileName = '${content.templateName}_${DateTime.now().millisecondsSinceEpoch}.svg';
      final message = await saveSvgToDownloads(content.content, fileName);
      ErrorHandler.showSuccessSnackBar(context, message);
    } catch (e) {
      ErrorHandler.showErrorSnackBar(context, e.toString());
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: widget.template.gradientColors,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${widget.template.name} Variations',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Choose from 4 different visual styles',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(widget.template.icon, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '"${widget.userInput}"',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.white,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _loadingController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _loadingController.value * 2 * 3.14159,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.template.gradientColors,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.template.icon,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Creating ${widget.template.name} variations...',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: widget.template.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Generating 4 different visual styles for your diagram',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVariationsLayout() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: Row(
          children: [
            // Left sidebar with variations
            _buildVariationsSidebar(),
            
            // Right side with diagram preview
            Expanded(
              flex: 3,
              child: _buildDiagramPreview(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariationsSidebar() {
    return Container(
      width: 320,
      height: double.infinity,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(
          right: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sidebar header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagram Variations',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: widget.template.color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Hover to preview, click to select',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          
          // Variations list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _variations.length,
              itemBuilder: (context, index) {
                final variation = _variations[index];
                final isSelected = index == _selectedVariationIndex;
                final isHovered = index == _hoveredVariationIndex;
                
                return MouseRegion(
                  onEnter: (_) => _hoverVariation(index),
                  onExit: (_) => _hoverVariation(null),
                  child: GestureDetector(
                    onTap: () => _selectVariation(index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? widget.template.color.withOpacity(0.1)
                          : isHovered 
                            ? Colors.white
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                            ? widget.template.color
                            : isHovered 
                              ? widget.template.color.withOpacity(0.3)
                              : Colors.transparent,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isHovered || isSelected ? [
                          BoxShadow(
                            color: widget.template.color.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ] : [],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: widget.template.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  widget.template.icon,
                                  color: widget.template.color,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      variation.templateName,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected 
                                          ? widget.template.color
                                          : Colors.grey.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _getVariationDescription(index),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          
                          // Mini preview
                          Container(
                            height: 80,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: SimpleDiagramViewer(
                                generatedContent: variation,
                                template: widget.template,
                                originalPrompt: widget.userInput,
                                onDiagramUpdated: (updatedContent) {},
                                svgContent: null,
                                isPreview: true,
                              ),
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
      ),
    );
  }

  Widget _buildDiagramPreview() {
    if (_variations.isEmpty) return Container();
    
    final displayIndex = _hoveredVariationIndex ?? _selectedVariationIndex;
    final displayVariation = _variations[displayIndex];
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Preview header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayVariation.templateName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: widget.template.color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getVariationDescription(displayIndex),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (_hoveredVariationIndex != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.template.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Hover Preview',
                    style: TextStyle(
                      color: widget.template.color,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Diagram content
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: SimpleDiagramViewer(
                      generatedContent: displayVariation,
                      template: widget.template,
                      originalPrompt: widget.userInput,
                      onDiagramUpdated: (updatedContent) {
                        setState(() {
                          _variations[displayIndex] = updatedContent;
                        });
                      },
                      svgContent: null,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Action buttons
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.template.gradientColors,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: widget.template.color.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _editSelectedDiagram,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.edit, color: Colors.white),
              label: const Text(
                'Edit This Diagram',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton.icon(
          onPressed: () => _handleDownload(_variations[_selectedVariationIndex]),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(Icons.download, color: Colors.grey.shade700),
          label: Text(
            'Download',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(
              text: _variations[_selectedVariationIndex].content,
            ));
            ErrorHandler.showSuccessSnackBar(
              context,
              'Diagram copied to clipboard',
            );
          },
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            side: BorderSide(color: Colors.grey.shade400),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: Icon(Icons.copy, color: Colors.grey.shade700),
          label: Text(
            'Copy',
            style: TextStyle(color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade600, size: 48),
            const SizedBox(height: 16),
            Text(
              'Failed to Generate Variations',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.red.shade700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: TextStyle(color: Colors.red.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _generateVariations,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  String _getVariationDescription(int index) {
    const descriptions = [
      'Clean and professional standard layout',
      'Detailed version with enhanced information',
      'Compact simplified visualization',
      'Enhanced style with visual emphasis',
    ];
    return descriptions[index % descriptions.length];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorState()
                    : _variations.isEmpty
                        ? _buildErrorState()
                        : _buildVariationsLayout(),
          ),
        ],
      ),
    );
  }
}
