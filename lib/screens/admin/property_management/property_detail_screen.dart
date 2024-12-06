import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:house_rental_app/models/property.dart';
import 'package:house_rental_app/models/tenant.dart';
import 'package:house_rental_app/providers/property_provider.dart';
import 'package:house_rental_app/providers/tenant_provider.dart';
import 'package:house_rental_app/providers/user_provider.dart';
import 'package:house_rental_app/utils/currency_utils.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Property Manager Section Widget
class PropertyManagerSection extends StatefulWidget {
  final Property property;
  final Function(Property) onPropertyUpdated;
  final bool isAdmin;

  const PropertyManagerSection({
    Key? key,
    required this.property,
    required this.onPropertyUpdated,
    required this.isAdmin,
  }) : super(key: key);

  @override
  _PropertyManagerSectionState createState() => _PropertyManagerSectionState();
}

class _PropertyManagerSectionState extends State<PropertyManagerSection> {
  bool _isLoading = false;

  Future<void> _assignManager() async {
    setState(() => _isLoading = true);

    try {
      final QuerySnapshot managersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'manager')
          .get();

      final List<Map<String, dynamic>> managers =
          managersSnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {
          'id': doc.id,
          'name': data['name'] ?? 'Unknown',
          'email': data['contactInfo']?['email'] ?? '',
          'phone': data['contactInfo']?['phone'] ?? '',
        };
      }).toList();

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (managers.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No managers available')),
        );
        return;
      }

      final String? selectedManagerId = await showDialog<String>(
        context: context,
        builder: (context) => _buildManagerSelectionDialog(managers),
      );

      if (selectedManagerId != null) {
        setState(() => _isLoading = true);

        final updatedProperty = Property(
          id: widget.property.id,
          address: widget.property.address,
          rentAmount: widget.property.rentAmount,
          status: widget.property.status,
          size: widget.property.size,
          assignedManagerId: selectedManagerId,
          description: widget.property.description,
          bedrooms: widget.property.bedrooms,
          bathrooms: widget.property.bathrooms,
          furnished: widget.property.furnished,
          parking: widget.property.parking,
          amenities: widget.property.amenities,
          createdAt: widget.property.createdAt,
          updatedAt: DateTime.now(),
        );

        await Provider.of<PropertyProvider>(context, listen: false)
            .updateProperty(updatedProperty);

        widget.onPropertyUpdated(updatedProperty);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Manager assigned successfully')),
        );
      }
    } catch (e) {
      print('Error assigning manager: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to assign manager: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeManager() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove Manager'),
        content: Text('Are you sure you want to remove the assigned manager?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Remove',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final updatedProperty = Property(
        id: widget.property.id,
        address: widget.property.address,
        rentAmount: widget.property.rentAmount,
        status: widget.property.status,
        size: widget.property.size,
        assignedManagerId: null,
        description: widget.property.description,
        bedrooms: widget.property.bedrooms,
        bathrooms: widget.property.bathrooms,
        furnished: widget.property.furnished,
        parking: widget.property.parking,
        amenities: widget.property.amenities,
        createdAt: widget.property.createdAt,
        updatedAt: DateTime.now(),
      );

      await Provider.of<PropertyProvider>(context, listen: false)
          .updateProperty(updatedProperty);

      widget.onPropertyUpdated(updatedProperty);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Manager removed successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove manager: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildManagerSelectionDialog(List<Map<String, dynamic>> managers) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Select Manager',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Divider(height: 1),
            Expanded(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: managers.length,
                itemBuilder: (context, index) {
                  final manager = managers[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.person),
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    title: Text(manager['name']),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(manager['email']),
                        if (manager['phone'].isNotEmpty) Text(manager['phone']),
                      ],
                    ),
                    onTap: () => Navigator.pop(context, manager['id']),
                  );
                },
              ),
            ),
            Divider(height: 1),
            ButtonBar(
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Property Manager',
                          style: Theme.of(context).textTheme.titleLarge,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.isAdmin)
                        TextButton.icon(
                          icon: Icon(
                            widget.property.assignedManagerId != null
                                ? Icons.edit
                                : Icons.person_add,
                            size: 20,
                          ),
                          label: Text(
                            widget.property.assignedManagerId != null
                                ? 'Change'
                                : 'Assign',
                            style: TextStyle(fontSize: 14),
                          ),
                          onPressed: _assignManager,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: Size(0, 36),
                          ),
                        ),
                    ],
                  ),
                  Divider(),
                  if (widget.property.assignedManagerId != null)
                    FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(widget.property.assignedManagerId)
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Error loading manager information'),
                          );
                        }

                        if (!snapshot.hasData || !snapshot.data!.exists) {
                          return Padding(
                            padding: EdgeInsets.all(8),
                            child: Text('Manager information not found'),
                          );
                        }

                        final managerData =
                            snapshot.data!.data() as Map<String, dynamic>;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                            child: Icon(Icons.person),
                            backgroundColor:
                                Theme.of(context).primaryColor.withOpacity(0.1),
                          ),
                          title: Text(managerData['name'] ?? 'Unknown'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(managerData['contactInfo']?['email'] ?? ''),
                              if (managerData['contactInfo']?['phone'] != null)
                                Text(managerData['contactInfo']['phone']),
                            ],
                          ),
                          trailing: widget.isAdmin
                              ? IconButton(
                                  icon: Icon(Icons.delete_outline),
                                  onPressed: _removeManager,
                                  color: Colors.red,
                                )
                              : null,
                        );
                      },
                    )
                  else
                    Padding(
                      padding: EdgeInsets.all(8),
                      child: Text('No manager assigned'),
                    ),
                ],
              ),
      ),
    );
  }
}

