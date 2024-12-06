import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/payment.dart';
import '../providers/payment_provider.dart';

class RecordPaymentScreen extends ConsumerStatefulWidget {
  final String leaseId;
  final String tenantId;
  final String propertyId;
  final double expectedAmount;

  const RecordPaymentScreen({
    super.key,
    required this.leaseId,
    required this.tenantId,
    required this.propertyId,
    required this.expectedAmount,
  });

  @override
  ConsumerState<RecordPaymentScreen> createState() => _RecordPaymentScreenState();
}

class _RecordPaymentScreenState extends ConsumerState<RecordPaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _transactionIdController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _dueDate = DateTime.now();
  DateTime? _paidDate;

  @override
  void initState() {
    super.initState();
    _amountController.text = widget.expectedAmount.toString();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _transactionIdController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _dueDate = date);
    }
  }

  Future<void> _selectPaidDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _paidDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _paidDate = date);
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState?.validate() ?? false) {
      final payment = Payment(
        id: '',
        leaseId: widget.leaseId,
        tenantId: widget.tenantId,
        propertyId: widget.propertyId,
        amount: double.parse(_amountController.text),
        dueDate: _dueDate,
        paidDate: _paidDate,
        status: _paidDate != null ? PaymentStatus.completed : PaymentStatus.pending,
        transactionId: _transactionIdController.text,
        notes: _notesController.text,
      );

      await ref.read(paymentProvider.notifier).addPayment(payment);
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Payment')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Amount'),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value?.isEmpty ?? true) return 'Please enter amount';
                if (double.tryParse(value!) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              },
            ),
            ListTile(
              title: const Text('Due Date'),
              subtitle: Text(_dueDate.toString().split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDueDate,
            ),
            ListTile(
              title: const Text('Payment Date'),
              subtitle:
                  Text(_paidDate?.toString().split(' ')[0] ?? 'Not paid yet'),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectPaidDate,
            ),
            TextFormField(
              controller: _transactionIdController,
              decoration: const InputDecoration(labelText: 'Transaction ID'),
            ),
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(labelText: 'Notes'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submitForm,
              child: const Text('Record Payment'),
            ),
          ],
        ),
      ),
    );
  }
}