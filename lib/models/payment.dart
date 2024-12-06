import 'package:cloud_firestore/cloud_firestore.dart';

class Payment {
  String id;
  String tenantId;
  String propertyId;
  double amount;
  DateTime paymentDate;
  String paymentMethod; // 'offline'
  String paymentStatus; // 'completed'
  String? managerId;
  String? notes;

  Payment({
    required this.id,
    required this.tenantId,
    required this.propertyId,
    required this.amount,
    required this.paymentDate,
    required this.paymentMethod,
    required this.paymentStatus,
    this.managerId,
    this.notes,
  });

  // From Map
  factory Payment.fromMap(Map<String, dynamic> data, String documentId) {
    return Payment(
      id: documentId,
      tenantId: data['tenantId'] ?? '',
      propertyId: data['propertyId'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      paymentDate: (data['paymentDate'] as Timestamp).toDate(),
      paymentMethod: data['paymentMethod'] ?? 'offline',
      paymentStatus: data['paymentStatus'] ?? 'completed',
      managerId: data['managerId'],
      notes: data['notes'],
    );
  }

  // To Map
  Map<String, dynamic> toMap() {
    return {
      'tenantId': tenantId,
      'propertyId': propertyId,
      'amount': amount,
      'paymentDate': Timestamp.fromDate(paymentDate),
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'managerId': managerId,
      'notes': notes,
    };
  }
}
