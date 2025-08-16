import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:my_flutter_app/screens/login_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/generated_content.dart';
import '../models/napkin_template.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../widgets/simple_diagram_viewer.dart';
import '../utils/platform_download.dart';

class ContentGeneratorScreen extends StatefulWidget {
  const ContentGeneratorScreen({super.key});

  @override
  State<ContentGeneratorScreen> createState() => _ContentGeneratorScreenState();
}

class _ContentGeneratorScreenState extends State<ContentGeneratorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ApiService _apiService = ApiService();
  List<GeneratedContent> _generatedContents = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isBackendHealthy = false;

  // Enhanced diagram properties
  NapkinTemplate? _selectedDiagramTemplate;
  List<NapkinTemplate> _diagramTemplates = [];
  String _selectedDiagramType = 'flowchart';

  // Variation state management
  List<GeneratedContent> _currentVariations = [];
  GeneratedContent? _selectedVariation;
  GeneratedContent? _hoveredVariation;

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  // Enhanced diagram templates matching your backend exactly
  final Map<String, List<NapkinTemplate>> _categorizedTemplates = {
    'Process & Flow': [
      NapkinTemplate(
        id: 'flowchart',
        name: 'Flowchart',
        description:
            'Sequential process with decision points and workflow steps',
        napkinType: 'flowchart',
        icon: Icons.account_tree,
        color: const Color(0xFF2563EB),
        gradientColors: [const Color(0xFF2563EB), const Color(0xFF3B82F6)],
        promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'sequence',
        name: 'Sequence Diagram',
        description:
            'Actor interactions and message flow between system components',
        napkinType: 'sequence',
        icon: Icons.timeline,
        color: const Color(0xFF059669),
        gradientColors: [const Color(0xFF059669), const Color(0xFF10B981)],
        promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'state',
        name: 'State Diagram',
        description:
            'System states, transitions, and state machine visualization',
        napkinType: 'state',
        icon: Icons.radio_button_checked,
        color: const Color(0xFFDC2626),
        gradientColors: [const Color(0xFFDC2626), const Color(0xFFEF4444)],
        promptInstruction: '',
      ),
    ],
    'Analysis & Planning': [
      NapkinTemplate(
        id: 'swot',
        name: 'SWOT Analysis',
        description:
            'Strategic analysis with strengths, weaknesses, opportunities, threats',
        napkinType: 'swot analysis',
        icon: Icons.analytics,
        color: const Color(0xFF7C3AED),
        gradientColors: [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)],
        promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'mindmap',
        name: 'Mind Map',
        description:
            'Hierarchical concept visualization with central topic and branches',
        napkinType: 'mind map',
        icon: Icons.psychology,
        color: const Color(0xFFEA580C),
        gradientColors: [const Color(0xFFEA580C), const Color(0xFFF97316)],
        promptInstruction: '',
      ),
    ],
    'Timeline & Project': [
      NapkinTemplate(
        id: 'timeline',
        name: 'Timeline',
        description: 'Chronological event sequence with phases and milestones',
        napkinType: 'timeline',
        icon: Icons.schedule,
        color: const Color(0xFF0891B2),
        gradientColors: [const Color(0xFF0891B2), const Color(0xFF06B6D4)],
        promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'gantt',
        name: 'Gantt Chart',
        description:
            'Project timeline with task dependencies and resource allocation',
        napkinType: 'gantt',
        icon: Icons.view_timeline,
        color: const Color(0xFF9333EA),
        gradientColors: [const Color(0xFF9333EA), const Color(0xFFA855F7)],
        promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'journey',
        name: 'User Journey',
        description:
            'User experience mapping with touchpoints and interactions',
        napkinType: 'journey',
        icon: Icons.route,
        color: const Color(0xFFBE185D),
        gradientColors: [const Color(0xFFBE185D), const Color(0xFFDB2777)],
        promptInstruction: '',
      ),
    ],
    'Technical & System': [
      NapkinTemplate(
        id: 'erd',
        name: 'Entity Relationship',
        description:
            'Database schema with entities, attributes, and relationships',
        napkinType: 'erd',
        icon: Icons.storage,
        color: const Color(0xFF059669),
        gradientColors: [const Color(0xFF059669), const Color(0xFF10B981)],
        promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'class',
        name: 'Class Diagram',
        description:
            'Object-oriented design with classes, attributes, and methods',
        napkinType: 'class',
        icon: Icons.class_,
        color: const Color(0xFF7C2D12),
        gradientColors: [const Color(0xFF7C2D12), const Color(0xFF9A3412)],
        promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'network',
        name: 'Network Diagram',
        description: 'System connectivity, topology, and network architecture',
        napkinType: 'network',
        icon: Icons.hub,
        color: const Color(0xFF1E40AF),
        gradientColors: [const Color(0xFF1E40AF), const Color(0xFF2563EB)],
        promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'architecture',
        name: 'Architecture',
        description:
            'System architecture with components, layers, and relationships',
        napkinType: 'architecture',
        icon: Icons.architecture,
        color: const Color(0xFF6D28D9),
        gradientColors: [const Color(0xFF6D28D9), const Color(0xFF7C3AED)],
        promptInstruction: '',
      ),
    ],
  };

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeDiagramTemplates();
    // Defer backend health check to avoid blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBackendHealth();
    });
  }

  void _initializeDiagramTemplates() {
    // Initialize lazily to reduce startup time
    if (_diagramTemplates.isEmpty) {
      _diagramTemplates = [];
      for (final templates in _categorizedTemplates.values) {
        _diagramTemplates.addAll(templates);
      }
    }

    if (_diagramTemplates.isNotEmpty && _selectedDiagramTemplate == null) {
      _selectedDiagramTemplate = _diagramTemplates.first;
      _selectedDiagramType = _selectedDiagramTemplate!.napkinType;
    }
  }

  void _setupAnimations() {
    // Use shorter durations and simpler animations to reduce load
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.fastOutSlowIn,
      ),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * 3.14159).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.linear),
    );

    // Start animations after first frame to improve initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animationController.forward();
      _pulseController.repeat(reverse: true);
    });
  }

  Future<void> _checkBackendHealth() async {
    try {
      final isHealthy = await _apiService.checkBackendHealth();
      setState(() {
        _isBackendHealthy = isHealthy;
      });

      if (isHealthy) {
        ErrorHandler.showSuccessSnackBar(
          context,
          '✅ Backend connected successfully!',
        );
      } else {
        ErrorHandler.showWarningSnackBar(
          context,
          'Backend not available. Please start the Python server.',
        );
      }
    } catch (e) {
      setState(() {
        _isBackendHealthy = false;
      });
      ErrorHandler.showWarningSnackBar(
        context,
        'Backend not available. Please start the Python server.',
      );
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  Future<void> _generateDiagram() async {
    if (_inputController.text.isEmpty) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Please enter a description for your diagram',
      );
      return;
    }

    if (_selectedDiagramTemplate == null) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Please select a diagram template',
      );
      return;
    }

    if (!_isBackendHealthy) {
      ErrorHandler.showErrorSnackBar(
        context,
        'Backend not available. Please start the Python server first.',
        onRetry: _checkBackendHealth,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _loadingController.repeat();

    try {
      // Double-check backend health before generating
      if (!_isBackendHealthy) {
        print('Backend not healthy, rechecking...');
        await _checkBackendHealth();
        if (!_isBackendHealthy) {
          throw Exception('Backend server is not available');
        }
      }

      // Generate 4 variations using the new endpoint
      final response = await _apiService.generateDiagramVariations(
        userInput: _inputController.text,
        diagramType: _selectedDiagramType,
      );
      
      final variations = response['variations'] as List<dynamic>;
      
      // Ensure we have exactly 4 variations
      if (variations.length < 4) {
        throw Exception('Expected 4 diagram variations, but received ${variations.length}');
      }
      
      // Convert to GeneratedContent objects with enhanced naming
      final List<GeneratedContent> diagramVariations = variations.take(4).map((variation) {
        final variationStyle = variation['variation'] ?? 'standard';
        
        return GeneratedContent(
          templateName: _getVariationDisplayName(variationStyle, _selectedDiagramTemplate!.name),
          content: variation['content'] ?? '',
          isDiagram: true,
          timestamp: DateTime.parse(
            variation['timestamp'] ?? DateTime.now().toIso8601String(),
          ),
          originalPrompt: _inputController.text,
          diagramType: variationStyle,
        );
      }).toList();

      print('About to update state with ${diagramVariations.length} variations');
      setState(() {
        // Remove any existing diagrams of the same type
        _generatedContents.removeWhere(
          (content) => content.isDiagram && content.templateName.contains(_selectedDiagramTemplate!.name),
        );

        // Add all the new variations
        _generatedContents.addAll(diagramVariations);
        
        // Update variation state
        _currentVariations = diagramVariations;
        _selectedVariation = diagramVariations.isNotEmpty ? diagramVariations.first : null;
        _hoveredVariation = null;
      });
      print('State updated successfully. Generated contents: ${_generatedContents.length}, Current variations: ${_currentVariations.length}');

      ErrorHandler.showSuccessSnackBar(
        context,
        '🎉 Generated ${diagramVariations.length} ${_selectedDiagramTemplate!.name} variations!',
      );
      print('Success snackbar shown');
    } catch (e) {
      print('Error in _generateDiagram: $e');
      print('Backend healthy: $_isBackendHealthy');
      print('Current base URL: ${ApiService.baseUrl}');
      
      final friendlyMessage = ErrorHandler.getFriendlyErrorMessage(
        e.toString(),
      );
      setState(() => _errorMessage = friendlyMessage);
      ErrorHandler.showErrorSnackBar(
        context,
        friendlyMessage,
        onRetry: _generateDiagram,
      );
    } finally {
      print('Entering finally block. Setting _isLoading to false');
      setState(() => _isLoading = false);
      _loadingController.stop();
      print('Finally block completed. _isLoading is now: $_isLoading');
    }
  }

  // Helper method to get variation display name
  String _getVariationDisplayName(String variationStyle, String diagramName) {
    switch (variationStyle.toLowerCase()) {
      case 'standard':
        return '$diagramName - Standard';
      case 'detailed':
        return '$diagramName - Detailed';
      case 'compact':
        return '$diagramName - Compact';
      case 'enhanced':
        return '$diagramName - Enhanced';
      default:
        return '$diagramName - $variationStyle';
    }
  }

  void _onDiagramTemplateSelected(NapkinTemplate? template) {
    if (template != null) {
      setState(() {
        _selectedDiagramTemplate = template;
        _selectedDiagramType = template.napkinType;
      });
      // Provide haptic feedback
      HapticFeedback.selectionClick();
    }
  }

  // Handle variation hover
  void _onVariationHover(GeneratedContent? variation) {
    setState(() {
      _hoveredVariation = variation;
    });
  }

  // Handle variation selection
  void _onVariationSelected(GeneratedContent variation) {
    print('Variation selected: ${variation.templateName}');
    setState(() {
      _selectedVariation = variation;
      _hoveredVariation = null; // Clear hover when selecting
    });
    print('Selected variation updated: ${_selectedVariation?.templateName}');
    // Provide haptic feedback
    HapticFeedback.selectionClick();
  }

  // Updated method to handle the download and authentication check
  Future<void> _handleDownload(String svgContent, String diagramName) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // User is not logged in, navigate to the LoginScreen
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder:
                (context) =>
                    const LoginScreen(), // Using your LoginScreen widget
          ),
        );
      }
      return;
    }

    // User is logged in, proceed with the download
    try {
      final fileName =
          '${diagramName}_${DateTime.now().millisecondsSinceEpoch}.svg';
      final message = await saveSvgToDownloads(svgContent, fileName);

      if (mounted) {
        ErrorHandler.showSuccessSnackBar(context, message);
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showErrorSnackBar(context, e.toString());
      }
    }
  }

  Widget _buildEnhancedHeader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.indigo.shade50,
                Colors.purple.shade50,
                Colors.blue.shade50,
              ],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.indigo.shade600,
                                Colors.purple.shade600,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.indigo.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            color: Colors.white,
                            size: isSmallScreen ? 24 : 32,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(width: isSmallScreen ? 12 : 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ShaderMask(
                          shaderCallback:
                              (bounds) => LinearGradient(
                                colors: [
                                  Colors.indigo.shade600,
                                  Colors.purple.shade600,
                                ],
                              ).createShader(bounds),
                          child: Text(
                            'AI Diagram Generator',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 20 : 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color:
                                    _isBackendHealthy
                                        ? Colors.green
                                        : Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Create professional diagrams with AI assistance',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 12 : 16,
                                  color: Colors.grey.shade700,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (!isSmallScreen) const SizedBox(height: 20),
              if (!isSmallScreen)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatCard('12', 'Diagram Types', Icons.dashboard),
                    _buildStatCard('AI', 'Powered', Icons.psychology),
                    _buildStatCard('Quick', 'Generation', Icons.bolt),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.indigo, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedInputCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        return Card(
          margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
          elevation: 12,
          shadowColor: Colors.indigo.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Colors.indigo.shade50.withOpacity(0.3)],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Input section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo.shade50, Colors.purple.shade50],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.indigo, Colors.purple],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Describe Your Concept',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 14 : 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.indigo,
                                ),
                              ),
                              Text(
                                'Enter your idea and select a diagram type',
                                style: TextStyle(
                                  fontSize: isSmallScreen ? 10 : 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 16 : 20),

                  // Enhanced input field
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _inputController,
                      maxLines: isSmallScreen ? 3 : 4,
                      style: const TextStyle(fontSize: 16),
                      decoration: InputDecoration(
                        hintText:
                            '💡 Describe your concept here...\n\nExamples:\n• "E-commerce checkout process"\n• "Software development lifecycle"\n• "Customer support workflow"',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: isSmallScreen ? 12 : 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Colors.indigo,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        contentPadding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      ),
                      onChanged: (value) => setState(() {}),
                    ),
                  ),

                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Enhanced diagram type selection with dropdown
                  _buildDiagramTypeDropdown(),

                  SizedBox(height: isSmallScreen ? 20 : 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(child: _buildGenerateButton()),
                      const SizedBox(width: 12),
                      _buildClearButton(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDiagramTypeDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.design_services,
                  color: Colors.indigo,
                  size: 20,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Diagram Type',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    Text(
                      'Choose the most suitable visualization for your concept',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300, width: 1),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<NapkinTemplate>(
              isExpanded: true,
              value: _selectedDiagramTemplate,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.indigo),
              iconSize: 24,
              elevation: 16,
              style: const TextStyle(color: Colors.indigo, fontSize: 16),
              onChanged: _onDiagramTemplateSelected,
              items:
                  _diagramTemplates.map<DropdownMenuItem<NapkinTemplate>>((
                    template,
                  ) {
                    return DropdownMenuItem<NapkinTemplate>(
                      value: template,
                      child: Row(
                        children: [
                          Icon(template.icon, color: template.color),
                          const SizedBox(width: 16),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.5,
                                child: Text(
                                  template.description,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenerateButton() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withOpacity(0.3),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: (_isLoading || !_isBackendHealthy) ? null : _generateDiagram,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon:
            _isLoading
                ? AnimatedBuilder(
                  animation: _rotationAnimation,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _rotationAnimation.value,
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 24,
                      ),
                    );
                  },
                )
                : const Icon(Icons.auto_awesome, color: Colors.white, size: 24),
        label: Text(
          _isLoading ? 'Generating...' : 'Generate Diagram',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildClearButton() {
    return OutlinedButton.icon(
      onPressed: () {
        setState(() {
          _inputController.clear();
          _generatedContents.clear();
          _errorMessage = null;
          _currentVariations.clear();
          _selectedVariation = null;
          _hoveredVariation = null;
        });
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        side: BorderSide(color: Colors.grey.shade400),
        foregroundColor: Colors.grey.shade700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(Icons.clear_all, size: 20, color: Colors.grey.shade700),
      label: Text(
        'Clear',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.grey.shade700,
        ),
      ),
    );
  }

  Widget _buildContentList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.indigo.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Colors.indigo,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Generated Diagrams',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    Text(
                      'Created ${_generatedContents.length} professional diagrams',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Content items
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _generatedContents.length,
          itemBuilder: (context, index) {
            final content = _generatedContents[index];
            final template = _diagramTemplates.firstWhere(
              (t) => t.name == content.templateName,
              orElse: () => _diagramTemplates.first,
            );

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Card(
                elevation: 8,
                shadowColor: template.color.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Enhanced Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: template.gradientColors,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              template.icon,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  content.templateName,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  template.description,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'AI Generated',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: SimpleDiagramViewer(
                        generatedContent: content,
                        template: template,
                        originalPrompt:
                            content.originalPrompt ?? _inputController.text,
                        onDiagramUpdated: (updatedContent) {
                          setState(() {
                            _generatedContents[index] = updatedContent;
                          });
                        },
                        svgContent: null,
                      ),
                    ),

                    // Footer with actions
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 14,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Generated ${_formatTimestamp(content.timestamp)}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(
                                ClipboardData(text: content.content),
                              );
                              ErrorHandler.showSuccessSnackBar(
                                context,
                                'Diagram copied to clipboard',
                              );
                            },
                            tooltip: 'Copy SVG',
                            color: Colors.grey.shade700,
                          ),
                          IconButton(
                            icon: const Icon(Icons.download, size: 18),
                            onPressed:
                                () => _handleDownload(
                                  content.content,
                                  content.templateName,
                                ),
                            tooltip: 'Download',
                            color: Colors.grey.shade700,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 40),
          margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _rotationAnimation,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.indigo, Colors.purple],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.indigo.withOpacity(0.3),
                            blurRadius: 15,
                            spreadRadius: 3,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: isSmallScreen ? 32 : 40,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
              ShaderMask(
                shaderCallback:
                    (bounds) => LinearGradient(
                      colors: [Colors.indigo, Colors.purple],
                    ).createShader(bounds),
                child: Text(
                  'Creating Your Professional Diagram',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 18 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isSmallScreen ? 6 : 8),
              Text(
                'Our AI is crafting a high-quality ${_selectedDiagramTemplate?.name ?? 'diagram'} for you.\nThis may take up to 30 seconds.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 16,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),

              // Enhanced progress indicator
              SizedBox(
                width: isSmallScreen ? 150 : 200,
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.indigo,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, _) {
                        final steps = [
                          'Analyzing your input...',
                          'Generating diagram structure...',
                          'Applying professional styling...',
                          'Finalizing your diagram...',
                        ];
                        final currentStep =
                            (_pulseController.value * 4).floor() % 4;
                        return Text(
                          steps[currentStep],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        return Container(
          padding: EdgeInsets.all(isSmallScreen ? 20 : 40),
          margin: EdgeInsets.all(isSmallScreen ? 12 : 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                spreadRadius: 0,
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.grey.shade100, Colors.grey.shade200],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.design_services_outlined,
                        size: isSmallScreen ? 40 : 60,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: isSmallScreen ? 16 : 24),
              Text(
                'Ready to Create Professional Diagrams',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isSmallScreen ? 8 : 12),
              Text(
                'Enter your concept above and select a diagram type\nto generate professional visualizations with AI',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isSmallScreen ? 12 : 16,
                  color: Colors.grey.shade600,
                ),
              ),

              if (!_isBackendHealthy) ...[
                SizedBox(height: isSmallScreen ? 16 : 24),
                Container(
                  padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    border: Border.all(color: Colors.orange.shade200, width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.orange.shade600,
                        size: isSmallScreen ? 24 : 32,
                      ),
                      SizedBox(height: isSmallScreen ? 6 : 8),
                      Text(
                        'Backend Server Required',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                          fontSize: isSmallScreen ? 14 : 16,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Text(
                        'Please run: python enhanced_original_backend.py',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 12 : 14,
                          color: Colors.orange.shade600,
                          fontFamily: 'monospace',
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 8 : 12),
                      OutlinedButton.icon(
                        onPressed: _checkBackendHealth,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Check Connection'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.orange.shade700,
                          side: BorderSide(color: Colors.orange.shade400),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hr ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade50,
              Colors.purple.shade50,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Enhanced Header
                SliverToBoxAdapter(child: _buildEnhancedHeader()),

                // Input Card
                SliverToBoxAdapter(child: _buildEnhancedInputCard()),

                // Error Message
                if (_errorMessage != null)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(
                          color: Colors.red.shade200,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade600),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Content Area
                SliverToBoxAdapter(
                  child: Builder(
                    builder: (context) {
                      print('Building main content area - isLoading: $_isLoading, generatedContents: ${_generatedContents.length}, currentVariations: ${_currentVariations.length}');
                      
                      if (_isLoading && _generatedContents.isEmpty) {
                        print('Showing loading state');
                        return _buildLoadingState();
                      } else if (_generatedContents.isEmpty) {
                        print('Showing empty state');
                        return _buildEmptyState();
                      } else if (_currentVariations.isNotEmpty) {
                        print('Showing variations layout with ${_currentVariations.length} variations');
                        return _buildVariationsLayout();
                      } else {
                        print('Showing content list');
                        return _buildContentList();
                      }
                    },
                  ),
                ),

                // Bottom padding
                const SliverToBoxAdapter(child: SizedBox(height: 30)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Build variations layout with left sidebar
  Widget _buildVariationsLayout() {
    return Container(
      margin: const EdgeInsets.all(16),
      height: 700, // Increased height for better visibility
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left sidebar with variation thumbnails
          Container(
            width: 300, // Slightly wider for better visibility
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sidebar header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.indigo.shade600, Colors.purple.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.dashboard, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'Diagram Variations',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Variations list
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _currentVariations.length,
                    itemBuilder: (context, index) {
                      final variation = _currentVariations[index];
                      final isSelected = _selectedVariation == variation;
                      final isHovered = _hoveredVariation == variation;
                      
                      return MouseRegion(
                        onEnter: (_) {
                          _onVariationHover(variation);
                        },
                        onExit: (_) {
                          _onVariationHover(null);
                        },
                        child: GestureDetector(
                          onTap: () {
                            _onVariationSelected(variation);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.indigo.shade50 : Colors.grey.shade50,
                              border: Border.all(
                                color: isSelected 
                                    ? Colors.indigo.shade300 
                                    : isHovered 
                                        ? Colors.indigo.shade200 
                                        : Colors.grey.shade300,
                                width: isSelected ? 2 : 1,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: isHovered ? [
                                BoxShadow(
                                  color: Colors.indigo.withOpacity(0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ] : null,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Variation thumbnail
                                Container(
                                  height: 140, // Increased height for better preview
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
                                      template: _diagramTemplates.firstWhere(
                                        (t) => t.name == variation.templateName,
                                        orElse: () => _diagramTemplates.first,
                                      ),
                                      onDiagramUpdated: (updatedContent) {
                                        setState(() {
                                          final index = _currentVariations.indexOf(variation);
                                          if (index != -1) {
                                            _currentVariations[index] = updatedContent;
                                          }
                                        });
                                      },
                                      originalPrompt: variation.originalPrompt ?? '',
                                      svgContent: variation.content,
                                      isPreview: true,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                
                                // Variation info
                                Text(
                                  variation.diagramType?.split('_').map((word) => 
                                    word[0].toUpperCase() + word.substring(1)
                                  ).join(' ') ?? 'Standard',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.indigo.shade700 : Colors.grey.shade700,
                                  ),
                                ),
                                Text(
                                  'Variation ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                // Add variation style info
                                Text(
                                  _getVariationStyleName(variation),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade500,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                                // Add current display indicator
                                if (isSelected || isHovered)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.indigo.shade100 : Colors.indigo.shade50,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isSelected ? Colors.indigo.shade300 : Colors.indigo.shade200,
                                        width: 1,
                                      ),
                                    ),
                                    child: Text(
                                      isSelected ? 'Currently Displayed' : 'Hovering',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: isSelected ? Colors.indigo.shade700 : Colors.indigo.shade600,
                                        fontWeight: FontWeight.w500,
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
          ),
          
          const SizedBox(width: 16),
          
          // Main content area
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Builder(
                builder: (context) {
                  print('Building main content area - Selected: ${_selectedVariation?.templateName}, Hovered: ${_hoveredVariation?.templateName}');
                  return _selectedVariation != null || _hoveredVariation != null
                      ? _buildVariationDetails(_hoveredVariation ?? _selectedVariation!)
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.touch_app,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Select a variation to view details',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Hover over variations to preview',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper method to get variation style name
  String _getVariationStyleName(GeneratedContent variation) {
    if (variation.diagramType?.contains('standard') == true) return 'Standard Style';
    if (variation.diagramType?.contains('detailed') == true) return 'Detailed Style';
    if (variation.diagramType?.contains('compact') == true) return 'Compact Style';
    if (variation.diagramType?.contains('enhanced') == true) return 'Enhanced Style';
    return 'Custom Style';
  }

  // Build variation details view
  Widget _buildVariationDetails(GeneratedContent variation) {
    final template = _diagramTemplates.firstWhere(
      (t) => t.name == variation.templateName,
      orElse: () => _diagramTemplates.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: template.gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  template.icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getVariationDisplayName(variation.diagramType ?? 'standard', template.name),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Based on: "${variation.originalPrompt ?? 'No prompt'}"',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getVariationStyleName(variation),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Action buttons
              Row(
                children: [
                  IconButton(
                    onPressed: () => _handleDownload(variation.content, variation.templateName),
                    icon: const Icon(Icons.download, color: Colors.white),
                    tooltip: 'Download SVG',
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SimpleDiagramViewer(
                            generatedContent: variation,
                            template: template,
                            onDiagramUpdated: (updatedContent) {
                              setState(() {
                                final index = _currentVariations.indexOf(variation);
                                if (index != -1) {
                                  _currentVariations[index] = updatedContent;
                                  if (_selectedVariation == variation) {
                                    _selectedVariation = updatedContent;
                                  }
                                }
                              });
                            },
                            originalPrompt: variation.originalPrompt ?? '',
                            svgContent: variation.content,
                            isPreview: false,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit, color: Colors.white),
                    tooltip: 'Edit Diagram',
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Diagram display
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: SimpleDiagramViewer(
                generatedContent: variation,
                template: template,
                onDiagramUpdated: (updatedContent) {
                  setState(() {
                    final index = _currentVariations.indexOf(variation);
                    if (index != -1) {
                      _currentVariations[index] = updatedContent;
                      if (_selectedVariation == variation) {
                        _selectedVariation = updatedContent;
                      }
                    }
                  });
                },
                originalPrompt: variation.originalPrompt ?? '',
                svgContent: variation.content,
                isPreview: false,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
