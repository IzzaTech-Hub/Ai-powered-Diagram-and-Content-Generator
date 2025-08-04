import 'package:flutter/material.dart';
import 'package:my_flutter_app/constants/document_template.dart';

class DocumentTemplates {
  static List<DocumentTemplate> getAvailableTemplates() {
    return [
      // Business Documents
      DocumentTemplate(
        id: 'business_plan',
        name: 'Business Plan',
        promptInstruction: 'Generate a comprehensive business plan for: [USER_INPUT]',
        icon: Icons.business_center_outlined,
        description: 'Complete business strategy document',
        color: Colors.blue,
        gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
        documentType: 'business',
        options: {'sections': ['executive_summary', 'market_analysis', 'financial_projections']},
      ),
      DocumentTemplate(
        id: 'project_proposal',
        name: 'Project Proposal',
        promptInstruction: 'Create a detailed project proposal for: [USER_INPUT]',
        icon: Icons.assignment_outlined,
        description: 'Professional project documentation',
        color: Colors.green,
        gradientColors: [Colors.green.shade400, Colors.green.shade600],
        documentType: 'project',
        options: {'format': 'formal', 'include_timeline': true},
      ),
      DocumentTemplate(
        id: 'technical_spec',
        name: 'Technical Specification',
        promptInstruction: 'Generate technical specification document for: [USER_INPUT]',
        icon: Icons.code_outlined,
        description: 'Detailed technical requirements',
        color: Colors.purple,
        gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
        documentType: 'technical',
        options: {'include_diagrams': true, 'detail_level': 'high'},
      ),
      
      // Academic Documents
      DocumentTemplate(
        id: 'research_paper',
        name: 'Research Paper',
        promptInstruction: 'Create a research paper outline for: [USER_INPUT]',
        icon: Icons.school_outlined,
        description: 'Academic research document',
        color: Colors.indigo,
        gradientColors: [Colors.indigo.shade400, Colors.indigo.shade600],
        documentType: 'academic',
        options: {'citation_style': 'APA', 'include_bibliography': true},
      ),
      DocumentTemplate(
        id: 'case_study',
        name: 'Case Study',
        promptInstruction: 'Generate a comprehensive case study for: [USER_INPUT]',
        icon: Icons.library_books_outlined,
        description: 'In-depth analysis document',
        color: Colors.teal,
        gradientColors: [Colors.teal.shade400, Colors.teal.shade600],
        documentType: 'academic',
        options: {'methodology': 'qualitative', 'include_recommendations': true},
      ),
      
      // Marketing Documents
      DocumentTemplate(
        id: 'marketing_plan',
        name: 'Marketing Plan',
        promptInstruction: 'Create a marketing strategy document for: [USER_INPUT]',
        icon: Icons.campaign_outlined,
        description: 'Strategic marketing roadmap',
        color: Colors.orange,
        gradientColors: [Colors.orange.shade400, Colors.orange.shade600],
        documentType: 'marketing',
        options: {'include_budget': true, 'target_audience': 'general'},
      ),
      DocumentTemplate(
        id: 'content_strategy',
        name: 'Content Strategy',
        promptInstruction: 'Generate content strategy document for: [USER_INPUT]',
        icon: Icons.edit_note_outlined,
        description: 'Content planning and execution',
        color: Colors.pink,
        gradientColors: [Colors.pink.shade400, Colors.pink.shade600],
        documentType: 'marketing',
        options: {'platforms': ['social', 'blog', 'email'], 'duration': '6_months'},
      ),
      
      // Legal Documents
      DocumentTemplate(
        id: 'contract_template',
        name: 'Contract Template',
        promptInstruction: 'Create a contract template for: [USER_INPUT]',
        icon: Icons.gavel_outlined,
        description: 'Legal agreement framework',
        color: Colors.brown,
        gradientColors: [Colors.brown.shade400, Colors.brown.shade600],
        documentType: 'legal',
        options: {'jurisdiction': 'general', 'include_clauses': true},
      ),
      
      // Reports
      DocumentTemplate(
        id: 'progress_report',
        name: 'Progress Report',
        promptInstruction: 'Generate a progress report for: [USER_INPUT]',
        icon: Icons.trending_up_outlined,
        description: 'Status and milestone tracking',
        color: Colors.cyan,
        gradientColors: [Colors.cyan.shade400, Colors.cyan.shade600],
        documentType: 'report',
        options: {'frequency': 'monthly', 'include_metrics': true},
      ),
      DocumentTemplate(
        id: 'analysis_report',
        name: 'Analysis Report',
        promptInstruction: 'Create an analysis report for: [USER_INPUT]',
        icon: Icons.analytics_outlined,
        description: 'Data-driven insights document',
        color: Colors.red,
        gradientColors: [Colors.red.shade400, Colors.red.shade600],
        documentType: 'report',
        options: {'include_charts': true, 'executive_summary': true},
      ),
    ];
  }
  
  static List<DocumentTemplate> getTemplatesByType(String type) {
    return getAvailableTemplates().where((template) => template.documentType == type).toList();
  }
  
  static List<String> getDocumentTypes() {
    return ['business', 'project', 'technical', 'academic', 'marketing', 'legal', 'report'];
  }
}
