import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental_app/data/models/tenant.dart';

class TenantRepository {
  final CollectionReference _tenantCollection =
      FirebaseFirestore.instance.collection('tenants');

  Future<String> addTenant(Tenant tenant) async {
    DocumentReference docRef = await _tenantCollection.add(tenant.toMap());
    return docRef.id;
  }

  Future<void> updateTenant(Tenant tenant) async {
    await _tenantCollection.doc(tenant.id).update(tenant.toMap());
  }

  Future<void> deleteTenant(String tenantId) async {
    await _tenantCollection.doc(tenantId).delete();
  }

  Future<Tenant?> getTenantById(String tenantId) async {
    DocumentSnapshot doc = await _tenantCollection.doc(tenantId).get();
    if (!doc.exists) return null;
    return Tenant.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<List<Tenant>> fetchTenants() async {
    QuerySnapshot snapshot = await _tenantCollection.get();
    return snapshot.docs
        .map(
            (doc) => Tenant.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<List<Tenant>> fetchTenantsByPropertyId(String propertyId) async {
    QuerySnapshot snapshot = await _tenantCollection
        .where('propertyId', isEqualTo: propertyId)
        .get();
    return snapshot.docs
        .map(
            (doc) => Tenant.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<List<Tenant>> fetchTenantsByManagerId(String managerId) async {
    // First get properties
    QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
        .collection('properties')
        .where('assignedManagerId', isEqualTo: managerId)
        .get();

    List<String> propertyIds =
        propertySnapshot.docs.map((doc) => doc.id).toList();
    if (propertyIds.isEmpty) return [];

    QuerySnapshot tenantSnapshot =
        await _tenantCollection.where('propertyId', whereIn: propertyIds).get();

    return tenantSnapshot.docs
        .map(
            (doc) => Tenant.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}
