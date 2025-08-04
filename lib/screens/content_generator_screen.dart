import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/generated_content.dart';
import '../models/napkin_template.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../widgets/simple_diagram_viewer.dart';

class ContentGeneratorScreen extends StatefulWidget {
  const ContentGeneratorScreen({super.key});

  @override
  State<ContentGeneratorScreen> createState() =>
      _ContentGeneratorScreenState();
}

class _ContentGeneratorScreenState
    extends State<ContentGeneratorScreen>
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
        gradientColors: [const Color(0xFF2563EB), const Color(0xFF3B82F6)], promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'sequence',
        name: 'Sequence Diagram',
        description:
            'Actor interactions and message flow between system components',
        napkinType: 'sequence',
        icon: Icons.timeline,
        color: const Color(0xFF059669),
        gradientColors: [const Color(0xFF059669), const Color(0xFF10B981)], promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'state',
        name: 'State Diagram',
        description:
            'System states, transitions, and state machine visualization',
        napkinType: 'state',
        icon: Icons.radio_button_checked,
        color: const Color(0xFFDC2626),
        gradientColors: [const Color(0xFFDC2626), const Color(0xFFEF4444)], promptInstruction: '',
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
        gradientColors: [const Color(0xFF7C3AED), const Color(0xFF8B5CF6)], promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'mindmap',
        name: 'Mind Map',
        description:
            'Hierarchical concept visualization with central topic and branches',
        napkinType: 'mind map',
        icon: Icons.psychology,
        color: const Color(0xFFEA580C),
        gradientColors: [const Color(0xFFEA580C), const Color(0xFFF97316)], promptInstruction: '',
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
        gradientColors: [const Color(0xFF0891B2), const Color(0xFF06B6D4)], promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'gantt',
        name: 'Gantt Chart',
        description:
            'Project timeline with task dependencies and resource allocation',
        napkinType: 'gantt',
        icon: Icons.view_timeline,
        color: const Color(0xFF9333EA),
        gradientColors: [const Color(0xFF9333EA), const Color(0xFFA855F7)], promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'journey',
        name: 'User Journey',
        description:
            'User experience mapping with touchpoints and interactions',
        napkinType: 'journey',
        icon: Icons.route,
        color: const Color(0xFFBE185D),
        gradientColors: [const Color(0xFFBE185D), const Color(0xFFDB2777)], promptInstruction: '',
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
        gradientColors: [const Color(0xFF059669), const Color(0xFF10B981)], promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'class',
        name: 'Class Diagram',
        description:
            'Object-oriented design with classes, attributes, and methods',
        napkinType: 'class',
        icon: Icons.class_,
        color: const Color(0xFF7C2D12),
        gradientColors: [const Color(0xFF7C2D12), const Color(0xFF9A3412)], promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'network',
        name: 'Network Diagram',
        description: 'System connectivity, topology, and network architecture',
        napkinType: 'network',
        icon: Icons.hub,
        color: const Color(0xFF1E40AF),
        gradientColors: [const Color(0xFF1E40AF), const Color(0xFF2563EB)], promptInstruction: '',
      ),
      NapkinTemplate(
        id: 'architecture',
        name: 'Architecture',
        description:
            'System architecture with components, layers, and relationships',
        napkinType: 'architecture',
        icon: Icons.architecture,
        color: const Color(0xFF6D28D9),
        gradientColors: [const Color(0xFF6D28D9), const Color(0xFF7C3AED)], promptInstruction: '',
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
      CurvedAnimation(parent: _animationController, curve: Curves.fastOutSlowIn),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 2 * math.pi).animate(
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
        ErrorHandler.showSuccessSnackBar(context, '✅ Backend connected successfully!');
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
      ErrorHandler.showErrorSnackBar(context, 'Please select a diagram template');
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
      // Create a copy of the template with the correct napkinType
      final templateWithType = NapkinTemplate(
        id: _selectedDiagramTemplate!.id,
        name: _selectedDiagramTemplate!.name,
        description: _selectedDiagramTemplate!.description,
        napkinType: _selectedDiagramType, // Use the selected diagram type
        icon: _selectedDiagramTemplate!.icon,
        color: _selectedDiagramTemplate!.color,
        gradientColors: _selectedDiagramTemplate!.gradientColors, promptInstruction: '',
      );

      final diagram = await _apiService.generateNapkinDiagram(
        userInput: _inputController.text,
        napkinTemplate: templateWithType,
      );

      setState(() {
        // Remove any existing diagram of the same type
        _generatedContents.removeWhere(
          (content) =>
              content.isDiagram && content.templateName == diagram.templateName,
        );

        // Add the new diagram
        _generatedContents.add(diagram);
      });

      ErrorHandler.showSuccessSnackBar(
        context,
        '🎉 ${_selectedDiagramTemplate!.name} generated successfully!',
      );
    } catch (e) {
      final friendlyMessage = ErrorHandler.getFriendlyErrorMessage(e.toString());
      setState(() => _errorMessage = friendlyMessage);
      ErrorHandler.showErrorSnackBar(
        context,
        friendlyMessage,
        onRetry: _generateDiagram,
      );
    } finally {
      setState(() => _isLoading = false);
      _loadingController.stop();
    }
  }

  void _onDiagramTemplateSelected(NapkinTemplate template) {
    setState(() {
      _selectedDiagramTemplate = template;
      _selectedDiagramType = template.napkinType;
    });

    // Provide haptic feedback
    HapticFeedback.selectionClick();
  }

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
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
                      child: const Icon(
                        Icons.auto_awesome,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
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
                      child: const Text(
                        'AI Diagram Generator',
                        style: TextStyle(
                          fontSize: 28,
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
                            color: _isBackendHealthy ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Create professional diagrams with AI assistance',
                            style: TextStyle(
                              fontSize: 16,
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
          const SizedBox(height: 20),

          // Enhanced stats
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard('12', 'Diagram Types', Icons.dashboard),
              _buildStatCard('AI', 'Powered', Icons.psychology),
              _buildStatCard('Pro', 'Quality', Icons.star),
            ],
          ),
        ],
      ),
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
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 12,
      shadowColor: Colors.indigo.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
          padding: const EdgeInsets.all(24.0),
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
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Describe Your Concept',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.indigo,
                            ),
                          ),
                          Text(
                            'Enter your idea and select a diagram type',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

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
                  maxLines: 4,
                  style: const TextStyle(fontSize: 16),
                  decoration: InputDecoration(
                    hintText:
                        '💡 Describe your concept here...\n\nExamples:\n• "E-commerce checkout process"\n• "Software development lifecycle"\n• "Customer support workflow"',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
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
                    contentPadding: const EdgeInsets.all(20),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
              ),

              const SizedBox(height: 24),

              // Enhanced diagram type selection
              _buildCategorizedDiagramSelection(),

              const SizedBox(height: 24),

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
  }

  Widget _buildCategorizedDiagramSelection() {
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
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
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

        // Categorized diagram templates
        ..._categorizedTemplates.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    entry.value.map((template) {
                      final isSelected =
                          _selectedDiagramTemplate?.id == template.id;
                      return InkWell(
                        onTap: () => _onDiagramTemplateSelected(template),
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            gradient:
                                isSelected
                                    ? LinearGradient(
                                      colors: template.gradientColors,
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                    : null,
                            color: isSelected ? null : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? template.color
                                      : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow:
                                isSelected
                                    ? [
                                      BoxShadow(
                                        color: template.color.withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                    : null,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                template.icon,
                                color:
                                    isSelected ? Colors.white : template.color,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    template.name,
                                    style: TextStyle(
                                      color:
                                          isSelected
                                              ? Colors.white
                                              : Colors.grey.shade800,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 140,
                                    child: Text(
                                      template.description,
                                      style: TextStyle(
                                        color:
                                            isSelected
                                                ? Colors.white.withOpacity(0.9)
                                                : Colors.grey.shade600,
                                        fontSize: 10,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
              const SizedBox(height: 16),
            ],
          );
        }).toList(),

        // Selected diagram info
        if (_selectedDiagramTemplate != null) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _selectedDiagramTemplate!.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedDiagramTemplate!.color.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _selectedDiagramTemplate!.icon,
                  color: _selectedDiagramTemplate!.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected: ${_selectedDiagramTemplate!.name}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _selectedDiagramTemplate!.color,
                        ),
                      ),
                      Text(
                        _selectedDiagramTemplate!.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
                        originalPrompt: content.originalPrompt ?? _inputController.text,
                        onDiagramUpdated: (updatedContent) {
                          setState(() {
                            _generatedContents[index] = updatedContent;
                          });
                        },
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
                            onPressed: () {
                              ErrorHandler.showSuccessSnackBar(
                                context,
                                'Download feature coming soon',
                              );
                            },
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
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.all(16),
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
                  padding: const EdgeInsets.all(20),
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
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          ShaderMask(
            shaderCallback:
                (bounds) => LinearGradient(
                  colors: [Colors.indigo, Colors.purple],
                ).createShader(bounds),
            child: const Text(
              'Creating Your Professional Diagram',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Our AI is crafting a high-quality ${_selectedDiagramTemplate?.name ?? 'diagram'} for you.\nThis may take up to 30 seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 24),

          // Enhanced progress indicator
          Container(
            width: 200,
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo),
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
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(40),
      margin: const EdgeInsets.all(16),
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
                  padding: const EdgeInsets.all(24),
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
                    size: 60,
                    color: Colors.grey.shade400,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Ready to Create Professional Diagrams',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your concept above and select a diagram type\nto generate professional visualizations with AI',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),

          if (!_isBackendHealthy) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
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
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Backend Server Required',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Please run: python enhanced_original_backend.py',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.orange.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  child:
                      _isLoading && _generatedContents.isEmpty
                          ? _buildLoadingState()
                          : _generatedContents.isEmpty
                          ? _buildEmptyState()
                          : _buildContentList(),
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
}
