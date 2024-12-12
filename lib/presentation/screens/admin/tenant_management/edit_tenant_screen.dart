import 'package:flutter/material.dart';
import 'package:house_rental_app/presentation/shared/widgets/custom_dropdown.dart';
import 'package:house_rental_app/presentation/shared/widgets/dialog_components.dart';
import 'package:house_rental_app/presentation/shared/widgets/loading_overlay.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental_app/data/models/tenant.dart';
import 'package:house_rental_app/presentation/providers/tenant_provider.dart';
import 'package:house_rental_app/presentation/providers/property_provider.dart';
// import 'package:house_rental_app/presentation/shared/widgets/custom_components.dart';
import 'package:house_rental_app/utils/currency_utils.dart';
import 'package:intl/intl.dart';

class EditTenantScreen extends StatefulWidget {
  final Tenant tenant;

  EditTenantScreen({required this.tenant});

  @override
  _EditTenantScreenState createState() => _EditTenantScreenState();
}

class _EditTenantScreenState extends State<EditTenantScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _rentAdjustmentController;
  late TextEditingController _advanceAmountController;

  late DateTime _leaseStartDate;
  late DateTime _leaseEndDate;
  late bool _advancePaid;
  late String _category;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.tenant.name);
    _emailController =
        TextEditingController(text: widget.tenant.contactInfo['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.tenant.contactInfo['phone'] ?? '');
    _rentAdjustmentController =
        TextEditingController(text: widget.tenant.rentAdjustment.toString());
    _advanceAmountController =
        TextEditingController(text: widget.tenant.advanceAmount.toString());

    _leaseStartDate = widget.tenant.leaseStartDate;
    _leaseEndDate = widget.tenant.leaseEndDate;
    _advancePaid = widget.tenant.advancePaid;
    _category = widget.tenant.category;
  }

  Future<void> _selectLeaseStartDate() async {
    final picked = await showDatePicker(
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

  Future<void> _selectLeaseEndDate() async {
    final picked = await showDatePicker(
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

    setState(() => _isLoading = true);

    try {
      final updatedTenant = Tenant(
        id: widget.tenant.id,
        propertyId: widget.tenant.propertyId,
        name: _nameController.text.trim(),
        contactInfo: {
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
        },
        category: _category,
        leaseStartDate: _leaseStartDate,
        leaseEndDate: _leaseEndDate,
        advancePaid: _advancePaid,
        advanceAmount: double.parse(_advanceAmountController.text),
        rentAdjustment: double.parse(_rentAdjustmentController.text),
        familyMembers: widget.tenant.familyMembers,
        documents: widget.tenant.documents,
        createdAt: widget.tenant.createdAt,
        lastUpdatedAt: DateTime.now(),
        createdBy: widget.tenant.createdBy,
        updatedBy: 'admin', // Should be dynamic based on logged-in user
      );

      await Provider.of<TenantProvider>(context, listen: false)
          .updateTenant(updatedTenant);

      // Update property if rent adjustment changed
      if (widget.tenant.rentAdjustment !=
          double.parse(_rentAdjustmentController.text)) {
        final propertyProvider =
            Provider.of<PropertyProvider>(context, listen: false);
        final property =
            await propertyProvider.getPropertyById(widget.tenant.propertyId);

        if (property != null) {
          await propertyProvider.updateRentAmount(
            property.id,
            double.parse(_rentAdjustmentController.text),
            'Rent adjustment for tenant: ${_nameController.text}',
          );
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tenant updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      showErrorDialog(context, 'Error updating tenant: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Tenant'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveTenant,
            child: Text(
              'Save',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information
                Text('Basic Information',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Tenant Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => v?.isEmpty ?? true ? 'Required' : null,
                ),
                SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (v!.length < 10) return 'Invalid phone number';
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
                  validator: (v) {
                    if (v?.isEmpty ?? true) return 'Required';
                    if (!v!.contains('@')) return 'Invalid email';
                    return null;
                  },
                ),
                SizedBox(height: 16),
                CustomDropdown<String>(
                  label: 'Category',
                  value: _category,
                  items: ['Family', 'Individual', 'Student', 'Company'],
                  onChanged: (val) => setState(() => _category = val!),
                  getLabel: (val) => val,
                ),
                SizedBox(height: 24),

                // Lease Information
                Text('Lease Information',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectLeaseStartDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Lease Start Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('MMM d, y').format(_leaseStartDate),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectLeaseEndDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Lease End Date',
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            DateFormat('MMM d, y').format(_leaseEndDate),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 24),

                // Payment Information
                Text('Payment Information',
                    style: Theme.of(context).textTheme.titleLarge),
                SizedBox(height: 16),
                SwitchListTile(
                  title: Text('Advance Paid'),
                  value: _advancePaid,
                  onChanged: (val) => setState(() => _advancePaid = val),
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
                    validator: (v) {
                      if (!_advancePaid) return null;
                      if (v?.isEmpty ?? true) return 'Required';
                      if (double.tryParse(v!) == null) return 'Invalid amount';
                      return null;
                    },
                  ),
                ],
                SizedBox(height: 16),
                TextFormField(
                  controller: _rentAdjustmentController,
                  decoration: InputDecoration(
                    labelText: 'Rent Adjustment',
                    prefixText: '₹',
                    helperText: 'Amount to be deducted from base rent (if any)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveTenant,
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(_isLoading ? 'Saving...' : 'Save Changes'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _rentAdjustmentController.dispose();
    _advanceAmountController.dispose();
    super.dispose();
  }
}
