import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:house_rental_app/services/auth/role_manager.dart';

class RoleBasedBuilder extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return fallback ?? SizedBox.shrink();

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(snapshot.data!.uid)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return SizedBox.shrink();

            final role = snapshot.data!.get('role') as String;
            if (!RoleManager.hasPermission(role, permission)) {
              return fallback ?? SizedBox.shrink();
            }

            return child;
          },
        );
      },
    );
  }
}
