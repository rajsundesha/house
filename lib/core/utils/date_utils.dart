import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _dateFormatter = DateFormat('MMM dd, yyyy');
  static final DateFormat _monthYearFormatter = DateFormat('MMMM yyyy');
  static final DateFormat _shortMonthYearFormatter = DateFormat('MMM yyyy');

  static String formatDate(DateTime date) {
    return _dateFormatter.format(date);
  }

  static String formatMonthYear(DateTime date) {
    return _monthYearFormatter.format(date);
  }

  static String formatShortMonthYear(DateTime date) {
    return _shortMonthYearFormatter.format(date);
  }

  static DateTime? tryParse(String? value) {
    if (value == null) return null;
    return DateTime.tryParse(value);
  }

  static bool isOverdue(DateTime dueDate) {
    final now = DateTime.now();
    return dueDate.isBefore(now);
  }

  static int daysBetween(DateTime from, DateTime to) {
    from = DateTime(from.year, from.month, from.day);
    to = DateTime(to.year, to.month, to.day);
    return (to.difference(from).inHours / 24).round();
  }

  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  static List<DateTime> getDaysInRange(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var current = start;
    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      days.add(current);
      current = current.add(const Duration(days: 1));
    }
    return days;
  }
}