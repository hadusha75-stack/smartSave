import 'package:intl/intl.dart';

/// Formats amounts as currency strings with thousands separators.
///
/// Used everywhere we display money so formatting is consistent.
class CurrencyFormatter {
  CurrencyFormatter._();

  /// Format [amount] with the given [currencyCode].
  ///
  /// ETB → "12,345 ETB"
  /// USD → "12,345.67 USD"
  static String format(double amount, String currencyCode) {
    final nf = currencyCode == 'ETB'
        ? NumberFormat('#,##0', 'en_US')
        : NumberFormat('#,##0.00', 'en_US');
    return '${nf.format(amount)} $currencyCode';
  }

  /// Format without the currency code label (used inside input hints).
  static String formatPlain(double amount, String currencyCode) {
    final nf = currencyCode == 'ETB'
        ? NumberFormat('#,##0', 'en_US')
        : NumberFormat('#,##0.00', 'en_US');
    return nf.format(amount);
  }

  /// Parse a currency string back to double. Returns 0 on failure.
  static double parse(String text) {
    final cleaned = text.replaceAll(',', '').trim();
    return double.tryParse(cleaned) ?? 0;
  }
}
