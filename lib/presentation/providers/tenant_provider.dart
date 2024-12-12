import 'package:flutter/material.dart';
import 'package:house_rental_app/data/models/tenant.dart';
import 'package:house_rental_app/data/repositories/tenant_repository.dart';

class TenantProvider with ChangeNotifier {
  final TenantRepository _tenantRepository;

  TenantProvider(this._tenantRepository);

  List<Tenant> _tenants = [];
  List<Tenant> get tenants => _tenants;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // Changed to return Future<List<Tenant>>
  Future<List<Tenant>> fetchTenants() async {
    _isLoading = true;
    _error = null;
    try {
      _tenants = await _tenantRepository.fetchTenants();
      notifyListeners();
      return _tenants; // Return the list
    } catch (e) {
      _error = e.toString();
      throw e;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Keep other methods the same...
  Future<void> addTenant(Tenant tenant) async {
    try {
      String id = await _tenantRepository.addTenant(tenant);
      tenant.id = id;
      _tenants.add(tenant);
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> updateTenant(Tenant tenant) async {
    try {
      await _tenantRepository.updateTenant(tenant);
      int index = _tenants.indexWhere((t) => t.id == tenant.id);
      if (index != -1) {
        _tenants[index] = tenant;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<void> deleteTenant(String tenantId) async {
    try {
      await _tenantRepository.deleteTenant(tenantId);
      _tenants.removeWhere((tenant) => tenant.id == tenantId);
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }

  Future<Tenant?> getTenantById(String tenantId) async {
    try {
      return await _tenantRepository.getTenantById(tenantId);
    } catch (e) {
      _error = e.toString();
      return null;
    }
  }

  Future<List<Tenant>> fetchTenantsByPropertyId(String propertyId) async {
    try {
      return await _tenantRepository.fetchTenantsByPropertyId(propertyId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }

  Future<List<Tenant>> fetchTenantsByManagerId(String managerId) async {
    try {
      return await _tenantRepository.fetchTenantsByManagerId(managerId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }
}
// import 'package:flutter/material.dart';
// import 'package:house_rental_app/data/models/tenant.dart';
// import 'package:house_rental_app/data/repositories/tenant_repository.dart';

// class TenantProvider with ChangeNotifier {
//   final TenantRepository _tenantRepository;

//   TenantProvider(this._tenantRepository);

//   List<Tenant> _tenants = [];
//   List<Tenant> get tenants => _tenants;

//   bool _isLoading = false;
//   bool get isLoading => _isLoading;

//   String? _error;
//   String? get error => _error;

//   Future<void> fetchTenants() async {
//     _isLoading = true;
//     _error = null;
//     try {
//       _tenants = await _tenantRepository.fetchTenants();
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> addTenant(Tenant tenant) async {
//     try {
//       String id = await _tenantRepository.addTenant(tenant);
//       tenant.id = id;
//       _tenants.add(tenant);
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       notifyListeners();
//     }
//   }

//   Future<void> updateTenant(Tenant tenant) async {
//     try {
//       await _tenantRepository.updateTenant(tenant);
//       int index = _tenants.indexWhere((t) => t.id == tenant.id);
//       if (index != -1) {
//         _tenants[index] = tenant;
//       }
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       notifyListeners();
//     }
//   }

//   Future<void> deleteTenant(String tenantId) async {
//     try {
//       await _tenantRepository.deleteTenant(tenantId);
//       _tenants.removeWhere((tenant) => tenant.id == tenantId);
//     } catch (e) {
//       _error = e.toString();
//     } finally {
//       notifyListeners();
//     }
//   }

//   Future<Tenant?> getTenantById(String tenantId) async {
//     try {
//       return await _tenantRepository.getTenantById(tenantId);
//     } catch (e) {
//       _error = e.toString();
//       return null;
//     }
//   }

//   Future<List<Tenant>> fetchTenantsByPropertyId(String propertyId) async {
//     try {
//       return await _tenantRepository.fetchTenantsByPropertyId(propertyId);
//     } catch (e) {
//       _error = e.toString();
//       return [];
//     }
//   }

//   Future<List<Tenant>> fetchTenantsByManagerId(String managerId) async {
//     try {
//       return await _tenantRepository.fetchTenantsByManagerId(managerId);
//     } catch (e) {
//       _error = e.toString();
//       return [];
//     }
//   }
// }
