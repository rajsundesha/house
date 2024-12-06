import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:house_rental_app/models/property.dart';

class PropertyProvider with ChangeNotifier {
  List<Property> _properties = [];

  List<Property> get properties => _properties;

  final CollectionReference _propertyCollection =
      FirebaseFirestore.instance.collection('properties');

  // Fetch all properties
  Future<void> fetchProperties() async {
    try {
      QuerySnapshot snapshot = await _propertyCollection.get();
      _properties = snapshot.docs
          .map((doc) =>
              Property.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching properties: $e');
    }
  }

// Update PropertyProvider with a fixed fetchPropertiesByManagerId method:
  Future<List<Property>> fetchPropertiesByManagerId(String managerId) async {
    try {
      final QuerySnapshot snapshot = await _propertyCollection
          .where('assignedManagerId', isEqualTo: managerId)
          .get();

      return snapshot.docs
          .map((doc) =>
              Property.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error fetching properties by manager ID: $e');
      throw e;
    }
  }

  // Add a new property
  Future<void> addProperty(Property property) async {
    try {
      DocumentReference docRef =
          await _propertyCollection.add(property.toMap());
      property.id = docRef.id;
      _properties.add(property);
      notifyListeners();
    } catch (e) {
      print('Error adding property: $e');
    }
  }

  // Update an existing property
  Future<void> updateProperty(Property property) async {
    try {
      await _propertyCollection.doc(property.id).update(property.toMap());
      int index = _properties.indexWhere((p) => p.id == property.id);
      if (index != -1) {
        _properties[index] = property;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating property: $e');
    }
  }

  Future<void> updatePropertyManager(
      String propertyId, String managerId) async {
    try {
      await _propertyCollection.doc(propertyId).update({
        'assignedManagerId': managerId,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      int index = _properties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        _properties[index].assignedManagerId = managerId;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating property manager: $e');
      throw e;
    }
  }

  // Delete a property
  Future<void> deleteProperty(String propertyId) async {
    try {
      await _propertyCollection.doc(propertyId).delete();
      _properties.removeWhere((property) => property.id == propertyId);
      notifyListeners();
    } catch (e) {
      print('Error deleting property: $e');
    }
  }

  // Update property status (e.g., 'occupied', 'vacant')
  Future<void> updatePropertyStatus(String propertyId, String status) async {
    try {
      await _propertyCollection.doc(propertyId).update({'status': status});
      int index = _properties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        _properties[index].status = status;
        notifyListeners();
      }
    } catch (e) {
      print('Error updating property status: $e');
    }
  }

  // Get a property by its ID
  Future<Property?> getPropertyById(String propertyId) async {
    try {
      DocumentSnapshot doc = await _propertyCollection.doc(propertyId).get();
      if (doc.exists) {
        return Property.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        print('Property not found');
        return null;
      }
    } catch (e) {
      print('Error getting property by ID: $e');
      return null;
    }
  }

  // Fetch properties with filtering and sorting
  Future<void> fetchPropertiesWithFilter({
    String? status,
    bool? sortByRentAscending,
  }) async {
    try {
      Query query = _propertyCollection;

      if (status != null && status != 'All') {
        query = query.where('status', isEqualTo: status.toLowerCase());
      }

      if (sortByRentAscending != null) {
        query = query.orderBy('rentAmount', descending: !sortByRentAscending);
      }

      QuerySnapshot snapshot = await query.get();
      _properties = snapshot.docs
          .map((doc) =>
              Property.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      notifyListeners();
    } catch (e) {
      print('Error fetching properties with filter: $e');
    }
  }

  //   // Add statistics methods
  // Future<Map<String, int>> getOccupancyStats() async {
  //   // Implementation
  // }

  // Future<List<Property>> getExpiringLeases() async {
  //   // Implementation
  // }
}
