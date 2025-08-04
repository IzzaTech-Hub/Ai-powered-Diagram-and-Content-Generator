import 'package:flutter/material.dart';

class DocumentTemplate {
  final String id;
  final String name;
  final String promptInstruction;
  final IconData icon;
  final String description;
  final Color color;
  final List<Color> gradientColors;
  final String documentType;
  final Map<String, dynamic> options;

  DocumentTemplate({
    required this.id,
    required this.name,
    required this.promptInstruction,
    required this.icon,
    required this.description,
    required this.color,
    required this.gradientColors,
    required this.documentType,
    this.options = const {},
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'promptInstruction': promptInstruction,
      'description': description,
      'documentType': documentType,
      'options': options,
    };
  }

  factory DocumentTemplate.fromJson(Map<String, dynamic> json) {
    return DocumentTemplate(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      promptInstruction: json['promptInstruction'] ?? '',
      icon: Icons.description, // Default icon
      description: json['description'] ?? '',
      color: Colors.blue, // Default color
      gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
      documentType: json['documentType'] ?? 'general',
      options: json['options'] ?? {},
    );
  }
}
