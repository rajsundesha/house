import 'package:cloud_firestore/cloud_firestore.dart';
import '../domain/lease.dart';

class LeaseRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Lease>> getLeases() async {
    final snapshot = await _firestore.collection('leases').get();
    return snapshot.docs.map((doc) => Lease.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<Lease>> getLeasesByProperty(String propertyId) async {
    final snapshot = await _firestore
        .collection('leases')
        .where('propertyId', isEqualTo: propertyId)
        .get();
    return snapshot.docs.map((doc) => Lease.fromMap(doc.data(), doc.id)).toList();
  }

  Future<List<Lease>> getLeasesByTenant(String tenantId) async {
    final snapshot = await _firestore
        .collection('leases')
        .where('tenantId', isEqualTo: tenantId)
        .get();
    return snapshot.docs.map((doc) => Lease.fromMap(doc.data(), doc.id)).toList();
  }

  Future<Lease> createLease(Lease lease) async {
    final docRef = await _firestore.collection('leases').add(lease.toMap());
    return lease.copyWith(id: docRef.id);
  }

  Future<void> updateLease(Lease lease) async {
    await _firestore.collection('leases').doc(lease.id).update(lease.toMap());
  }

  Future<void> deleteLease(String id) async {
    await _firestore.collection('leases').doc(id).delete();
  }
}