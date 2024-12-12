import 'package:cloud_firestore/cloud_firestore.dart';

class TenantMember {
  String name;
  String relation;
  String aadharNumber;
  String? phoneNumber;

  TenantMember({
    required this.name,
    required this.relation,
    required this.aadharNumber,
    this.phoneNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'relation': relation,
      'aadharNumber': aadharNumber,
      'phoneNumber': phoneNumber,
    };
  }

  factory TenantMember.fromMap(Map<String, dynamic> map) {
    return TenantMember(
      name: map['name'] ?? '',
      relation: map['relation'] ?? '',
      aadharNumber: map['aadharNumber'] ?? '',
      phoneNumber: map['phoneNumber'],
    );
  }
}

class TenantDocument {
  String type; // 'aadhar', 'pan', 'other'
  String documentId;
  String documentUrl;
  DateTime uploadedAt;

  TenantDocument({
    required this.type,
    required this.documentId,
    required this.documentUrl,
    required this.uploadedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'documentId': documentId,
      'documentUrl': documentUrl,
      'uploadedAt': Timestamp.fromDate(uploadedAt),
    };
  }

  factory TenantDocument.fromMap(Map<String, dynamic> map) {
    return TenantDocument(
      type: map['type'] ?? '',
      documentId: map['documentId'] ?? '',
      documentUrl: map['documentUrl'] ?? '',
      uploadedAt: (map['uploadedAt'] as Timestamp).toDate(),
    );
  }
}

class Tenant {
  String id;
  String propertyId;
  String name;
  Map<String, String> contactInfo;
  String category;
  DateTime leaseStartDate;
  DateTime leaseEndDate;
  bool advancePaid;
  double advanceAmount;
  double rentAdjustment; // New field for dynamic rent adjustments
  List<TenantMember> familyMembers;
  List<TenantDocument> documents;
  DateTime createdAt;
  DateTime? lastUpdatedAt;
  String? createdBy;
  String? updatedBy;

  Tenant({
    required this.id,
    required this.propertyId,
    required this.name,
    required this.contactInfo,
    required this.category,
    required this.leaseStartDate,
    required this.leaseEndDate,
    required this.advancePaid,
    required this.advanceAmount,
    this.rentAdjustment = 0.0,
    List<TenantMember>? familyMembers,
    List<TenantDocument>? documents,
    DateTime? createdAt,
    this.lastUpdatedAt,
    this.createdBy,
    this.updatedBy,
  })  : this.familyMembers = familyMembers ?? [],
        this.documents = documents ?? [],
        this.createdAt = createdAt ?? DateTime.now();

  double getEffectiveRent(double baseRent) {
    double effective = baseRent - rentAdjustment;
    return effective < 0 ? 0 : effective;
  }

  factory Tenant.fromMap(Map<String, dynamic> data, String documentId) {
    return Tenant(
      id: documentId,
      propertyId: data['propertyId'] ?? '',
      name: data['name'] ?? '',
      contactInfo: Map<String, String>.from(data['contactInfo'] ?? {}),
      category: data['category'] ?? '',
      leaseStartDate: (data['leaseStartDate'] as Timestamp).toDate(),
      leaseEndDate: (data['leaseEndDate'] as Timestamp).toDate(),
      advancePaid: data['advancePaid'] ?? false,
      advanceAmount: (data['advanceAmount'] ?? 0).toDouble(),
      rentAdjustment: (data['rentAdjustment'] ?? 0.0).toDouble(),
      familyMembers: (data['familyMembers'] as List<dynamic>? ?? [])
          .map((member) => TenantMember.fromMap(member))
          .toList(),
      documents: (data['documents'] as List<dynamic>? ?? [])
          .map((doc) => TenantDocument.fromMap(doc))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastUpdatedAt: (data['lastUpdatedAt'] as Timestamp?)?.toDate(),
      createdBy: data['createdBy'],
      updatedBy: data['updatedBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'name': name,
      'contactInfo': contactInfo,
      'category': category,
      'leaseStartDate': Timestamp.fromDate(leaseStartDate),
      'leaseEndDate': Timestamp.fromDate(leaseEndDate),
      'advancePaid': advancePaid,
      'advanceAmount': advanceAmount,
      'rentAdjustment': rentAdjustment,
      'familyMembers': familyMembers.map((member) => member.toMap()).toList(),
      'documents': documents.map((doc) => doc.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastUpdatedAt':
          lastUpdatedAt != null ? Timestamp.fromDate(lastUpdatedAt!) : null,
      'createdBy': createdBy,
      'updatedBy': updatedBy,
    };
  }
}
