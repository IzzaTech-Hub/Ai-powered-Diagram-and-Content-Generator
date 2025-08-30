import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_flutter_app/constants/document_template.dart';
import 'package:my_flutter_app/models/generated_document.dart';
import '../models/content_template.dart';
import '../models/generated_content.dart';
import '../models/napkin_template.dart';
import '../widgets/mind_map_template_selector.dart';
import 'config_service.dart';

class ApiService {
  // Backend URLs prioritized for production APK distribution
  static final List<String> _possibleUrls = [
    'https://aidiagramgenerator-5sbzj7l4s-uzairhassan375s-projects.vercel.app', // Vercel backend (working!)
    'http://127.0.0.1:5000', // Local backend (fallback)
    'http://10.0.2.2:5000', // Android emulator only
    'http://localhost:5000', // Local development alternative
  ];

  static String _baseUrl = 'https://aidiagramgenerator-5sbzj7l4s-uzairhassan375s-projects.vercel.app'; // Vercel backend (working!)

  // Initialize API service with connection test
  static void initialize() {
    // Get base URL from ConfigService
    _baseUrl = ConfigService().apiUrl;
    
    print('🚀 API Service initialized with endpoint: $_baseUrl');
    print('🔍 Testing connection...');
    
    // Test connection in background
    _testConnectionInBackground();
  }
  
  static void _testConnectionInBackground() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(Duration(seconds: ConfigService().apiTimeout));
          
