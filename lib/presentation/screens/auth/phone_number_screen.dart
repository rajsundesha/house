import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PhoneNumberScreen extends StatefulWidget {
  @override
  _PhoneNumberScreenState createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyPhoneNumber() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _phoneController.text.trim(),
        timeout: Duration(seconds: 60),
        verificationCompleted: (credential) async {
          // Auto verification can happen here
        },
        verificationFailed: (e) {
          setState(() {
            _isLoading = false;
            _errorMessage = e.message ?? 'Verification failed';
          });
        },
        codeSent: (verificationId, resendToken) {
          setState(() => _isLoading = false);
          Navigator.pushNamed(context, '/otp_verification', arguments: {
            'verificationId': verificationId,
            'phoneNumber': _phoneController.text.trim(),
            'resendToken': resendToken
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {},
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _errorMessage = e.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login with Phone')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 32),
                Text('Enter your phone number',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center),
                SizedBox(height: 8),
                Text('We will send a verification code',
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
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (val) {
                    if (val?.isEmpty ?? true) return 'Enter your phone number';
                    // Basic validation
                    // Ensure it starts with country code if needed, or just +91 for india etc.
                    // For simplicity assume user enters full number with country code
                    return null;
                  },
                ),
                SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _verifyPhoneNumber,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white)))
                      : Text('Send Verification Code'),
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: Text('Use Email Instead'),
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
    _phoneController.dispose();
    super.dispose();
  }
}
