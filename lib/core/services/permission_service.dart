import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';

/// Uygulama izinlerini yöneten servis
class PermissionService {
  /// Galeri erişim izni kontrolü ve isteği (Android 13+ uyumlu)
  static Future<bool> requestStoragePermission() async {
    try {
      // Android 13+ için photos izni
      if (await Permission.photos.isGranted) {
        return true;
      }
      
      // İzin durumunu kontrol et
      final status = await Permission.photos.request();
      
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        // Kullanıcıya ayarlara git seçeneği sun
        _showPermissionDeniedDialog();
        return false;
      }
      
      return false;
    } catch (e) {
      debugPrint('İzin hatası: $e');
      return false;
    }
  }

  /// Kamera izni kontrolü
  static Future<bool> requestCameraPermission() async {
    try {
      if (await Permission.camera.isGranted) {
        return true;
      }
      
      final status = await Permission.camera.request();
      
      if (status.isGranted) {
        return true;
      } else if (status.isPermanentlyDenied) {
        _showPermissionDeniedDialog();
        return false;
      }
      
      return false;
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
              openAppSettings();
            },
            child: const Text('Ayarlar'),
          ),
        ],
      ),
    );
  }
}
