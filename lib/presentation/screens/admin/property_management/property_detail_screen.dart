import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/presentation/providers/tenant_provider.dart';
import 'package:house_rental_app/utils/currency_utils.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:url_launcher/url_launcher.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;

  PropertyDetailScreen({required this.property});

  @override
  _PropertyDetailScreenState createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  bool _isLoading = false;
  List _tenants = [];
  String? _errorMessage;
  late GoogleMapController _mapController;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() => _isLoading = true);
    try {
      final tenantProvider =
          Provider.of<TenantProvider>(context, listen: false);
      _tenants =
          await tenantProvider.fetchTenantsByPropertyId(widget.property.id);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

Widget _buildRentHistorySection() {
    final propertyProvider = Provider.of<PropertyProvider>(context);
    final updatedProperty = propertyProvider.properties.firstWhere(
      (p) => p.id == widget.property.id,
      orElse: () => widget.property,
    );

    final history = updatedProperty.flexibleRentHistory.entries.toList()
      ..sort((a, b) {
        // Handle Timestamp properly
        final aTime = (a.value['timestamp'] as Timestamp?)?.toDate();
        final bTime = (b.value['timestamp'] as Timestamp?)?.toDate();
        if (aTime == null || bTime == null) return 0;
        return bTime.compareTo(aTime);
      });

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rent History',
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: _showRentAdjustmentDialog,
                ),
              ],
            ),
            SizedBox(height: 8),
            Text(
                'Current Rent: ${CurrencyUtils.formatCurrency(updatedProperty.currentRentAmount)}'),
            Text(
                'Base Rent: ${CurrencyUtils.formatCurrency(updatedProperty.baseRentAmount)}'),
            Text(
                'Yearly Increase: ${updatedProperty.yearlyIncreasePercentage}%'),
            if (history.isNotEmpty) ...[
              SizedBox(height: 8),
              Divider(),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final entry = history[index];
                  final data = entry.value as Map<String, dynamic>;
                  final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
                  final reason =
                      data['reason'] as String? ?? 'No reason provided';
                  final timestamp = (data['timestamp'] as Timestamp?)?.toDate();

                  return ListTile(
                    title: Text(CurrencyUtils.formatCurrency(amount)),
                    subtitle: Text(reason),
                    trailing: Text(timestamp != null
                        ? DateFormat('MMM d, y').format(timestamp)
                        : 'No date'),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
}
// / Update _showRentAdjustmentDialog to handle nulls
  Future<void> _showRentAdjustmentDialog() async {
    final _amountController = TextEditingController();
    final _reasonController = TextEditingController();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adjust Rent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'New Rent Amount',
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for Adjustment',
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final amountText = _amountController.text.trim();
              if (amountText.isNotEmpty) {
                try {
                  final newAmount = double.parse(amountText);
                  final reason = _reasonController.text.trim();

                  await Provider.of<PropertyProvider>(context, listen: false)
                      .updateRentAmount(widget.property.id, newAmount, reason);

                  await Provider.of<PropertyProvider>(context, listen: false)
                      .refreshProperty(widget.property.id);

                  Navigator.pop(context);

                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Rent updated successfully')),
                    );
                    setState(() {});
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: Invalid amount format')),
                  );
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showMaintenanceDialog({MaintenanceRecord? record}) {
    showDialog(
      context: context,
      builder: (context) => MaintenanceDialog(
        propertyId: widget.property.id,
        record: record,
      ),
    ).then((_) {
      // Refresh property details after maintenance update
      Provider.of<PropertyProvider>(context, listen: false)
          .refreshProperty(widget.property.id);
    });
  }

  Widget _buildImageCarousel() {
    return Stack(
      children: [
        CarouselSlider(
          options: CarouselOptions(
            height: 250,
            viewportFraction: 1.0,
            onPageChanged: (index, reason) {
              setState(() => _currentImageIndex = index);
            },
          ),
          items: widget.property.images.map((imageUrl) {
            return Builder(
              builder: (BuildContext context) {
                return Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                );
              },
            );
          }).toList(),
        ),
        Positioned(
          bottom: 10,
          right: 10,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${_currentImageIndex + 1}/${widget.property.images.length}',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationMap() {
    if (widget.property.locationCoordinates.isEmpty) {
      return Container();
    }

    final position = LatLng(
      widget.property.locationCoordinates['latitude']!,
      widget.property.locationCoordinates['longitude']!,
    );

    return Container(
      height: 200,
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: position,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            markers: {
              Marker(
                markerId: MarkerId('property_location'),
                position: position,
              ),
            },
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: () async {
                final url = 'https://www.google.com/maps/search/?api=1&query='
                    '${position.latitude},${position.longitude}';
                if (await canLaunch(url)) {
                  await launch(url);
                }
              },
              child: Icon(Icons.directions),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMaintenanceSection() {
    final records = widget.property.maintenanceRecords;
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Maintenance Records',
                    style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: () => _showMaintenanceDialog(),
                ),
              ],
            ),
            if (records.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No maintenance records'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: records.length,
                itemBuilder: (context, index) {
                  final record = records[index];
                  return ListTile(
                    title: Text(record.title),
                    subtitle: Text(
                      '${record.description}\n${DateFormat('MMM d, y').format(record.date)}',
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(CurrencyUtils.formatCurrency(record.cost)),
                        Chip(
                          label: Text(
                            record.status.toUpperCase(),
                            style: TextStyle(fontSize: 10),
                          ),
                          backgroundColor: _getStatusColor(record.status),
                        ),
                      ],
                    ),
                    onTap: () => _showMaintenanceDialog(record: record),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange.shade100;
      case 'in_progress':
        return Colors.blue.shade100;
      case 'completed':
        return Colors.green.shade100;
      default:
        return Colors.grey.shade100;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Property Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => Navigator.pushNamed(
              context,
              '/edit_property',
              arguments: widget.property,
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Delete Property'),
                  content:
                      Text('Are you sure you want to delete this property?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('CANCEL'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child:
                          Text('DELETE', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                try {
                  await Provider.of<PropertyProvider>(context, listen: false)
                      .deleteProperty(widget.property.id);
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting property: $e')),
                  );
                }
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                await Provider.of<PropertyProvider>(context, listen: false)
                    .refreshProperty(widget.property.id);
                await _loadTenants();
              },
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.property.images.isNotEmpty)
                      _buildImageCarousel(),
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.property.address,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          SizedBox(height: 8),
                          Text(
                            widget.property.location,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          SizedBox(height: 16),
                          _buildLocationMap(),
                          SizedBox(height: 16),
                          _buildRentHistorySection(),
                          SizedBox(height: 16),
                          _buildMaintenanceSection(),
                          // Add other sections as needed
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class MaintenanceDialog extends StatefulWidget {
  final String propertyId;
  final MaintenanceRecord? record;

  MaintenanceDialog({required this.propertyId, this.record});

  @override
  _MaintenanceDialogState createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<MaintenanceDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costController = TextEditingController();
  String _status = 'pending';

  @override
  void initState() {
    super.initState();
    if (widget.record != null) {
      _titleController.text = widget.record!.title;
      _descriptionController.text = widget.record!.description;
      _costController.text = widget.record!.cost.toString();
      _status = widget.record!.status;
    }
  }

  Future<void> _save() async {
    if (_titleController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _costController.text.isEmpty) {
      return;
    }

    final record = MaintenanceRecord(
      title: _titleController.text,
      description: _descriptionController.text,
      cost: double.parse(_costController.text),
      date: DateTime.now(),
      status: _status,
    );

    try {
      final provider = Provider.of<PropertyProvider>(context, listen: false);
      if (widget.record == null) {
        await provider.addMaintenanceRecord(widget.propertyId, record);
      } else {
        // Update functionality would go here
      }
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving maintenance record: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.record == null
          ? 'Add Maintenance Record'
          : 'Edit Maintenance Record'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
            TextField(
              controller: _costController,
              decoration: InputDecoration(
                labelText: 'Cost',
                prefixText: '₹',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _status,
              decoration: InputDecoration(labelText: 'Status'),
              items: ['pending', 'in_progress', 'completed']
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text(s.toUpperCase()),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _status = val!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('CANCEL'),
        ),
        TextButton(
          onPressed: _save,
          child: Text('SAVE'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _costController.dispose();
    super.dispose();
  }
}

// Add Property Features Section
class PropertyFeaturesSection extends StatelessWidget {
  final Property property;

  PropertyFeaturesSection({required this.property});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Property Features',
                style: Theme.of(context).textTheme.titleLarge),
            SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildFeatureItem(
                  icon: Icons.king_bed,
                  label: '${property.bedrooms} Bedrooms',
                ),
                _buildFeatureItem(
                  icon: Icons.bathtub,
                  label: '${property.bathrooms} Bathrooms',
                ),
                _buildFeatureItem(
                  icon: Icons.square_foot,
                  label: '${property.size} sq ft',
                ),
                _buildFeatureItem(
                  icon: Icons.chair,
                  label: property.furnishingStatus.toUpperCase(),
                ),
                if (property.parking)
                  _buildFeatureItem(
                    icon: Icons.local_parking,
                    label: 'Parking Available',
                  ),
              ],
            ),
            if (property.amenities.isNotEmpty) ...[
              SizedBox(height: 24),
              Text('Amenities', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: property.amenities.map((amenity) {
                  return Chip(
                    label: Text(amenity),
                    backgroundColor:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({required IconData icon, required String label}) {
    return Container(
      width: 120,
      child: Row(
        children: [
          Icon(icon, size: 20),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// Add Tenant Section
class TenantSection extends StatelessWidget {
  final List tenants;
  final VoidCallback onAddTenant;
  final String propertyId;

  TenantSection({
    required this.tenants,
    required this.onAddTenant,
    required this.propertyId,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tenants', style: Theme.of(context).textTheme.titleLarge),
                IconButton(
                  icon: Icon(Icons.add),
                  onPressed: onAddTenant,
                ),
              ],
            ),
            if (tenants.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Text('No tenants assigned'),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: tenants.length,
                itemBuilder: (context, index) {
                  final tenant = tenants[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                      backgroundColor: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                    ),
                    title: Text(tenant.name),
                    subtitle: Text(
                      'Lease ends: ${DateFormat('MMM d, y').format(tenant.leaseEndDate)}',
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.arrow_forward_ios),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/tenant_detail',
                          arguments: tenant,
                        );
                      },
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
