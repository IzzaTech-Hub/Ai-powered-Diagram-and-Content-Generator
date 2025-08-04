import 'package:flutter/material.dart';

class NapkinTemplate {
  final String id;
  final String name;
  final String promptInstruction;
  final IconData icon;
  final String description;
  final Color color;
  final List<Color> gradientColors;
  final String previewImage;
  final String napkinType;
  final Map<String, dynamic> napkinOptions;

  NapkinTemplate({
    required this.id,
    required this.name,
    required this.promptInstruction,
    required this.icon,
    required this.description,
    required this.color,
    required this.gradientColors,
    this.previewImage = '',
    required this.napkinType,
    this.napkinOptions = const {},
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'promptInstruction': promptInstruction,
    'napkinType': napkinType,
    'napkinOptions': napkinOptions,
  };
} 