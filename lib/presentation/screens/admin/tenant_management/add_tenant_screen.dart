import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/tenant_provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
import 'package:house_rental_app/data/models/tenant.dart';
import 'package:intl/intl.dart';
import 'package:house_rental_app/utils/currency_utils.dart';

class AddTenantScreen extends StatefulWidget {
  final String?
      propertyId; // If you want to pre-select a property, pass it here.
  AddTenantScreen({this.propertyId});

  @override
  _AddTenantScreenState createState() => _AddTenantScreenState();
}

class _AddTenantScreenState extends State<AddTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _advanceAmountController = TextEditingController();
  final _rentAdjustmentController = TextEditingController();

  String? _selectedPropertyId;
  String _selectedCategory = 'Family';
  DateTime _leaseStartDate = DateTime.now();
  DateTime _leaseEndDate = DateTime.now().add(Duration(days: 365));
  bool _advancePaid = false;
  bool _isLoading = false;
  String? _errorMessage;
  List _availableProperties = [];

  @override
  void initState() {
    super.initState();
    // Fetch available properties after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAvailableProperties();
    });
  }

  Future<void> _fetchAvailableProperties() async {
    setState(() => _isLoading = true);
    try {
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);
      // Fetch all vacant properties (assuming admin perspective)
      await propertyProvider.fetchProperties(status: 'vacant');
      _availableProperties = propertyProvider.properties;

      // If a propertyId was passed and it's in the vacant list, preselect it
      if (widget.propertyId != null) {
        final propExists =
            _availableProperties.any((p) => p.id == widget.propertyId);
        if (propExists) {
          _selectedPropertyId = widget.propertyId;
        }
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectStartDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _leaseStartDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _leaseStartDate = picked;
        if (_leaseEndDate.isBefore(_leaseStartDate)) {
          _leaseEndDate = _leaseStartDate.add(Duration(days: 365));
        }
      });
    }
  }

  Future<void> _selectEndDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _leaseEndDate,
      firstDate: _leaseStartDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _leaseEndDate = picked);
    }
  }

  Future<void> _saveTenant() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPropertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a property')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      double advanceAmt = 0;
      if (_advancePaid && _advanceAmountController.text.trim().isNotEmpty) {
        advanceAmt =
            double.tryParse(_advanceAmountController.text.trim()) ?? 0.0;
      }

      double rentAdj = 0.0;
      if (_rentAdjustmentController.text.trim().isNotEmpty) {
        rentAdj = double.tryParse(_rentAdjustmentController.text.trim()) ?? 0.0;
      }

      final tenant = Tenant(
        id: '',
        propertyId: _selectedPropertyId!,
        name: _nameController.text.trim(),
        contactInfo: {
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
        },
        category: _selectedCategory,
        leaseStartDate: _leaseStartDate,
        leaseEndDate: _leaseEndDate,
        advancePaid: _advancePaid,
        advanceAmount: advanceAmt,
        rentAdjustment: rentAdj,
      );

      final tenantProvider =
          Provider.of<TenantProvider>(context, listen: false);
      final propertyProvider =
          Provider.of<PropertyProvider>(context, listen: false);

      await tenantProvider.addTenant(tenant);

      if (tenantProvider.error != null) {
        _errorMessage = tenantProvider.error;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorMessage!)));
      } else {
        // Mark property occupied
        await propertyProvider.updatePropertyStatus(
            _selectedPropertyId!, 'occupied');
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Tenant added successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      _errorMessage = 'Failed to add tenant: ${e.toString()}';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage!)));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPropertySelection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: _availableProperties.isEmpty
            ? Text('No vacant properties available')
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Select Property',
                      style: Theme.of(context).textTheme.headlineLarge),
                  SizedBox(height: 16),
                  ..._availableProperties.map((p) {
                    return RadioListTile<String>(
                      title: Text(p.address),
                      subtitle: Text(
                          'Rent: ${CurrencyUtils.formatCurrency(p.currentRentAmount)}/month'),
                      value: p.id,
                      groupValue: _selectedPropertyId,
                      onChanged: (val) =>
                          setState(() => _selectedPropertyId = val),
                    );
                  }).toList(),
                ],
              ),
      ),
    );
  }

  Widget _buildBasicInformation() {
    return Card(
      child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Basic Information',
                  style: Theme.of(context).textTheme.headlineLarge),
              SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Tenant Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val?.isEmpty ?? true ? 'Required' : null,
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
                validator: (val) {
                  if (val?.isEmpty ?? true) return 'Required';
                  if (val!.length != 10) return 'Must be 10 digits';
                  return null;
                },
              ),
              SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val?.isEmpty ?? true) return 'Required';
                  if (!val!.contains('@')) return 'Invalid email';
                  return null;
                },
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ['Family', 'Company', 'Student']
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategory = val!),
              ),
            ],
          )),
    );
  }

  Widget _buildLeaseDuration() {
    return Card(
      child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Lease Duration',
                  style: Theme.of(context).textTheme.headlineLarge),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _selectStartDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Start Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                            DateFormat('yyyy-MM-dd').format(_leaseStartDate)),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: _selectEndDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'End Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Text(
                            DateFormat('yyyy-MM-dd').format(_leaseEndDate)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          )),
    );
  }

  Widget _buildAdvancePayment() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Advance Payment',
                    style: Theme.of(context).textTheme.headlineLarge),
                Switch(
                  value: _advancePaid,
                  onChanged: (val) => setState(() => _advancePaid = val),
                ),
              ],
            ),
            if (_advancePaid) ...[
              SizedBox(height: 16),
              TextFormField(
                controller: _advanceAmountController,
                decoration: InputDecoration(
                  labelText: 'Advance Amount',
                  prefixText: '₹',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (val) {
                  if (!_advancePaid) return null;
                  if (val?.isEmpty ?? true) return 'Enter advance amount';
                  final number = double.tryParse(val!);
                  if (number == null || number <= 0) return 'Invalid amount';
                  return null;
                },
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildRentAdjustment() {
    return Card(
      child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rent Adjustment',
                  style: Theme.of(context).textTheme.headlineLarge),
              SizedBox(height: 16),
              TextFormField(
                controller: _rentAdjustmentController,
                decoration: InputDecoration(
                  labelText: 'Rent Adjustment (if any discount)',
                  prefixText: '-₹',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          )),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _advanceAmountController.dispose();
    _rentAdjustmentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Tenant'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_errorMessage != null)
                      Container(
                        padding: EdgeInsets.all(8),
                        color: Colors.red.shade50,
                        child: Text(_errorMessage!,
                            style: TextStyle(color: Colors.red)),
                      ),
                    _buildPropertySelection(),
                    SizedBox(height: 16),
                    _buildBasicInformation(),
                    SizedBox(height: 16),
                    _buildLeaseDuration(),
                    SizedBox(height: 16),
                    _buildAdvancePayment(),
                    SizedBox(height: 16),
                    _buildRentAdjustment(),
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveTenant,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Add Tenant'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