// Main Property Detail Screen
class PropertyDetailScreen extends StatefulWidget {
  Property property;

  PropertyDetailScreen({required this.property});

  @override
  _PropertyDetailScreenState createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  bool _isLoading = false;
  List<Tenant> _tenants = [];
  String? _errorMessage;
  bool _isEditMode = false;
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
    _loadTenants();
  }

  Future<void> _checkAdminStatus() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();
    setState(() {
      _isAdmin = userDoc.data()?['role'] == 'admin';
    });
  }

  Future<void> _loadTenants() async {
    setState(() => _isLoading = true);
    try {
      _tenants = await Provider.of<TenantProvider>(context, listen: false)
          .fetchTenantsByPropertyId(widget.property.id);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to load tenants: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePropertyUpdate(Property updatedProperty) {
    setState(() {
      widget.property = updatedProperty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Property Details'),
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditMode = true),
            ),
          if (_isEditMode)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _updateProperty,
            ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteProperty,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SafeArea(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(8),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width,
                      ),
                      child: _isEditMode
                          ? PropertyEditForm(
                              property: widget.property,
                              onPropertyUpdated: _handlePropertyUpdate,
                              onCancel: () =>
                                  setState(() => _isEditMode = false),
                            )
                          : PropertyDetailView(
                              property: widget.property,
                              tenants: _tenants,
                              isAdmin: _isAdmin,
                              onPropertyUpdated: _handlePropertyUpdate,
                              onTenantsUpdated: _loadTenants,
                            ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _updateProperty() async {
    // This method will be called from PropertyEditForm
    setState(() => _isEditMode = false);
  }

  Future<void> _deleteProperty() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Property'),
        content: Text(
            'Are you sure you want to delete this property? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      await Provider.of<PropertyProvider>(context, listen: false)
          .deleteProperty(widget.property.id);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Property deleted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(
          () => _errorMessage = 'Failed to delete property: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}

// Property Detail View Component
class PropertyDetailView extends StatelessWidget {
  final Property property;
  final List<Tenant> tenants;
  final bool isAdmin;
  final Function(Property) onPropertyUpdated;
  final VoidCallback onTenantsUpdated;

  const PropertyDetailView({
    Key? key,
    required this.property,
    required this.tenants,
    required this.isAdmin,
    required this.onPropertyUpdated,
    required this.onTenantsUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PropertyBasicInfoCard(property: property),
        SizedBox(height: 16),
        PropertyDetailsCard(property: property),
        SizedBox(height: 16),
        if (property.amenities.isNotEmpty)
          PropertyAmenitiesCard(amenities: property.amenities),
        SizedBox(height: 16),
        PropertyManagerSection(
          property: property,
          onPropertyUpdated: onPropertyUpdated,
          isAdmin: isAdmin,
        ),
        SizedBox(height: 16),
        PropertyTenantsCard(
          propertyId: property.id,
          tenants: tenants,
          onTenantsUpdated: onTenantsUpdated,
        ),
      ],
    );
  }
}

// Property Basic Info Card Component
class PropertyBasicInfoCard extends StatelessWidget {
  final Property property;

  const PropertyBasicInfoCard({
    Key? key,
    required this.property,
  }) : super(key: key);

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: color != null ? FontWeight.w500 : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Divider(),
            _buildInfoRow('Address', property.address),
            _buildInfoRow(
              'Rent',
              CurrencyUtils.formatWithSuffix(property.rentAmount, '/month'),
            ),
            _buildInfoRow('Size', '${property.size} sq ft'),
            _buildInfoRow(
              'Status',
              property.status.toUpperCase(),
              color: property.status == 'vacant' ? Colors.red : Colors.green,
            ),
          ],
        ),
      ),
    );
  }
}

