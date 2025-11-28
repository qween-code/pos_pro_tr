import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/payment_model.dart';
import '../../data/repositories/payment_repository.dart';
import '../../../orders/data/models/order_model.dart';

class PaymentController extends GetxController {
  final PaymentRepository _paymentRepository = PaymentRepository();
  final RxList<Payment> payments = <Payment>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPayments();
  }

  Future<void> fetchPayments() async {
    isLoading.value = true;
    try {
      final List<Payment> paymentList = await _paymentRepository.getPayments();
      payments.assignAll(paymentList);
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Ödemeler yüklenemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addPayment(Order order, double amount, String paymentMethod) async {
    isLoading.value = true;
    try {
      final Payment newPayment = Payment(
        orderId: order.id!,
        amount: amount,
        paymentMethod: paymentMethod,
        paymentDate: DateTime.now(),
        orderNumber: order.id?.substring(0, 8),
        customerName: order.customerName,
      );

      final paymentId = await _paymentRepository.insertPayment(newPayment);
      await fetchPayments();

      // Bildirim gönder
      try {
        final notificationService = NotificationService();
        await notificationService.sendPaymentNotification(
          paymentId: paymentId,
          orderId: order.id!,
          amount: amount,
        );
      } catch (e) {
        // Bildirim hatası kritik değil, sessizce geç
        debugPrint('Bildirim gönderilemedi: $e');
      }

      Get.back();
      ErrorHandler.showSuccessMessage('Ödeme başarıyla kaydedildi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Ödeme kaydedilemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updatePayment(Payment payment) async {
    isLoading.value = true;
    try {
      await _paymentRepository.updatePayment(payment);
      await fetchPayments();
      Get.back();
      ErrorHandler.showSuccessMessage('Ödeme başarıyla güncellendi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Ödeme güncellenemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deletePayment(String id) async {
    isLoading.value = true;
    try {
      await _paymentRepository.deletePayment(id);
      await fetchPayments();
      ErrorHandler.showSuccessMessage('Ödeme başarıyla silindi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Ödeme silinemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Payment>> getPaymentsByOrderId(String orderId) async {
    try {
      return await _paymentRepository.getPaymentsByOrderId(orderId);
    } catch (e) {
      Get.snackbar('Hata', 'Sipariş ödemeleri alınamadı: ${e.toString()}');
      return [];
    }
  }

  Future<double> getTotalPaymentsForDate(DateTime date) async {
    try {
      return await _paymentRepository.getTotalPaymentsForDate(date);
    } catch (e) {
      Get.snackbar('Hata', 'Günlük toplam ödemeler alınamadı: ${e.toString()}');
      return 0;
    }
  }

  Future<Map<String, double>> getPaymentMethodsSummary(DateTime date) async {
    try {
      return await _paymentRepository.getPaymentMethodsSummary(date);
    } catch (e) {
      Get.snackbar('Hata', 'Ödeme yöntemi özeti alınamadı: ${e.toString()}');
      return {};
    }
  }
}