import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../domain/document.dart';

class DocumentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<List<Document>> getDocuments() async {
    final snapshot = await _firestore.collection('documents').get();
    return snapshot.docs.map((doc) => Document.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<Document>> getDocumentsByType(DocumentType type) async {
    final snapshot = await _firestore
        .collection('documents')
        .where('type', isEqualTo: type.name)
        .get();
    return snapshot.docs.map((doc) => Document.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<Document>> getDocumentsByRelatedId(String relatedId) async {
    final snapshot = await _firestore
        .collection('documents')
        .where('relatedId', isEqualTo: relatedId)
        .get();
    return snapshot.docs.map((doc) => Document.fromMap(doc.data(), doc.id)).toList();
  }

  Future<Document> uploadDocument({
    required File file,
    required String fileName,
    required DocumentType type,
    required String relatedId,
    required String uploadedBy,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    // Upload file to Firebase Storage
    final storageRef = _storage.ref().child('documents/$fileName');
    await storageRef.putFile(file);
    final url = await storageRef.getDownloadURL();

    // Create document record in Firestore
    final document = Document(
      id: '',
      name: fileName,
      url: url,
      type: type,
      description: description,
      uploadedAt: DateTime.now(),
      uploadedBy: uploadedBy,
      relatedId: relatedId,
      metadata: metadata,
    );

    final docRef = await _firestore.collection('documents').add(document.toMap());
    return document.copyWith(id: docRef.id);
  }

  Future<void> deleteDocument(String id) async {
    // Get the document to get the storage reference
    final doc = await _firestore.collection('documents').doc(id).get();
    final data = doc.data();
    if (data != null) {
      // Delete from Storage
      final storageRef = _storage.refFromURL(data['url']);
      await storageRef.delete();
    }

    // Delete from Firestore
    await _firestore.collection('documents').doc(id).delete();
  }
}