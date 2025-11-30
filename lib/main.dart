import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/services/state_service.dart';
import 'core/services/database_service.dart';
import 'core/services/sync_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/notification_service.dart';
import 'core/services/stock_monitor_service.dart';
import 'core/services/background_sync_service.dart';
import 'core/utils/error_handler.dart';
import 'core/utils/data_seeder.dart';

import 'core/utils/auto_image_adder.dart';
import 'firebase_options.dart';
import 'core/database/database_instance.dart'; // Hibrit database
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/register/presentation/controllers/register_controller.dart';
import 'features/products/presentation/controllers/product_controller.dart';
import 'features/customers/presentation/controllers/customer_controller.dart';
import 'features/orders/presentation/controllers/order_controller.dart';
import 'features/branches/presentation/controllers/branch_controller.dart';

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

  // Locale verilerini başlat
  await initializeDateFormatting('tr_TR', null);

  try {
    // **ÖNEMLİ: Firebase'i başlat - uygulama açılmadan önce**
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase başlatıldı');

    // Firestore offline persistence'ı AÇ (Hız ve offline kullanım için)
    // Cache boyutunu 100MB ile sınırla (Doğru yönetim)
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: 100 * 1024 * 1024, // 100 MB
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

  // Zone guard ile uygulamayı başlat
  runZonedGuarded(
    () {
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
  
  // Arka plan senkronizasyonunu başlat (WorkManager)
  _initializeBackgroundSync();
  
  // Otomatik resim ekleme (ilk çalıştırmada)
  _addImagesToProducts();

  // Otomatik veri tohumlama (Eğer veritabanı boşsa)
  _seedDataOnFirstRun();
}

/// Ürünlere otomatik resim ekle (background)
void _addImagesToProducts() async {
  try {
    // 5 saniye bekle (app başlatılsın)
    await Future.delayed(const Duration(seconds: 5));
    
    final autoAdder = AutoImageAdder();
    await autoAdder.addImagesToAllProducts();
  } catch (e) {
    debugPrint('Auto image adder hatası: $e');
  }
}

/// Veritabanı boşsa otomatik veri ekle
void _seedDataOnFirstRun() async {
  try {
    // 3 saniye bekle
    await Future.delayed(const Duration(seconds: 3));
    
    final firestore = FirebaseFirestore.instance;
    
    // Kasiyer sayısını ve veri kalitesini kontrol et
    final cashierSnapshot = await firestore.collection('users').where('role', isEqualTo: 'cashier').get();
    final ordersSnapshot = await firestore.collection('orders').limit(100).get();
    
    bool needsSeed = false;
    
    if (cashierSnapshot.docs.length < 5) {
      needsSeed = true;
      debugPrint('🌱 Yetersiz kasiyer (${cashierSnapshot.docs.length}), tohumlama gerekli.');
    } else if (ordersSnapshot.docs.length < 100) {
      needsSeed = true;
      debugPrint('🌱 Yetersiz sipariş (${ordersSnapshot.docs.length}), tohumlama gerekli.');
    } else {
      // İsim kontrolü
      final hasLegacyNames = cashierSnapshot.docs.any((doc) {
        final name = doc.data()['name'] as String? ?? '';
        return name.startsWith('Kasiyer') || name.contains('Kasiyer 1');
      });
      
      if (hasLegacyNames) {
        needsSeed = true;
        debugPrint('🌱 Eski veri formatı tespit edildi, tohumlama gerekli.');
      }
    }
    
    if (needsSeed) {
      debugPrint('🚀 Otomatik tohumlama başlatılıyor...');
      final seeder = DataSeeder();
      await seeder.seedAll();
      debugPrint('✅ Otomatik tohumlama tamamlandı!');
    } else {
      debugPrint('ℹ️ Veritabanı güncel (${cashierSnapshot.docs.length} kasiyer), tohumlama atlandı.');
    }
  } catch (e) {
    debugPrint('❌ Otomatik tohumlama hatası: $e');
  }
}



/// Uygulama başlangıcında gerekli servisleri başlat
Future<void> initServices() async {
  // 1. Hibrit Database'i başlat (EN ÖNCELİKLİ)
  if (!Get.isRegistered<DatabaseInstance>()) {
    await Get.putAsync(() => DatabaseInstance().init());
    debugPrint('✅ Hibrit Database hazır');
  }
  
  // 2. State servisini başlat
  if (!Get.isRegistered<StateService>()) {
    await Get.putAsync(() => StateService().init());
  }
  
  // Kritik controller'ları pre-initialize et
  debugPrint('📦 Pre-initializing controllers...');
  
  // AuthController (En kritiği)
  if (!Get.isRegistered<AuthController>()) {
    Get.put(AuthController(), permanent: true);
  }

  // Diğer controller'lar (Lazy put ile ihtiyaç duyulduğunda oluşturulur ama kayıtlı olur)
  if (!Get.isRegistered<RegisterController>()) {
    Get.lazyPut(() => RegisterController(), fenix: true);
  }
  if (!Get.isRegistered<ProductController>()) {
    Get.lazyPut(() => ProductController(), fenix: true);
  }
  if (!Get.isRegistered<CustomerController>()) {
    Get.lazyPut(() => CustomerController(), fenix: true);
  }
  if (!Get.isRegistered<OrderController>()) {
    Get.lazyPut(() => OrderController(), fenix: true);
  }
  if (!Get.isRegistered<BranchController>()) {
    Get.lazyPut(() => BranchController(), fenix: true);
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

/// Arka plan senkronizasyonunu başlat (WorkManager)
void _initializeBackgroundSync() async {
  try {
    // WorkManager'ı başlat
    await BackgroundSyncService.initialize();
    
    // 15 dakikada bir periyodik senkronizasyon kur
    await BackgroundSyncService.registerPeriodicSync(
      frequency: const Duration(minutes: 15),
    );
    
    debugPrint('✅ Arka plan senkronizasyonu kuruldu');
  } catch (e) {
    debugPrint('❌ Arka plan senkronizasyonu başlatma hatası: $e');
  }
}