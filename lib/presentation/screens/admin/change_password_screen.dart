import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      // Re-authenticate user
      final user = FirebaseAuth.instance.currentUser;
      final credential = EmailAuthProvider.credential(
        email: user?.email ?? '',
        password: _currentPasswordController.text,
      );

      await user?.reauthenticateWithCredential(credential);
      await user?.updatePassword(_newPasswordController.text);

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password updated successfully')));
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        switch (e.code) {
          case 'wrong-password':
            _error = 'Current password is incorrect';
            break;
          case 'weak-password':
            _error = 'New password is too weak';
            break;
          default:
            _error = e.message;
        }
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_error ?? 'An error occurred')));
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_error ?? 'An error occurred')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Change Password'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error != null)
                Container(
                  padding: EdgeInsets.all(8),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red),
                  ),
                ),

              // Current Password
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureCurrentPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(() =>
                        _obscureCurrentPassword = !_obscureCurrentPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                obscureText: _obscureCurrentPassword,
                validator: (value) {
                  if (value?.isEmpty ?? true)
                    return 'Please enter your current password';
                  return null;
                },
              ),
              SizedBox(height: 16),

              // New Password
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureNewPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(
                        () => _obscureNewPassword = !_obscureNewPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                obscureText: _obscureNewPassword,
                validator: (value) {
                  if (value?.isEmpty ?? true)
                    return 'Please enter a new password';
                  if (value!.length < 6)
                    return 'Password must be at least 6 characters';
                  // if (!value.contains(RegExp(r'[A-Z]')))
                  //   return 'Password must contain at least one uppercase letter';
                  // if (!value.contains(RegExp(r'[0-9]')))
                  //   return 'Password must contain at least one number';
                  return null;
                },
              ),
              SizedBox(height: 16),

              // Confirm Password
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                obscureText: _obscureConfirmPassword,
                validator: (value) {
                  if (value?.isEmpty ?? true)
                    return 'Please confirm your new password';
                  if (value != _newPasswordController.text)
                    return 'Passwords do not match';
                  return null;
                },
              ),
              SizedBox(height: 24),

              // Change Password Button
              ElevatedButton(
                onPressed: _isLoading ? null : _changePassword,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('Change Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
