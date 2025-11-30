import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/error_handler.dart';
import '../../data/models/register_model.dart';
import '../../data/repositories/register_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class RegisterController extends GetxController {
  final RegisterRepository _repository = RegisterRepository();
  
  final Rxn<RegisterModel> currentRegister = Rxn<RegisterModel>();
  final RxBool isLoading = false.obs;

  @override
  void onReady() {
    super.onReady();
    checkOpenRegister();
  }

  // Açık kasa var mı kontrol et
  Future<void> checkOpenRegister() async {
    isLoading.value = true;
    try {
      final register = await _repository.getOpenRegister();
      currentRegister.value = register;
    } catch (e) {
      debugPrint('Kasa durumu kontrol edilemedi: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Kasa Aç
  Future<bool> openRegister(double openingBalance, String userName) async {
    isLoading.value = true;
    try {
      final authController = Get.find<AuthController>();
      final newRegister = RegisterModel(
        userId: authController.currentUser.value?.id ?? 'unknown_user',
        userName: userName,
        openingTime: DateTime.now(),
        openingBalance: openingBalance,
      );

      final created = await _repository.openRegister(newRegister);
      currentRegister.value = created;
      
      // Başarı mesajı
      ErrorHandler.showSuccessMessage('Kasa başarıyla açıldı. İyi çalışmalar!');
      return true;
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Kasa açılamadı');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Kasa Kapat (Z Raporu)
  Future<bool> closeRegister(double closingBalance, String notes) async {
    if (currentRegister.value == null) return false;

    isLoading.value = true;
    try {
      await _repository.closeRegister(
        currentRegister.value!.id!,
        closingBalance,
        notes,
      );
      
      // Rapor verilerini hazırla (PDF için kullanılabilir)
      final report = currentRegister.value!;
      
      currentRegister.value = null;
      
      // Başarı mesajı
      ErrorHandler.showSuccessMessage('Z Raporu alındı ve kasa kapatıldı.');
      return true;
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Kasa kapatılamadı');
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // Satış sonrası güncelleme
  Future<void> updateSales(double amount, String paymentMethod) async {
    if (currentRegister.value != null) {
      await _repository.updateSales(currentRegister.value!.id!, amount, paymentMethod);
      // Local state'i de güncelle
      final current = currentRegister.value!;
      if (paymentMethod == 'cash') {
        currentRegister.value = current.copyWith(
          totalCashSales: current.totalCashSales + amount,
        );
      } else if (paymentMethod == 'card') {
        currentRegister.value = current.copyWith(
          totalCardSales: current.totalCardSales + amount,
        );
      }
    }
  }
}