      if (response.statusCode == 200) {
        final healthData = json.decode(response.body);
        print('✅ Connected to backend successfully');
        print('🤖 AI service status: ${healthData['groq_client']}');
      } else {
        print('⚠️ Backend responded with status: ${response.statusCode}');
        findWorkingBackend();
      }
    } catch (e) {
      print('🔄 Initial connection failed, will try alternatives when needed');
      print('💡 Error: ${e.toString().substring(0, 100)}...');
    }
  }

  // Get the current base URL
  static String get baseUrl => _baseUrl;

  // Update base URL from ConfigService
  static void updateBaseUrl() {
    _baseUrl = ConfigService().apiUrl;
    print('🔄 API Service base URL updated to: $_baseUrl');
  }

  // Find working backend URL with better error handling
  static Future<String?> findWorkingBackend() async {
    print('🔍 Searching for working backend...');
    
    // First try the configured URL from Remote Config
    try {
      final configUrl = ConfigService().apiUrl;
      print('🔗 Trying configured URL: $configUrl');
      final response = await http
          .get(Uri.parse('$configUrl/health'))
          .timeout(Duration(seconds: ConfigService().apiTimeout));

      if (response.statusCode == 200) {
        final healthData = json.decode(response.body);
        print('✅ Found working backend at configured URL: $configUrl');
        print('📊 Server status: ${healthData['status']}');
        print('🤖 AI service: ${healthData['groq_client']}');
        _baseUrl = configUrl;
        return configUrl;
      }
    } catch (e) {
      print('💥 Failed to connect to configured URL: ${e.toString().substring(0, 100)}...');
    }
    
    // Fallback to hardcoded URLs
    for (String url in _possibleUrls) {
      try {
        print('🔗 Trying fallback: $url');
        final response = await http
            .get(Uri.parse('$url/health'))
            .timeout(Duration(seconds: ConfigService().apiTimeout));

        if (response.statusCode == 200) {
          final healthData = json.decode(response.body);
          print('✅ Found working backend at: $url');
          print('📊 Server status: ${healthData['status']}');
          print('🤖 AI service: ${healthData['groq_client']}');
          _baseUrl = url;
          return url;
        } else {
          print('❌ $url returned status: ${response.statusCode}');
        }
      } catch (e) {
        print('💥 Failed to connect to $url: ${e.toString().substring(0, 100)}...');
      }
    }
    
    print('🔴 No working backend found!');
    return null;
  }

  Future<bool> checkBackendHealth() async {
    print('🏥 Checking backend health at: $_baseUrl');
    
    try {
      // First try current URL
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final healthData = json.decode(response.body);
        print('✅ Backend health check successful at $_baseUrl');
        print('📊 Status: ${healthData['status']}');
        print('🤖 AI service: ${healthData['groq_client']}');
        print('⏰ Server time: ${healthData['timestamp']}');
        return true;
      } else {
        print('⚠️ Backend health check returned status: ${response.statusCode}');
        // Try to find working backend
        final workingUrl = await findWorkingBackend();
        return workingUrl != null;
      }
    } catch (e) {
      print('💥 Backend health check failed: ${e.toString()}');
      
      // Provide specific guidance based on error type
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('Failed host lookup') ||
          e.toString().contains('SocketException')) {
        print('🔌 Network connection issue detected');
        print('💡 Trying alternative backends...');
      } else if (e.toString().contains('timeout')) {
        print('⏰ Backend request timed out - server might be overloaded');
        print('💡 Trying alternative backends...');
      } else {
        print('🔧 Unknown connection error: ${e.toString()}');
      }
      
      // Try to find working backend
      final workingUrl = await findWorkingBackend();
      if (workingUrl != null) {
        print('🎯 Successfully switched to alternative backend: $workingUrl');
        return true;
      } else {
        print('🔴 All backends are unreachable');
        return false;
      }
    }
  }

  Future<List<MindMapTemplate>> getMindMapTemplates() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/mind_map_templates'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((item) => MindMapTemplate.fromJson(item)).toList();
      } else {
        throw Exception('Failed to load mind map templates');
      }
    } catch (e) {
      throw Exception('Error fetching mind map templates: $e');
    }
  }

  Future<List<GeneratedContent>> generateContent({
    required String userInput,
    required List<ContentTemplate> selectedTemplates,
    Map<String, String> templateOptions = const {},
  }) async {
    try {
      // Prepare templates with additional options
      final List<Map<String, dynamic>> templatesWithOptions =
          selectedTemplates.map((template) {
            final Map<String, dynamic> templateJson = template.toJson();

            // Add mind map style if this is a mind map template
            if (template.name.toLowerCase().contains('mind map') &&
                templateOptions.containsKey('mindMapStyle')) {
              templateJson['mindMapStyle'] = templateOptions['mindMapStyle'];
            }

            return templateJson;
          }).toList();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/generate_ai_content'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userInput': userInput,
              'selectedTemplates': templatesWithOptions,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData.map((item) {
          // Add the original prompt to each generated content
          final Map<String, dynamic> enrichedItem = Map<String, dynamic>.from(
            item,
          );
          enrichedItem['originalPrompt'] = userInput;
          return GeneratedContent.fromJson(enrichedItem);
        }).toList();
      } else {
        throw Exception('Error from backend: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  // Add these methods to your existing ApiService class

  Future<GeneratedDocument> generateDocument({
    required String userInput,
    required DocumentTemplate documentTemplate,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/generate_document'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userInput': userInput,
              'documentTemplate': documentTemplate.toJson(),
            }),
          )
          .timeout(
            const Duration(seconds: 180),
          ); // Longer timeout for documents

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return GeneratedDocument.fromJson(responseData);
      } else {
        throw Exception('Error from backend: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  Future<List<GeneratedDocument>> generateDocuments({
    required String userInput,
    required List<DocumentTemplate> documentTemplates,
  }) async {
    try {
      final List<Map<String, dynamic>> templatesJson =
          documentTemplates.map((template) => template.toJson()).toList();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/generate_documents'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userInput': userInput,
              'documentTemplates': templatesJson,
            }),
          )
          .timeout(
            const Duration(seconds: 300),
          ); // Even longer for multiple documents

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData
            .map((item) => GeneratedDocument.fromJson(item))
            .toList();
      } else {
        throw Exception('Error from backend: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getDocumentTemplates() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/document_templates'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load document templates');
      }
    } catch (e) {
      throw Exception('Error fetching document templates: $e');
    }
  }

  Future<GeneratedContent> generateNapkinDiagram({
    required String userInput,
    required NapkinTemplate napkinTemplate,
  }) async {
    print('🎨 Generating diagram: ${napkinTemplate.napkinType} for "$userInput"');
    print('🔗 Using backend: $_baseUrl');
    
    try {
      final requestData = {
        'userInput': userInput,
        'napkinTemplate': napkinTemplate.toJson(),
      };
      
      print('📤 Sending request to: $_baseUrl/generate_napkin_diagram');
      print('📊 Request payload: ${json.encode(requestData).substring(0, 100)}...');
      
      final response = await http
          .post(
            Uri.parse('$_baseUrl/generate_napkin_diagram'),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: json.encode(requestData),
          )
          .timeout(const Duration(seconds: 120));

      print('📥 Response status: ${response.statusCode}');
      print('📏 Response size: ${response.body.length} chars');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        print('✅ Diagram generated successfully');
        print('🎯 Content type: ${responseData['isDiagram'] ? 'SVG Diagram' : 'Text Content'}');
        return GeneratedContent.fromJson(responseData);
      } else {
        print('❌ Backend error: ${response.statusCode}');
        print('📄 Error response: ${response.body.substring(0, 200)}...');
        
        // Try alternative backend
        print('🔄 Trying alternative backend...');
        final workingUrl = await findWorkingBackend();
        if (workingUrl != null && workingUrl != _baseUrl) {
          print('🎯 Retrying with: $workingUrl');
          return generateNapkinDiagram(
            userInput: userInput,
            napkinTemplate: napkinTemplate,
          );
        }
        
        throw Exception('Backend error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('💥 Connection error: ${e.toString()}');
      
      if (e.toString().contains('Backend error')) {
        rethrow; // Re-throw backend errors
      }
      
      // Try alternative backend for connection errors
      if (!e.toString().contains('Retrying with')) {
        print('🔄 Trying alternative backend due to connection error...');
        final workingUrl = await findWorkingBackend();
        if (workingUrl != null && workingUrl != _baseUrl) {
          print('🎯 Retrying with: $workingUrl');
          return generateNapkinDiagram(
            userInput: userInput,
            napkinTemplate: napkinTemplate,
          );
        }
      }
      
      throw Exception('Unable to connect to diagram generation service. Please check your internet connection and try again.');
    }
  }

  Future<List<GeneratedContent>> generateNapkinDiagrams({
    required String userInput,
    required List<NapkinTemplate> napkinTemplates,
  }) async {
    try {
      final List<Map<String, dynamic>> templatesJson =
          napkinTemplates.map((template) => template.toJson()).toList();

      final response = await http
          .post(
            Uri.parse('$_baseUrl/generate_napkin_diagrams'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userInput': userInput,
              'napkinTemplates': templatesJson,
            }),
          )
          .timeout(const Duration(seconds: 180));

      if (response.statusCode == 200) {
        final List<dynamic> responseData = json.decode(response.body);
        return responseData
            .map((item) => GeneratedContent.fromJson(item))
            .toList();
      } else {
        throw Exception('Error from backend: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }

  Future<String> regenerateDiagram({
    required String prompt,
    required String diagramType,
    required String currentSvg,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/regenerate_diagram'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'prompt': prompt,
              'diagramType': diagramType,
              'currentSvg': currentSvg,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['success'] == true && responseData['svg'] != null) {
          // Store additional info for potential user feedback
          final bool usingAi = responseData['using_ai'] ?? true;
          final String message = responseData['message'] ?? '';

          // You could use this info to show different messages to the user
          print('Regeneration result: $message (AI: $usingAi)');

          return responseData['svg'] as String;
        } else {
          throw Exception(
            'Invalid response from backend: ${responseData['error'] ?? 'Unknown error'}',
          );
        }
      } else if (response.statusCode == 503) {
        // Service unavailable - AI service not available
        throw Exception(
          'AI service is currently unavailable. Please check if the backend has proper API keys configured.',
        );
      } else {
        // Try to parse error message from response
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          throw Exception(
            'Backend error (${response.statusCode}): ${errorData['error'] ?? 'Unknown error'}',
          );
        } catch (_) {
          throw Exception(
            'Backend error: ${response.statusCode} - ${response.reasonPhrase}',
          );
        }
      }
    } catch (e) {
      if (e.toString().contains('AI service is currently unavailable') ||
          e.toString().contains('Backend error')) {
        rethrow; // Re-throw our custom exceptions
      }
      throw Exception(
        'Connection error: Failed to connect to backend. Please ensure the backend server is running.',
      );
    }
  }

  // NEW: Generate multiple variations of the same diagram type
  Future<Map<String, dynamic>> generateDiagramVariations({
    required String userInput,
    required String diagramType,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/generate_diagram_variations'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userInput': userInput,
              'diagramType': diagramType,
            }),
          )
          .timeout(const Duration(seconds: 180));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return responseData;
      } else {
        throw Exception('Error from backend: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
}
