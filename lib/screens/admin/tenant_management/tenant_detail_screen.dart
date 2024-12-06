import 'package:flutter/material.dart';
import 'package:house_rental_app/models/tenant.dart';
import 'package:house_rental_app/models/property.dart';
import 'package:house_rental_app/models/payment.dart';
import 'package:house_rental_app/providers/tenant_provider.dart';
import 'package:house_rental_app/providers/property_provider.dart';
import 'package:house_rental_app/providers/payment_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class TenantDetailScreen extends StatefulWidget {
  final Tenant tenant;
  TenantDetailScreen({required this.tenant});

  @override
  _TenantDetailScreenState createState() => _TenantDetailScreenState();
}

class _TenantDetailScreenState extends State<TenantDetailScreen> {
  bool _isLoading = false;
  String? _errorMessage;
  Property? _property;
  List<Payment> _payments = [];
  bool _isEditMode = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late String _selectedCategory;
  late DateTime _leaseStartDate;
  late DateTime _leaseEndDate;
  late bool _advancePaid;
  late TextEditingController _advanceAmountController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadData();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.tenant.name);
    _phoneController =
        TextEditingController(text: widget.tenant.contactInfo['phone']);
    _emailController =
        TextEditingController(text: widget.tenant.contactInfo['email']);
    _selectedCategory = widget.tenant.category;
    _leaseStartDate = widget.tenant.leaseStartDate;
    _leaseEndDate = widget.tenant.leaseEndDate;
    _advancePaid = widget.tenant.advancePaid;
    _advanceAmountController =
        TextEditingController(text: widget.tenant.advanceAmount.toString());
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Load property details
      _property = await Provider.of<PropertyProvider>(context, listen: false)
          .getPropertyById(widget.tenant.propertyId);

      // Load payment history
      _payments = await Provider.of<PaymentProvider>(context, listen: false)
          .fetchPaymentsByTenantId(widget.tenant.id);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateTenant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final updatedTenant = Tenant(
        id: widget.tenant.id,
        propertyId: widget.tenant.propertyId,
        name: _nameController.text.trim(),
        contactInfo: {
          'phone': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
        },
        category: _selectedCategory,
        leaseStartDate: _leaseStartDate,
        leaseEndDate: _leaseEndDate,
        advancePaid: _advancePaid,
        advanceAmount:
            _advancePaid ? double.parse(_advanceAmountController.text) : 0,
      );

      await Provider.of<TenantProvider>(context, listen: false)
          .updateTenant(updatedTenant);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tenant updated successfully')),
      );
      setState(() => _isEditMode = false);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to update tenant: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTenant() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Tenant'),
        content: Text('Are you sure you want to delete this tenant?'),
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
      await Provider.of<TenantProvider>(context, listen: false)
          .deleteTenant(widget.tenant.id);

      // Update property status to vacant
      await Provider.of<PropertyProvider>(context, listen: false)
          .updatePropertyStatus(widget.tenant.propertyId, 'vacant');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Tenant deleted successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = 'Failed to delete tenant: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime picked = (await showDatePicker(
      context: context,
      initialDate: isStartDate ? _leaseStartDate : _leaseEndDate,
      firstDate: isStartDate ? DateTime.now() : _leaseStartDate,
      lastDate: DateTime.now().add(Duration(days: 1825)),
    ))!;

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _leaseStartDate = picked;
          if (_leaseEndDate.isBefore(_leaseStartDate)) {
            _leaseEndDate = _leaseStartDate.add(Duration(days: 365));
          }
        } else {
          _leaseEndDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tenant Details'),
        actions: [
          if (!_isEditMode)
            IconButton(
              icon: Icon(Icons.edit),
              onPressed: () => setState(() => _isEditMode = true),
            ),
          if (_isEditMode)
            IconButton(
              icon: Icon(Icons.save),
              onPressed: _updateTenant,
            ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: _deleteTenant,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: _isEditMode ? _buildEditForm() : _buildDetailView(),
            ),
    );
  }

  Widget _buildDetailView() {
    final daysLeft =
        widget.tenant.leaseEndDate.difference(DateTime.now()).inDays;
    final isLeaseEnding = daysLeft <= 30;
    final formatter = NumberFormat("#,##0.00", "en_US");

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
            child: Text(_errorMessage!, style: TextStyle(color: Colors.red)),
          ),

        // Tenant Information Card
        Card(
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
                      radius: 30,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tenant.name,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            widget.tenant.category,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Divider(height: 32),
                _buildInfoRow(
                    'Phone', widget.tenant.contactInfo['phone'] ?? ''),
                _buildInfoRow(
                    'Email', widget.tenant.contactInfo['email'] ?? ''),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Property Information Card
        if (_property != null)
          Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Property Information',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Divider(),
                  _buildInfoRow('Address', _property!.address),
                  _buildInfoRow('Size', _property!.size),
                  _buildInfoRow(
                    'Rent',
                    '\$${formatter.format(_property!.rentAmount)}/month',
                  ),
                ],
              ),
            ),
          ),
        SizedBox(height: 16),

        // Lease Information Card
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Lease Information',
                        style: Theme.of(context).textTheme.titleLarge,
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
                        isLeaseEnding ? '$daysLeft days left' : 'Active',
                        style: TextStyle(
                          color: isLeaseEnding ? Colors.red : Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(),
                _buildInfoRow(
                  'Start Date',
                  DateFormat('MMM dd, yyyy')
                      .format(widget.tenant.leaseStartDate),
                ),
                _buildInfoRow(
                  'End Date',
                  DateFormat('MMM dd, yyyy').format(widget.tenant.leaseEndDate),
                ),
                if (widget.tenant.advancePaid) ...[
                  _buildInfoRow(
                    'Advance Amount',
                    '\$${formatter.format(widget.tenant.advanceAmount)}',
                  ),
                ],
              ],
            ),
          ),
        ),
        SizedBox(height: 16),

        // Payment History Card
        Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Payment History',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    TextButton.icon(
                      icon: Icon(Icons.add, size: 20),
                      label: Text('Record'), // Shortened text
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        minimumSize: Size(0, 36),
                      ),
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          '/record_payment',
                          arguments: widget.tenant.id,
                        ).then((_) => _loadData());
                      },
                    ),
                  ],
                ),
                Divider(),
                if (_payments.isEmpty)
                  Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: Text('No payment records found')),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _payments.length,
                    itemBuilder: (context, index) {
                      final payment = _payments[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Icon(Icons.payment),
                          backgroundColor: Colors.green.withOpacity(0.1),
                        ),
                        title: Text('\$${formatter.format(payment.amount)}'),
                        subtitle: Text(
                          DateFormat('MMM dd, yyyy')
                              .format(payment.paymentDate),
                        ),
                        trailing: Chip(
                          label: Text(payment.paymentStatus.toUpperCase()),
                          backgroundColor: Colors.green.withOpacity(0.1),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEditForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ... [Form implementation similar to AddTenantScreen but with pre-filled values]
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _advanceAmountController.dispose();
    super.dispose();
  }
}
