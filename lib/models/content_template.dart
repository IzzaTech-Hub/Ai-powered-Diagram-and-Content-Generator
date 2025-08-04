import 'package:flutter/material.dart';

class ContentTemplate {
  final String name;
  final String promptInstruction;
  final bool isDiagram;
  final IconData icon;
  final String description;
  final Color color;
  final List<Color> gradientColors;

  ContentTemplate({
    required this.name,
    required this.promptInstruction,
    this.isDiagram = false,
    required this.icon,
    required this.description,
    required this.color,
    required this.gradientColors,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'promptInstruction': promptInstruction,
    'isDiagram': isDiagram,
  };
} 