// Property Details Card Component
class PropertyDetailsCard extends StatelessWidget {
  final Property property;

  const PropertyDetailsCard({
    Key? key,
    required this.property,
  }) : super(key: key);

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Property Details',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Divider(),
            if (property.description?.isNotEmpty ?? false)
              Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(property.description!),
              ),
            _buildInfoRow('Bedrooms', property.bedrooms.toString()),
            _buildInfoRow('Bathrooms', property.bathrooms.toString()),
            _buildInfoRow('Furnished', property.furnished ? 'Yes' : 'No'),
            _buildInfoRow(
                'Parking', property.parking ? 'Available' : 'Not available'),
          ],
        ),
      ),
    );
  }
}

// Property Amenities Card Component
class PropertyAmenitiesCard extends StatelessWidget {
  final List<String> amenities;

  const PropertyAmenitiesCard({
    Key? key,
    required this.amenities,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Amenities',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Divider(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities.map((amenity) {
                return Chip(
                  label: Text(amenity),
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.1),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// Property Tenants Card Component
class PropertyTenantsCard extends StatelessWidget {
  final String propertyId;
  final List<Tenant> tenants;
  final VoidCallback onTenantsUpdated;

  const PropertyTenantsCard({
    Key? key,
    required this.propertyId,
    required this.tenants,
    required this.onTenantsUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Tenants',
                    style: Theme.of(context).textTheme.titleLarge,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  icon: Icon(Icons.add, size: 20),
                  label: Text(
                    'Add',
                    style: TextStyle(fontSize: 14),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/add_tenant',
                      arguments: propertyId,
                    ).then((_) => onTenantsUpdated());
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: Size(0, 36),
                  ),
                ),
              ],
            ),
            Divider(),
            if (tenants.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('No tenants assigned to this property'),
                ),
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
                      backgroundColor:
                          Theme.of(context).primaryColor.withOpacity(0.1),
                    ),
                    title: Text(tenant.name),
                    subtitle: Text(
                      'Lease ends: ${DateFormat('dd/MM/yyyy').format(tenant.leaseEndDate)}',
                    ),
                    trailing: Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/tenant_detail',
                        arguments: tenant,
                      ).then((_) => onTenantsUpdated());
                    },
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

// [Would you like me to continue with the PropertyEditForm and its related components?]

// Property Edit Form Component
class PropertyEditForm extends StatefulWidget {
  final Property property;
  final Function(Property) onPropertyUpdated;
  final VoidCallback onCancel;

  const PropertyEditForm({
    Key? key,
    required this.property,
    required this.onPropertyUpdated,
    required this.onCancel,
  }) : super(key: key);

  @override
  _PropertyEditFormState createState() => _PropertyEditFormState();
}

