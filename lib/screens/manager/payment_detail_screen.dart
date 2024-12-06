import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:house_rental_app/models/payment.dart';
import 'package:house_rental_app/models/property.dart';
import 'package:house_rental_app/models/tenant.dart';
import 'package:intl/intl.dart';

class PaymentDetailsScreen extends StatelessWidget {
  final Payment payment;

  const PaymentDetailsScreen({Key? key, required this.payment})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat("#,##0.00", "en_US");

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment Details'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _loadPaymentDetails(payment),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading details: ${snapshot.error}'));
          }

          final details = snapshot.data!;
          final tenant = details['tenant'];
          final property = details['property'];

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Information',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Divider(),
                        _buildInfoRow(
                          'Amount',
                          '\$${formatter.format(payment.amount)}',
                          Icons.attach_money,
                        ),
                        _buildInfoRow(
                          'Date',
                          DateFormat('MMM dd, yyyy')
                              .format(payment.paymentDate),
                          Icons.calendar_today,
                        ),
                        _buildInfoRow(
                          'Time',
                          DateFormat('hh:mm a').format(payment.paymentDate),
                          Icons.access_time,
                        ),
                        _buildInfoRow(
                          'Payment Method',
                          payment.paymentMethod.toUpperCase(),
                          Icons.payment,
                        ),
                        _buildInfoRow(
                          'Status',
                          payment.paymentStatus.toUpperCase(),
                          Icons.check_circle,
                          valueColor: Colors.green,
                        ),
                        if (payment.notes?.isNotEmpty ?? false)
                          _buildInfoRow(
                            'Notes',
                            payment.notes!,
                            Icons.note,
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Tenant Information
                if (tenant != null)
                  Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tenant Information',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Divider(),
                          _buildInfoRow(
                            'Name',
                            tenant.name,
                            Icons.person,
                          ),
                          _buildInfoRow(
                            'Contact',
                            tenant.contactInfo['phone'] ?? 'N/A',
                            Icons.phone,
                          ),
                          _buildInfoRow(
                            'Email',
                            tenant.contactInfo['email'] ?? 'N/A',
                            Icons.email,
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 16),

                // Property Information
                if (property != null)
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
                          _buildInfoRow(
                            'Address',
                            property.address,
                            Icons.home,
                          ),
                          _buildInfoRow(
                            'Monthly Rent',
                            '\$${formatter.format(property.rentAmount)}',
                            Icons.monetization_on,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon,
      {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<Map<String, dynamic>> _loadPaymentDetails(Payment payment) async {
    final tenantDoc = await FirebaseFirestore.instance
        .collection('tenants')
        .doc(payment.tenantId)
        .get();

    final propertyDoc = await FirebaseFirestore.instance
        .collection('properties')
        .doc(payment.propertyId)
        .get();

    return {
      'tenant': tenantDoc.exists
          ? Tenant.fromMap(
              tenantDoc.data() as Map<String, dynamic>, tenantDoc.id)
          : null,
      'property': propertyDoc.exists
          ? Property.fromMap(
              propertyDoc.data() as Map<String, dynamic>, propertyDoc.id)
          : null,
    };
  }
}
