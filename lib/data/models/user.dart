import 'package:cloud_firestore/cloud_firestore.dart';

class AppUser {
  String uid;
  String role; // 'admin', 'manager'
  String name;
  Map<String, String> contactInfo;
  DateTime createdAt;

  AppUser({
    required this.uid,
    required this.role,
    required this.name,
    required this.contactInfo,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> data, String documentId) {
    return AppUser(
      uid: documentId,
      role: data['role'] ?? '',
      name: data['name'] ?? '',
      contactInfo: Map<String, String>.from(data['contactInfo'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'name': name,
      'contactInfo': contactInfo,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
