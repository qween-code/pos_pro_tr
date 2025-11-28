import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class CurrencyFormatter {
  static String format(double amount) {
    final format = NumberFormat.currency(
      locale: AppConstants.locale,
      symbol: AppConstants.currencySymbol,
      decimalDigits: 2,
    );
    return format.format(amount);
  }

  static String formatWithoutSymbol(double amount) {
    final format = NumberFormat.decimalPattern(AppConstants.locale);
    return format.format(amount);
  }
}