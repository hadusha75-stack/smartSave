/// Convenience extensions on DateTime used in savings calculations.
extension DateTimeExtensions on DateTime {
  /// Number of whole days between this date and [other].
  int daysUntil(DateTime other) {
    final a = DateTime(year, month, day);
    final b = DateTime(other.year, other.month, other.day);
    return b.difference(a).inDays;
  }

  /// True if this date is the same calendar day as [other].
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// True if this date is in the same ISO week as [other].
  bool isSameWeek(DateTime other) {
    final thisMonday = subtract(Duration(days: weekday - 1));
    final otherMonday = other.subtract(Duration(days: other.weekday - 1));
    return thisMonday.isSameDay(otherMonday);
  }

  /// True if this date is in the same calendar month as [other].
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  /// Return date at midnight (start of day).
  DateTime get startOfDay => DateTime(year, month, day);

  /// Return the first day of the current week (Monday).
  DateTime get startOfWeek => subtract(Duration(days: weekday - 1)).startOfDay;

  /// Return the first day of the current month.
  DateTime get startOfMonth => DateTime(year, month, 1);
}
