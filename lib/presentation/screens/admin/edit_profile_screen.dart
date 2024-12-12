import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/user_provider.dart';
import 'package:house_rental_app/data/models/user.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final userData = await userProvider.getUserById(currentUser.uid);
        if (userData != null) {
          _nameController.text = userData.name;
          _emailController.text = userData.contactInfo['email'] ?? '';
          _phoneController.text = userData.contactInfo['phone'] ?? '';
          _addressController.text = userData.contactInfo['address'] ?? '';
        }
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        final updatedUser = AppUser(
          uid: currentUser.uid,
          name: _nameController.text.trim(),
          role: 'admin', // Preserve existing role
          contactInfo: {
            'email': _emailController.text.trim(),
            'phone': _phoneController.text.trim(),
            'address': _addressController.text.trim(),
          },
          createdAt: DateTime
              .now(), // You might want to preserve the original creation date
        );

        await userProvider.updateUser(updatedUser);

        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully')));

        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $_error')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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

                    // Profile Picture
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 50,
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                            child: Icon(
                              Icons.person,
                              size: 50,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.camera_alt,
                                size: 20,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),

                    // Name Field
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return 'Please enter your name';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      readOnly: true, // Email cannot be changed
                      enabled: false,
                    ),
                    SizedBox(height: 16),

                    // Phone Field
                    TextFormField(
                      controller: _phoneController,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return 'Please enter your phone number';
                        if (value!.length < 10)
                          return 'Please enter a valid phone number';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),

                    // Address Field
                    TextFormField(
                      controller: _addressController,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: Icon(Icons.location_on),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return 'Please enter your address';
                        return null;
                      },
                    ),
                    SizedBox(height: 24),

                    // Save Button
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveProfile,
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
                          : Text('Save Changes'),
                    ),
                  ],
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
