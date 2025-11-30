import 'package:flutter/material.dart';
import 'package:workmanager/workmanager.dart';
import 'package:firebase_core/firebase_core.dart';
import '../database/database_instance.dart';
import '../../features/orders/data/repositories/hybrid_order_repository.dart';
import '../../features/products/data/repositories/hybrid_product_repository.dart';
import '../../features/customers/data/repositories/hybrid_customer_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' show Value;
import '../database/app_database.dart' as db;

/// Arka plan senkronizasyon görevi için callback
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('🔄 Arka plan senkronizasyonu başladı: $task');
    
    try {
      // Firebase'i initialize et
      await Firebase.initializeApp();
      
      // Database instance oluştur
      final dbInstance = DatabaseInstance();
      await dbInstance.init();
      
      final firestore = FirebaseFirestore.instance;
      
      // Repository'leri oluştur
      final orderRepo = HybridOrderRepository(
        localDb: dbInstance.database,
        firestore: firestore,
      );
      
      final productRepo = HybridProductRepository(
        localDb: dbInstance.database,
        firestore: firestore,
      );
      
      final customerRepo = HybridCustomerRepository(
        localDb: dbInstance.database,
        firestore: firestore,
      );
      
      // Senkronize edilmemiş verileri bul ve Firebase'e yükle
      await _syncUnsyncedData(dbInstance, firestore);
      
      debugPrint('✅ Arka plan senkronizasyonu tamamlandı');
      return Future.value(true);
    } catch (e) {
      debugPrint('❌ Arka plan senkronizasyonu hatası: $e');
      return Future.value(false);
    }
  });
}

/// Senkronize edilmemiş verileri Firebase'e yükle
Future<void> _syncUnsyncedData(DatabaseInstance dbInstance, FirebaseFirestore firestore) async {
  try {
    final database = dbInstance.database;
    
    // Senkronize edilmemiş siparişleri bul
    final unsyncedOrders = await (database.select(database.orders)
          ..where((t) => t.syncedToFirebase.equals(false)))
        .get();
    
    debugPrint('📦 Senkronize edilecek sipariş sayısı: ${unsyncedOrders.length}');
    
    for (final order in unsyncedOrders) {
      try {
        await firestore.collection('orders').doc(order.id).set({
          'customerId': order.customerId,
          'orderDate': order.orderDate,
          'totalAmount': order.totalAmount,
          'taxAmount': order.taxAmount,
          'discountAmount': order.discountAmount,
          'paymentMethod': order.paymentMethod,
          'status': order.status,
          'customerName': order.customerName,
          'cashierName': order.cashierName,
          'cashierId': order.cashierId,
          'branchId': order.branchId,
          'items': order.items,
          'payments': order.payments,
          'createdAt': order.createdAt,
          'updatedAt': order.updatedAt,
        });
        
        // Başarılı olursa local'de işaretle
        await (database.update(database.orders)..where((t) => t.id.equals(order.id)))
            .write(db.OrdersCompanion(syncedToFirebase: const Value(true)));
            
        debugPrint('✅ Sipariş senkronize edildi: ${order.id}');
      } catch (e) {
        debugPrint('❌ Sipariş senkronizasyon hatası: ${order.id} - $e');
      }
    }
    
    // Senkronize edilmemiş ürünleri bul
    final unsyncedProducts = await (database.select(database.products)
          ..where((t) => t.syncedToFirebase.equals(false)))
        .get();
    
    debugPrint('📦 Senkronize edilecek ürün sayısı: ${unsyncedProducts.length}');
    
    for (final product in unsyncedProducts) {
      try {
        await firestore.collection('products').doc(product.id).set({
          'name': product.name,
          'price': product.price,
          'stock': product.stock,
          'category': product.category,
          'barcode': product.barcode,
          'description': product.description,
          'taxRate': product.taxRate,
          'criticalStockLevel': product.criticalStockLevel,
          'imageUrl': product.imageUrl,
          'createdAt': product.createdAt,
          'updatedAt': product.updatedAt,
        });
        
        await (database.update(database.products)..where((t) => t.id.equals(product.id)))
            .write(db.ProductsCompanion(syncedToFirebase: const Value(true)));
            
        debugPrint('✅ Ürün senkronize edildi: ${product.id}');
      } catch (e) {
        debugPrint('❌ Ürün senkronizasyon hatası: ${product.id} - $e');
      }
    }
    
    // Müşterileri senkronize et
    final unsyncedCustomers = await (database.select(database.customers)
          ..where((t) => t.syncedToFirebase.equals(false)))
        .get();
    
    debugPrint('📦 Senkronize edilecek müşteri sayısı: ${unsyncedCustomers.length}');
    
    for (final customer in unsyncedCustomers) {
      try {
        await firestore.collection('customers').doc(customer.id).set({
          'name': customer.name,
          'email': customer.email,
          'phone': customer.phone,
          'address': customer.address,
          'note': customer.note,
          'balance': customer.balance,
          'loyaltyPoints': customer.loyaltyPoints,
          'totalShopping': customer.totalShopping,
          'visitCount': customer.visitCount,
          'createdAt': customer.createdAt,
          'updatedAt': customer.updatedAt,
        });
        
        await (database.update(database.customers)..where((t) => t.id.equals(customer.id)))
            .write(db.CustomersCompanion(syncedToFirebase: const Value(true)));
            
        debugPrint('✅ Müşteri senkronize edildi: ${customer.id}');
      } catch (e) {
        debugPrint('❌ Müşteri senkronizasyon hatası: ${customer.id} - $e');
      }
    }
  } catch (e) {
    debugPrint('❌ Senkronizasyon genel hatası: $e');
    rethrow;
  }
}

/// Background Sync Service
class BackgroundSyncService {
  static const String syncTaskName = "pos_pro_sync_task";
  
  /// Arka plan senkronizasyonunu başlat
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: true, // Release'te false yapılabilir
    );
    
    debugPrint('🔧 WorkManager başlatıldı');
  }
  
  /// Periyodik senkronizasyon görevi kur
  static Future<void> registerPeriodicSync({
    Duration frequency = const Duration(minutes: 15),
  }) async {
    await Workmanager().registerPeriodicTask(
      syncTaskName,
      syncTaskName,
      frequency: frequency,
      constraints: Constraints(
        networkType: NetworkType.connected, // İnternet bağlantısı gerekli
        requiresBatteryNotLow: true, // Batarya düşük değilse
      ),
    );
    
    debugPrint('✅ Periyodik senkronizasyon kuruldu (${frequency.inMinutes} dakikada bir)');
  }
  
  /// Tek seferlik senkronizasyon görevi kur
  static Future<void> runOneTimeSync() async {
    await Workmanager().registerOneOffTask(
      "${syncTaskName}_onetime",
      syncTaskName,
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
    
    debugPrint('🔄 Tek seferlik senkronizasyon başlatıldı');
  }
  
  /// Tüm arka plan görevlerini iptal et
  static Future<void> cancelAllTasks() async {
    await Workmanager().cancelAll();
    debugPrint('⛔ Tüm arka plan görevleri iptal edildi');
  }
}
