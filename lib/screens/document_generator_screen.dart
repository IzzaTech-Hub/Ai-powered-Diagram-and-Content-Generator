import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:my_flutter_app/constants/document_template.dart';
import '../models/generated_document.dart';
import '../services/api_service.dart';
import '../utils/error_handler.dart';
import '../constants/document_templates.dart';
import '../widgets/document_viewer.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter/foundation.dart';

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

class DocumentGeneratorScreen extends StatefulWidget {
  const DocumentGeneratorScreen({super.key});

  @override
  State<DocumentGeneratorScreen> createState() =>
      _DocumentGeneratorScreenState();
}

class _DocumentGeneratorScreenState extends State<DocumentGeneratorScreen>
    with TickerProviderStateMixin {
  final TextEditingController _inputController = TextEditingController();
  final ApiService _apiService = ApiService();
  DocumentTemplate? _selectedTemplate;
  List<GeneratedDocument> _generatedDocuments = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _isBackendHealthy = false;
  String _selectedDocumentType = 'all';

  late AnimationController _animationController;
  late AnimationController _pulseController;
  late AnimationController _loadingController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    // Defer backend health check to avoid blocking UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkBackendHealth();
    });
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

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
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

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(message, style: const TextStyle(fontSize: 14)),
            ),
          ],
        ),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: Duration(seconds: isError ? 4 : 2),
        margin: const EdgeInsets.all(12),
        elevation: 6,
      ),
    );
  }

  Future<void> _generateDocument() async {
    if (_inputController.text.isEmpty) {
      _showSnackBar(
        'Please enter a description for your document',
        isError: true,
      );
      return;
    }
    if (_selectedTemplate == null) {
      _showSnackBar('Please select a document template', isError: true);
      return;
    }

    if (!_isBackendHealthy) {
      _showSnackBar(
        'Backend not available. Please start the Python server first.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    _loadingController.repeat();

    try {
      final document = await _apiService.generateDocument(
        userInput: _inputController.text,
        documentTemplate: _selectedTemplate!,
      );

      setState(() {
        _generatedDocuments.insert(0, document);
      });
      _showSnackBar('📄 Document generated successfully!', isError: false);
    } catch (e) {
      setState(() => _errorMessage = 'Connection error: $e');
      _showSnackBar(
        '🔌 Connection error. Please check your backend.',
        isError: true,
      );
    } finally {
      setState(() => _isLoading = false);
      _loadingController.stop();
    }
  }

  void _clearAll() {
    setState(() {
      _inputController.clear();
      _selectedTemplate = null;
      _generatedDocuments.clear();
      _errorMessage = null;
    });
  }

  List<DocumentTemplate> _getFilteredTemplates() {
    final allTemplates = DocumentTemplates.getAvailableTemplates();
    if (_selectedDocumentType == 'all') {
      return allTemplates;
    }
    return allTemplates
        .where((template) => template.documentType == _selectedDocumentType)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Generator'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkBackendHealth,
            tooltip: 'Check backend connection',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue.shade50,
              Colors.purple.shade50,
              Colors.indigo.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 600;
              final horizontalPadding = isSmallScreen ? 12.0 : 24.0;

              return FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: _buildHeader(isSmallScreen, horizontalPadding),
                    ),

                    // Input Section
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      sliver: SliverToBoxAdapter(
                        child: _buildInputSection(isSmallScreen),
                      ),
                    ),

                    // Error Message
                    if (_errorMessage != null)
                      SliverPadding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                        ),
                        sliver: SliverToBoxAdapter(child: _buildErrorMessage()),
                      ),

                    // Content Area
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: horizontalPadding,
                      ),
                      sliver: SliverToBoxAdapter(
                        child:
                            _isLoading && _generatedDocuments.isEmpty
                                ? _buildLoadingState(isSmallScreen)
                                : _generatedDocuments.isEmpty
                                ? _buildEmptyState(isSmallScreen)
                                : _buildDocumentsList(isSmallScreen),
                      ),
                    ),

                    // Bottom padding
                    const SliverToBoxAdapter(child: SizedBox(height: 30)),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isSmallScreen, double horizontalPadding) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: isSmallScreen ? 16.0 : 20.0,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.5),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                            Colors.blue.shade600,
                            Colors.purple.shade600,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.description,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShaderMask(
                    shaderCallback:
                        (bounds) => LinearGradient(
                          colors: [
                            Colors.blue.shade600,
                            Colors.purple.shade600,
                          ],
                        ).createShader(bounds),
                    child: const Text(
                      'Document Generator',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                      Text(
                        'Create professional documents with AI',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Stats
          Wrap(
            alignment: WrapAlignment.spaceEvenly,
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildStatCard(
                '10+',
                'Templates',
                Icons.library_books,
                isSmallScreen,
              ),
              _buildStatCard('AI', 'Powered', Icons.psychology, isSmallScreen),
              _buildStatCard('Pro', 'Quality', Icons.star, isSmallScreen),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String value,
    String label,
    IconData icon,
    bool isSmallScreen,
  ) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      constraints: BoxConstraints(minWidth: isSmallScreen ? 80 : 100),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: Colors.blue,
              size: isSmallScreen ? 20 : 24,
            ),
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: isSmallScreen ? 10 : 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(bool isSmallScreen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16, top: 8),
      elevation: 12,
      shadowColor: Colors.blue.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue.shade50, Colors.purple.shade50],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.purple.shade600],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.edit_document,
                      color: Colors.white,
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Document Details',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade800,
                          ),
                        ),
                        Text(
                          'Describe your document requirements',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 12 : 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // Input Field
            TextField(
              controller: _inputController,
              maxLines: isSmallScreen ? 4 : 5,
              style: TextStyle(fontSize: isSmallScreen ? 14 : 16),
              decoration: InputDecoration(
                hintText:
                    '📄 Describe the document you need...\n\nExamples:\n• "Business plan for a sustainable coffee shop"\n• "Technical specification for mobile app"\n• "Marketing strategy for new product launch"',
                hintStyle: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: isSmallScreen ? 12 : 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.blue, width: 2),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                contentPadding: EdgeInsets.all(isSmallScreen ? 16 : 20),
              ),
            ),

            SizedBox(height: isSmallScreen ? 16 : 20),

            // Document Type Filter
            Row(
              children: [
                Icon(Icons.filter_list, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Document Type:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButton<String>(
                    value: _selectedDocumentType,
                    isExpanded: true,
                    underline: Container(),
                    items: [
                      const DropdownMenuItem(
                        value: 'all',
                        child: Text('All Types'),
                      ),
                      ...DocumentTemplates.getDocumentTypes().map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.toUpperCase()),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedDocumentType = value!;
                        _selectedTemplate = null; // Reset selection
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Template Selection
            Text(
              'Choose Document Template',
              style: TextStyle(
                fontSize: isSmallScreen ? 16 : 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade800,
              ),
            ),
            const SizedBox(height: 12),

            // Template Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isSmallScreen ? 1 : 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: isSmallScreen ? 4.0 : 3.5,
              ),
              itemCount: _getFilteredTemplates().length,
              itemBuilder: (context, index) {
                final template = _getFilteredTemplates()[index];
                final isSelected = _selectedTemplate?.id == template.id;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTemplate = isSelected ? null : template;
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient:
                          isSelected
                              ? LinearGradient(colors: template.gradientColors)
                              : LinearGradient(
                                colors: [Colors.white, Colors.grey.shade50],
                              ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected ? template.color : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              isSelected
                                  ? template.color.withOpacity(0.3)
                                  : Colors.black.withOpacity(0.05),
                          blurRadius: isSelected ? 8 : 3,
                          spreadRadius: isSelected ? 1 : 0,
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? Colors.white.withOpacity(0.2)
                                      : template.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              template.icon,
                              color: isSelected ? Colors.white : template.color,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  template.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color:
                                        isSelected
                                            ? Colors.white
                                            : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  template.description,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color:
                                        isSelected
                                            ? Colors.white.withOpacity(0.9)
                                            : Colors.grey.shade600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),

            SizedBox(height: isSmallScreen ? 20 : 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed:
                        (_isLoading || !_isBackendHealthy)
                            ? null
                            : _generateDocument,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: isSmallScreen ? 14 : 16,
                      ),
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
                                  ),
                                );
                              },
                            )
                            : const Icon(Icons.description),
                    label: Text(
                      _isLoading ? 'Generating...' : 'Generate Document',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                OutlinedButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      vertical: isSmallScreen ? 14 : 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200, width: 2),
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
    );
  }

  Widget _buildLoadingState(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 40),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                      colors: [Colors.blue.shade600, Colors.purple.shade600],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.description,
                    color: Colors.white,
                    size: isSmallScreen ? 32 : 40,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          Text(
            'Generating Your Document',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 6 : 8),
          Text(
            'Our AI is crafting a professional document for you.\nThis may take up to 60 seconds.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 20 : 40),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
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
                scale: _pulseAnimation.value * 0.9,
                child: Container(
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey.shade100, Colors.grey.shade200],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.description_outlined,
                    size: isSmallScreen ? 60 : 80,
                    color: Colors.grey.shade400,
                  ),
                ),
              );
            },
          ),
          SizedBox(height: isSmallScreen ? 16 : 24),
          Text(
            'Ready to Create Professional Documents',
            style: TextStyle(
              fontSize: isSmallScreen ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isSmallScreen ? 8 : 12),
          Text(
            'Enter your requirements and select a template\nto generate AI-powered professional documents',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isSmallScreen ? 14 : 16,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsList(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 4, bottom: 16, top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.description,
                  color: Colors.blue,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Generated Documents',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade800,
                      ),
                    ),
                    Text(
                      'Created ${_generatedDocuments.length} documents',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: _clearAll,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('New Document'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  side: const BorderSide(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),

        // Documents list
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _generatedDocuments.length,
          itemBuilder: (context, index) {
            final document = _generatedDocuments[index];
            final template = DocumentTemplates.getAvailableTemplates()
                .firstWhere(
                  (t) => t.name == document.templateName,
                  orElse: () => DocumentTemplates.getAvailableTemplates().first,
                );

            return Container(
              margin: EdgeInsets.only(bottom: isSmallScreen ? 16.0 : 20.0),
              child: Card(
                elevation: 12,
                shadowColor: template.color.withOpacity(0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Container(
                      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: template.gradientColors,
                        ),
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              template.icon,
                              color: Colors.white,
                              size: isSmallScreen ? 20 : 24,
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 12 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  document.templateName,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 16 : 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  template.description,
                                  style: TextStyle(
                                    fontSize: isSmallScreen ? 12 : 14,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 8 : 12,
                              vertical: isSmallScreen ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              document.documentType.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 10 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Content
                    Padding(
                      padding: EdgeInsets.all(isSmallScreen ? 16.0 : 20.0),
                      child: DocumentViewer(
                        content: document.content,
                        documentType: document.documentType,
                      ),
                    ),

                    // ---- START OF NEW DIAGRAM RENDERING CODE ----
                    if (document.associatedDiagram?.svgContent != null &&
                        document.associatedDiagram!.svgContent.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(
                          left: isSmallScreen ? 16.0 : 20.0,
                          right: isSmallScreen ? 16.0 : 20.0,
                          bottom: isSmallScreen ? 16.0 : 20.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Associated Diagram (${document.associatedDiagram!.type.capitalizeFirstOfEachWord()})', // Added .capitalizeFirstOfEachWord() for better display
                              style: TextStyle(
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Container(
                              padding: const EdgeInsets.all(12.0),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12.0),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1),
                                    spreadRadius: 2,
                                    blurRadius: 5,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              // Use SvgPicture.string to render the SVG
                              child: SvgPicture.string(
                                normalizeSvgColors(document.associatedDiagram!.svgContent),
                                fit:
                                    BoxFit.contain, // Adjust how the SVG scales
                                // You might want to make these responsive or
                                // use a Flexible widget if in a row
                                width:
                                    isSmallScreen
                                        ? MediaQuery.of(context).size.width *
                                            0.8
                                        : 600,
                                height: isSmallScreen ? 250 : 400,
                                placeholderBuilder:
                                    (context) => const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                // Optional: errorBuilder for debugging SVG issues
                                errorBuilder: (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) {
                                  return Text(
                                    'Error loading diagram: ${error.toString()}',
                                    style: const TextStyle(color: Colors.red),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    // ---- END OF NEW DIAGRAM RENDERING CODE ----

                    // Footer
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
                            // Ensure timestamp is properly handled as a String or DateTime
                            'Generated ${_formatTimestamp(document.timestamp != null ? DateTime.parse(document.timestamp!) : DateTime.now())}',
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
                                ClipboardData(text: document.content),
                              );
                              _showSnackBar(
                                'Document copied to clipboard',
                                isError: false,
                              );
                            },
                            tooltip: 'Copy to clipboard',
                            color: Colors.grey.shade700,
                          ),
                          IconButton(
                            icon: const Icon(Icons.share, size: 18),
                            onPressed: () {
                              _showSnackBar(
                                'Sharing options opened',
                                isError: false,
                              );
                            },
                            tooltip: 'Share document',
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
}

// Extension to capitalize first letter of each word for better display of diagram type
extension StringExtension on String {
  String capitalizeFirstOfEachWord() {
    if (isEmpty) {
      return '';
    }
    return split(' ')
        .map((word) {
          if (word.isEmpty) {
            return '';
          }
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        })
        .join(' ');
  }
}
