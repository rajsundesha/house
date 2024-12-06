import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class PhoneLoginScreen extends StatefulWidget {
  @override
  _PhoneLoginScreenState createState() => _PhoneLoginScreenState();
}

class _PhoneLoginScreenState extends State<PhoneLoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _completePhoneNumber = '';
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyPhoneNumber() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: _completePhoneNumber,
        timeout: Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-verification on Android
          try {
            await _signInWithCredential(credential);
          } catch (e) {
            print("Error in auto verification: $e");
            setState(() {
              _isLoading = false;
              _errorMessage = 'Auto-verification failed. Please try again.';
            });
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          print("Verification Failed: ${e.message}");
          setState(() {
            _isLoading = false;
            switch (e.code) {
              case 'invalid-phone-number':
                _errorMessage = 'Invalid phone number format';
                break;
              case 'too-many-requests':
                _errorMessage = 'Too many attempts. Please try again later';
                break;
              default:
                _errorMessage = e.message ?? 'Verification failed';
            }
          });
        },
        codeSent: (String verificationId, int? resendToken) {
          print("Code Sent to $_completePhoneNumber");
          setState(() => _isLoading = false);
          Navigator.pushNamed(
            context,
            '/otp_verification',
            arguments: {
              'verificationId': verificationId,
              'phoneNumber': _completePhoneNumber,
              'resendToken': resendToken,
            },
          );
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          print("Auto Retrieval Timeout");
        },
      );
    } catch (e) {
      print("Error in phone verification: $e");
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to verify phone number. Please try again.';
      });
    }
  }

  Future<void> _signInWithCredential(PhoneAuthCredential credential) async {
    try {
      final userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user == null) throw Exception('Login failed');

      // Check if user exists in Firestore
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User not found in database');
      }

      final userData = userDoc.data()!;

      // Update last login
      await userDoc.reference.update({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'phoneNumber': _completePhoneNumber,
      });

      if (!mounted) return;

      // Navigate based on role
      final role = userData['role'] as String;
      switch (role) {
        case 'admin':
          Navigator.pushReplacementNamed(context, '/admin_dashboard');
          break;
        case 'manager':
          Navigator.pushReplacementNamed(context, '/manager_dashboard');
          break;
        default:
          throw Exception('Invalid user role');
      }
    } catch (e) {
      print("Error in sign in: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Authentication failed. Please try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Login with Phone'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 32),
                Text(
                  'Enter your phone number',
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Text(
                  'We will send you a verification code',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32),
                if (_errorMessage != null) ...[
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16),
                ],
                IntlPhoneField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  initialCountryCode: 'IN', // Change this based on your region
                  onChanged: (phone) {
                    _completePhoneNumber = phone.completeNumber;
                    if (_errorMessage != null) {
                      setState(() => _errorMessage = null);
                    }
                  },
                  disableLengthCheck: false,
                  invalidNumberMessage: 'Invalid phone number',
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
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text('Send Verification Code'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
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
