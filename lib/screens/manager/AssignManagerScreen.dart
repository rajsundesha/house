import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/providers/property_provider.dart';

class AssignManagerScreen extends StatefulWidget {
  final String propertyId;
  AssignManagerScreen({required this.propertyId});

  @override
  _AssignManagerScreenState createState() => _AssignManagerScreenState();
}

class _AssignManagerScreenState extends State<AssignManagerScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Map<String, dynamic>> _managers = [];
  String? _selectedManagerId;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchManagers();
  }

  Future<void> _fetchManagers() async {
    setState(() => _isLoading = true);
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'manager')
          .get();

      _managers = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'email': data['contactInfo']?['email'] ?? '',
          'phone': data['contactInfo']?['phone'] ?? '',
        };
      }).toList();
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _assignManager() async {
    if (_selectedManagerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a manager')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Provider.of<PropertyProvider>(context, listen: false)
          .updatePropertyManager(widget.propertyId, _selectedManagerId!);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Manager assigned successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> get filteredManagers {
    if (_searchQuery.isEmpty) return _managers;
    return _managers.where((manager) {
      return manager['name']
              .toLowerCase()
              .contains(_searchQuery.toLowerCase()) ||
          manager['email'].toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Manager'),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search managers...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_errorMessage!),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _fetchManagers,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : filteredManagers.isEmpty
                        ? Center(
                            child: Text('No managers found'),
                          )
                        : ListView.builder(
                            itemCount: filteredManagers.length,
                            itemBuilder: (context, index) {
                              final manager = filteredManagers[index];
                              final isSelected =
                                  manager['id'] == _selectedManagerId;

                              return Card(
                                margin: EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                child: InkWell(
                                  onTap: () {
                                    setState(() =>
                                        _selectedManagerId = manager['id']);
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: isSelected
                                          ? Theme.of(context)
                                              .primaryColor
                                              .withOpacity(0.1)
                                          : null,
                                    ),
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          CircleAvatar(
                                            child: Icon(Icons.person),
                                            backgroundColor: isSelected
                                                ? Theme.of(context)
                                                    .primaryColor
                                                    .withOpacity(0.2)
                                                : Colors.grey.withOpacity(0.2),
                                          ),
                                          SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  manager['name'],
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                if (manager['email'].isNotEmpty)
                                                  Text(
                                                    manager['email'],
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                if (manager['phone'].isNotEmpty)
                                                  Text(
                                                    manager['phone'],
                                                    style: TextStyle(
                                                      color: Colors.grey[600],
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(
                                              Icons.check_circle,
                                              color: Theme.of(context)
                                                  .primaryColor,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _selectedManagerId == null || _isLoading
                ? null
                : _assignManager,
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(_isLoading ? 'Assigning...' : 'Assign Manager'),
            ),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
