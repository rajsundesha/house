// user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental_app/data/models/user.dart';

class UserRepository {
  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('users');

  Future<List<AppUser>> fetchUsers() async {
    QuerySnapshot snapshot = await _userCollection.get();
    return snapshot.docs
        .map((doc) =>
            AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<List<AppUser>> fetchUsersByRole(String role) async {
    QuerySnapshot snapshot =
        await _userCollection.where('role', isEqualTo: role).get();
    return snapshot.docs
        .map((doc) =>
            AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<AppUser?> getUserById(String userId) async {
    DocumentSnapshot doc = await _userCollection.doc(userId).get();
    if (!doc.exists) return null;
    return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> addUser(AppUser user) async {
    await _userCollection.doc(user.uid).set(user.toMap());
  }

  // Add update method
  Future<void> updateUser(AppUser user) async {
    try {
      await _userCollection.doc(user.uid).update(user.toMap());
    } catch (e) {
      throw Exception('Failed to update user: ${e.toString()}');
    }
  }

  // Add method to update specific fields
  Future<void> updateUserFields(
      String userId, Map<String, dynamic> fields) async {
    try {
      await _userCollection.doc(userId).update(fields);
    } catch (e) {
      throw Exception('Failed to update user fields: ${e.toString()}');
    }
  }
}
