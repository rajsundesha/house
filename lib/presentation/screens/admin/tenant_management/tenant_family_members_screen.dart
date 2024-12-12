import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental_app/data/models/tenant.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';


class TenantFamilyMembersScreen extends StatefulWidget {
  final Tenant tenant;
   List<TenantMember> _familyMembers = [];

  TenantFamilyMembersScreen({required this.tenant});

  @override
  _TenantFamilyMembersScreenState createState() =>
      _TenantFamilyMembersScreenState();
}

class _TenantFamilyMembersScreenState extends State<TenantFamilyMembersScreen> {
  bool _isLoading = false;
  List<TenantMember> _familyMembers = [];

  final _nameController = TextEditingController();
  final _relationController = TextEditingController();
  final _aadharController = TextEditingController();
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _familyMembers = List.from(widget.tenant.familyMembers);
  }

  Future<void> _addFamilyMember() async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Family Member'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _relationController,
                  decoration: InputDecoration(
                    labelText: 'Relation',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _aadharController,
                  decoration: InputDecoration(
                    labelText: 'Aadhar Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (v!.length != 12) return 'Invalid Aadhar number';
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final member = TenantMember(
                  name: _nameController.text.trim(),
                  relation: _relationController.text.trim(),
                  aadharNumber: _aadharController.text.trim(),
                  phoneNumber: _phoneController.text.trim(),
                );
                Navigator.pop(context, member);
              }
            },
            child: Text('ADD'),
          ),
        ],
      ),
  ).then((member) async {
      if (member != null) {
        setState(() => _isLoading = true);
        try {
          final updatedMembers = [..._familyMembers, member as TenantMember];
          await _updateFamilyMembers(updatedMembers);
          setState(() {
            _familyMembers = updatedMembers;
          });
          _clearForm();
        } catch (e) {
          showErrorDialog(context, 'Error adding family member: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _editFamilyMember(TenantMember member, int index) async {
    _nameController.text = member.name;
    _relationController.text = member.relation;
    _aadharController.text = member.aadharNumber;
    _phoneController.text = member.phoneNumber ?? '';

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Family Member'),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _relationController,
                  decoration: InputDecoration(
                    labelText: 'Relation',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _aadharController,
                  decoration: InputDecoration(
                    labelText: 'Aadhar Number',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (v!.length != 12) return 'Invalid Aadhar number';
                    return null;
                  },
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState!.validate()) {
                final updatedMember = TenantMember(
                  name: _nameController.text.trim(),
                  relation: _relationController.text.trim(),
                  aadharNumber: _aadharController.text.trim(),
                  phoneNumber: _phoneController.text.trim(),
                );
                Navigator.pop(context, updatedMember);
              }
            },
            child: Text('UPDATE'),
          ),
        ],
      ),
    ).then((updatedMember) async {
      if (updatedMember != null) {
        setState(() => _isLoading = true);
        try {
          final updatedMembers = List<TenantMember>.from(_familyMembers);
          updatedMembers[index] = updatedMember as TenantMember;
          await _updateFamilyMembers(updatedMembers);
          setState(() {
            _familyMembers = updatedMembers;
          });
          _clearForm();
        } catch (e) {
          showErrorDialog(context, 'Error updating family member: $e');
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
    });
  }

  Future<void> _deleteFamilyMember(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Family Member'),
        content: Text('Are you sure you want to delete this family member?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        final updatedMembers = List<TenantMember>.from(_familyMembers)
          ..removeAt(index);
        await _updateFamilyMembers(updatedMembers);
        setState(() {
          _familyMembers = updatedMembers;
        });
      } catch (e) {
        showErrorDialog(context, 'Error deleting family member: $e');
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateFamilyMembers(List<TenantMember> members) async {
    await FirebaseFirestore.instance
        .collection('tenants')
        .doc(widget.tenant.id)
        .update({
      'familyMembers': members.map((m) => m.toMap()).toList(),
    });
  }

  void _clearForm() {
    _nameController.clear();
    _relationController.clear();
    _aadharController.clear();
    _phoneController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Family Members'),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: _familyMembers.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people_outline, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No family members added'),
                    SizedBox(height: 16),
                    ElevatedButton.icon(
                      icon: Icon(Icons.add),
                      label: Text('Add Family Member'),
                      onPressed: _addFamilyMember,
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: _familyMembers.length,
                itemBuilder: (context, index) {
                  final member = _familyMembers[index];
                  return Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          member.name[0].toUpperCase(),
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                      title: Text(member.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(member.relation),
                          if (member.phoneNumber?.isNotEmpty ?? false)
                            Text('Phone: ${member.phoneNumber}'),
                        ],
                      ),
                      trailing: PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(Icons.edit),
                              title: Text('Edit'),
                            ),
                            value: 'edit',
                          ),
                          PopupMenuItem(
                            child: ListTile(
                              leading: Icon(Icons.delete, color: Colors.red),
                              title: Text('Delete',
                                  style: TextStyle(color: Colors.red)),
                            ),
                            value: 'delete',
                          ),
                        ],
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              _editFamilyMember(member, index);
                              break;
                            case 'delete':
                              _deleteFamilyMember(index);
                              break;
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addFamilyMember,
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _relationController.dispose();
    _aadharController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
