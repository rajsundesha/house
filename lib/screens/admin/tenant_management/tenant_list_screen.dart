import 'package:flutter/material.dart';
import 'package:house_rental_app/models/tenant.dart';
import 'package:house_rental_app/models/property.dart';
import 'package:house_rental_app/providers/tenant_provider.dart';
import 'package:house_rental_app/providers/property_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class TenantListScreen extends StatefulWidget {
  @override
  _TenantListScreenState createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterCategory = 'All';
  final _searchController = TextEditingController();
  Map<String, Property> _propertyCache = {};

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Provider.of<TenantProvider>(context, listen: false).fetchTenants();

      // Pre-load property details
      final tenants =
          Provider.of<TenantProvider>(context, listen: false).tenants;
      final propertyIds = tenants.map((t) => t.propertyId).toSet();

      for (var propertyId in propertyIds) {
        final property =
            await Provider.of<PropertyProvider>(context, listen: false)
                .getPropertyById(propertyId);
        if (property != null) {
          _propertyCache[propertyId] = property;
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Tenants'),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Category'),
                DropdownButton<String>(
                  value: _filterCategory,
                  isExpanded: true,
                  items: ['All', 'Family', 'Company', 'Student']
                      .map((category) => DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() => _filterCategory = value!);
                  },
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadTenants();
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildTenantCard(Tenant tenant) {
    final property = _propertyCache[tenant.propertyId];
    final daysLeft = tenant.leaseEndDate.difference(DateTime.now()).inDays;
    final isLeaseEnding = daysLeft <= 30;

    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/tenant_detail',
            arguments: tenant,
          ).then((_) => _loadTenants());
        },
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    child: Icon(Icons.person),
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tenant.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          tenant.category,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isLeaseEnding
                          ? Colors.red.withOpacity(0.1)
                          : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isLeaseEnding ? 'Lease ending soon' : 'Active',
                      style: TextStyle(
                        color: isLeaseEnding ? Colors.red : Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12),
              if (property != null) ...[
                Row(
                  children: [
                    Icon(Icons.home, size: 16, color: Colors.grey),
                    SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        property.address,
                        style: TextStyle(color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
              ],
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                  SizedBox(width: 4),
                  Text(
                    'Lease ends: ${DateFormat('MMM dd, yyyy').format(tenant.leaseEndDate)}',
                    style: TextStyle(
                      color: isLeaseEnding ? Colors.red : Colors.grey[600],
                      fontWeight: isLeaseEnding ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenants'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.pushNamed(context, '/add_tenant')
                  .then((_) => _loadTenants());
            },
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
                hintText: 'Search tenants...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value.toLowerCase());
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error'),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadTenants,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : Consumer<TenantProvider>(
                        builder: (context, tenantProvider, child) {
                          var tenants = tenantProvider.tenants;

                          if (_searchQuery.isNotEmpty) {
                            tenants = tenants.where((tenant) {
                              return tenant.name
                                      .toLowerCase()
                                      .contains(_searchQuery) ||
                                  (_propertyCache[tenant.propertyId]
                                              ?.address
                                              .toLowerCase() ??
                                          '')
                                      .contains(_searchQuery);
                            }).toList();
                          }

                          if (_filterCategory != 'All') {
                            tenants = tenants
                                .where((tenant) =>
                                    tenant.category == _filterCategory)
                                .toList();
                          }

                          if (tenants.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline,
                                    size: 64,
                                    color: Colors.grey,
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'No tenants found',
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Try adjusting your filters',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: Colors.grey,
                                        ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return RefreshIndicator(
                            onRefresh: _loadTenants,
                            child: ListView.builder(
                              padding: EdgeInsets.all(8),
                              itemCount: tenants.length,
                              itemBuilder: (context, index) =>
                                  _buildTenantCard(tenants[index]),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/add_tenant')
              .then((_) => _loadTenants());
        },
        child: Icon(Icons.add),
        tooltip: 'Add Tenant',
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
