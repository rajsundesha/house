import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  ThemeMode _themeMode = ThemeMode.light;

  Future<void> _showLogoutDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Logout'),
        content: Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          // Profile Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Settings',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SizedBox(height: 16),
                  ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    title: Text('Edit Profile'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () => Navigator.pushNamed(context, '/edit_profile'),
                  ),
                  ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.lock),
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    title: Text('Change Password'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.pushNamed(context, '/change_password'),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Preferences Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferences',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  SwitchListTile(
                    title: Text('Notifications'),
                    subtitle: Text('Enable push notifications'),
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() => _notificationsEnabled = value);
                    },
                  ),
                  ListTile(
                    title: Text('Theme'),
                    subtitle:
                        Text(_themeMode == ThemeMode.light ? 'Light' : 'Dark'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Select Theme'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RadioListTile<ThemeMode>(
                                title: Text('Light'),
                                value: ThemeMode.light,
                                groupValue: _themeMode,
                                onChanged: (value) {
                                  setState(() => _themeMode = value!);
                                  Navigator.pop(context);
                                },
                              ),
                              RadioListTile<ThemeMode>(
                                title: Text('Dark'),
                                value: ThemeMode.dark,
                                groupValue: _themeMode,
                                onChanged: (value) {
                                  setState(() => _themeMode = value!);
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // About Section
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ListTile(
                    title: Text('App Version'),
                    trailing: Text('1.0.0'),
                  ),
                  ListTile(
                    title: Text('Terms of Service'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      // Show terms of service dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Terms of Service'),
                          content: SingleChildScrollView(
                            child:
                                Text('Your terms of service content here...'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: Text('Privacy Policy'),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      // Show privacy policy dialog
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('Privacy Policy'),
                          content: SingleChildScrollView(
                            child: Text('Your privacy policy content here...'),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Logout Button
          ElevatedButton(
            onPressed: _showLogoutDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Logout',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
