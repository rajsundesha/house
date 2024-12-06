class DateUtils {
  static String getRelativeTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()} years ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()} months ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} days ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hours ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minutes ago';
    } else {
      return 'Just now';
    }
  }

  static int calculateLeaseDuration(DateTime start, DateTime end) {
    return end.difference(start).inDays;
  }

  static bool isLeaseEnding(DateTime endDate) {
    final daysRemaining = endDate.difference(DateTime.now()).inDays;
    return daysRemaining <= 30 && daysRemaining > 0;
  }

  static bool isLeaseExpired(DateTime endDate) {
    return DateTime.now().isAfter(endDate);
  }
}
