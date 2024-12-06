import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/tenant.dart';
import '../../data/tenant_repository.dart';

final tenantRepositoryProvider = Provider((ref) => TenantRepository());

final tenantProvider = StateNotifierProvider<TenantNotifier, AsyncValue<List<Tenant>>>(
  (ref) => TenantNotifier(ref.watch(tenantRepositoryProvider)),
);

class TenantNotifier extends StateNotifier<AsyncValue<List<Tenant>>> {
  final TenantRepository _repository;

  TenantNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTenants();
  }

  Future<void> loadTenants() async {
    try {
      state = const AsyncValue.loading();
      final tenants = await _repository.getTenants();
      state = AsyncValue.data(tenants);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addTenant(Tenant tenant) async {
    try {
      final newTenant = await _repository.createTenant(tenant);
      state.whenData((tenants) {
        state = AsyncValue.data([...tenants, newTenant]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateTenant(Tenant tenant) async {
    try {
      await _repository.updateTenant(tenant);
      state.whenData((tenants) {
        state = AsyncValue.data(
          tenants.map((t) => t.id == tenant.id ? tenant : t).toList(),
        );
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteTenant(String id) async {
    try {
      await _repository.deleteTenant(id);
      state.whenData((tenants) {
        state = AsyncValue.data(tenants.where((t) => t.id != id).toList());
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}