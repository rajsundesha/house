import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/property.dart';
import '../../data/property_repository.dart';

final propertyRepositoryProvider = Provider((ref) => PropertyRepository());

final propertyProvider = StateNotifierProvider<PropertyNotifier, List<Property>>(
  (ref) => PropertyNotifier(ref.watch(propertyRepositoryProvider)),
);

class PropertyNotifier extends StateNotifier<List<Property>> {
  final PropertyRepository _repository;

  PropertyNotifier(this._repository) : super([]) {
    loadProperties();
  }

  Future<void> loadProperties() async {
    state = await _repository.getProperties();
  }

  Future<void> addProperty(Property property) async {
    final newProperty = await _repository.addProperty(property);
    state = [...state, newProperty];
  }

  Future<void> updateProperty(Property property) async {
    await _repository.updateProperty(property);
    state = [
      for (final prop in state)
        if (prop.id == property.id) property else prop
    ];
  }

  Future<void> deleteProperty(String id) async {
    await _repository.deleteProperty(id);
    state = state.where((prop) => prop.id != id).toList();
  }
}