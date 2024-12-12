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
  List _managers = [];
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
      _managers = mgrs
          .map((m) => {
                'id': m.uid,
                'name': m.name,
                'email': m.contactInfo['email'] ?? ''
              })
          .toList();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _assignManager() async {
    if (_selectedManagerId == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Select a manager')));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await Provider.of<PropertyProvider>(context, listen: false)
          .assignManager(widget.propertyId, _selectedManagerId!);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Manager assigned successfully')));
      Navigator.pop(context);
    } catch (e) {
      _errorMessage = e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage!)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Assign Manager')),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                        child: _managers.isEmpty
                            ? Center(child: Text('No managers available'))
                            : ListView.builder(
                                itemCount: _managers.length,
                                itemBuilder: (context, index) {
                                  final mgr = _managers[index];
                                  final isSelected =
                                      (mgr['id'] == _selectedManagerId);
                                  return Card(
                                    margin: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    child: InkWell(
                                      onTap: () => setState(
                                          () => _selectedManagerId = mgr['id']),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Theme.of(context)
                                                  .primaryColor
                                                  .withOpacity(0.1)
                                              : null,
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                                    : Colors.grey
                                                        .withOpacity(0.2)),
                                            SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(mgr['name'],
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold)),
                                                  if (mgr['email'].isNotEmpty)
                                                    Text(mgr['email'],
                                                        style: TextStyle(
                                                            color: Colors
                                                                .grey[600],
                                                            fontSize: 14))
                                                ],
                                              ),
                                            ),
                                            if (isSelected)
                                              Icon(Icons.check_circle,
                                                  color: Theme.of(context)
                                                      .primaryColor)
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              )),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: ElevatedButton(
                        onPressed: _assignManager,
                        child: Text(
                            _isLoading ? 'Assigning...' : 'Assign Manager'),
                      ),
                    )
                  ],
                ),
    );
  }
}
