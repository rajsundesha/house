import 'package:flutter/material.dart';
import 'package:house_rental_app/data/models/payment.dart';
import 'package:intl/intl.dart';

class PaymentTile extends StatelessWidget {
  final Payment payment;
  final VoidCallback onTap;

  PaymentTile({required this.payment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        child: Icon(Icons.payment),
        backgroundColor: Colors.green.withOpacity(0.1),
      ),
      title: Text('\$${payment.amount.toStringAsFixed(2)}'),
      subtitle: Text(DateFormat('MMM dd, yyyy').format(payment.paymentDate)),
      trailing: Chip(
        label: Text(payment.paymentStatus.toUpperCase(),
            style: TextStyle(color: Colors.green)),
        backgroundColor: Colors.green.withOpacity(0.1),
      ),
    );
  }
}
