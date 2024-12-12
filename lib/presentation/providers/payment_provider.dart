import 'package:flutter/material.dart';
import 'package:house_rental_app/data/models/payment.dart';
import 'package:house_rental_app/data/repositories/payment_repository.dart';

class PaymentProvider with ChangeNotifier {
  final PaymentRepository _paymentRepository;

  PaymentProvider(this._paymentRepository);

  List<Payment> _payments = [];
  List<Payment> get payments => _payments;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  

  Future<void> fetchPayments() async {
    _isLoading = true;
    _error = null;
    try {
      _payments = await _paymentRepository.fetchPayments();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPayment(Payment payment) async {
    try {
      String id = await _paymentRepository.addPayment(payment);
      payment.id = id;
      _payments.add(payment);
    } catch (e) {
      _error = e.toString();
    } finally {
      notifyListeners();
    }
  }


  // Add new method for property-specific payments
  Future<List<Payment>> fetchPaymentsByPropertyId(String propertyId) async {
    try {
      final payments = await _paymentRepository.fetchPayments();
      return payments.where((p) => p.propertyId == propertyId).toList();
    } catch (e) {
      _error = e.toString();
      throw e;
    }
  }

  Future<List<Payment>> fetchPaymentsByTenantId(String tenantId) async {
    try {
      return await _paymentRepository.fetchPaymentsByTenantId(tenantId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }
  

  Future<List<Payment>> fetchPaymentsByManagerId(String managerId) async {
    try {
      return await _paymentRepository.fetchPaymentsByManagerId(managerId);
    } catch (e) {
      _error = e.toString();
      return [];
    }
  }
}
