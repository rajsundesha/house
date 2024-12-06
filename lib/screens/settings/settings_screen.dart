class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          _buildSection(
            'Account',
            [
              _buildSettingTile(
                'Profile',
                Icons.person,
                () => Navigator.pushNamed(context, '/profile'),
              ),
              _buildSettingTile(
                'Security',
                Icons.security,
                () => Navigator.pushNamed(context, '/security'),
              ),
              _buildSettingTile(
                'Notifications',
                Icons.notifications,
                () => Navigator.pushNamed(context, '/notifications'),
              ),
            ],
          ),
          _buildSection(
            'App Settings',
            [
              _buildSettingTile(
                'Language',
                Icons.language,
                () => _showLanguageDialog(context),
              ),
              _buildSettingTile(
                'Theme',
                Icons.palette,
                () => _showThemeDialog(context),
              ),
              _buildSettingTile(
                'Currency',
                Icons.currency_rupee,
                () => _showCurrencyDialog(context),
              ),
            ],
          ),
          _buildSection(
            'Help & Support',
            [
              _buildSettingTile(
                'Documentation',
                Icons.book,
                () => _launchDocumentation(),
              ),
              _buildSettingTile(
                'Contact Support',
                Icons.support_agent,
                () => _contactSupport(context),
              ),
              _buildSettingTile(
                'About',
                Icons.info,
                () => _showAboutDialog(context),
              ),
            ],
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Colors.red),
            title: Text('Logout'),
            onTap: () => _logout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> tiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),
        ...tiles,
      ],
    );
  }

  Widget _buildSettingTile(
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  Future<void> _logout(BuildContext context) async {
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
            child: Text('Logout'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.pushReplacementNamed(context, '/login');
    }
  }
}
