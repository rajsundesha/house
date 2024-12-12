import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import '../models/property.dart';

class PropertyRepository {
  final CollectionReference _propertyCollection =
      FirebaseFirestore.instance.collection('properties');
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> addProperty(Property property, List<File> images) async {
    List<String> imageUrls = [];
    for (var image in images) {
      final ref =
          _storage.ref().child('properties/${DateTime.now().toString()}');
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      imageUrls.add(url);
    }

    property.images = imageUrls;
    DocumentReference docRef = await _propertyCollection.add(property.toMap());
    return docRef.id;
  }

  Future<void> updateProperty(Property property) async {
    await _propertyCollection.doc(property.id).update(property.toMap());
  }

  Future<void> deleteProperty(String propertyId) async {
    DocumentSnapshot doc = await _propertyCollection.doc(propertyId).get();
    if (doc.exists) {
      Property property =
          Property.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      for (String imageUrl in property.images) {
        try {
          await _storage.refFromURL(imageUrl).delete();
        } catch (e) {
          print('Error deleting image: $e');
        }
      }
    }

    await _propertyCollection.doc(propertyId).delete();
  }

  Future<void> assignManager(String propertyId, String managerId) async {
    await _propertyCollection.doc(propertyId).update({
      'assignedManagerId': managerId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<Property?> getPropertyById(String propertyId) async {
    DocumentSnapshot doc = await _propertyCollection.doc(propertyId).get();
    if (!doc.exists) return null;
    return Property.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> addMaintenanceRecord(
      String propertyId, MaintenanceRecord record) async {
    await _propertyCollection.doc(propertyId).update({
      'maintenanceRecords': FieldValue.arrayUnion([record.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Add the new method for updating maintenance records
  Future<void> updateMaintenanceRecord(String propertyId,
      MaintenanceRecord oldRecord, MaintenanceRecord newRecord) async {
    try {
      // First remove the old record
      await _propertyCollection.doc(propertyId).update({
        'maintenanceRecords': FieldValue.arrayRemove([oldRecord.toMap()]),
      });

      // Then add the new record
      await _propertyCollection.doc(propertyId).update({
        'maintenanceRecords': FieldValue.arrayUnion([newRecord.toMap()]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating maintenance record: $e');
      throw e;
    }
  }


Future<void> updateRentAmount(
      String propertyId, double newAmount, String reason) async {
    try {
      final now = DateTime.now().toIso8601String();
      final propertyDoc = await _propertyCollection.doc(propertyId).get();

      if (propertyDoc.exists) {
        final currentData = propertyDoc.data() as Map<String, dynamic>;
        final currentAmount =
            (currentData['currentRentAmount'] ?? 0.0).toDouble();

        final historyEntry = {
          'amount': newAmount.toDouble(),
          'reason': reason,
          'previousAmount': currentAmount,
          'timestamp': FieldValue.serverTimestamp(),
        };

        await _propertyCollection.doc(propertyId).update({
          'currentRentAmount': newAmount.toDouble(),
          'flexibleRentHistory.$now': historyEntry,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print('Error updating rent amount: $e');
      throw e;
    }
  }
  Future<void> deleteMaintenanceRecord(
      String propertyId, MaintenanceRecord record) async {
    await _propertyCollection.doc(propertyId).update({
      'maintenanceRecords': FieldValue.arrayRemove([record.toMap()]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Property>> fetchProperties({
    String? status,
    String? furnishingStatus,
    double? minPrice,
    double? maxPrice,
    double? minArea,
    double? maxArea,
    List<String>? amenities,
    String? location,
    bool? sortByRentAsc,
  }) async {
    Query query = _propertyCollection;

    if (status != null && status.toLowerCase() != 'all') {
      query = query.where('status', isEqualTo: status.toLowerCase());
    }

    if (furnishingStatus != null && furnishingStatus.toLowerCase() != 'all') {
      query = query.where('furnishingStatus',
          isEqualTo: furnishingStatus.toLowerCase());
    }

    if (location != null && location.isNotEmpty) {
      query = query.where('location', isEqualTo: location);
    }

    if (sortByRentAsc != null) {
      query = query.orderBy('currentRentAmount', descending: !sortByRentAsc);
    }

    QuerySnapshot snapshot = await query.get();
    List<Property> properties = snapshot.docs
        .map((doc) =>
            Property.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .where((property) {
      bool matchesPrice = true;
      bool matchesArea = true;
      bool matchesAmenities = true;

      if (minPrice != null && maxPrice != null) {
        matchesPrice = property.currentRentAmount >= minPrice &&
            property.currentRentAmount <= maxPrice;
      }

      if (minArea != null && maxArea != null) {
        double propertyArea = double.tryParse(property.size) ?? 0;
        matchesArea = propertyArea >= minArea && propertyArea <= maxArea;
      }

      if (amenities != null && amenities.isNotEmpty) {
        matchesAmenities =
            amenities.every((amenity) => property.amenities.contains(amenity));
      }

      return matchesPrice && matchesArea && matchesAmenities;
    }).toList();

    return properties;
  }

  Future<List<Property>> fetchPropertiesByManagerId(String managerId) async {
    final QuerySnapshot snapshot = await _propertyCollection
        .where('assignedManagerId', isEqualTo: managerId)
        .get();

    return snapshot.docs
        .map((doc) =>
            Property.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }

  Future<void> updatePropertyStatus(String propertyId, String status) async {
    await _propertyCollection.doc(propertyId).update({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> addPropertyImages(
      String propertyId, List<File> newImages) async {
    List<String> newImageUrls = [];
    for (var image in newImages) {
      final ref =
          _storage.ref().child('properties/${DateTime.now().toString()}');
      final uploadTask = ref.putFile(image);
      final snapshot = await uploadTask.whenComplete(() {});
      final url = await snapshot.ref.getDownloadURL();
      newImageUrls.add(url);
    }

    await _propertyCollection.doc(propertyId).update({
      'images': FieldValue.arrayUnion(newImageUrls),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removePropertyImage(String propertyId, String imageUrl) async {
    try {
      await _storage.refFromURL(imageUrl).delete();
      await _propertyCollection.doc(propertyId).update({
        'images': FieldValue.arrayRemove([imageUrl]),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error removing image: $e');
      throw e;
    }
  }

  Future<void> updateLocationCoordinates(
      String propertyId, Map<String, double> coordinates) async {
    await _propertyCollection.doc(propertyId).update({
      'locationCoordinates': coordinates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<Property>> searchProperties(String searchTerm) async {
    // Search in address and location fields
    QuerySnapshot snapshot = await _propertyCollection
        .orderBy('address')
        .startAt([searchTerm]).endAt([searchTerm + '\uf8ff']).get();

    QuerySnapshot locationSnapshot = await _propertyCollection
        .orderBy('location')
        .startAt([searchTerm]).endAt([searchTerm + '\uf8ff']).get();

    Set<Property> properties = {};

    properties.addAll(snapshot.docs.map(
        (doc) => Property.fromMap(doc.data() as Map<String, dynamic>, doc.id)));
    properties.addAll(locationSnapshot.docs.map(
        (doc) => Property.fromMap(doc.data() as Map<String, dynamic>, doc.id)));

    return properties.toList();
  }

  Stream<Property> streamProperty(String propertyId) {
    return _propertyCollection.doc(propertyId).snapshots().map((snapshot) =>
        Property.fromMap(snapshot.data() as Map<String, dynamic>, snapshot.id));
  }

  Future<Map<String, dynamic>> getPropertyStatistics(String propertyId) async {
    DocumentSnapshot doc = await _propertyCollection.doc(propertyId).get();
    if (!doc.exists) throw Exception('Property not found');

    Property property =
        Property.fromMap(doc.data() as Map<String, dynamic>, doc.id);

    double totalMaintenanceCost = property.maintenanceRecords
        .map((record) => record.cost)
        .fold(0, (prev, curr) => prev + curr);

    int pendingMaintenanceCount = property.maintenanceRecords
        .where((record) => record.status == 'pending')
        .length;

    return {
      'totalMaintenanceCost': totalMaintenanceCost,
      'pendingMaintenanceCount': pendingMaintenanceCount,
      'rentHistory': property.flexibleRentHistory,
      'currentRent': property.currentRentAmount,
      'baseRent': property.baseRentAmount,
      'yearlyIncrease': property.yearlyIncreasePercentage,
    };
  }
}
