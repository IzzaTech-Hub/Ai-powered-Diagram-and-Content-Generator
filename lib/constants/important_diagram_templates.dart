import 'package:flutter/material.dart';
import '../models/napkin_template.dart';

class ImportantDiagramTemplates {
  static List<NapkinTemplate> getTemplates() {
    return [
      // Process Flowchart - Most common and useful diagram type
      NapkinTemplate(
        id: 'flowchart_process',
        name: 'Process Flowchart',
        promptInstruction: 'Generate a process flowchart for: [USER_INPUT]',
        icon: Icons.account_tree_outlined,
        description: 'Step-by-step process visualization',
        color: Colors.blue,
        gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
        napkinType: 'flowchart',
        napkinOptions: {'style': 'process', 'orientation': 'top-to-bottom'},
      ),
      
      // Mind Map - Great for brainstorming and concept organization
      NapkinTemplate(
        id: 'mind_map',
        name: 'Mind Map',
        promptInstruction: 'Create a mind map for: [USER_INPUT]',
        icon: Icons.bubble_chart_outlined,
        description: 'Organize ideas and concepts',
        color: Colors.purple,
        gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
        napkinType: 'mind map',
        napkinOptions: {'style': 'modern'},
      ),
      
      // SWOT Analysis - Important for business and strategic planning
      NapkinTemplate(
        id: 'swot_analysis',
        name: 'SWOT Analysis',
        promptInstruction: 'Generate a SWOT analysis for: [USER_INPUT]',
        icon: Icons.grid_view_outlined,
        description: 'Strengths, Weaknesses, Opportunities, Threats',
        color: Colors.green,
        gradientColors: [Colors.green.shade400, Colors.green.shade600],
        napkinType: 'swot analysis',
        napkinOptions: {'theme': 'professional'},
      ),
    ];
  }
}