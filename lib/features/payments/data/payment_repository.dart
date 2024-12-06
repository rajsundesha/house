import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/payment.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Payment>> getPayments() async {
    final snapshot = await _firestore.collection('payments').get();
    return snapshot.docs.map((doc) => Payment.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<Payment>> getPaymentsByProperty(String propertyId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('propertyId', isEqualTo: propertyId)
        .get();
    return snapshot.docs.map((doc) => Payment.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<Payment>> getPaymentsByTenant(String tenantId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('tenantId', isEqualTo: tenantId)
        .get();
    return snapshot.docs.map((doc) => Payment.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<Payment>> getPaymentsByLease(String leaseId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('leaseId', isEqualTo: leaseId)
        .get();
    return snapshot.docs.map((doc) => Payment.fromMap(doc.data(), doc.id)).toList();
  }

  Future<Payment> createPayment(Payment payment) async {
    final docRef = await _firestore.collection('payments').add(payment.toMap());
    return payment.copyWith(id: docRef.id);
  }

  Future<void> updatePayment(Payment payment) async {
    await _firestore.collection('payments').doc(payment.id).update(payment.toMap());
  }

  Future<void> deletePayment(String id) async {
    await _firestore.collection('payments').doc(id).delete();
  }
}