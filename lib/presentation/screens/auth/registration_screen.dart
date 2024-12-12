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
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'email': _emailController.text.trim(),
          'name': _nameController.text.trim(),
          'role': _role,
          'createdAt': FieldValue.serverTimestamp(),
          'contactInfo': {
            'email': _emailController.text.trim(),
            'phone': '',
            'address': ''
          }
        });

        // Send email verification if needed
        await userCredential.user!.sendEmailVerification();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Registration successful. Verify your email.')));

        // Navigate based on role
        if (_role == 'admin') {
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
        } else {
          Navigator.pushReplacementNamed(context, '/manager_dashboard');
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Registration failed';
      switch (e.code) {
        case 'email-already-in-use':
          message = 'Email already registered';
          break;
        case 'invalid-email':
          message = 'Invalid email address';
          break;
        case 'weak-password':
          message = 'Password too weak';
          break;
      }
      _errorMessage = message;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage!)));
    } catch (e) {
      _errorMessage = 'Unexpected error: ${e.toString()}';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage!)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
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
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Name is required' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(),
                      ),
                      validator: (val) {
                        if (val?.isEmpty ?? true) return 'Email required';
                        if (!val!.contains('@')) return 'Invalid email';
                        return null;
                      },
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
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Password required';
                        if (v.length < 6) return 'Must be >=6 chars';
                        if (!v.contains(RegExp(r'[A-Z]')))
                          return 'At least one uppercase';
                        if (!v.contains(RegExp(r'[0-9]')))
                          return 'At least one number';
                        return null;
                      },
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
                      validator: (val) {
                        if (val != _passwordController.text)
                          return 'Passwords do not match';
                        return null;
                      },
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
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      ],
                      onChanged: (val) => setState(() => _role = val!),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      child: Text('Register'),
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
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }
}
