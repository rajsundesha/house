import 'package:flutter/material.dart';

enum PaymentStatus { pending, completed, failed, refunded }

class Payment {
  final String id;
  final String leaseId;
  final String tenantId;
  final String propertyId;
  final double amount;
  final DateTime dueDate;
  final DateTime? paidDate;
  final PaymentStatus status;
  final String? transactionId;
  final String? notes;

  Payment({
    required this.id,
    required this.leaseId,
    required this.tenantId,
    required this.propertyId,
    required this.amount,
    required this.dueDate,
    this.paidDate,
    this.status = PaymentStatus.pending,
    this.transactionId,
    this.notes,
  });

  factory Payment.fromMap(Map<String, dynamic> map, String id) {
    return Payment(
      id: id,
      leaseId: map['leaseId'],
      tenantId: map['tenantId'],
      propertyId: map['propertyId'],
      amount: map['amount'].toDouble(),
      dueDate: DateTime.parse(map['dueDate']),
      paidDate: map['paidDate'] != null ? DateTime.parse(map['paidDate']) : null,
      status: PaymentStatus.values.byName(map['status'] ?? 'pending'),
      transactionId: map['transactionId'],
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'leaseId': leaseId,
      'tenantId': tenantId,
      'propertyId': propertyId,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'paidDate': paidDate?.toIso8601String(),
      'status': status.name,
      'transactionId': transactionId,
      'notes': notes,
    };
  }

  Payment copyWith({
    String? id,
    String? leaseId,
    String? tenantId,
    String? propertyId,
    double? amount,
    DateTime? dueDate,
    DateTime? paidDate,
    PaymentStatus? status,
    String? transactionId,
    String? notes,
  }) {
    return Payment(
      id: id ?? this.id,
      leaseId: leaseId ?? this.leaseId,
      tenantId: tenantId ?? this.tenantId,
      propertyId: propertyId ?? this.propertyId,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      paidDate: paidDate ?? this.paidDate,
      status: status ?? this.status,
      transactionId: transactionId ?? this.transactionId,
      notes: notes ?? this.notes,
    );
  }
}