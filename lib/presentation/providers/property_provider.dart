import 'package:flutter/material.dart';
import 'dart:io';
import 'package:house_rental_app/data/models/property.dart';
import 'package:house_rental_app/data/repositories/property_repository.dart';

class PropertyProvider with ChangeNotifier {
  final PropertyRepository _propertyRepository;

  PropertyProvider(this._propertyRepository);

  List<Property> _properties = [];
  List<Property> get properties => _properties;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Property? _selectedProperty;
  Property? get selectedProperty => _selectedProperty;

  // Add the new method for updating maintenance records
  Future<void> updateMaintenanceRecord(
    String propertyId,
    MaintenanceRecord oldRecord,
    MaintenanceRecord newRecord,
  ) async {
    try {
      await _propertyRepository.updateMaintenanceRecord(
        propertyId,
        oldRecord,
        newRecord,
      );

      // Update local state
      final propertyIndex = _properties.indexWhere((p) => p.id == propertyId);
      if (propertyIndex != -1) {
        final property = _properties[propertyIndex];
        final recordIndex = property.maintenanceRecords.indexWhere(
          (r) =>
              r.title == oldRecord.title &&
              r.date == oldRecord.date &&
              r.cost == oldRecord.cost,
        );

        if (recordIndex != -1) {
          final updatedRecords =
              List<MaintenanceRecord>.from(property.maintenanceRecords);
          updatedRecords[recordIndex] = newRecord;

          final updatedProperty = Property(
            id: property.id,
            address: property.address,
            location: property.location,
            baseRentAmount: property.baseRentAmount,
            currentRentAmount: property.currentRentAmount,
            maintenanceCharge: property.maintenanceCharge,
            yearlyIncreasePercentage: property.yearlyIncreasePercentage,
            status: property.status,
            size: property.size,
            assignedManagerId: property.assignedManagerId,
            description: property.description,
            bedrooms: property.bedrooms,
            bathrooms: property.bathrooms,
            furnishingStatus: property.furnishingStatus,
            parking: property.parking,
            amenities: property.amenities,
            images: property.images,
            locationCoordinates: property.locationCoordinates,
            maintenanceRecords: updatedRecords,
            createdAt: property.createdAt,
            updatedAt: DateTime.now(),
            flexibleRentHistory: property.flexibleRentHistory,
          );

          _properties[propertyIndex] = updatedProperty;

          // Update selected property if it's the same one
          if (_selectedProperty?.id == propertyId) {
            _selectedProperty = updatedProperty;
          }
        }
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  // Update to return List<Property>
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
    _isLoading = true;
    _error = null;
    try {
      _properties = await _propertyRepository.fetchProperties(
        status: status,
        furnishingStatus: furnishingStatus,
        minPrice: minPrice,
        maxPrice: maxPrice,
        minArea: minArea,
        maxArea: maxArea,
        amenities: amenities,
        location: location,
        sortByRentAsc: sortByRentAsc,
      );
      notifyListeners();
      return _properties;
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProperty(Property property, List<File> images) async {
    try {
      String id = await _propertyRepository.addProperty(property, images);
      property.id = id;
      _properties.add(property);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  // // Add the missing method
  // Future<Property?> getPropertyById(String propertyId) async {
  //   try {
  //     return await _propertyRepository.getPropertyById(propertyId);
  //   } catch (e) {
  //     _error = e.toString();
  //     throw e;
  //   }
  // }

  Future<void> updateProperty(Property property) async {
    try {
      await _propertyRepository.updateProperty(property);
      int index = _properties.indexWhere((p) => p.id == property.id);
      if (index != -1) {
        _properties[index] = property;
        if (_selectedProperty?.id == property.id) {
          _selectedProperty = property;
        }
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  Future<void> deleteProperty(String propertyId) async {
    try {
      await _propertyRepository.deleteProperty(propertyId);
      _properties.removeWhere((property) => property.id == propertyId);
      if (_selectedProperty?.id == propertyId) {
        _selectedProperty = null;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  Future<void> addMaintenanceRecord(
      String propertyId, MaintenanceRecord record) async {
    try {
      await _propertyRepository.addMaintenanceRecord(propertyId, record);
      int index = _properties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        _properties[index].maintenanceRecords.add(record);
        if (_selectedProperty?.id == propertyId) {
          _selectedProperty!.maintenanceRecords.add(record);
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  Future<void> updateRentAmount(
      String propertyId, double newAmount, String reason) async {
    try {
      await _propertyRepository.updateRentAmount(propertyId, newAmount, reason);
      int index = _properties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        _properties[index].updateRentAmount(newAmount, reason);
        if (_selectedProperty?.id == propertyId) {
          _selectedProperty!.updateRentAmount(newAmount, reason);
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  Future<void> updatePropertyStatus(String propertyId, String status) async {
    try {
      await _propertyRepository.updatePropertyStatus(propertyId, status);
      int index = _properties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        _properties[index].status = status;
        if (_selectedProperty?.id == propertyId) {
          _selectedProperty!.status = status;
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  Future<void> addPropertyImages(
      String propertyId, List<File> newImages) async {
    try {
      await _propertyRepository.addPropertyImages(propertyId, newImages);
      await refreshProperty(propertyId);
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  Future<void> removePropertyImage(String propertyId, String imageUrl) async {
    try {
      await _propertyRepository.removePropertyImage(propertyId, imageUrl);
      await refreshProperty(propertyId);
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  Future<void> updateLocationCoordinates(
      String propertyId, Map<String, double> coordinates) async {
    try {
      await _propertyRepository.updateLocationCoordinates(
          propertyId, coordinates);
      int index = _properties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        _properties[index].locationCoordinates = coordinates;
        if (_selectedProperty?.id == propertyId) {
          _selectedProperty!.locationCoordinates = coordinates;
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  Future<void> refreshProperty(String propertyId) async {
    try {
      final property = await _propertyRepository.getPropertyById(propertyId);
      if (property != null) {
        int index = _properties.indexWhere((p) => p.id == propertyId);
        if (index != -1) {
          _properties[index] = property;
        }
        if (_selectedProperty?.id == propertyId) {
          _selectedProperty = property;
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  void selectProperty(String propertyId) {
    _selectedProperty = _properties.firstWhere((p) => p.id == propertyId);
    notifyListeners();
  }

  Future<void> assignManager(String propertyId, String managerId) async {
    try {
      await _propertyRepository.assignManager(propertyId, managerId);
      int index = _properties.indexWhere((p) => p.id == propertyId);
      if (index != -1) {
        _properties[index].assignedManagerId = managerId;
        if (_selectedProperty?.id == propertyId) {
          _selectedProperty!.assignedManagerId = managerId;
        }
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  Future<List<Property>> searchProperties(String searchTerm) async {
    try {
      return await _propertyRepository.searchProperties(searchTerm);
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  Future<List<Property>> fetchPropertiesByManagerId(String managerId) async {
    try {
      return await _propertyRepository.fetchPropertiesByManagerId(managerId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  // If you need to get a specific property
  Property? getPropertyById(String propertyId) {
    try {
      return _properties.firstWhere(
        (property) => property.id == propertyId,
      );
    } catch (e) {
      print('Error getting property by ID: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> getPropertyStatistics(String propertyId) async {
    try {
      return await _propertyRepository.getPropertyStatistics(propertyId);
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
