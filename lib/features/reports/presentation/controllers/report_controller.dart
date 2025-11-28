import 'package:get/get.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../orders/data/repositories/order_repository.dart';
import '../../../payments/data/repositories/payment_repository.dart';

class ReportController extends GetxController {
  final OrderRepository _orderRepository = OrderRepository();
  final PaymentRepository _paymentRepository = PaymentRepository();

  final RxBool isLoading = false.obs;
  final Rx<DateTime> selectedDate = DateTime.now().obs;

  // Günlük satış raporu
  final RxDouble dailyTotalSales = 0.0.obs;
  final RxDouble dailyTotalPayments = 0.0.obs;
  final RxMap<String, double> paymentMethodsSummary = <String, double>{}.obs;

  // En çok satan ürünler
  final RxList<MapEntry<String, int>> topSellingProducts = <MapEntry<String, int>>[].obs;

  // Müşteri istatistikleri
  final RxInt totalCustomers = 0.obs;
  final RxInt newCustomersToday = 0.obs;

  @override
  void onInit() {
    super.onInit();
    fetchDailyReport();
    fetchTopSellingProducts();
    fetchCustomerStatistics();
  }

  Future<void> fetchDailyReport() async {
    isLoading.value = true;
    try {
      final date = selectedDate.value;
      dailyTotalSales.value = await _orderRepository.getTotalSalesForDate(date);
      dailyTotalPayments.value = await _paymentRepository.getTotalPaymentsForDate(date);
      paymentMethodsSummary.value = await _paymentRepository.getPaymentMethodsSummary(date);
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Günlük rapor alınamadı');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> fetchTopSellingProducts({int limit = 5}) async {
    try {
      // Bu metod daha sonra gerçek verilerle doldurulacak
      // Şimdilik örnek veri kullanıyoruz
      topSellingProducts.assignAll([
        const MapEntry('Ürün 1', 15),
        const MapEntry('Ürün 2', 12),
        const MapEntry('Ürün 3', 8),
        const MapEntry('Ürün 4', 5),
        const MapEntry('Ürün 5', 3),
      ]);
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'En çok satan ürünler alınamadı');
    }
  }

  Future<void> fetchCustomerStatistics() async {
    try {
      // Bu metod daha sonra gerçek verilerle doldurulacak
      totalCustomers.value = 42;
      newCustomersToday.value = 3;
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Müşteri istatistikleri alınamadı');
    }
  }

  Future<void> changeDate(DateTime newDate) async {
    selectedDate.value = newDate;
    await fetchDailyReport();
  }

  // Belirli bir tarih aralığı için rapor alma
  Future<Map<String, dynamic>> getDateRangeReport(DateTime startDate, DateTime endDate) async {
    try {
      final orders = await _orderRepository.getOrdersByDateRange(startDate, endDate);
      final payments = await _paymentRepository.getPaymentsByDateRange(startDate, endDate);

      double totalSales = 0;
      double totalPayments = 0;
      final Map<String, double> paymentSummary = {};

      for (var order in orders) {
        totalSales += order.totalAmount;
      }

      for (var payment in payments) {
        totalPayments += payment.amount;
        paymentSummary[payment.paymentMethod] = (paymentSummary[payment.paymentMethod] ?? 0) + payment.amount;
      }

      return {
        'totalSales': totalSales,
        'totalPayments': totalPayments,
        'paymentSummary': paymentSummary,
        'orderCount': orders.length,
        'paymentCount': payments.length,
      };
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Tarih aralığı raporu alınamadı');
      return {};
    }
  }
}