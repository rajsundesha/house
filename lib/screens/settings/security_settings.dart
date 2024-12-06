class SecuritySettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Security')),
      body: ListView(
        children: [
          _buildPasswordSection(),
          _buildTwoFactorSection(),
          _buildLoginHistorySection(),
        ],
      ),
    );
  }

  Widget _buildPasswordSection() {
    return SecuritySection(
      title: 'Password',
      children: [
        PasswordChangeForm(),
        SwitchListTile(
          title: Text('Require password for sensitive actions'),
          value: true,
          onChanged: (value) {},
        ),
      ],
    );
  }
}
