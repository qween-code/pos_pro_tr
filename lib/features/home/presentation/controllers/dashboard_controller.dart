import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../orders/data/repositories/hybrid_order_repository.dart';
import '../../../customers/data/repositories/hybrid_customer_repository.dart';
import '../../../products/data/repositories/hybrid_product_repository.dart';
import '../../../../core/database/database_instance.dart';
import '../../../../core/database/app_database.dart' as db;

class DashboardController extends GetxController {
  late final HybridOrderRepository _orderRepository;
  late final HybridCustomerRepository _customerRepository;
  late final HybridProductRepository _productRepository;

  @override
  void onInit() {
    super.onInit();
    final dbInstance = Get.find<DatabaseInstance>();
    final firestore = FirebaseFirestore.instance;
    
    _orderRepository = HybridOrderRepository(localDb: dbInstance.database, firestore: firestore);
    _customerRepository = HybridCustomerRepository(localDb: dbInstance.database, firestore: firestore);
    _productRepository = HybridProductRepository(localDb: dbInstance.database, firestore: firestore);
  }

  final RxDouble todaysSales = 0.0.obs;
  final RxInt todaysOrders = 0.obs;
  final RxInt newCustomersToday = 0.obs;
  final RxInt lowStockCount = 0.obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> selectedBranchId = Rx<String?>(null);
  final Rx<DateTimeRange?> selectedDateRange = Rx<DateTimeRange?>(null);

  // Toplam satış ve sipariş (filtrelenmiş)
  final RxDouble totalSales = 0.0.obs;
  final RxInt totalOrders = 0.obs;

  @override
  void onReady() {
    super.onReady();
    loadDashboardData();
  }

  /// Şube değiştiğinde dashboard'u yenile
  void selectBranch(String? branchId) {
    selectedBranchId.value = branchId;
    loadDashboardData();
    Get.snackbar(
      'Şube Değişti',
      'Dashboard verileri güncelleniyor...',
      backgroundColor: Colors.blue,
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
    );
  }

  /// Tarih aralığı değiştiğinde
  void selectDateRange(DateTimeRange? range) {
    selectedDateRange.value = range;
    loadDashboardData();
    Get.snackbar(
      'Tarih Filtresi',
      'Veriler seçilen tarihe göre güncelleniyor',
      backgroundColor: Colors.orange,
      colorText: Colors.white,
      duration: const Duration(seconds: 1),
    );
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadTodaysSales(),
        _loadNewCustomers(),
        _loadLowStockProducts(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadTodaysSales() async {
    try {
      final now = DateTime.now();
      
      // Tarih filtresi varsa onu kullan, yoksa bugünü kullan
      final start = selectedDateRange.value?.start ?? DateTime(now.year, now.month, now.day);
      final end = selectedDateRange.value?.end.add(const Duration(days: 1)) ?? 
                  DateTime(now.year, now.month, now.day).add(const Duration(days: 1));

      final orders = await _orderRepository.getOrders();
      
      // Filtrele
      var filteredOrders = orders.where((order) =>
        order.orderDate.isAfter(start) &&
        order.orderDate.isBefore(end) &&
        (order.status == 'completed' || order.status == 'partial_refunded')
      ).toList();

      // Şube filtresi
      if (selectedBranchId.value != null) {
        filteredOrders = filteredOrders.where((order) {
           // Order modelinde branchId varsa kullan
           // Şimdilik tüm siparişleri göster (branchId alanı eklenecek)
           return true; 
        }).toList();
      }

      // Değerleri güncelle
      todaysOrders.value = filteredOrders.length;
      todaysSales.value = filteredOrders.fold(
        0.0,
        (sum, order) => sum + order.totalAmount,
      );

      // Toplam değerleri de güncelle (SalesDetailScreen için)
      totalOrders.value = todaysOrders.value;
      totalSales.value = todaysSales.value;

    } catch (e) {
      print('Günlük satış yükleme hatası: $e');
    }
  }

  Future<void> _loadNewCustomers() async {
    try {
      final customers = await _customerRepository.getCustomers();
      // Şimdilik tüm müşterileri sayıyoruz
      newCustomersToday.value = customers.length;
    } catch (e) {
      print('Müşteri yükleme hatası: $e');
    }
  }

  Future<void> _loadLowStockProducts() async {
    try {
      final products = await _productRepository.getProducts();
      lowStockCount.value = products.where((p) => p.stock <= p.criticalStockLevel).length;
    } catch (e) {
      print('Düşük stok yükleme hatası: $e');
    }
  }
}
