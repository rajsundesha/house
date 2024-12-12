// user_provider.dart
import 'package:flutter/material.dart';
import 'package:house_rental_app/data/models/user.dart';
import 'package:house_rental_app/data/repositories/user_repository.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _userRepository;

  UserProvider(this._userRepository);

  List<AppUser> _users = [];
  List<AppUser> get users => _users;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> fetchUsers() async {
    _isLoading = true;
    _error = null;
    try {
      _users = await _userRepository.fetchUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<AppUser>> fetchUsersByRole(String role) async {
    try {
      return await _userRepository.fetchUsersByRole(role);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  Future<AppUser?> getUserById(String userId) async {
    try {
      return await _userRepository.getUserById(userId);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<void> addUser(AppUser user) async {
    try {
      await _userRepository.addUser(user);
      _users.add(user);
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  // Add update user method
  Future<void> updateUser(AppUser user) async {
    try {
      await _userRepository.updateUser(user);
      int index = _users.indexWhere((u) => u.uid == user.uid);
      if (index != -1) {
        _users[index] = user;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  // Add method to update specific fields
  Future<void> updateUserFields(
      String userId, Map<String, dynamic> fields) async {
    try {
      await _userRepository.updateUserFields(userId, fields);
      int index = _users.indexWhere((u) => u.uid == userId);
      if (index != -1) {
        // Update only the specified fields in the local user object
        final updatedUser = AppUser(
          uid: _users[index].uid,
          name: fields['name'] ?? _users[index].name,
          role: fields['role'] ?? _users[index].role,
          contactInfo: fields['contactInfo'] ?? _users[index].contactInfo,
          createdAt: _users[index].createdAt,
        );
        _users[index] = updatedUser;
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  // Clear any errors
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
