// lib/screens/manager/payment_list_screen.dart
import 'package:flutter/material.dart';
import 'package:house_rental_app/models/payment.dart';
import 'package:house_rental_app/providers/payment_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PaymentListScreen extends StatefulWidget {
  @override
  _PaymentListScreenState createState() => _PaymentListScreenState();
}

class _PaymentListScreenState extends State<PaymentListScreen> {
  bool _isLoading = false;
  List<Payment> _payments = [];
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
      setState(() {
        _payments =
            Provider.of<PaymentProvider>(context, listen: false).payments;
      });
    } catch (e) {
      setState(() => _error = e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading payments: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0.00", "en_US");

    return Scaffold(
      appBar: AppBar(
        title: Text('Payments'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadPayments,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Error: $_error'),
                      ElevatedButton(
                        onPressed: _loadPayments,
                        child: Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadPayments,
                  child: _payments.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.payment_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No payments found',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: _payments.length,
                          itemBuilder: (context, index) {
                            final payment = _payments[index];
                            return Card(
                              margin: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Colors.green.withOpacity(0.1),
                                  child:
                                      Icon(Icons.payment, color: Colors.green),
                                ),
                                title: Text(
                                    '\$${formatter.format(payment.amount)}'),
                                subtitle: Text(
                                  DateFormat('MMM dd, yyyy')
                                      .format(payment.paymentDate),
                                ),
                                trailing: Chip(
                                  label: Text(
                                    payment.paymentStatus.toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/payment_detail',
                                    arguments: payment,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
