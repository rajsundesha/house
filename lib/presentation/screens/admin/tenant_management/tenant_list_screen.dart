import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/tenant_provider.dart';
import 'package:house_rental_app/data/models/tenant.dart';

class TenantListScreen extends StatefulWidget {
  @override
  _TenantListScreenState createState() => _TenantListScreenState();
}

class _TenantListScreenState extends State<TenantListScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<TenantProvider>(context, listen: false).fetchTenants();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tenantProvider = Provider.of<TenantProvider>(context);
    final filteredTenants = tenantProvider.tenants
        .where((t) => t.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      appBar: AppBar(title: Text('Tenants'), actions: [
        IconButton(icon: Icon(Icons.refresh), onPressed: _loadTenants),
      ]),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : Column(children: [
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search tenants...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (val) => setState(() => _searchQuery = val),
                    ),
                  ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: _loadTenants,
                      child: filteredTenants.isEmpty
                          ? Center(child: Text('No tenants found'))
                          : ListView.builder(
                              itemCount: filteredTenants.length,
                              itemBuilder: (context, index) {
                                final tenant = filteredTenants[index];
                                return ListTile(
                                  title: Text(tenant.name),
                                  subtitle: Text(
                                      'Lease ends: ${tenant.leaseEndDate.toLocal().toString().split(' ')[0]}'),
                                  onTap: () => Navigator.pushNamed(
                                          context, '/tenant_detail',
                                          arguments: tenant)
                                      .then((_) => _loadTenants()),
                                );
                              }),
                    ),
                  )
                ]),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/add_tenant')
            .then((_) => _loadTenants()),
        child: Icon(Icons.add),
      ),
    );
  }
}
