import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/napkin_template.dart';

class ConnectionTestWidget extends StatefulWidget {
  const ConnectionTestWidget({super.key});

  @override
  State<ConnectionTestWidget> createState() => _ConnectionTestWidgetState();
}

class _ConnectionTestWidgetState extends State<ConnectionTestWidget> {
  String _status = 'Ready to test';
  bool _isLoading = false;
  String _details = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connection Diagnostic'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Backend Connection Test',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Current Backend: ${ApiService.baseUrl}'),
                    const SizedBox(height: 16),
                    Text(
                      _status,
                      style: TextStyle(
                        color: _status.contains('✅') 
                            ? Colors.green 
                            : _status.contains('❌') 
                                ? Colors.red 
                                : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_details.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _details,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testHealthCheck,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test Health Check'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testDiagramGeneration,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Test Diagram Generation'),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _isLoading ? null : _testFindBackend,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Find Working Backend'),
            ),
            const SizedBox(height: 24),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Troubleshooting Tips:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('1. Ensure you have internet connection'),
                    Text('2. Try switching between WiFi and mobile data'),
                    Text('3. Check if antivirus/firewall is blocking connections'),
                    Text('4. Production backend should work: diagramgenerator-hj9d.onrender.com'),
                    Text('5. For local testing, ensure backend server is running'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testHealthCheck() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing health check...';
      _details = '';
    });

    try {
      final apiService = ApiService();
      final isHealthy = await apiService.checkBackendHealth();
      
      setState(() {
        _status = isHealthy 
            ? '✅ Health check passed' 
            : '❌ Health check failed';
        _details = 'Backend URL: ${ApiService.baseUrl}';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Health check error';
        _details = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testDiagramGeneration() async {
    setState(() {
      _isLoading = true;
      _status = 'Testing diagram generation...';
      _details = '';
    });

    try {
      final apiService = ApiService();
      final napkinTemplate = NapkinTemplate(
        id: 'test-flowchart',
        name: 'Test Flowchart',
        description: 'Test diagram',
        napkinType: 'flowchart',
        promptInstruction: 'Create a simple flowchart for [USER_INPUT]',
        icon: Icons.account_tree,
        color: Colors.blue,
        gradientColors: [Colors.blue, Colors.lightBlue],
      );

      final result = await apiService.generateNapkinDiagram(
        userInput: 'Test diagram generation process',
        napkinTemplate: napkinTemplate,
      );

      setState(() {
        _status = '✅ Diagram generation successful';
        _details = 'Generated content: ${result.content.substring(0, 100)}...';
      });
    } catch (e) {
      setState(() {
        _status = '❌ Diagram generation failed';
        _details = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testFindBackend() async {
    setState(() {
      _isLoading = true;
      _status = 'Searching for working backend...';
      _details = '';
    });

    try {
      final workingUrl = await ApiService.findWorkingBackend();
      
      setState(() {
        if (workingUrl != null) {
          _status = '✅ Found working backend';
          _details = 'Working URL: $workingUrl';
        } else {
          _status = '❌ No working backend found';
          _details = 'All tested URLs are unreachable';
        }
      });
    } catch (e) {
      setState(() {
        _status = '❌ Backend search error';
        _details = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
