class Tenant {
  final String id;
  final String name;
  final String phone;
  final String email;
  final String? idNumber;
  final DateTime? dateOfBirth;
  final String? emergencyContact;
  final List<String> leaseIds;

  Tenant({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.idNumber,
    this.dateOfBirth,
    this.emergencyContact,
    this.leaseIds = const [],
  });

  factory Tenant.fromMap(Map<String, dynamic> map, String id) {
    return Tenant(
      id: id,
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      idNumber: map['idNumber'],
      dateOfBirth: map['dateOfBirth'] != null ? DateTime.parse(map['dateOfBirth']) : null,
      emergencyContact: map['emergencyContact'],
      leaseIds: List<String>.from(map['leaseIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'phone': phone,
      'email': email,
      'idNumber': idNumber,
      'dateOfBirth': dateOfBirth?.toIso8601String(),
      'emergencyContact': emergencyContact,
      'leaseIds': leaseIds,
    };
  }

  Tenant copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? idNumber,
    DateTime? dateOfBirth,
    String? emergencyContact,
    List<String>? leaseIds,
  }) {
    return Tenant(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      idNumber: idNumber ?? this.idNumber,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      leaseIds: leaseIds ?? this.leaseIds,
    );
  }
}