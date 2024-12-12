import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (userCredential.user == null)
        throw FirebaseAuthException(code: 'null-user', message: 'Login failed');
      final uid = userCredential.user!.uid;
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!doc.exists)
        throw FirebaseAuthException(
            code: 'user-not-found', message: 'User data not found');
      final data = doc.data()!;
      final role = data['role'] ?? 'manager'; // default manager

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else if (role == 'manager') {
        Navigator.pushReplacementNamed(context, '/manager_dashboard');
      } else {
        // If tenant route is available, use it. If not, handle gracefully.
        Navigator.pushReplacementNamed(context, '/');
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Error during login';
    } catch (e) {
      _errorMessage = 'Unexpected error: ${e.toString()}';
    } finally {
      if (mounted) setState(() => _isLoading = false);
      if (_errorMessage != null) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorMessage!)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 32),
                Text('Welcome Back',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center),
                SizedBox(height: 8),
                Text('Login to continue',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey)),
                SizedBox(height: 32),
                if (_errorMessage != null)
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(_errorMessage!,
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                  ),
                if (_errorMessage != null) SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  validator: (val) {
                    if (val?.isEmpty ?? true) return 'Enter your email';
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
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  obscureText: _obscurePassword,
                  validator: (val) {
                    if (val?.isEmpty ?? true) return 'Enter your password';
                    return null;
                  },
                  onFieldSubmitted: (_) => _login(),
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white)))
                      : Text('Login'),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pushNamed(context, '/register'),
                  child: Text("Don't have an account? Register"),
                ),
                SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => Navigator.pushNamed(context, '/phone_login'),
                  icon: Icon(Icons.phone),
                  label: Text('Login with Phone Number'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
