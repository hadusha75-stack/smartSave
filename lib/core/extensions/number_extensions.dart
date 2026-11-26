import 'package:intl/intl.dart';

/// Formatting extensions for numbers (currency, percentages).
extension NumberExtensions on num {
  /// Format as currency with thousands separators.
  /// Example: 12345.6 -> "12,346" (ETB) or "12,345.60" (USD)
  String toCurrency(String currencyCode) {
    if (currencyCode == 'ETB') {
      // ETB typically shown without decimals in informal use
      return NumberFormat('#,##0', 'en_US').format(this);
    }
    return NumberFormat('#,##0.00', 'en_US').format(this);
  }

  /// Format as a percentage string with one decimal place.
  String toPercent() => '${toStringAsFixed(1)}%';

  /// Clamp to [0, 100].
  double toProgressValue() => clamp(0.0, 100.0).toDouble();
}
