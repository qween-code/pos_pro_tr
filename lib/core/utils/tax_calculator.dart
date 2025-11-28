import '../constants/app_constants.dart';

class TaxCalculator {
  static double calculateTax(double amount, double taxRate) {
    return amount * taxRate;
  }

  static double calculateTotalWithTax(double amount, double taxRate) {
    return amount + calculateTax(amount, taxRate);
  }

  static double getTaxRate(String taxType) {
    switch (taxType) {
      case 'kdv1':
        return AppConstants.kdvOrani1;
      case 'kdv10':
        return AppConstants.kdvOrani10;
      case 'kdv20':
        return AppConstants.kdvOrani20;
      default:
        return AppConstants.kdvOrani10; // Varsayılan KDV %10
    }
  }
}