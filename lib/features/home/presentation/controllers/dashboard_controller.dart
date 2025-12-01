import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../orders/data/repositories/hybrid_order_repository.dart';
import '../../../customers/data/repositories/hybrid_customer_repository.dart';
import '../../../products/data/repositories/hybrid_product_repository.dart';
import '../../../../core/database/database_instance.dart';
import '../../../../core/database/app_database.dart' as db;
import '../../../../core/services/firebase_service.dart';

class DashboardController extends GetxController {
  late final HybridOrderRepository _orderRepository;
  late final HybridCustomerRepository _customerRepository;
  late final HybridProductRepository _productRepository;

  @override
  void onInit() {
    super.onInit();
    final dbInstance = Get.find<DatabaseInstance>();
    final firestore = FirebaseService.instance.firestore;
    
    _orderRepository = HybridOrderRepository(localDb: dbInstance.database, firestore: firestore);
    _customerRepository = HybridCustomerRepository(localDb: dbInstance.database, firestore: firestore);
    _productRepository = HybridProductRepository(localDb: dbInstance.database, firestore: firestore);
  }

  final RxDouble todaysSales = 0.0.obs;
  final RxDouble weeklySales = 0.0.obs;
  final RxDouble monthlySales = 0.0.obs;
  final RxInt todaysOrders = 0.obs;
  final RxInt totalCustomers = 0.obs;
  final RxInt lowStockCount = 0.obs;
  final RxBool isLoading = false.obs;
  final Rx<String?> selectedBranchId = Rx<String?>(null);
  
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
  }

  Future<void> loadDashboardData() async {
    isLoading.value = true;
    try {
      await Future.wait([
        _loadSalesMetrics(),
        _loadNewCustomers(),
        _loadLowStockProducts(),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadSalesMetrics() async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final startOfMonth = DateTime(now.year, now.month, 1);

      final orders = await _orderRepository.getOrders(limit: 5000); // Fetch more for analytics
      
      // Filter completed orders
      final completedOrders = orders.where((o) => o.status == 'completed').toList();

      // Calculate Today
      final todayOrdersList = completedOrders.where((o) => o.orderDate.isAfter(startOfDay)).toList();
      todaysSales.value = todayOrdersList.fold(0.0, (sum, o) => sum + o.totalAmount);
      todaysOrders.value = todayOrdersList.length;

      // Calculate Week
      final weekOrdersList = completedOrders.where((o) => o.orderDate.isAfter(startOfWeek)).toList();
      weeklySales.value = weekOrdersList.fold(0.0, (sum, o) => sum + o.totalAmount);

      // Calculate Month
      final monthOrdersList = completedOrders.where((o) => o.orderDate.isAfter(startOfMonth)).toList();
      monthlySales.value = monthOrdersList.fold(0.0, (sum, o) => sum + o.totalAmount);

      // Update filtered totals (for now same as today, or based on selection if we had one)
      // For simplicity in this controller, we keep totalSales as today's sales or implement date range logic if needed.
      // But HomeScreen uses specific cards.
      
    } catch (e) {
      debugPrint('Satış verileri yükleme hatası: $e');
    }
  }

  Future<void> _loadNewCustomers() async {
    try {
      final customers = await _customerRepository.getCustomers();
      totalCustomers.value = customers.length;
    } catch (e) {
      debugPrint('Müşteri yükleme hatası: $e');
    }
  }

  Future<void> _loadLowStockProducts() async {
    try {
      final products = await _productRepository.getProducts();
      lowStockCount.value = products.where((p) => p.stock <= p.criticalStockLevel).length;
    } catch (e) {
      debugPrint('Düşük stok yükleme hatası: $e');
    }
  }
}
