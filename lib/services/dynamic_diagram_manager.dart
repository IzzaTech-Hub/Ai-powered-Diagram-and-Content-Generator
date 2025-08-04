import 'dart:async';
import '../models/generated_content.dart';
import '../models/napkin_template.dart';
import '../services/api_service.dart';

class DynamicDiagramManager {
  final ApiService _apiService = ApiService();
  
  // Stream controllers for real-time updates
  final StreamController<GeneratedContent> _diagramStreamController = 
      StreamController<GeneratedContent>.broadcast();
  
  // Getters for streams
  Stream<GeneratedContent> get diagramStream => _diagramStreamController.stream;
  
  // Track the current input and template
  String _currentInput = '';
  NapkinTemplate? _currentTemplate;
  
  // Flag to track if auto-sync is enabled
  bool _autoSyncEnabled = false;
  Timer? _debounceTimer;
  
  // Getter and setter for auto-sync
  bool get autoSyncEnabled => _autoSyncEnabled;
  set autoSyncEnabled(bool value) {
    _autoSyncEnabled = value;
  }
  
  // Method to update input and regenerate diagram if auto-sync is enabled
  Future<void> updateInput(String input, NapkinTemplate template) async {
    _currentInput = input;
    _currentTemplate = template;
    
    // If auto-sync is enabled, debounce the regeneration
    if (_autoSyncEnabled && input.isNotEmpty) {
      if (_debounceTimer != null && _debounceTimer!.isActive) {
        _debounceTimer!.cancel();
      }
      
      // Wait for 1.5 seconds of inactivity before regenerating
      _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
        regenerateDiagram();
      });
    }
  }
  
  // Method to manually regenerate diagram
  Future<GeneratedContent?> regenerateDiagram() async {
    if (_currentInput.isEmpty || _currentTemplate == null) {
      return null;
    }
    
    try {
      final diagram = await _apiService.generateNapkinDiagram(
        userInput: _currentInput,
        napkinTemplate: _currentTemplate!,
      );
      
      // Broadcast the new diagram
      _diagramStreamController.add(diagram);
      
      return diagram;
    } catch (e) {
      // Handle error but don't broadcast
      print('Error regenerating diagram: $e');
      return null;
    }
  }
  
  // Method to sync text changes with diagram
  Future<GeneratedContent?> syncTextWithDiagram(String newText) async {
    if (_currentTemplate == null) {
      return null;
    }
    
    _currentInput = newText;
    return regenerateDiagram();
  }
  
  // Dispose method to clean up resources
  void dispose() {
    _debounceTimer?.cancel();
    _diagramStreamController.close();
  }
}