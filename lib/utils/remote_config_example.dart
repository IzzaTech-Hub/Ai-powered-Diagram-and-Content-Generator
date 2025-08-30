import 'package:http/http.dart' as http;
import 'package:my_flutter_app/services/config_service.dart';

/// Example utility class showing how to use Remote Config for API calls
class RemoteConfigExample {
  static final ConfigService _configService = ConfigService();

  /// Example: Make an API call using the Remote Config API URL
  static Future<Map<String, dynamic>> makeApiCall(String endpoint) async {
    try {
      // Get the current API URL from Remote Config
      final apiUrl = _configService.apiUrl;
      final timeout = _configService.apiTimeout;
      final maxRetries = _configService.maxRetries;

      print('🌐 Making API call to: $apiUrl$endpoint');
      print('⏱️ Timeout: ${timeout}s');
      print('🔄 Max retries: $maxRetries');

      // Make the API call with configured timeout
      final response = await http
          .get(Uri.parse('$apiUrl$endpoint'))
          .timeout(Duration(seconds: timeout));

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': response.body,
          'statusCode': response.statusCode,
          'apiUrl': apiUrl,
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'statusCode': response.statusCode,
          'apiUrl': apiUrl,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'apiUrl': _configService.apiUrl,
      };
    }
  }

  /// Example: Make a POST API call with JSON data
  static Future<Map<String, dynamic>> makePostApiCall(
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      final apiUrl = _configService.apiUrl;
      final timeout = _configService.apiTimeout;

      print('🌐 Making POST API call to: $apiUrl$endpoint');

      final response = await http
          .post(
            Uri.parse('$apiUrl$endpoint'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(data),
          )
          .timeout(Duration(seconds: timeout));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'data': response.body,
          'statusCode': response.statusCode,
          'apiUrl': apiUrl,
        };
      } else {
        return {
          'success': false,
          'error': 'HTTP ${response.statusCode}',
          'statusCode': response.statusCode,
          'apiUrl': apiUrl,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
        'apiUrl': _configService.apiUrl,
      };
    }
  }

  /// Example: Check if using custom API URL from Remote Config
  static bool isUsingCustomApiUrl() {
    return _configService.isUsingCustomApiUrl;
  }

  /// Example: Get current configuration summary
  static Map<String, dynamic> getCurrentConfig() {
    return _configService.getConfigMap();
  }

  /// Example: Force refresh configuration and retry API call
  static Future<Map<String, dynamic>> refreshAndRetry(String endpoint) async {
    print('🔄 Refreshing Remote Config...');
    
    try {
      // Refresh configuration from Firebase
      await _configService.refreshConfig();
      
      // Retry the API call with new configuration
      return await makeApiCall(endpoint);
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to refresh config: $e',
        'apiUrl': _configService.apiUrl,
      };
    }
  }
}

// Helper function for JSON encoding
String jsonEncode(Map<String, dynamic> data) {
  // Simple JSON encoding for demonstration
  // In real app, use dart:convert
  return data.toString();
}

