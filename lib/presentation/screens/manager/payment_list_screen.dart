import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:house_rental_app/presentation/providers/payment_provider.dart';
import 'package:house_rental_app/data/models/payment.dart';
import 'package:intl/intl.dart';

class PaymentListScreen extends StatefulWidget {
  @override
  _PaymentListScreenState createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  Future<void> _loadPayments() async {
    setState(() => _isLoading = true);
    try {
      await Provider.of<PaymentProvider>(context, listen: false)
          .fetchPayments();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paymentProvider = Provider.of<PaymentProvider>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text('Payments'),
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: _loadPayments),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : paymentProvider.payments.isEmpty
                  ? Center(child: Text('No payments found'))
                  : RefreshIndicator(
                      onRefresh: _loadPayments,
                      child: ListView.builder(
                        itemCount: paymentProvider.payments.length,
                        itemBuilder: (context, index) {
                          final payment = paymentProvider.payments[index];
                          return ListTile(
                            leading: CircleAvatar(
                                child: Icon(Icons.payment),
                                backgroundColor: Colors.green.withOpacity(0.1)),
                            title:
                                Text('\$${payment.amount.toStringAsFixed(2)}'),
                            subtitle: Text(DateFormat('MMM dd, yyyy')
                                .format(payment.paymentDate)),
                            trailing: Chip(
                              label: Text(payment.paymentStatus.toUpperCase()),
                              backgroundColor: Colors.green.withOpacity(0.1),
                            ),
                            onTap: () => Navigator.pushNamed(
                                context, '/payment_detail',
                                arguments: payment),
                          );
                        },
                      ),
                    ),
    );
  }
}
