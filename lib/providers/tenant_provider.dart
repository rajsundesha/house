import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental_app/models/tenant.dart';

class TenantProvider with ChangeNotifier {
  List<Tenant> _tenants = [];

  List<Tenant> get tenants => _tenants;

  final CollectionReference _tenantCollection =
      FirebaseFirestore.instance.collection('tenants');

  // Fetch all tenants
  Future<void> fetchTenants() async {
    try {
      QuerySnapshot snapshot = await _tenantCollection.get();
      _tenants = snapshot.docs
          .map((doc) =>
              Tenant.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching tenants: $e');
    }
  }

  // Fetch tenants by property ID
  Future<List<Tenant>> fetchTenantsByPropertyId(String propertyId) async {
    try {
      QuerySnapshot snapshot = await _tenantCollection
          .where('propertyId', isEqualTo: propertyId)
          .get();
      List<Tenant> tenants = snapshot.docs
          .map((doc) =>
              Tenant.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      return tenants;
    } catch (e) {
      print('Error fetching tenants by property ID: $e');
      return [];
    }
  }

  // Fetch tenants by manager ID (for properties assigned to the manager)
// Update TenantProvider with a fixed fetchTenantsByManagerId method:
  Future<List<Tenant>> fetchTenantsByManagerId(String managerId) async {
    try {
      // First, get all properties assigned to the manager
      QuerySnapshot propertySnapshot = await FirebaseFirestore.instance
          .collection('properties')
          .where('assignedManagerId', isEqualTo: managerId)
          .get();

      List<String> propertyIds =
          propertySnapshot.docs.map((doc) => doc.id).toList();

      if (propertyIds.isEmpty) return [];

      // Then get all tenants for these properties
      QuerySnapshot tenantSnapshot = await _tenantCollection
          .where('propertyId', whereIn: propertyIds)
          .get();

      return tenantSnapshot.docs
          .map((doc) =>
              Tenant.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error fetching tenants by manager ID: $e');
      throw e;
    }
  }

  // Add a new tenant
  Future<void> addTenant(Tenant tenant) async {
    try {
      DocumentReference docRef = await _tenantCollection.add(tenant.toMap());
      tenant.id = docRef.id;
      _tenants.add(tenant);
      notifyListeners();
    } catch (e) {
      print('Error adding tenant: $e');
    }
  }

  // Update an existing tenant
  Future<void> updateTenant(Tenant tenant) async {
    try {
      await _tenantCollection.doc(tenant.id).update(tenant.toMap());
      int index = _tenants.indexWhere((t) => t.id == tenant.id);
      if (index != -1) {
        _tenants[index] = tenant;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating tenant: $e');
    }
  }

  // Delete a tenant
  Future<void> deleteTenant(String tenantId) async {
    try {
      await _tenantCollection.doc(tenantId).delete();
      _tenants.removeWhere((tenant) => tenant.id == tenantId);
      notifyListeners();
    } catch (e) {
      print('Error deleting tenant: $e');
    }
  }

  // Get a tenant by ID
  Future<Tenant?> getTenantById(String tenantId) async {
    try {
      DocumentSnapshot doc = await _tenantCollection.doc(tenantId).get();
      if (doc.exists) {
        return Tenant.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        print('Tenant not found');
        return null;
      }
    } catch (e) {
      print('Error getting tenant by ID: $e');
      return null;
    }
  }
}
