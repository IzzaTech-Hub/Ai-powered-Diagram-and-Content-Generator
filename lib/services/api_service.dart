import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:my_flutter_app/constants/document_template.dart';
import 'package:my_flutter_app/models/generated_document.dart';
import '../models/content_template.dart';
import '../models/generated_content.dart';
import '../models/napkin_template.dart';
import '../widgets/mind_map_template_selector.dart';

class ApiService {
  // Production and development URLs to try
  static List<String> _possibleUrls = [
    'https://diagramgenerator-hj9d.onrender.com',           // 🚀 Your live backend
    'http://127.0.0.1:5000',                                 // Local development
    'http://localhost:5000',                                 // Local development
    'http://10.0.2.2:5000',                                  // Android emulator
    'http://192.168.0.108:5000',                             // Network IP from logs
  ];
  
  static String _baseUrl = 'https://diagramgenerator-hj9d.onrender.com';  // 🚀 Your live backend

  // Initialize API service
  static void initialize() {
    print('API Service initialized with endpoint: $_baseUrl');
  }
  
  // Get the current base URL
  static String get baseUrl => _baseUrl;

  // Find working backend URL
  static Future<String?> findWorkingBackend() async {
    for (String url in _possibleUrls) {
      try {
        final response = await http
            .get(Uri.parse('$url/health'))
            .timeout(const Duration(seconds: 3));
        
        if (response.statusCode == 200) {
          print('Found working backend at: $url');
          _baseUrl = url;
          return url;
        }
      } catch (e) {
        print('Failed to connect to $url: $e');
      }
    }
    return null;
  }

  Future<bool> checkBackendHealth() async {
    try {
      // First try current URL
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        print('Backend health check successful at $_baseUrl');
        return true;
      } else {
        print('Backend health check returned status: ${response.statusCode}');
        // Try to find working backend
        final workingUrl = await findWorkingBackend();
        return workingUrl != null;
      }
    } catch (e) {
      print('Backend health check failed: $e');
      print('Tip: Start the backend server with: python backend/app.py');
      
      // Try to find working backend
      final workingUrl = await findWorkingBackend();
      if (workingUrl != null) {
        print('Found alternative backend at: $workingUrl');
        return true;
      }
      
      return false;
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
      final List<Map<String, dynamic>> templatesWithOptions = selectedTemplates.map((template) {
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
          final Map<String, dynamic> enrichedItem = Map<String, dynamic>.from(item);
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
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/generate_napkin_diagram'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userInput': userInput,
              'napkinTemplate': napkinTemplate.toJson(),
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        return GeneratedContent.fromJson(responseData);
      } else {
        throw Exception('Error from backend: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Connection error: $e');
    }
  }
  
  Future<List<GeneratedContent>> generateNapkinDiagrams({
    required String userInput,
    required List<NapkinTemplate> napkinTemplates,
  }) async {
    try {
      final List<Map<String, dynamic>> templatesJson = napkinTemplates.map((template) => template.toJson()).toList();
      
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
          throw Exception('Invalid response from backend: ${responseData['error'] ?? 'Unknown error'}');
        }
      } else if (response.statusCode == 503) {
        // Service unavailable - AI service not available
        throw Exception('AI service is currently unavailable. Please check if the backend has proper API keys configured.');
      } else {
        // Try to parse error message from response
        try {
          final Map<String, dynamic> errorData = json.decode(response.body);
          throw Exception('Backend error (${response.statusCode}): ${errorData['error'] ?? 'Unknown error'}');
        } catch (_) {
          throw Exception('Backend error: ${response.statusCode} - ${response.reasonPhrase}');
        }
      }
    } catch (e) {
      if (e.toString().contains('AI service is currently unavailable') || 
          e.toString().contains('Backend error')) {
        rethrow; // Re-throw our custom exceptions
      }
      throw Exception('Connection error: Failed to connect to backend. Please ensure the backend server is running.');
    }
  }
} 

