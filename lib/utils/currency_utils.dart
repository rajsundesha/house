import 'package:intl/intl.dart';

class CurrencyUtils {
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '₹',
    locale: 'en_IN',
    decimalDigits: 2,
  );

  static final NumberFormat _compactCurrencyFormatter =
      NumberFormat.compactCurrency(
    symbol: '₹',
    locale: 'en_IN',
    decimalDigits: 1,
  );

  static String formatCurrency(double amount) {
    try {
      return _currencyFormatter.format(amount);
    } catch (e) {
      return '₹0.00';
    }
  }

  static String formatCompactCurrency(double amount) {
    try {
      return _compactCurrencyFormatter.format(amount);
      // This will format like: ₹1K, ₹1M, ₹1B etc.
    } catch (e) {
      return '₹0';
    }
  }

  static double parseCurrency(String amount) {
    try {
      final clean = amount.replaceAll('₹', '').replaceAll(',', '');
      return double.parse(clean);
    } catch (e) {
      return 0.0;
    }
  }
}
