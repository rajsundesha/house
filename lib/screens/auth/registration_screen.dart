import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegistrationScreen extends StatefulWidget {
  @override
  _RegistrationScreenState createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  String _role = 'manager';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    // Basic email validation regex
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    // Check for at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Password must contain at least one uppercase letter';
    }
    // Check for at least one number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Password must contain at least one number';
    }
    return null;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Create user with email and password
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        // Save additional user data to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'role': _role,
          'createdAt': FieldValue.serverTimestamp(),
          'lastUpdated': FieldValue.serverTimestamp(),
          'isActive': true,
          'contactInfo': {
            'email': _emailController.text.trim(),
            'phone': '',
            'address': ''
          }
        });

        // Send email verification
        await userCredential.user!.sendEmailVerification();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Registration successful. Please verify your email.')),
        );

        // Navigate based on role
        Navigator.pushReplacementNamed(
          context,
          _role == 'admin' ? '/admin_dashboard' : '/manager_dashboard',
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';

      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'operation-not-allowed':
          message = 'Email/password registration is not enabled';
          break;
        case 'weak-password':
          message = 'Password is too weak';
          break;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('An unexpected error occurred')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Register'),
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (val) =>
                            val?.isEmpty ?? true ? 'Name is required' : null,
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                          border: OutlineInputBorder(),
                        ),
                        validator: _validateEmail,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: _obscurePassword,
                        validator: _validatePassword,
                        textInputAction: TextInputAction.next,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: 'Confirm Password',
                          prefixIcon: Icon(Icons.lock_clock),
                          suffixIcon: IconButton(
                            icon: Icon(_obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility),
                            onPressed: () => setState(() =>
                                _obscureConfirmPassword =
                                    !_obscureConfirmPassword),
                          ),
                          border: OutlineInputBorder(),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (val) => val != _passwordController.text
                            ? 'Passwords do not match'
                            : null,
                        textInputAction: TextInputAction.done,
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _role,
                        decoration: InputDecoration(
                          labelText: 'Role',
                          prefixIcon: Icon(Icons.work),
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          DropdownMenuItem(
                              value: 'manager', child: Text('Manager')),
                          DropdownMenuItem(
                              value: 'admin', child: Text('Admin')),
                        ],
                        onChanged: (value) => setState(() => _role = value!),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _register,
                        child: Text('Register'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      TextButton(
                        onPressed: () =>
                            Navigator.pushReplacementNamed(context, '/'),
                        child: Text('Already have an account? Login'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';

// class RegistrationScreen extends StatefulWidget {
//   @override
//   _RegistrationScreenState createState() => _RegistrationScreenState();
// }

// class _RegistrationScreenState extends State<RegistrationScreen> {
//   final _formKey = GlobalKey<FormState>();
//   String _email = '';
//   String _password = '';
//   String _confirmPassword = '';
//   String _name = '';
//   String _role = 'manager'; // Options: 'admin', 'manager', 'tenant'
//   bool _isLoading = false;

//   void _register() async {
//     if (!_formKey.currentState!.validate()) return;

//     if (_password != _confirmPassword) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Passwords do not match')),
//       );
//       return;
//     }

//     setState(() {
//       _isLoading = true;
//     });

//     try {
//       // Create user with email and password
//       UserCredential userCredential =
//           await FirebaseAuth.instance.createUserWithEmailAndPassword(
//         email: _email.trim(),
//         password: _password.trim(),
//       );

//       User? user = userCredential.user;

//       if (user != null) {
//         // Save additional user data to Firestore
//         await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
//           'email': _email,
//           'name': _name,
//           'role': _role,
//           'createdAt': Timestamp.now(),
//         });

//         // Navigate to appropriate dashboard based on role
//         if (_role == 'admin') {
//           Navigator.pushReplacementNamed(context, '/admin_dashboard');
//         } else if (_role == 'manager') {
//           Navigator.pushReplacementNamed(context, '/manager_dashboard');
//         } else if (_role == 'tenant') {
//           Navigator.pushReplacementNamed(context, '/tenant_dashboard');
//         } else {
//           // Handle unknown role
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('Registration successful, unknown role')),
//           );
//         }
//       }
//     } on FirebaseAuthException catch (e) {
//       // Handle Firebase authentication errors
//       print('FirebaseAuthException: ${e.code} - ${e.message}');
//       String message = 'Registration failed. Please try again.';
//       if (e.code == 'email-already-in-use') {
//         message = 'The email address is already in use.';
//       } else if (e.code == 'weak-password') {
//         message = 'The password provided is too weak.';
//       } else if (e.code == 'invalid-email') {
//         message = 'The email address is not valid.';
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message)),
//       );
//     } on FirebaseException catch (e) {
//       // Handle Firestore errors
//       print('FirebaseException: ${e.code} - ${e.message}');
//       String message = 'An error occurred while saving data. Please try again.';
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text(message)),
//       );
//     } catch (e) {
//       // Handle any other exceptions
//       print('Exception during registration: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('An unexpected error occurred.')),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }

//   List<DropdownMenuItem<String>> _getRoleDropdownItems() {
//     return [
//       DropdownMenuItem(value: 'manager', child: Text('Manager')),
//       DropdownMenuItem(value: 'admin', child: Text('Admin')),
//       DropdownMenuItem(value: 'tenant', child: Text('Tenant')),
//     ];
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Register'),
//       ),
//       body: _isLoading
//           ? Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: EdgeInsets.all(16.0),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   children: [
//                     // Name Field
//                     TextFormField(
//                       decoration: InputDecoration(labelText: 'Name'),
//                       validator: (val) =>
//                           val == null || val.isEmpty ? 'Enter your name' : null,
//                       onChanged: (val) => _name = val.trim(),
//                     ),
//                     // Email Field
//                     TextFormField(
//                       decoration: InputDecoration(labelText: 'Email'),
//                       validator: (val) =>
//                           val == null || val.isEmpty ? 'Enter an email' : null,
//                       onChanged: (val) => _email = val.trim(),
//                     ),
//                     // Password Field
//                     TextFormField(
//                       decoration: InputDecoration(labelText: 'Password'),
//                       obscureText: true,
//                       validator: (val) => val == null || val.length < 6
//                           ? 'Enter a password 6+ chars long'
//                           : null,
//                       onChanged: (val) => _password = val.trim(),
//                     ),
//                     // Confirm Password Field
//                     TextFormField(
//                       decoration:
//                           InputDecoration(labelText: 'Confirm Password'),
//                       obscureText: true,
//                       validator: (val) =>
//                           val != _password ? 'Passwords do not match' : null,
//                       onChanged: (val) => _confirmPassword = val.trim(),
//                     ),
//                     // Role Dropdown
//                     DropdownButtonFormField<String>(
//                       value: _role,
//                       items: _getRoleDropdownItems(),
//                       onChanged: (value) {
//                         setState(() {
//                           _role = value!;
//                         });
//                       },
//                       decoration: InputDecoration(labelText: 'Role'),
//                     ),
//                     SizedBox(height: 20),
//                     // Register Button
//                     ElevatedButton(
//                       onPressed: _register,
//                       child: Text('Register'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//     );
//   }
// }
