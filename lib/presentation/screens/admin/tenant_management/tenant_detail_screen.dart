import 'package:flutter/material.dart';
import 'package:house_rental_app/data/models/tenant.dart';
import 'package:house_rental_app/presentation/providers/tenant_provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class TenantDetailScreen extends StatefulWidget {
  final Tenant tenant;

  TenantDetailScreen({required this.tenant});

  @override
  _TenantDetailScreenState createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _deleteTenant() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Tenant'),
        content: Text('Are you sure you want to delete this tenant?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      await Provider.of<TenantProvider>(context, listen: false)
          .deleteTenant(widget.tenant.id);
      // Possibly set property vacant if no other tenants
      final propertyId = widget.tenant.propertyId;
      final tenants = await Provider.of<TenantProvider>(context, listen: false)
          .fetchTenantsByPropertyId(propertyId);
      if (tenants.isEmpty) {
        await Provider.of<PropertyProvider>(context, listen: false)
            .updatePropertyStatus(propertyId, 'vacant');
      }
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Tenant deleted')));
      Navigator.pop(context);
    } catch (e) {
      _errorMessage = e.toString();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $_errorMessage')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tenant = widget.tenant;
    final daysLeft = tenant.leaseEndDate.difference(DateTime.now()).inDays;
    final isLeaseEnding = daysLeft <= 30;

    return Scaffold(
      appBar: AppBar(
        title: Text('Tenant Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteTenant,
          )
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null)
                    Container(
                      color: Colors.red.shade50,
                      padding: EdgeInsets.all(8),
                      child: Text(_errorMessage!,
                          style: TextStyle(color: Colors.red)),
                    ),
                  Row(
                    children: [
                      CircleAvatar(
                        child: Icon(Icons.person),
                        radius: 30,
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tenant.name,
                              style: Theme.of(context).textTheme.headlineLarge,
                            ),
                            Text(
                              tenant.category,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Divider(height: 32),
                  _buildInfoRow('Phone', tenant.contactInfo['phone'] ?? 'N/A'),
                  _buildInfoRow('Email', tenant.contactInfo['email'] ?? 'N/A'),
                  SizedBox(height: 16),
                  Text('Lease Information',
                      style: Theme.of(context).textTheme.headlineLarge),
                  Divider(),
                  _buildInfoRow('Start Date',
                      DateFormat('yyyy-MM-dd').format(tenant.leaseStartDate)),
                  _buildInfoRow('End Date',
                      DateFormat('yyyy-MM-dd').format(tenant.leaseEndDate)),
                  if (tenant.advancePaid)
                    _buildInfoRow('Advance Amount',
                        '₹${tenant.advanceAmount.toStringAsFixed(2)}'),
                  if (tenant.rentAdjustment > 0)
                    _buildInfoRow('Rent Adjustment',
                        '-₹${tenant.rentAdjustment.toStringAsFixed(2)}'),
                  SizedBox(height: 16),
                  if (isLeaseEnding)
                    Container(
                      padding: EdgeInsets.all(8),
                      color: Colors.orange.shade50,
                      child: Text('$daysLeft days left until lease ends',
                          style: TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold)),
                    ),
                  SizedBox(height: 16),
                  Text('Family Members',
                      style: Theme.of(context).textTheme.headlineLarge),
                  Divider(),
                  tenant.familyMembers.isEmpty
                      ? Text('No family members added')
                      : Column(
                          children: tenant.familyMembers.map((m) {
                            return ListTile(
                              title: Text(m.name),
                              subtitle: Text(
                                  '${m.relation}, Aadhar: ${m.aadharNumber}'),
                            );
                          }).toList(),
                        ),
                  SizedBox(height: 16),
                  Text('Documents',
                      style: Theme.of(context).textTheme.headlineLarge),
                  Divider(),
                  tenant.documents.isEmpty
                      ? Text('No documents uploaded')
                      : Column(
                          children: tenant.documents.map((d) {
                            // Since there's no `name` in TenantDocument, we use documentId or fallback to type
                            final docTitle = d.documentId.isNotEmpty
                                ? d.documentId
                                : d.type.toUpperCase();
                            return ListTile(
                              leading: Icon(Icons.description),
                              title: Text(docTitle),
                              subtitle: Text(
                                'Uploaded: ${DateFormat('yyyy-MM-dd').format(d.uploadedAt)}',
                              ),
                              onTap: () {
                                // Could open viewer if implemented
                              },
                            );
                          }).toList(),
                        )
                ],
              ),
            ),
    );
  }
}
