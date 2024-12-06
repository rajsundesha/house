import 'package:cloud_firestore/cloud_firestore.dart';

class Property {
  String id;
  String address;
  double rentAmount;
  String status;
  String size;
  String? assignedManagerId;
  String? description;
  int bedrooms;
  int bathrooms;
  bool furnished;
  bool parking;
  List<String> amenities;
  DateTime createdAt;
  DateTime updatedAt;

  Property({
    required this.id,
    required this.address,
    required this.rentAmount,
    required this.status,
    required this.size,
    this.assignedManagerId,
    this.description = '',
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.furnished = false,
    this.parking = false,
    List<String>? amenities,
    required this.createdAt,
    required this.updatedAt,
  }) : this.amenities = amenities ?? [];

  factory Property.fromMap(Map<String, dynamic> data, String documentId) {
    return Property(
      id: documentId,
      address: data['address'] ?? '',
      rentAmount: (data['rentAmount'] ?? 0).toDouble(),
      status: data['status'] ?? 'vacant',
      size: data['size'] ?? '',
      assignedManagerId: data['assignedManagerId'],
      description: data['description'],
      bedrooms: data['bedrooms'] ?? 0,
      bathrooms: data['bathrooms'] ?? 0,
      furnished: data['furnished'] ?? false,
      parking: data['parking'] ?? false,
      amenities: List<String>.from(data['amenities'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'rentAmount': rentAmount,
      'status': status,
      'size': size,
      'assignedManagerId': assignedManagerId,
      'description': description,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'furnished': furnished,
      'parking': parking,
      'amenities': amenities,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
