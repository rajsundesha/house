import 'package:flutter/material.dart';
import 'package:house_rental_app/models/property.dart';
import 'package:house_rental_app/providers/property_provider.dart';
import 'package:house_rental_app/utils/currency_utils.dart';
import 'package:provider/provider.dart';

// Property Filter Component
class PropertyFilter extends StatelessWidget {
  final String filterStatus;
  final bool sortByRentAscending;
  final Function(String) onStatusChanged;
  final Function(bool) onSortChanged;
  final VoidCallback onApply;

  const PropertyFilter({
    Key? key,
    required this.filterStatus,
    required this.sortByRentAscending,
    required this.onStatusChanged,
    required this.onSortChanged,
    required this.onApply,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Filter Properties'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status'),
          DropdownButton<String>(
            value: filterStatus,
            isExpanded: true,
            items: ['All', 'Vacant', 'Occupied'].map((status) {
              return DropdownMenuItem(
                value: status,
                child: Text(status),
              );
            }).toList(),
            onChanged: (value) => onStatusChanged(value!),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Text('Sort by Rent'),
              Spacer(),
              Switch(
                value: sortByRentAscending,
                onChanged: onSortChanged,
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            onApply();
          },
          child: Text('Apply'),
        ),
      ],
    );
  }
}

// Property Card Component
class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;

  const PropertyCard({
    Key? key,
    required this.property,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
              ),
              child: Icon(
                Icons.home,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          property.address,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
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
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.square_foot, size: 16, color: Colors.grey),
                      SizedBox(width: 4),
                      Text(
                        property.size,
                        style: TextStyle(color: Colors.grey),
                      ),
                      Spacer(),
                      Text(
                        CurrencyUtils.formatWithSuffix(
                            property.rentAmount, '/month'),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Main Property List Screen
class PropertyListScreen extends StatefulWidget {
  @override
  _PropertyListScreenState createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';
  String _filterStatus = 'All';
  bool _sortByRentAscending = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);

    try {
      await Provider.of<PropertyProvider>(context, listen: false)
          .fetchPropertiesWithFilter(
        status: _filterStatus == 'All' ? null : _filterStatus.toLowerCase(),
        sortByRentAscending: _sortByRentAscending,
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => PropertyFilter(
        filterStatus: _filterStatus,
        sortByRentAscending: _sortByRentAscending,
        onStatusChanged: (value) => setState(() => _filterStatus = value),
        onSortChanged: (value) => setState(() => _sortByRentAscending = value),
        onApply: _loadProperties,
      ),
    );
  }

  List<Property> _getFilteredProperties(List<Property> properties) {
    if (_searchQuery.isEmpty) return properties;
    return properties.where((property) {
      return property.address
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_work,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'No properties found',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Properties'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
          ),
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/add_property')
                .then((_) => _loadProperties()),
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
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: $_error'),
                            SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: _loadProperties,
                              child: Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : Consumer<PropertyProvider>(
                        builder: (context, propertyProvider, child) {
                          final filteredProperties = _getFilteredProperties(
                              propertyProvider.properties);

                          if (filteredProperties.isEmpty) {
                            return _buildEmptyState();
                          }

                          return RefreshIndicator(
                            onRefresh: _loadProperties,
                            child: ListView.builder(
                              padding: EdgeInsets.all(8),
                              itemCount: filteredProperties.length,
                              itemBuilder: (context, index) {
                                final property = filteredProperties[index];
                                return PropertyCard(
                                  property: property,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/property_detail',
                                    arguments: property,
                                  ).then((_) => _loadProperties()),
                                );
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_property')
            .then((_) => _loadProperties()),
        child: Icon(Icons.add),
        tooltip: 'Add Property',
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
