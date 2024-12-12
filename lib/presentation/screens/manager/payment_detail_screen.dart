import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:house_rental_app/data/models/payment.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/data/models/tenant.dart';

class PaymentDetailsScreen extends StatelessWidget {
  final Payment payment;

  PaymentDetailsScreen({required this.payment});

  // Assuming we have property and tenant info in previous steps, or if needed
  // you can load them via providers. For brevity, we'll just show payment details.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Details'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Amount: \$${payment.amount.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text(
                'Date: ${DateFormat('yyyy-MM-dd').format(payment.paymentDate)}'),
            Text('Method: ${payment.paymentMethod}'),
            Text('Status: ${payment.paymentStatus}'),
            if (payment.notes?.isNotEmpty ?? false)
              Text('Notes: ${payment.notes}'),
          ],
        ),
      ),
    );
  }
}
