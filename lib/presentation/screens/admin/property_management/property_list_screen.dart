import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/presentation/screens/shared/widgets/property_tile.dart';
import 'package:house_rental_app/data/models/property.dart';

class PropertyListScreen extends StatefulWidget {
  @override
  _PropertyListScreenState createState() => _PropertyListScreenState();
}

class _PropertyListScreenState extends State<PropertyListScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterStatus = 'All';

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    await Provider.of<PropertyProvider>(context, listen: false).fetchProperties(
        status: _filterStatus == 'All' ? null : _filterStatus.toLowerCase());
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final filteredProperties = propertyProvider.properties.where((property) {
      return property.address
          .toLowerCase()
          .contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Properties'),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
              _loadProperties();
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'All', child: Text('All')),
              PopupMenuItem(value: 'Vacant', child: Text('Vacant')),
              PopupMenuItem(value: 'Occupied', child: Text('Occupied')),
            ],
          ),
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadProperties,
          )
        ],
      ),
      body: propertyProvider.isLoading
          ? Center(child: CircularProgressIndicator())
          : propertyProvider.error != null
              ? Center(child: Text('Error: ${propertyProvider.error}'))
              : Column(
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
                        onChanged: (value) =>
                            setState(() => _searchQuery = value),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadProperties,
                        child: filteredProperties.isEmpty
                            ? Center(child: Text('No properties found'))
                            : ListView.builder(
                                itemCount: filteredProperties.length,
                                itemBuilder: (context, index) {
                                  final property = filteredProperties[index];
                                  return PropertyTile(
                                    property: property,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/property_detail',
                                      arguments: property,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_property')
            .then((_) => _loadProperties()),
        child: Icon(Icons.add),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
