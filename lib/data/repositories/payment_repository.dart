

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental_app/data/models/payment.dart';

class PaymentRepository {
  final CollectionReference _paymentCollection =
      FirebaseFirestore.instance.collection('payments');

  Future<String> addPayment(Payment payment) async {
    DocumentReference docRef = await _paymentCollection.add(payment.toMap());
    return docRef.id;
  }

  Future<List<Payment>> fetchPayments() async {
    QuerySnapshot snapshot =
        await _paymentCollection.orderBy('paymentDate', descending: true).get();
    return snapshot.docs
        .map((doc) =>
            Payment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<List<Payment>> fetchPaymentsByTenantId(String tenantId) async {
    QuerySnapshot snapshot =
        await _paymentCollection.where('tenantId', isEqualTo: tenantId).get();
    return snapshot.docs
        .map((doc) =>
            Payment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<List<Payment>> fetchPaymentsByManagerId(String managerId) async {
    final QuerySnapshot snapshot = await _paymentCollection
        .where('managerId', isEqualTo: managerId)
        .orderBy('paymentDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) =>
            Payment.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

}
