import 'package:flutter/material.dart';
import '../models/napkin_template.dart';

class DiagramTemplates {
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
      
      // Entity Relationship Diagram (ERD)
      NapkinTemplate(
        id: 'erd_diagram',
        name: 'ERD Diagram',
        promptInstruction: 'Generate an entity relationship diagram for: [USER_INPUT]',
        icon: Icons.schema_outlined,
        description: 'Database schema visualization',
        color: Colors.red,
        gradientColors: [Colors.red.shade400, Colors.red.shade600],
        napkinType: 'erd',
        napkinOptions: {'notation': 'chen'},
      ),
      
      // Business Flow Diagram
      NapkinTemplate(
        id: 'business_flow',
        name: 'Business Flow',
        promptInstruction: 'Create a business flow diagram for: [USER_INPUT]',
        icon: Icons.business_center_outlined,
        description: 'Visualize business processes and workflows',
        color: Colors.green,
        gradientColors: [Colors.green.shade400, Colors.green.shade600],
        napkinType: 'flowchart',
        napkinOptions: {'style': 'business', 'orientation': 'left-to-right'},
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
        color: Colors.amber,
        gradientColors: [Colors.amber.shade400, Colors.amber.shade600],
        napkinType: 'swot analysis',
        napkinOptions: {'theme': 'professional'},
      ),
      
      // Sequence Diagram
      NapkinTemplate(
        id: 'sequence_diagram',
        name: 'Sequence Diagram',
        promptInstruction: 'Generate a sequence diagram for: [USER_INPUT]',
        icon: Icons.swap_calls_outlined,
        description: 'Visualize interactions between components',
        color: Colors.teal,
        gradientColors: [Colors.teal.shade400, Colors.teal.shade600],
        napkinType: 'sequence',
        napkinOptions: {'theme': 'simple'},
      ),
      
      // Class Diagram
      NapkinTemplate(
        id: 'class_diagram',
        name: 'Class Diagram',
        promptInstruction: 'Create a class diagram for: [USER_INPUT]',
        icon: Icons.view_module_outlined,
        description: 'Object-oriented structure visualization',
        color: Colors.indigo,
        gradientColors: [Colors.indigo.shade400, Colors.indigo.shade600],
        napkinType: 'class',
        napkinOptions: {'theme': 'modern'},
      ),
      
      // Network Diagram
      NapkinTemplate(
        id: 'network_diagram',
        name: 'Network Diagram',
        promptInstruction: 'Create a network architecture diagram for: [USER_INPUT]',
        icon: Icons.router_outlined,
        description: 'IT infrastructure visualization',
        color: Colors.cyan,
        gradientColors: [Colors.cyan.shade400, Colors.cyan.shade600],
        napkinType: 'network',
        napkinOptions: {'theme': 'technical'},
      ),
    ];
  }
}