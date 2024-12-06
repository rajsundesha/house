import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/property.dart';

class PropertyRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Property>> getProperties() async {
    final snapshot = await _firestore.collection('properties').get();
    return snapshot.docs.map((doc) => Property.fromMap(doc.data(), doc.id)).toList();
  }

  Future<Property> addProperty(Property property) async {
    final docRef = await _firestore.collection('properties').add(property.toMap());
    return property.copyWith(id: docRef.id);
  }

  Future<void> updateProperty(Property property) async {
    await _firestore.collection('properties').doc(property.id).update(property.toMap());
  }

  Future<void> deleteProperty(String id) async {
    await _firestore.collection('properties').doc(id).delete();
  }
}
