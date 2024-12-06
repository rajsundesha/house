import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental_app/models/payment.dart';
import 'package:intl/intl.dart';

class PaymentProvider with ChangeNotifier {
  List<Payment> _payments = [];

  List<Payment> get payments => _payments;

  final CollectionReference _paymentCollection =
      FirebaseFirestore.instance.collection('payments');

  // Fetch all payments
// In payment_provider.dart
  Future<void> fetchPayments() async {
    try {
      QuerySnapshot snapshot = await _paymentCollection
          .orderBy('paymentDate', descending: true)
          .get();

      _payments = snapshot.docs
          .map((doc) =>
              Payment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching payments: $e');
      throw e;
    }
  }

  // Fetch payments by tenant ID
  Future<List<Payment>> fetchPaymentsByTenantId(String tenantId) async {
    try {
      QuerySnapshot snapshot =
          await _paymentCollection.where('tenantId', isEqualTo: tenantId).get();
      List<Payment> payments = snapshot.docs
          .map((doc) =>
              Payment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      return payments;
    } catch (e) {
      print('Error fetching payments by tenant ID: $e');
      return [];
    }
  }

  // Update PaymentProvider with a fixed fetchPaymentsByManagerId method:
  Future<List<Payment>> fetchPaymentsByManagerId(String managerId) async {
    try {
      final QuerySnapshot snapshot = await _paymentCollection
          .where('managerId', isEqualTo: managerId)
          .orderBy('paymentDate', descending: true)
          .get();

      return snapshot.docs
          .map((doc) =>
              Payment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error fetching payments by manager ID: $e');
      throw e;
    }
  }

  // Add a new payment
  Future<void> addPayment(Payment payment) async {
    try {
      DocumentReference docRef = await _paymentCollection.add(payment.toMap());
      payment.id = docRef.id;
      _payments.add(payment);
      notifyListeners();
    } catch (e) {
      print('Error adding payment: $e');
    }
  }

  // Get payments for a specific tenant
  Future<void> fetchPaymentsForTenant(String tenantId) async {
    try {
      QuerySnapshot snapshot =
          await _paymentCollection.where('tenantId', isEqualTo: tenantId).get();
      _payments = snapshot.docs
          .map((doc) =>
              Payment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching payments for tenant: $e');
    }
  }


  // // Add analytics methods
Future<Map<String, double>> getMonthlyRevenue() async {
    try {
      final now = DateTime.now();
      final startOfYear = DateTime(now.year, 1, 1);

      QuerySnapshot snapshot = await _firestore
          .collection('payments')
          .where('paymentDate', isGreaterThanOrEqual: startOfYear)
          .get();

      Map<String, double> monthlyRevenue = {};
      for (var doc in snapshot.docs) {
        final payment =
            Payment.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        final month = DateFormat('MMM').format(payment.paymentDate);
        monthlyRevenue[month] = (monthlyRevenue[month] ?? 0) + payment.amount;
      }

      return monthlyRevenue;
    } catch (e) {
      print('Error getting monthly revenue: $e');
      throw e;
    }
  }

  Future<List<Payment>> getPendingPayments() async {
    // Implementation
  }

  Future<void> generateReceipt(String paymentId) async {
    // Implementation
  }

}
