import 'package:intl/intl.dart';

/// Utility helper for formatting amounts in Sri Lankan Rupees (LKR).
/// Centralizes currency formatting so the whole app stays consistent.
class CurrencyUtil {
  CurrencyUtil._();

  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'en_LK',
    symbol: 'LKR ', // Explicit ISO-based symbol prefix
    decimalDigits: 2,
  );

  /// Format a numeric value to LKR string (e.g. LKR 1,250.00)
  static String format(num value) => _formatter.format(value);

  /// Parses a user-entered string to an int (rupees) if possible.
  /// Strips commas and currency text gracefully.
  static int? parseToInt(String raw) {
    final cleaned = raw
        .replaceAll('LKR', '')
        .replaceAll('Rs', '')
        .replaceAll(':', '')
        .replaceAll(',', '')
        .trim();
    final doubleVal = double.tryParse(cleaned);
    if (doubleVal == null) return null;
    return doubleVal.round();
  }
}
