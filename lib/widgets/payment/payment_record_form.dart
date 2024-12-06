import 'package:flutter/material.dart';
import 'package:house_rental_app/models/payment.dart';

class PaymentRecordForm extends StatefulWidget {
  final String tenantId;
  final double expectedAmount;
  final Function(Payment) onSubmit;

  @override
  _PaymentRecordFormState createState() => _PaymentRecordFormState();
}

class _PaymentRecordFormState extends State<PaymentRecordForm> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _paymentDate = DateTime.now();
  String _paymentMethod = 'cash';

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _amountController,
            decoration: InputDecoration(
              labelText: 'Amount',
              prefixText: '₹',
              suffixText: '/ ${widget.expectedAmount}',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              final amount = double.tryParse(value);
              if (amount == null || amount <= 0) return 'Invalid amount';
              return null;
            },
          ),
          SizedBox(height: 16),
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Payment Date',
                suffixIcon: Icon(Icons.calendar_today),
              ),
              child: Text(DateFormat('dd MMM yyyy').format(_paymentDate)),
            ),
          ),
          SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _paymentMethod,
            decoration: InputDecoration(labelText: 'Payment Method'),
            items: [
              DropdownMenuItem(value: 'cash', child: Text('Cash')),
              DropdownMenuItem(value: 'bank', child: Text('Bank Transfer')),
              DropdownMenuItem(value: 'upi', child: Text('UPI')),
              DropdownMenuItem(value: 'check', child: Text('Check')),
            ],
            onChanged: (value) => setState(() => _paymentMethod = value!),
          ),
          SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            decoration: InputDecoration(
              labelText: 'Notes (Optional)',
              hintText: 'Enter any additional notes...',
            ),
            maxLines: 3,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submitPayment,
            child: Text('Record Payment'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paymentDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _paymentDate = picked);
  }

  void _submitPayment() {
    if (!_formKey.currentState!.validate()) return;

    final payment = Payment(
      id: '',
      tenantId: widget.tenantId,
      propertyId: '', // Get from tenant
      amount: double.parse(_amountController.text),
      paymentDate: _paymentDate,
      paymentMethod: _paymentMethod,
      paymentStatus: 'completed',
      notes: _notesController.text,
    );

    widget.onSubmit(payment);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
