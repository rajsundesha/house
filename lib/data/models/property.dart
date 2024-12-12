import 'package:cloud_firestore/cloud_firestore.dart';

class MaintenanceRecord {
  String title;
  String description;
  double cost;
  DateTime date;
  String status;

  MaintenanceRecord({
    required this.title,
    required this.description,
    required this.cost,
    required this.date,
    required this.status,
  });

  factory MaintenanceRecord.fromMap(Map<String, dynamic> data) {
    return MaintenanceRecord(
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      cost: (data['cost'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      status: data['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'cost': cost,
      'date': Timestamp.fromDate(date),
      'status': status,
    };
  }
}

class Property {
  String id;
  String address;
  String location;
  double baseRentAmount;
  double currentRentAmount;
  double maintenanceCharge;
  double yearlyIncreasePercentage;
  String status;
  String size;
  String? assignedManagerId;
  String? description;
  int bedrooms;
  int bathrooms;
  String furnishingStatus;
  bool parking;
  List<String> amenities;
  List<String> images;
  Map<String, double> locationCoordinates;
  List<MaintenanceRecord> maintenanceRecords;
  DateTime createdAt;
  DateTime updatedAt;
  Map<String, dynamic> flexibleRentHistory;

  Property({
    required this.id,
    required this.address,
    required this.location,
    required this.baseRentAmount,
    required this.currentRentAmount,
    required this.maintenanceCharge,
    this.yearlyIncreasePercentage = 5.0,
    required this.status,
    required this.size,
    this.assignedManagerId,
    this.description = '',
    this.bedrooms = 0,
    this.bathrooms = 0,
    this.furnishingStatus = 'unfurnished',
    this.parking = false,
    List<String>? amenities,
    List<String>? images,
    Map<String, double>? locationCoordinates,
    List<MaintenanceRecord>? maintenanceRecords,
    required this.createdAt,
    required this.updatedAt,
    Map<String, dynamic>? flexibleRentHistory,
  })  : amenities = amenities ?? [],
        images = images ?? [],
        locationCoordinates = locationCoordinates ?? {},
        maintenanceRecords = maintenanceRecords ?? [],
        flexibleRentHistory = flexibleRentHistory ?? {};

  factory Property.fromMap(Map<String, dynamic> data, String documentId) {
    return Property(
      id: documentId,
      address: data['address'] ?? '',
      location: data['location'] ?? '',
      baseRentAmount: (data['baseRentAmount'] ?? 0).toDouble(),
      currentRentAmount: (data['currentRentAmount'] ?? 0).toDouble(),
      maintenanceCharge: (data['maintenanceCharge'] ?? 0).toDouble(),
      yearlyIncreasePercentage:
          (data['yearlyIncreasePercentage'] ?? 5).toDouble(),
      status: data['status'] ?? 'vacant',
      size: data['size'] ?? '',
      assignedManagerId: data['assignedManagerId'],
      description: data['description'] ?? '',
      bedrooms: data['bedrooms'] ?? 0,
      bathrooms: data['bathrooms'] ?? 0,
      furnishingStatus: data['furnishingStatus'] ?? 'unfurnished',
      parking: data['parking'] ?? false,
      amenities: List<String>.from(data['amenities'] ?? []),
      images: List<String>.from(data['images'] ?? []),
      locationCoordinates:
          Map<String, double>.from(data['locationCoordinates'] ?? {}),
      maintenanceRecords: (data['maintenanceRecords'] as List<dynamic>? ?? [])
          .map((record) => MaintenanceRecord.fromMap(record))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      flexibleRentHistory:
          Map<String, dynamic>.from(data['flexibleRentHistory'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'address': address,
      'location': location,
      'baseRentAmount': baseRentAmount,
      'currentRentAmount': currentRentAmount,
      'maintenanceCharge': maintenanceCharge,
      'yearlyIncreasePercentage': yearlyIncreasePercentage,
      'status': status,
      'size': size,
      'assignedManagerId': assignedManagerId,
      'description': description,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'furnishingStatus': furnishingStatus,
      'parking': parking,
      'amenities': amenities,
      'images': images,
      'locationCoordinates': locationCoordinates,
      'maintenanceRecords':
          maintenanceRecords.map((record) => record.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'flexibleRentHistory': flexibleRentHistory,
    };
  }

  void updateRentAmount(double newAmount, String reason) {
    currentRentAmount = newAmount;
    final now = DateTime.now().toIso8601String();
    flexibleRentHistory[now] = {
      'amount': newAmount,
      'reason': reason,
      'previousAmount': currentRentAmount,
      'timestamp':
          Timestamp.fromDate(DateTime.now()), // Use Timestamp instead of string
    };
  }

  Property copyWith({
    String? id,
    String? address,
    String? location,
    double? baseRentAmount,
    double? currentRentAmount,
    double? maintenanceCharge,
    double? yearlyIncreasePercentage,
    String? status,
    String? size,
    String? assignedManagerId,
    String? description,
    int? bedrooms,
    int? bathrooms,
    String? furnishingStatus,
    bool? parking,
    List<String>? amenities,
    List<String>? images,
    Map<String, double>? locationCoordinates,
    List<MaintenanceRecord>? maintenanceRecords,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? flexibleRentHistory,
  }) {
    return Property(
      id: id ?? this.id,
      address: address ?? this.address,
      location: location ?? this.location,
      baseRentAmount: baseRentAmount ?? this.baseRentAmount,
      currentRentAmount: currentRentAmount ?? this.currentRentAmount,
      maintenanceCharge: maintenanceCharge ?? this.maintenanceCharge,
      yearlyIncreasePercentage:
          yearlyIncreasePercentage ?? this.yearlyIncreasePercentage,
      status: status ?? this.status,
      size: size ?? this.size,
      assignedManagerId: assignedManagerId ?? this.assignedManagerId,
      description: description ?? this.description,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      furnishingStatus: furnishingStatus ?? this.furnishingStatus,
      parking: parking ?? this.parking,
      amenities: amenities ?? List.from(this.amenities),
      images: images ?? List.from(this.images),
      locationCoordinates:
          locationCoordinates ?? Map.from(this.locationCoordinates),
      maintenanceRecords:
          maintenanceRecords ?? List.from(this.maintenanceRecords),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      flexibleRentHistory:
          flexibleRentHistory ?? Map.from(this.flexibleRentHistory),
    );
  }

  double calculateNextYearRent() {
    return currentRentAmount * (1 + (yearlyIncreasePercentage / 100));
  }
}
