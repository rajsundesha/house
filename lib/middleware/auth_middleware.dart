// class AuthMiddleware extends RouteAwareWidget {
//   final String requiredPermission;
//   final Widget child;

//   @override
//   Widget build(BuildContext context) {
//     return StreamBuilder<User?>(
//       stream: FirebaseAuth.instance.authStateChanges(),
//       builder: (context, snapshot) {
//         if (!snapshot.hasData) {
//           Navigator.pushReplacementNamed(context, '/login');
//           return LoadingIndicator();
//         }

//         return FutureBuilder<DocumentSnapshot>(
//           future: FirebaseFirestore.instance
//               .collection('users')
//               .doc(snapshot.data!.uid)
//               .get(),
//           builder: (context, snapshot) {
//             if (!snapshot.hasData) return LoadingIndicator();

//             final role = snapshot.data!.get('role') as String;
//             if (!RoleManager.hasPermission(role, requiredPermission)) {
//               Navigator.pushReplacementNamed(context, '/unauthorized');
//               return LoadingIndicator();
//             }

//             return child;
//           },
//         );
//       },
//     );
//   }
// }
