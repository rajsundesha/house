import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/user_provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';

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

  @override
  void initState() {
    super.initState();
    _fetchManagers();
  }

  Future<void> _fetchManagers() async {
    setState(() => _isLoading = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final mgrs = await userProvider.fetchUsersByRole('manager');
      _managers = mgrs.map((m) {
        return {
          'id': m.uid,
          'name': m.name,
          'email': m.contactInfo['email'] ?? ''
        };
      }).toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          .assignManager(widget.propertyId, _selectedManagerId!);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Manager assigned successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      _errorMessage = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Assign Manager'),
      ),
      body: _isLoading
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
              : Column(
                  children: [
                    Expanded(
                      child: _managers.isEmpty
                          ? Center(child: Text('No managers available'))
                          : ListView.builder(
                              itemCount: _managers.length,
                              itemBuilder: (context, index) {
                                final manager = _managers[index];
                                final isSelected =
                                    manager['id'] == _selectedManagerId;
                                return Card(
                                  margin: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: InkWell(
                                    onTap: () => setState(() =>
                                        _selectedManagerId = manager['id']),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Theme.of(context)
                                                .primaryColor
                                                .withOpacity(0.1)
                                            : null,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
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
                                                Text(manager['name'],
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold)),
                                                if (manager['email'].isNotEmpty)
                                                  Text(manager['email'],
                                                      style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontSize: 14))
                                              ],
                                            ),
                                          ),
                                          if (isSelected)
                                            Icon(Icons.check_circle,
                                                color: Theme.of(context)
                                                    .primaryColor),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _assignManager,
                        child: Text(
                            _isLoading ? 'Assigning...' : 'Assign Manager'),
                      ),
                    ),
                  ],
                ),
    );
  }
}
