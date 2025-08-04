import 'package:flutter/material.dart';
import '../models/content_template.dart';

class TemplateData {
  static List<ContentTemplate> getAvailableTemplates() {
    return [
      ContentTemplate(
        name: 'Tweet',
        promptInstruction: 'Generate an engaging tweet about: [USER_INPUT]',
        icon: Icons.chat_bubble_outline,
        description: 'Create viral social media content',
        color: Colors.blue,
        gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
      ),
      ContentTemplate(
        name: 'Blog Outline',
        promptInstruction: 'Create comprehensive blog outline for: [USER_INPUT]',
        icon: Icons.article_outlined,
        description: 'Structure your blog posts',
        color: Colors.green,
        gradientColors: [Colors.green.shade400, Colors.green.shade600],
      ),
      ContentTemplate(
        name: 'Flow Chart',
        promptInstruction: 'Generate step-by-step flowchart for: [USER_INPUT]',
        isDiagram: true,
        icon: Icons.account_tree_outlined,
        description: 'Visualize processes and workflows',
        color: Colors.purple,
        gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
      ),
      ContentTemplate(
        name: 'Mind Map',
        promptInstruction: 'Create hierarchical mind map for: [USER_INPUT]',
        isDiagram: true,
        icon: Icons.psychology_outlined,
        description: 'Organize ideas and concepts',
        color: Colors.orange,
        gradientColors: [Colors.orange.shade400, Colors.orange.shade600],
      ),
      ContentTemplate(
        name: 'SWOT Analysis',
        promptInstruction: 'Generate SWOT analysis for: [USER_INPUT]',
        isDiagram: true,
        icon: Icons.analytics_outlined,
        description: 'Strategic business analysis',
        color: Colors.red,
        gradientColors: [Colors.red.shade400, Colors.red.shade600],
      ),
      ContentTemplate(
        name: 'Timeline',
        promptInstruction: 'Create timeline for: [USER_INPUT]',
        isDiagram: true,
        icon: Icons.timeline_outlined,
        description: 'Visualize events over time',
        color: Colors.indigo,
        gradientColors: [Colors.indigo.shade400, Colors.indigo.shade600],
      ),
    ];
  }
} 