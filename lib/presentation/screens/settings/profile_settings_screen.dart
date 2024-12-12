
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:house_rental_app/data/models/user.dart';


class ProfileSettingsScreen extends StatefulWidget {
  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  String? _profileImageUrl;
  File? _newProfileImage;

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        final doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          final userData = doc.data() as Map<String, dynamic>;
          setState(() {
            _nameController.text = userData['name'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _phoneController.text = userData['phone'] ?? '';
            _addressController.text = userData['address'] ?? '';
            _profileImageUrl = userData['profileImage'];
          });
        }
      }
    } catch (e) {
      showErrorDialog(context, 'Error loading profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final imagePicker = ImagePicker();
      final pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
      
      if (pickedFile != null) {
        setState(() {
          _newProfileImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      showErrorDialog(context, 'Error picking image: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      String? imageUrl = _profileImageUrl;

      // Upload new image if selected
      if (_newProfileImage != null) {
        final ref = _storage.ref().child('profile_images/$userId');
        await ref.putFile(_newProfileImage!);
        imageUrl = await ref.getDownloadURL();
      }

      // Update profile data
      await _firestore.collection('users').doc(userId).update({
        'name': _nameController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'profileImage': imageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Update email if changed
      final currentUser = _auth.currentUser;
      if (currentUser != null &&
          currentUser.email != _emailController.text) {
        await currentUser.updateEmail(_emailController.text);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully')),
      );
    } catch (e) {
      showErrorDialog(context, 'Error updating profile: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile Settings'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveProfile,
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundImage: _newProfileImage != null
                            ? FileImage(_newProfileImage!)
                            : _profileImageUrl != null
                                ? NetworkImage(_profileImageUrl!)
                                : null,
                        child: _newProfileImage == null &&
                                _profileImageUrl == null
                            ? Icon(Icons.person, size: 60)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (!v!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
 
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (v!.length < 10) return 'Invalid phone number';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _addressController,
                  decoration: InputDecoration(
                    labelText: 'Address',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on),
                  ),
                  maxLines: 3,
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Account Security',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        ListTile(
                          leading: Icon(Icons.lock),
                          title: Text('Change Password'),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.pushNamed(context, '/change_password');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.security),
                          title: Text('Two-Factor Authentication'),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Implement 2FA setup
                            Navigator.pushNamed(context, '/two_factor_auth');
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.visibility),
                          title: Text('Privacy Settings'),
                          trailing: Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            Navigator.pushNamed(context, '/privacy_settings');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Connected Accounts',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        SizedBox(height: 16),
                        ListTile(
                          leading: Icon(Icons.phone_android),
                          title: Text('Phone Number Verification'),
                          subtitle: Text(_phoneController.text.isNotEmpty
                              ? 'Verified'
                              : 'Not verified'),
                          trailing: TextButton(
                            onPressed: () {
                              // Implement phone verification
                              Navigator.pushNamed(context, '/verify_phone');
                            },
                            child: Text(_phoneController.text.isNotEmpty
                                ? 'Change'
                                : 'Verify'),
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.email),
                          title: Text('Email Verification'),
                          subtitle: Text(_auth.currentUser?.emailVerified ?? false
                              ? 'Verified'
                              : 'Not verified'),
                          trailing: TextButton(
                            onPressed: () async {
                              if (!(_auth.currentUser?.emailVerified ?? false)) {
                                try {
                                  await _auth.currentUser?.sendEmailVerification();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content:
                                          Text('Verification email sent'),
                                    ),
                                  );
                                } catch (e) {
                                  showErrorDialog(
                                      context, 'Error sending verification email: $e');
                                }
                              }
                            },
                            child: Text(_auth.currentUser?.emailVerified ?? false
                                ? 'Verified'
                                : 'Verify'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Danger Zone',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(color: Colors.red),
                        ),
                        SizedBox(height: 16),
                        ListTile(
                          leading: Icon(Icons.delete_forever, color: Colors.red),
                          title: Text(
                            'Delete Account',
                            style: TextStyle(color: Colors.red),
                          ),
                          onTap: () async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Delete Account'),
                                content: Text(
                                    'Are you sure you want to delete your account? This action cannot be undone.'),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text('CANCEL'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: Text(
                                      'DELETE',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirmed == true) {
                              try {
                                setState(() => _isLoading = true);
                                // Delete user data
                                final userId = _auth.currentUser?.uid;
                                if (userId != null) {
                                  // Delete profile image
                                  if (_profileImageUrl != null) {
                                    await _storage
                                        .refFromURL(_profileImageUrl!)
                                        .delete();
                                  }
                                  // Delete user document
                                  await _firestore
                                      .collection('users')
                                      .doc(userId)
                                      .delete();
                                }
                                // Delete authentication account
                                await _auth.currentUser?.delete();
                                // Navigate to login
                                Navigator.of(context)
                                    .pushReplacementNamed('/login');
                              } catch (e) {
                                showErrorDialog(
                                    context, 'Error deleting account: $e');
                              } finally {
                                if (mounted) {
                                  setState(() => _isLoading = false);
                                }
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ),
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
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
