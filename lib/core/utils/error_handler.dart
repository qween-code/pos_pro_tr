import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ErrorHandler {
  // Post-frame callback ile snackbar göster (build sırasında setState önleme)
  static void _showSnackbar({
    required String title,
    required String message,
    required Color backgroundColor,
  }) {
    if (Get.isRegistered<GetMaterialController>()) {
      try {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Get.snackbar(
            title,
            message,
            backgroundColor: backgroundColor,
            colorText: Colors.white,
            snackPosition: SnackPosition.BOTTOM,
            duration: const Duration(seconds: 3),
          );
        });
      } catch (e) {
        debugPrint('Snackbar gösterilemedi: $e');
      }
    }
  }

  // Global hata yakalayıcı - SADECE LOGLAMA (popup gösterme)
  static void setupGlobalErrorHandler() {
    FlutterError.onError = (FlutterErrorDetails details) async {
      // Hata detaylarını sadece logla, popup gösterme
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack Trace: ${details.stack}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      
      // Kritik hatalar için popup (opsiyonel - yorumda bırakıldı)
      // if (details.exception.toString().contains('CRITICAL')) {
      //   _showSnackbar(
      //     title: 'Kritik Hata',
      //     message: 'Uygulamada kritik bir hata oluştu.',
      //     backgroundColor: Colors.red,
      //   );
      // }
    };
  }

  // Zone hatalarını yakalamak için callback - SADECE LOGLAMA
  static void handleZoneError(Object error, StackTrace stack) {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('Zone Error: $error');
    debugPrint('Stack Trace: $stack');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

    // Sistem hatası popup'ı devre dışı (sadece loglama)
    // _showSnackbar(
    //   title: 'Sistem Hatası',
    //   message: 'Uygulamada bir sistem hatası oluştu.',
    //   backgroundColor: Colors.red,
    // );
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

    debugPrint('API Error: $error');

    _showSnackbar(
      title: 'Hata',
      message: message,
      backgroundColor: Colors.red,
    );
  }

  // Ağ bağlantısı hatası
  static void handleNetworkError() {
    _showSnackbar(
      title: 'Bağlantı Hatası',
      message: 'İnternet bağlantınızı kontrol edin ve tekrar deneyin.',
      backgroundColor: Colors.orange,
    );
  }

  // Yetkilendirme hatası
  static void handleAuthError() {
    _showSnackbar(
      title: 'Yetkilendirme Hatası',
      message: 'Bu işlemi gerçekleştirmek için yetkiniz bulunmamaktadır.',
      backgroundColor: Colors.red,
    );
  }

  // Form validasyon hatası
  static void handleValidationError(String message) {
    _showSnackbar(
      title: 'Geçersiz Bilgi',
      message: message,
      backgroundColor: Colors.orange,
    );
  }

  // Bilgi mesajı göster
  static void showInfoMessage(String message) {
    _showSnackbar(
      title: 'Bilgi',
      message: message,
      backgroundColor: Colors.blue,
    );
  }

  // Başarı mesajı göster
  static void showSuccessMessage(String message) {
    _showSnackbar(
      title: 'Başarılı',
      message: message,
      backgroundColor: Colors.green,
    );
  }
}