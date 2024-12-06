import 'package:intl/intl.dart';

class CurrencyUtils {
  // Private constructor to prevent instantiation
  CurrencyUtils._();

  // Standard currency formatter for Indian Rupees
  static final NumberFormat _currencyFormatter = NumberFormat.currency(
    symbol: '₹',
    locale: 'en_IN',
    decimalDigits: 2,
  );

  // Formatter for numbers without currency symbol
  static final NumberFormat _numberFormatter =
      NumberFormat('#,##,##0.00', 'en_IN');

  // Format amount with currency symbol
  static String formatCurrency(double amount) {
    try {
      return _currencyFormatter.format(amount);
    } catch (e) {
      return '₹0.00';
    }
  }

  // Format amount without currency symbol
  static String formatNumber(double amount) {
    try {
      return _numberFormatter.format(amount);
    } catch (e) {
      return '0.00';
    }
  }

  // Format with custom prefix (e.g., "₹1,00,000/month")
  static String formatWithSuffix(double amount, String suffix) {
    try {
      return '${_currencyFormatter.format(amount)}$suffix';
    } catch (e) {
      return '₹0.00$suffix';
    }
  }

  // Parse currency string back to double
  static double parseCurrency(String amount) {
    try {
      // Remove currency symbol and convert to double
      final cleanAmount = amount.replaceAll('₹', '').replaceAll(',', '');
      return double.parse(cleanAmount);
    } catch (e) {
      return 0.0;
    }
  }

  // Format large amounts with abbreviated units (e.g., "₹1.5L" for 150000)
  static String formatAbbreviated(double amount) {
    if (amount >= 10000000) {
      // 1 Crore
      return '₹${(amount / 10000000).toStringAsFixed(2)}Cr';
    } else if (amount >= 100000) {
      // 1 Lakh
      return '₹${(amount / 100000).toStringAsFixed(2)}L';
    } else if (amount >= 1000) {
      // 1 Thousand
      return '₹${(amount / 1000).toStringAsFixed(2)}K';
    }
    return formatCurrency(amount);
  }

  // Validate if a string is a valid currency amount
  static bool isValidCurrencyAmount(String amount) {
    try {
      // Remove currency symbol, commas and spaces
      final cleanAmount =
          amount.replaceAll('₹', '').replaceAll(',', '').replaceAll(' ', '');
      double.parse(cleanAmount);
      return true;
    } catch (e) {
      return false;
    }
  }

  //lib/utils/currency_utils.dart
// Add this method to the existing CurrencyUtils class
  static String formatCompact(double amount) {
    if (amount >= 10000000) {
      // 1 Crore
      return '₹${(amount / 10000000).toStringAsFixed(1)}Cr';
    } else if (amount >= 100000) {
      // 1 Lakh
      return '₹${(amount / 100000).toStringAsFixed(1)}L';
    } else if (amount >= 1000) {
      // 1 Thousand
      return '₹${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatCurrency(amount);
  }
}
