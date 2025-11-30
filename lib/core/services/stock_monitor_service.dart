import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/products/data/repositories/hybrid_product_repository.dart';
import '../../features/products/data/models/product_model.dart';
import '../../core/database/database_instance.dart';
import 'notification_service.dart';

class StockMonitorService {
  static final StockMonitorService _instance = StockMonitorService._internal();
  factory StockMonitorService() => _instance;
  StockMonitorService._internal();

  HybridProductRepository? _productRepository;
  final NotificationService _notificationService = NotificationService();
  Timer? _monitorTimer;
  final Set<String> _notifiedProducts = {}; // Bildirim gönderilen ürünler
  static const int stockThreshold = 10; // Stok uyarı eşiği
  static const Duration checkInterval = Duration(minutes: 30); // 30 dakikada bir kontrol

  // Stok izlemeyi başlat
  void startMonitoring() {
    // Repository'yi başlat
    if (_productRepository == null) {
      try {
        final dbInstance = Get.find<DatabaseInstance>();
        _productRepository = HybridProductRepository(
          localDb: dbInstance.database,
          firestore: FirebaseFirestore.instance,
        );
      } catch (e) {
        debugPrint('❌ StockMonitorService başlatılamadı: $e');
        return;
      }
    }

    // İlk kontrol
    _checkLowStockProducts();

    // Periyodik kontrol
    _monitorTimer = Timer.periodic(checkInterval, (_) {
      _checkLowStockProducts();
    });
  }

  // Stok izlemeyi durdur
  void stopMonitoring() {
    _monitorTimer?.cancel();
    _monitorTimer = null;
    _productRepository?.dispose();
    _productRepository = null;
  }

  // Düşük stoklu ürünleri kontrol et
  Future<void> _checkLowStockProducts() async {
    if (_productRepository == null) return;

    try {
      final lowStockProducts = await _productRepository!.getLowStockProducts(stockThreshold);

      for (var product in lowStockProducts) {
        // Eğer bu ürün için daha önce bildirim gönderilmediyse
        if (!_notifiedProducts.contains(product.id.toString())) {
          try {
            await _notificationService.sendStockAlertNotification(
              productName: product.name,
              stock: product.stock,
            );
            _notifiedProducts.add(product.id.toString());
            debugPrint('Stok uyarısı gönderildi: ${product.name} (Stok: ${product.stock})');
          } catch (e) {
            debugPrint('Stok uyarı bildirimi gönderilemedi: $e');
          }
        }
      }

      // Stoku normale dönen ürünleri listeden çıkar
      final allProducts = await _productRepository!.getProducts();
      _notifiedProducts.removeWhere((productId) {
        final product = allProducts.firstWhere(
          (p) => p.id.toString() == productId,
          orElse: () => Product(
            id: null,
            name: '',
            price: 0,
            stock: 100,
            category: 'Genel',          ),
        );
        return product.stock > stockThreshold;
      });
    } catch (e) {
      debugPrint('Stok kontrolü hatası: $e');
    }
  }

  // Manuel stok kontrolü
  Future<void> checkStockNow() async {
    await _checkLowStockProducts();
  }

  // Dispose
  void dispose() {
    stopMonitoring();
    _notifiedProducts.clear();
  }
}

