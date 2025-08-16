// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> saveTextContent(
    String userId,
    String content,
    String prompt,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('generatedContent')
        .add({
          'content': content,
          'prompt': prompt,
          'type': 'text',
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<void> saveDiagram(
    String userId,
    String diagramType,
    String svgContent,
    String prompt,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('generatedContent')
        .add({
          'type': 'diagram',
          'diagramType': diagramType,
          'svgContent': svgContent,
          'prompt': prompt,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }

  Future<void> saveDocument(
    String userId,
    String documentType,
    String documentContent,
    String prompt,
  ) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('generatedContent')
        .add({
          'type': 'document',
          'documentType': documentType,
          'content': documentContent,
          'prompt': prompt,
          'timestamp': FieldValue.serverTimestamp(),
        });
  }
}
