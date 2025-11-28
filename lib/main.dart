import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'app.dart';
import 'core/services/state_service.dart';
import 'core/services/database_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/stock_monitor_service.dart';
import 'core/utils/error_handler.dart';
import 'firebase_options.dart';

// Background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Background mesaj alındı: ${message.messageId}');
}

Future<void> main() async {
  // Flutter binding'i başlat
  WidgetsFlutterBinding.ensureInitialized();

  // Global hata yönetimini başlat
  ErrorHandler.setupGlobalErrorHandler();

  // Zone hatalarını yakalamak için runZonedGuarded kullan
  runZonedGuarded(
    () async {
      try {
        // **ÖNEMLİ: Firebase'i başlat - uygulama açılmadan önce**
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        debugPrint('✅ Firebase başlatıldı');

        // Firestore offline persistence'ı aktifleştir
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );

        // Background message handler'ı kaydet
        FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

        // State servisini başlat
        await initServices();
        debugPrint('✅ Servisler başlatıldı');

        // Diğer servisleri arka planda başlat
        _initializeServicesAsync();

      } catch (e, stack) {
        debugPrint('❌ Başlatma hatası: $e');
        debugPrint('Stack trace: $stack');
      }

      // Uygulamayı başlat (Firebase hazır olduktan SONRA)
      runApp(const PosProApp());
    },
    (error, stack) {
      ErrorHandler.handleZoneError(error, stack);
    },
  );
}

/// Servisleri async olarak başlat (non-blocking)
void _initializeServicesAsync() {
  // SQLite veritabanını başlat (async)
  DatabaseService().database.then((_) {
    debugPrint('✅ SQLite veritabanı hazır');
  }).catchError((e) {
    debugPrint('❌ SQLite başlatma hatası: $e');
  });

  // Bildirim servisini başlat (async)
  NotificationService().initialize().then((_) {
    debugPrint('✅ Bildirim servisi hazır');
  }).catchError((e) {
    debugPrint('❌ Bildirim servisi başlatma hatası: $e');
  });

  // Connectivity monitoring başlat (non-blocking)
  ConnectivityService().startMonitoring();

  // Stok izlemeyi başlat (non-blocking)
  StockMonitorService().startMonitoring();

  // Sync servisini başlat ve periyodik senkronizasyon başlat (non-blocking)
  _startPeriodicSync();
}

/// Uygulama başlangıcında gerekli servisleri başlat
Future<void> initServices() async {
  // State servisini başlat (eğer yoksa)
  if (!Get.isRegistered<StateService>()) {
    await Get.putAsync(() => StateService().init());
  }
}

/// Periyodik senkronizasyon başlat
void _startPeriodicSync() {
  final syncService = SyncService();
  final connectivityService = ConnectivityService();
  
  // Her 30 saniyede bir senkronizasyon kontrolü yap
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    try {
      final isOnline = await connectivityService.checkConnectivity();
      if (isOnline) {
        await syncService.syncAll();
      }
    } catch (e) {
      // Sessizce hata yok say (loglama yapılabilir)
      debugPrint('Periyodik sync hatası: $e');
    }
  });
}