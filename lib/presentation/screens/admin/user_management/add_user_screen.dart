import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:house_rental_app/data/models/user.dart';
import 'package:house_rental_app/presentation/providers/user_provider.dart';

class AddUserScreen extends StatefulWidget {
  @override
  _AddUserScreenState createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedRole = 'manager';
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (userCredential.user != null) {
        AppUser newUser = AppUser(
          uid: userCredential.user!.uid,
          role: _selectedRole,
          name: _nameController.text.trim(),
          contactInfo: {'email': _emailController.text.trim()},
          createdAt: DateTime.now(),
        );

        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.addUser(newUser);

        if (userProvider.error != null) {
          _errorMessage = userProvider.error;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(_errorMessage!)));
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('User created successfully')));
          Navigator.pop(context);
        }
      }
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.message ?? 'Failed to create user';
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
      appBar: AppBar(title: Text('Add New User')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v?.isEmpty ?? true ? 'Please enter a name' : null,
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) {
                        if (v?.isEmpty ?? true) return 'Enter an email';
                        if (!v!.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      obscureText: true,
                      validator: (v) => v != null && v.length < 6
                          ? 'Password must be >=6 chars'
                          : null,
                    ),
                    SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      decoration: InputDecoration(
                        labelText: 'Role',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(value: 'admin', child: Text('Admin')),
                        DropdownMenuItem(
                            value: 'manager', child: Text('Manager')),
                      ],
                      onChanged: (val) => setState(() => _selectedRole = val!),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _createUser,
                      child: Text('Create User'),
                    )
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
    _nameController.dispose();
    super.dispose();
  }
}
