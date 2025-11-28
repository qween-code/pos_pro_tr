import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ErrorHandler {
  // Global hata yakalayıcı
  static void setupGlobalErrorHandler() {
    FlutterError.onError = (FlutterErrorDetails details) async {
      // Firebase Crashlytics entegrasyonu için buraya ekleme yapılabilir
      
      // Hata detaylarını logla
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack Trace: ${details.stack}');
      
      // GetX context hazırsa snackbar göster
      if (Get.isRegistered<GetMaterialController>()) {
        try {
      Get.snackbar(
        'Beklenmeyen Hata',
        'Uygulamada beklenmeyen bir hata oluştu. Lütfen tekrar deneyin.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        } catch (e) {
          debugPrint('Snackbar gösterilemedi: $e');
        }
      }
    };
  }

  // Zone hatalarını yakalamak için callback
  static void handleZoneError(Object error, StackTrace stack) {
        debugPrint('Zone Error: $error');
        debugPrint('Stack Trace: $stack');

    // GetX context hazırsa snackbar göster
    if (Get.isRegistered<GetMaterialController>()) {
      try {
        Get.snackbar(
          'Sistem Hatası',
          'Uygulamada bir sistem hatası oluştu. Lütfen uygulamayı yeniden başlatın.',
          backgroundColor: Colors.red,
          colorText: Colors.white,
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
        );
      } catch (e) {
        debugPrint('Snackbar gösterilemedi: $e');
      }
    }
  }

  // API hatalarını işleme
  static void handleApiError(dynamic error, {String? customMessage}) {
    String message = customMessage ?? 'İşlem sırasında bir hata oluştu';

    if (error is String) {
      message = error;
    } else if (error is Exception) {
      message = error.toString();
    } else if (error is Error) {
      message = error.toString();
    }

    // Firebase Crashlytics entegrasyonu için buraya ekleme yapılabilir
    debugPrint('API Error: $error');

    if (Get.isRegistered<GetMaterialController>()) {
      try {
    Get.snackbar(
      'Hata',
      message,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
    );
      } catch (e) {
        debugPrint('Snackbar gösterilemedi: $e');
      }
    }
  }

  // Ağ bağlantısı hatası
  static void handleNetworkError() {
    if (Get.isRegistered<GetMaterialController>()) {
      try {
    Get.snackbar(
      'Bağlantı Hatası',
      'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
    );
      } catch (e) {
        debugPrint('Snackbar gösterilemedi: $e');
      }
    }
  }

  // Yetkilendirme hatası
  static void handleAuthError() {
    if (Get.isRegistered<GetMaterialController>()) {
      try {
    Get.snackbar(
      'Yetkilendirme Hatası',
      'Bu işlemi gerçekleştirmek için yetkiniz bulunmamaktadır.',
      backgroundColor: Colors.red,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
    );
      } catch (e) {
        debugPrint('Snackbar gösterilemedi: $e');
      }
    }
  }

  // Form validasyon hatası
  static void handleValidationError(String message) {
    if (Get.isRegistered<GetMaterialController>()) {
      try {
    Get.snackbar(
      'Geçersiz Bilgi',
      message,
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
    );
      } catch (e) {
        debugPrint('Snackbar gösterilemedi: $e');
      }
    }
  }

  // Bilgi mesajı göster
  static void showInfoMessage(String message) {
    if (Get.isRegistered<GetMaterialController>()) {
      try {
    Get.snackbar(
      'Bilgi',
      message,
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
    );
      } catch (e) {
        debugPrint('Snackbar gösterilemedi: $e');
      }
    }
  }

  // Başarı mesajı göster
  static void showSuccessMessage(String message) {
    if (Get.isRegistered<GetMaterialController>()) {
      try {
    Get.snackbar(
      'Başarılı',
      message,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 3),
    );
      } catch (e) {
        debugPrint('Snackbar gösterilemedi: $e');
      }
    }
  }
}