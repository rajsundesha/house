import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final int? resendToken;

  OTPVerificationScreen(
      {required this.verificationId,
      required this.phoneNumber,
      this.resendToken});

  @override
  _OTPVerificationScreenState createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyOTP() async {
    if (_otpController.text.length != 6) {
      setState(() => _errorMessage = 'Please enter valid 6-digit code');
      return;
    }

    setState(() => _isLoading = true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpController.text.trim(),
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);
      if (userCredential.user == null)
        throw FirebaseAuthException(code: 'null-user', message: 'Login failed');
      // Fetch user role from Firestore (similar to login)
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();
      if (!doc.exists)
        throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'No user found with this phone number');
      final data = doc.data()!;
      final role = data['role'] as String;

      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin_dashboard');
      } else if (role == 'manager') {
        Navigator.pushReplacementNamed(context, '/manager_dashboard');
      } else {
        Navigator.pushReplacementNamed(context, '/');
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = e.message ?? 'Verification failed');
    } catch (e) {
      setState(() => _errorMessage = 'Verification failed: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Verify Phone Number')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Verification Code',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center),
              SizedBox(height: 8),
              Text('Enter the code sent to ${widget.phoneNumber}',
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
              SizedBox(height: 16),
              TextField(
                controller: _otpController,
                decoration: InputDecoration(
                  labelText: 'OTP',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
              ),
              SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOTP,
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)))
                    : Text('Verify Code'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
