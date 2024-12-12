import 'package:flutter/material.dart';
import 'package:house_rental_app/presentation/providers/payment_provider.dart';
import 'package:house_rental_app/presentation/providers/tenant_provider.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/data/models/payment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class RecordPaymentScreen extends StatefulWidget {
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
  List _tenants = [];

  @override
  void initState() {
    super.initState();
    _loadTenants();
  }

  Future<void> _loadTenants() async {
    setState(() => _isLoading = true);
    try {
      final managerId = FirebaseAuth.instance.currentUser!.uid;
      _tenants = await Provider.of<TenantProvider>(context, listen: false)
          .fetchTenantsByManagerId(managerId);
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    DateTime? picked = await showDatePicker(
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please select a tenant')));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final tenantProvider =
          Provider.of<TenantProvider>(context, listen: false);
      final tenant = await tenantProvider.getTenantById(_selectedTenantId!);
      if (tenant == null) {
        throw Exception('Tenant not found');
      }

      double amount = double.parse(_amountController.text.trim());
      final managerId = FirebaseAuth.instance.currentUser!.uid;

      final payment = Payment(
        id: '',
        tenantId: _selectedTenantId!,
        propertyId: tenant.propertyId,
        amount: amount,
        paymentDate: _paymentDate,
        paymentMethod: 'offline',
        paymentStatus: 'completed',
        managerId: managerId,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final paymentProvider =
          Provider.of<PaymentProvider>(context, listen: false);
      await paymentProvider.addPayment(payment);

      if (paymentProvider.error != null) {
        _errorMessage = paymentProvider.error;
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_errorMessage!)));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Payment recorded successfully')));
        Navigator.pop(context);
      }
    } catch (e) {
      _errorMessage = 'Failed to record payment: ${e.toString()}';
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(_errorMessage!)));
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
                        color: Colors.red.shade50,
                        child: Text(_errorMessage!,
                            style: TextStyle(color: Colors.red)),
                      ),
                    _buildTenantSelection(),
                    SizedBox(height: 16),
                    TextFormField(
                      controller: _amountController,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        prefixText: '₹',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (val) {
                        if (val?.isEmpty ?? true) return 'Enter amount';
                        final n = double.tryParse(val!);
                        if (n == null || n <= 0) return 'Invalid amount';
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
                        child:
                            Text(DateFormat('yyyy-MM-dd').format(_paymentDate)),
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
                    SizedBox(height: 32),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _savePayment,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Record Payment'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTenantSelection() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Tenant', style: Theme.of(context).textTheme.headlineLarge),
            SizedBox(height: 16),
            if (_tenants.isEmpty)
              Text('No tenants found for your properties')
            else
              ..._tenants.map((t) {
                return RadioListTile<String>(
                  title: Text(t.name),
                  subtitle: Text(
                      'Lease ends: ${DateFormat('yyyy-MM-dd').format(t.leaseEndDate)}'),
                  value: t.id,
                  groupValue: _selectedTenantId,
                  onChanged: (val) => setState(() => _selectedTenantId = val),
                );
              }).toList()
          ],
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
