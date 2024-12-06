import 'package:freezed_annotation/freezed_annotation.dart';

enum LeaseStatus { active, expired, terminated }

class Lease {
  final String id;
  final String propertyId;
  final String tenantId;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyRent;
  final double securityDeposit;
  final String? terms;
  final LeaseStatus status;

  Lease({
    required this.id,
    required this.propertyId,
    required this.tenantId,
    required this.startDate,
    required this.endDate,
    required this.monthlyRent,
    required this.securityDeposit,
    this.terms,
    this.status = LeaseStatus.active,
  });

  factory Lease.fromMap(Map<String, dynamic> map, String id) {
    return Lease(
      id: id,
      propertyId: map['propertyId'],
      tenantId: map['tenantId'],
      startDate: DateTime.parse(map['startDate']),
      endDate: DateTime.parse(map['endDate']),
      monthlyRent: map['monthlyRent'].toDouble(),
      securityDeposit: map['securityDeposit'].toDouble(),
      terms: map['terms'],
      status: LeaseStatus.values.byName(map['status'] ?? 'active'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'propertyId': propertyId,
      'tenantId': tenantId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'monthlyRent': monthlyRent,
      'securityDeposit': securityDeposit,
      'terms': terms,
      'status': status.name,
    };
  }

  Lease copyWith({
    String? id,
    String? propertyId,
    String? tenantId,
    DateTime? startDate,
    DateTime? endDate,
    double? monthlyRent,
    double? securityDeposit,
    String? terms,
    LeaseStatus? status,
  }) {
    return Lease(
      id: id ?? this.id,
      propertyId: propertyId ?? this.propertyId,
      tenantId: tenantId ?? this.tenantId,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      monthlyRent: monthlyRent ?? this.monthlyRent,
      securityDeposit: securityDeposit ?? this.securityDeposit,
      terms: terms ?? this.terms,
      status: status ?? this.status,
    );
  }
}