import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/user_provider.dart';
import 'package:house_rental_app/data/models/user.dart';

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.fetchUsers();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final filteredUsers = userProvider.users.where((u) {
      return u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.contactInfo['email']
                  ?.toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ==
              true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users'),
        actions: [
          IconButton(
              icon: Icon(Icons.add),
              onPressed: () => Navigator.pushNamed(context, '/add_user')
                  .then((_) => _loadUsers())),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _loadUsers, child: Text('Retry'))
                    ],
                  ),
                )
              : Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search users...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (val) => setState(() => _searchQuery = val),
                      ),
                    ),
                    Expanded(
                      child: filteredUsers.isEmpty
                          ? Center(child: Text('No users found'))
                          : ListView.builder(
                              itemCount: filteredUsers.length,
                              itemBuilder: (context, index) {
                                final user = filteredUsers[index];
                                return ListTile(
                                  leading:
                                      CircleAvatar(child: Icon(Icons.person)),
                                  title: Text(user.name),
                                  subtitle: Text(
                                      'Role: ${user.role}\nEmail: ${user.contactInfo['email'] ?? ''}'),
                                );
                              }),
                    )
                  ],
                ),
    );
  }
}
