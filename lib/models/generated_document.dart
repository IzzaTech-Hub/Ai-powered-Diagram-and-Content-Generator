// lib/models/generated_document.dart

class GeneratedDocument {
  final String templateName;
  final String content;
  final String documentType;
  final String? timestamp; // Use String? for nullable string
  final Map<String, dynamic>? metadata;
  final AssociatedDiagram? associatedDiagram; // <--- NEW: Add this field

  GeneratedDocument({
    required this.templateName,
    required this.content,
    required this.documentType,
    this.timestamp,
    this.metadata,
    this.associatedDiagram, // <--- NEW: Add to constructor
  });

  factory GeneratedDocument.fromJson(Map<String, dynamic> json) {
    return GeneratedDocument(
      templateName: json['templateName'] as String,
      content: json['content'] as String,
      documentType: json['documentType'] as String,
      timestamp:
          json['timestamp']
              as String?, // Can be parsed to DateTime if needed, but String is fine for display
      metadata: json['metadata'] as Map<String, dynamic>?,
      associatedDiagram:
          json['associatedDiagram'] != null
              ? AssociatedDiagram.fromJson(
                json['associatedDiagram'] as Map<String, dynamic>,
              )
              : null, // <--- NEW: Parse associatedDiagram
    );
  }
}

class AssociatedDiagram {
  final String type;
  final String svgContent;
  final String? error; // Can be null if no error

  AssociatedDiagram({required this.type, required this.svgContent, this.error});

  factory AssociatedDiagram.fromJson(Map<String, dynamic> json) {
    return AssociatedDiagram(
      type: json['type'] as String,
      svgContent: json['svgContent'] as String,
      error: json['error'] as String?,
    );
  }
}
