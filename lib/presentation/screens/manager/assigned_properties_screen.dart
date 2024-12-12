import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/presentation/providers/tenant_provider.dart';
import 'package:house_rental_app/presentation/screens/shared/widgets/property_tile.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AssignedPropertiesScreen extends StatefulWidget {
  @override
  _AssignedPropertiesScreenState createState() =>
      _AssignedPropertiesScreenState();
}

class _AssignedPropertiesScreenState extends State<AssignedPropertiesScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  Future<void> _loadProperties() async {
    setState(() => _isLoading = true);
    try {
      final managerId = FirebaseAuth.instance.currentUser!.uid;
      // fetchPropertiesByManagerId is already available in propertyProvider
      await Provider.of<PropertyProvider>(context, listen: false)
          .fetchProperties();
      // If needed, filter by manager here or use separate method
      // Actually fetchPropertiesByManagerId returns a list directly:
      // final props = await Provider.of<PropertyProvider>(context,listen:false).fetchPropertiesByManagerId(managerId);
      // If we want to store them, just do that. For now let's rely on general fetch and filter in memory:
      // This approach can be improved by just calling a method that sets state in provider. For simplicity:
      // We'll just fetch all and filter in memory. Or better, create a variable in setState. Let’s just do in memory here.
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final managerId = FirebaseAuth.instance.currentUser!.uid;
    final assignedProps = propertyProvider.properties
        .where((p) => p.assignedManagerId == managerId)
        .toList();
    final filtered = assignedProps
        .where(
            (p) => p.address.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
        appBar: AppBar(
          title: Text('My Properties'),
          actions: [
            IconButton(icon: Icon(Icons.refresh), onPressed: _loadProperties),
          ],
        ),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(child: Text('Error: $_errorMessage'))
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
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (v) => setState(() => _searchQuery = v),
                        ),
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _loadProperties,
                          child: filtered.isEmpty
                              ? Center(child: Text('No properties found'))
                              : ListView.builder(
                                  itemCount: filtered.length,
                                  itemBuilder: (context, index) {
                                    final prop = filtered[index];
                                    return PropertyTile(
                                      property: prop,
                                      onTap: () => Navigator.pushNamed(
                                              context, '/property_detail',
                                              arguments: prop)
                                          .then((_) => _loadProperties()),
                                    );
                                  },
                                ),
                        ),
                      )
                    ],
                  ));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
