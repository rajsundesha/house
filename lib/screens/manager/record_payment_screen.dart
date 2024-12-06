import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:house_rental_app/models/payment.dart';
import 'package:house_rental_app/models/tenant.dart';
import 'package:house_rental_app/providers/payment_provider.dart';
import 'package:house_rental_app/providers/tenant_provider.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class RecordPaymentScreen extends StatefulWidget {
  final String? tenantId;

  RecordPaymentScreen({this.tenantId});

  @override
  _RecordPaymentScreenState createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends State<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedTenantId;
  DateTime _paymentDate = DateTime.now();
  bool _isLoading = false;
  String? _errorMessage;
  List<Tenant> _tenants = [];

  @override
  void initState() {
    super.initState();
    _selectedTenantId = widget.tenantId;
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<TenantProvider>(context, listen: false).fetchTenants();
      _tenants = Provider.of<TenantProvider>(context, listen: false).tenants;
      setState(() {});
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _paymentDate = picked);
    }
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTenantId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a tenant')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final tenant = _tenants.firstWhere((t) => t.id == _selectedTenantId);

      final payment = Payment(
        id: '',
        tenantId: _selectedTenantId!,
        propertyId: tenant.propertyId,
        amount: double.parse(_amountController.text),
        paymentDate: _paymentDate,
        paymentMethod: 'offline',
        paymentStatus: 'completed',
        managerId: FirebaseAuth.instance.currentUser!.uid, // Add this line
        notes: _notesController.text.trim(),
      );

      await Provider.of<PaymentProvider>(context, listen: false)
          .addPayment(payment);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment recorded successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Record Payment'),
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
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Text(_errorMessage!,
                            style: TextStyle(color: Colors.red)),
                      ),
                    if (widget.tenantId == null)
                      DropdownButtonFormField<String>(
                        value: _selectedTenantId,
                        decoration: InputDecoration(
                          labelText: 'Select Tenant',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: _tenants.map((tenant) {
                          return DropdownMenuItem(
                            value: tenant.id,
                            child: Text(tenant.name),
                          );
                        }).toList(),
                        onChanged: (value) =>
                            setState(() => _selectedTenantId = value),
                        validator: (value) =>
                            value == null ? 'Please select a tenant' : null,
                      ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '\$',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value?.isEmpty ?? true)
                          return 'Please enter amount';
                        if (double.tryParse(value!) == null)
                          return 'Please enter a valid amount';
                        if (double.parse(value) <= 0)
                          return 'Amount must be greater than 0';
                        return null;
                      },
                    ),
                    SizedBox(height: 16),
                    InkWell(
                      onTap: _selectDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Payment Date',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('MMM dd, yyyy')
                                .format(_paymentDate)),
                            Icon(Icons.calendar_today),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notes (Optional)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _savePayment,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text(_isLoading
                            ? 'Recording Payment...'
                            : 'Record Payment'),
                      ),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
