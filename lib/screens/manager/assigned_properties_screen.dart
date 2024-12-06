import 'package:flutter/material.dart';
import 'package:house_rental_app/models/property.dart';
import 'package:house_rental_app/providers/property_provider.dart';
import 'package:house_rental_app/models/tenant.dart';
import 'package:house_rental_app/providers/tenant_provider.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class AssignedPropertiesScreen extends StatefulWidget {
  @override
  _AssignedPropertiesScreenState createState() =>
      _AssignedPropertiesScreenState();
}

class _AssignedPropertiesScreenState extends State<AssignedPropertiesScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  List<Property> _properties = [];
  Map<String, List<Tenant>> _propertyTenants = {};
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final managerId = FirebaseAuth.instance.currentUser!.uid;
      final properties =
          await Provider.of<PropertyProvider>(context, listen: false)
              .fetchPropertiesByManagerId(managerId);

      for (var property in properties) {
        _propertyTenants[property.id] =
            await Provider.of<TenantProvider>(context, listen: false)
                .fetchTenantsByPropertyId(property.id);
      }

      setState(() => _properties = properties);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Property> get filteredProperties {
    return _properties.where((property) {
      final matchesSearch =
          property.address.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesStatus = _filterStatus == 'All' ||
          property.status == _filterStatus.toLowerCase();
      return matchesSearch && matchesStatus;
    }).toList();
  }

  Widget _buildPropertyCard(Property property) {
    final tenants = _propertyTenants[property.id] ?? [];
    final formatter = NumberFormat("#,##0.00", "en_US");

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/property_detail',
            arguments: property,
          ).then((_) => _loadProperties());
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.vertical(top: Radius.circular(4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          property.address,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${formatter.format(property.rentAmount)}/month',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: property.status == 'vacant'
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      property.status.toUpperCase(),
                      style: TextStyle(
                        color: property.status == 'vacant'
                            ? Colors.red
                            : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.square_foot, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(property.size),
                      SizedBox(width: 16),
                      Icon(Icons.king_bed, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('${property.bedrooms} bed'),
                      SizedBox(width: 16),
                      Icon(Icons.bathroom, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('${property.bathrooms} bath'),
                    ],
                  ),
                  if (tenants.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Current Tenants',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    ...tenants.map((tenant) {
                      final daysLeft =
                          tenant.leaseEndDate.difference(DateTime.now()).inDays;
                      final isLeaseEnding = daysLeft <= 30;

                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.person_outline,
                                size: 16, color: Colors.grey),
                            SizedBox(width: 8),
                            Expanded(child: Text(tenant.name)),
                            if (isLeaseEnding)
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '$daysLeft days left',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('My Properties'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() => _filterStatus = value);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Vacant', child: Text('Vacant')),
              PopupMenuItem(value: 'Occupied', child: Text('Occupied')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search properties...',
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
                              onPressed: _loadProperties,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadProperties,
                        child: filteredProperties.isEmpty
                            ? Center(
                                child: Text(
                                  _properties.isEmpty
                                      ? 'No properties assigned'
                                      : 'No properties match your search',
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredProperties.length,
                                itemBuilder: (context, index) {
                                  return _buildPropertyCard(
                                      filteredProperties[index]);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