class _PropertyEditFormState extends State<PropertyEditForm> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late TextEditingController _addressController;
  late TextEditingController _rentAmountController;
  late TextEditingController _sizeController;
  late TextEditingController _descriptionController;
  late TextEditingController _bedroomsController;
  late TextEditingController _bathroomsController;
  late bool _hasFurnished;
  late bool _hasParking;
  late List<String> _amenities;

  final List<String> _availableAmenities = [
    'Air Conditioning',
    'Heating',
    'Internet',
    'Cable TV',
    'Security System',
    'Elevator',
    'Swimming Pool',
    'Gym',
    'Laundry',
    'Garden',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _addressController = TextEditingController(text: widget.property.address);
    _rentAmountController = TextEditingController(
        text: CurrencyUtils.formatNumber(widget.property.rentAmount));
    _sizeController = TextEditingController(text: widget.property.size);
    _descriptionController =
        TextEditingController(text: widget.property.description);
    _bedroomsController =
        TextEditingController(text: widget.property.bedrooms.toString());
    _bathroomsController =
        TextEditingController(text: widget.property.bathrooms.toString());
    _hasFurnished = widget.property.furnished;
    _hasParking = widget.property.parking;
    _amenities = List.from(widget.property.amenities);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final amount = CurrencyUtils.parseCurrency(_rentAmountController.text);
      final updatedProperty = Property(
        id: widget.property.id,
        address: _addressController.text.trim(),
        rentAmount: amount,
        status: widget.property.status,
        size: _sizeController.text.trim(),
        assignedManagerId: widget.property.assignedManagerId,
        description: _descriptionController.text.trim(),
        bedrooms: int.tryParse(_bedroomsController.text) ?? 0,
        bathrooms: int.tryParse(_bathroomsController.text) ?? 0,
        furnished: _hasFurnished,
        parking: _hasParking,
        amenities: _amenities,
        createdAt: widget.property.createdAt,
        updatedAt: DateTime.now(),
      );

      await Provider.of<PropertyProvider>(context, listen: false)
          .updateProperty(updatedProperty);

      widget.onPropertyUpdated(updatedProperty);
      widget.onCancel();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Property updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update property: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Basic Information Section
          _buildSectionHeader('Basic Information'),
          _buildBasicInformationFields(),
          SizedBox(height: 24),

          // Property Details Section
          _buildSectionHeader('Property Details'),
          _buildPropertyDetailsFields(),
          SizedBox(height: 24),

          // Features Section
          _buildSectionHeader('Features'),
          _buildFeaturesFields(),
          SizedBox(height: 24),

          // Amenities Section
          _buildSectionHeader('Amenities'),
          _buildAmenitiesField(),
          SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.onCancel,
                  child: Text('Cancel'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  child: _isLoading
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text('Save Changes'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge,
      ),
    );
  }

  Widget _buildBasicInformationFields() {
    return Column(
      children: [
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            labelText: 'Address',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) =>
              value?.isEmpty ?? true ? 'Please enter property address' : null,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _rentAmountController,
                decoration: InputDecoration(
                  labelText: 'Rent Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Please enter rent amount';
                  }
                  if (!CurrencyUtils.isValidCurrencyAmount(value!)) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _sizeController,
                decoration: InputDecoration(
                  labelText: 'Size (sq ft)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value?.isEmpty ?? true
                    ? 'Please enter property size'
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPropertyDetailsFields() {
    return Column(
      children: [
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Description',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          maxLines: 3,
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _bedroomsController,
                decoration: InputDecoration(
                  labelText: 'Bedrooms',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _bathroomsController,
                decoration: InputDecoration(
                  labelText: 'Bathrooms',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeaturesFields() {
    return Column(
      children: [
        SwitchListTile(
          title: Text('Furnished'),
          value: _hasFurnished,
          onChanged: (value) => setState(() => _hasFurnished = value),
        ),
        SwitchListTile(
          title: Text('Parking Available'),
          value: _hasParking,
          onChanged: (value) => setState(() => _hasParking = value),
        ),
      ],
    );
  }

  Widget _buildAmenitiesField() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _availableAmenities.map((amenity) {
        final isSelected = _amenities.contains(amenity);
        return FilterChip(
          label: Text(amenity),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _amenities.add(amenity);
              } else {
                _amenities.remove(amenity);
              }
            });
          },
        );
      }).toList(),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _rentAmountController.dispose();
    _sizeController.dispose();
    _descriptionController.dispose();
    _bedroomsController.dispose();
    _bathroomsController.dispose();
    super.dispose();
  }
}
