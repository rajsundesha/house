import 'package:freezed_annotation/freezed_annotation.dart';

part 'property.freezed.dart';
part 'property.g.dart';

@freezed
class Property with _$Property {
  const factory Property({
    required String id,
    required String name,
    required String address,
    required double rent,
    String? description,
    String? imageUrl,
    String? ownerId,
    String? managerId,
    @Default(false) bool isOccupied,
  }) = _Property;

  factory Property.fromMap(Map<String, dynamic> map, String id) {
    return Property(
      id: id,
      name: map['name'] as String,
      address: map['address'] as String,
      rent: (map['rent'] as num).toDouble(),
      description: map['description'] as String?,
      imageUrl: map['imageUrl'] as String?,
      ownerId: map['ownerId'] as String?,
      managerId: map['managerId'] as String?,
      isOccupied: map['isOccupied'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'address': address,
      'rent': rent,
      'description': description,
      'imageUrl': imageUrl,
      'ownerId': ownerId,
      'managerId': managerId,
      'isOccupied': isOccupied,
    };
  }
}