import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Uygulama izinlerini yöneten servis
class PermissionService {
  /// Galeri erişim izni kontrolü ve isteği (Android 13+ uyumlu)
  static Future<bool> requestStoragePermission() async {
    try {
      // Windows/Linux/macOS'ta izin gerekmez
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return true;
      }
      
      // Mobile platformlarda permission_handler gerekir
      // Şimdilik tüm mobile platformlar için true döndür
      // TODO: Android/iOS için permission_handler eklenebilir
      debugPrint('Warning: Permission handler not implemented for mobile platforms');
      return true;
    } catch (e) {
      debugPrint('İzin hatası: $e');
      return false;
    }
  }

  /// Kamera izni kontrolü
  static Future<bool> requestCameraPermission() async {
    try {
      // Windows/Linux/macOS'ta izin gerekmez
      if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
        return true;
      }
      
      // Mobile platformlarda permission_handler gerekir
      // Şimdilik tüm mobile platformlar için true döndür
      // TODO: Android/iOS için permission_handler eklenebilir
      debugPrint('Warning: Permission handler not implemented for mobile platforms');
      return true;
    } catch (e) {
      debugPrint('Kamera izin hatası: $e');
      return false;
    }
  }

  /// İzin reddedildi dialog'u
  static void _showPermissionDeniedDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('İzin Gerekli'),
        content: const Text(
          'Bu özelliği kullanmak için izin vermeniz gerekiyor. '
          'Lütfen ayarlardan uygulamaya izin verin.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              // TODO: Platform-specific settings implementation
            },
            child: const Text('Ayarlar'),
          ),
        ],
      ),
    );
  }
}
