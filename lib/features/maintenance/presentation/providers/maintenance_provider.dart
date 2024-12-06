import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/maintenance_request.dart';
import '../../data/maintenance_repository.dart';

final maintenanceRepositoryProvider = Provider((ref) => MaintenanceRepository());

final maintenanceProvider = StateNotifierProvider<MaintenanceNotifier, AsyncValue<List<MaintenanceRequest>>>(
  (ref) => MaintenanceNotifier(ref.watch(maintenanceRepositoryProvider)),
);

class MaintenanceNotifier extends StateNotifier<AsyncValue<List<MaintenanceRequest>>> {
  final MaintenanceRepository _repository;

  MaintenanceNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadRequests();
  }

  Future<void> loadRequests() async {
    try {
      state = const AsyncValue.loading();
      final requests = await _repository.getMaintenanceRequests();
      state = AsyncValue.data(requests);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createRequest(MaintenanceRequest request) async {
    try {
      final newRequest = await _repository.createMaintenanceRequest(request);
      state.whenData((requests) {
        state = AsyncValue.data([...requests, newRequest]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateRequest(MaintenanceRequest request) async {
    try {
      await _repository.updateMaintenanceRequest(request);
      state.whenData((requests) {
        state = AsyncValue.data(
          requests.map((r) => r.id == request.id ? request : r).toList(),
        );
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteRequest(String id) async {
    try {
      await _repository.deleteMaintenanceRequest(id);
      state.whenData((requests) {
        state = AsyncValue.data(requests.where((r) => r.id != id).toList());
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}