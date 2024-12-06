import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/payment.dart';
import '../../data/payment_repository.dart';

final paymentRepositoryProvider = Provider((ref) => PaymentRepository());

final paymentProvider =
    StateNotifierProvider<PaymentNotifier, AsyncValue<List<Payment>>>(
  (ref) => PaymentNotifier(ref.watch(paymentRepositoryProvider)),
);

class PaymentNotifier extends StateNotifier<AsyncValue<List<Payment>>> {
  final PaymentRepository _repository;

  PaymentNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPayments();
  }

  Future<void> loadPayments() async {
    try {
      state = const AsyncValue.loading();
      final payments = await _repository.getPayments();
      state = AsyncValue.data(payments);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addPayment(Payment payment) async {
    try {
      final newPayment = await _repository.createPayment(payment);
      state.whenData((payments) {
        state = AsyncValue.data([...payments, newPayment]);
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updatePayment(Payment payment) async {
    try {
      await _repository.updatePayment(payment);
      state.whenData((payments) {
        state = AsyncValue.data(
          payments.map((p) => p.id == payment.id ? payment : p).toList(),
        );
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deletePayment(String id) async {
    try {
      await _repository.deletePayment(id);
      state.whenData((payments) {
        state = AsyncValue.data(payments.where((p) => p.id != id).toList());
      });
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}