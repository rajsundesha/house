import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental_app/models/user.dart';


class UserProvider with ChangeNotifier {
  List<AppUser> _users = [];

  List<AppUser> get users => _users;

  final CollectionReference _userCollection =
      FirebaseFirestore.instance.collection('users');

  // Fetch all users
  Future<void> fetchUsers() async {
    try {
      QuerySnapshot snapshot = await _userCollection.get();
      _users = snapshot.docs
          .map((doc) =>
              AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching users: $e');
    }
  }

  // Fetch users by role (e.g., managers)
  Future<List<AppUser>> fetchUsersByRole(String role) async {
    try {
      QuerySnapshot snapshot =
          await _userCollection.where('role', isEqualTo: role).get();
      List<AppUser> users = snapshot.docs
          .map((doc) =>
              AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      return users;
    } catch (e) {
      print('Error fetching users by role: $e');
      return [];
    }
  }

  // Get user by ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      DocumentSnapshot doc = await _userCollection.doc(userId).get();
      if (doc.exists) {
        return AppUser.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        print('User not found');
        return null;
      }
    } catch (e) {
      print('Error getting user by ID: $e');
      return null;
    }
  }

  // Add a new user (optional, if admin can add managers)
  Future<void> addUser(AppUser user) async {
    try {
      await _userCollection.doc(user.uid).set(user.toMap());
      _users.add(user);
      notifyListeners();
    } catch (e) {
      print('Error adding user: $e');
    }
  }
}
