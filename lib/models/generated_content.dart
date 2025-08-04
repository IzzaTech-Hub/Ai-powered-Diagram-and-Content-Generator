class GeneratedContent {
  final String templateName;
  final String content;
  final bool isDiagram;
  final DateTime timestamp;
  final String? originalPrompt;

  GeneratedContent({
    required this.templateName,
    required this.content,
    this.isDiagram = false,
    DateTime? timestamp,
    this.originalPrompt,
  }) : timestamp = timestamp ?? DateTime.now();

  factory GeneratedContent.fromJson(Map<String, dynamic> json) =>
      GeneratedContent(
        templateName: json['templateName'] ?? 'Unknown',
        content: json['content'] ?? 'No content generated.',
        isDiagram: json['isDiagram'] ?? false,
        originalPrompt: json['originalPrompt'],
      );
      
  GeneratedContent copyWith({
    String? templateName,
    String? content,
    bool? isDiagram,
    DateTime? timestamp,
    String? originalPrompt,
  }) {
    return GeneratedContent(
      templateName: templateName ?? this.templateName,
      content: content ?? this.content,
      isDiagram: isDiagram ?? this.isDiagram,
      timestamp: timestamp ?? this.timestamp,
      originalPrompt: originalPrompt ?? this.originalPrompt,
    );
  }
} 