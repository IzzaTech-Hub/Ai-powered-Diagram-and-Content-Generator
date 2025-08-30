import 'package:flutter/material.dart';
import 'package:my_flutter_app/services/config_service.dart';
import 'package:my_flutter_app/services/api_service.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final ConfigService _configService = ConfigService();
  bool _isRefreshing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshConfig,
            tooltip: 'Refresh Configuration',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildConfigCard(),
            const SizedBox(height: 16),
            _buildInfoCard(),
            const SizedBox(height: 16),
            _buildActionsCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigCard() {
    final config = _configService.getConfigMap();
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.settings,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Current Configuration',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildConfigRow('API URL', config['apiUrl'] ?? 'Not set'),
            _buildConfigRow('API Timeout', '${config['apiTimeout'] ?? 30} seconds'),
            _buildConfigRow('Max Retries', '${config['maxRetries'] ?? 3}'),
            _buildConfigRow('Initialized', config['isInitialized'] ? 'Yes' : 'No'),
            _buildConfigRow('Using Custom URL', config['isUsingCustomApiUrl'] ? 'Yes' : 'No'),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                const Text(
                  'How Remote Config Works',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Firebase Remote Config allows you to change your app\'s behavior without updating the app\n'
              '• The API URL is fetched from Firebase when the app starts\n'
              '• If Remote Config fails, the app uses default values\n'
              '• Configuration is cached and refreshed every hour',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isRefreshing ? null : _refreshConfig,
                    icon: _isRefreshing
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                    label: Text(_isRefreshing ? 'Refreshing...' : 'Refresh Config'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _resetToDefaults,
                    icon: const Icon(Icons.restore),
                    label: const Text('Reset to Defaults'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _updateApiService,
                icon: const Icon(Icons.update),
                label: const Text('Update API Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshConfig() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      await _configService.refreshConfig();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuration refreshed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to refresh configuration: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Configuration'),
        content: const Text(
          'Are you sure you want to reset the configuration to default values? '
          'This will use the hardcoded API URL.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _configService.resetToDefaults();
              Navigator.of(context).pop();
              setState(() {});
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Configuration reset to defaults'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  void _updateApiService() {
    ApiService.updateBaseUrl();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('API Service updated with new configuration'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

