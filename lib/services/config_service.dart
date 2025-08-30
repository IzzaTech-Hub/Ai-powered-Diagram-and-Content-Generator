import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  late FirebaseRemoteConfig _remoteConfig;
  bool _isInitialized = false;

  // Default API URL fallback
  static const String _defaultApiUrl = 'https://aidiagramgenerator-5sbzj7l4s-uzairhassan375s-projects.vercel.app';
  
  // Remote Config keys
  static const String _apiUrlKey = 'api_url';
  static const String _apiTimeoutKey = 'api_timeout';
  static const String _maxRetriesKey = 'max_retries';

  // Current configuration values
  String _currentApiUrl = _defaultApiUrl;
  int _currentApiTimeout = 30;
  int _currentMaxRetries = 3;

  // Getters for current values
  String get apiUrl => _currentApiUrl;
  int get apiTimeout => _currentApiTimeout;
  int get maxRetries => _currentMaxRetries;
  bool get isInitialized => _isInitialized;

  /// Initialize Firebase Remote Config
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _remoteConfig = FirebaseRemoteConfig.instance;
      
      // Set default values
      await _remoteConfig.setDefaults({
        _apiUrlKey: _defaultApiUrl,
        _apiTimeoutKey: 30,
        _maxRetriesKey: 3,
      });

      // Set fetch timeout
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(minutes: 1),
        minimumFetchInterval: const Duration(hours: 1), // Minimum 1 hour between fetches
      ));

      // Fetch and activate config
      await _fetchAndActivateConfig();
      
      _isInitialized = true;
      
      if (kDebugMode) {
        print('✅ ConfigService initialized successfully');
        print('🌐 API URL: $_currentApiUrl');
        print('⏱️ API Timeout: ${_currentApiTimeout}s');
        print('🔄 Max Retries: $_currentMaxRetries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to initialize ConfigService: $e');
        print('🔄 Using default configuration');
      }
      // Use default values if Remote Config fails
      _currentApiUrl = _defaultApiUrl;
      _currentApiTimeout = 30;
      _currentMaxRetries = 3;
      _isInitialized = true;
    }
  }

  /// Fetch and activate Remote Config
  Future<void> _fetchAndActivateConfig() async {
    try {
      // Fetch config from Firebase
      await _remoteConfig.fetchAndActivate();
      
      // Update current values
      _currentApiUrl = _remoteConfig.getString(_apiUrlKey);
      _currentApiTimeout = _remoteConfig.getInt(_apiTimeoutKey);
      _currentMaxRetries = _remoteConfig.getInt(_maxRetriesKey);
      
      if (kDebugMode) {
        print('🔄 Remote Config fetched and activated');
        print('🌐 New API URL: $_currentApiUrl');
        print('⏱️ New API Timeout: ${_currentApiTimeout}s');
        print('🔄 New Max Retries: $_currentMaxRetries');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to fetch Remote Config: $e');
        print('🔄 Using cached/default values');
      }
    }
  }

  /// Force refresh configuration from Firebase
  Future<void> refreshConfig() async {
    if (!_isInitialized) {
      await initialize();
      return;
    }

    try {
      await _fetchAndActivateConfig();
      
      if (kDebugMode) {
        print('🔄 Configuration refreshed successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to refresh configuration: $e');
      }
    }
  }

  /// Get configuration as a map for debugging
  Map<String, dynamic> getConfigMap() {
    return {
      'apiUrl': _currentApiUrl,
      'apiTimeout': _currentApiTimeout,
      'maxRetries': _currentMaxRetries,
      'isInitialized': _isInitialized,
      'defaultApiUrl': _defaultApiUrl,
    };
  }

  /// Check if current API URL is different from default
  bool get isUsingCustomApiUrl => _currentApiUrl != _defaultApiUrl;

  /// Reset to default configuration
  void resetToDefaults() {
    _currentApiUrl = _defaultApiUrl;
    _currentApiTimeout = 30;
    _currentMaxRetries = 3;
    
    if (kDebugMode) {
      print('🔄 Configuration reset to defaults');
    }
  }
}

