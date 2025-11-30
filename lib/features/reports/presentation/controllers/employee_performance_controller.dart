import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../orders/data/repositories/hybrid_order_repository.dart';
import '../../../orders/data/models/order_model.dart' as models;
import '../../../../core/database/database_instance.dart';

class EmployeePerformanceController extends GetxController {
  late final HybridOrderRepository _orderRepository;
  
  @override
  void onInit() {
    super.onInit();
    final dbInstance = Get.find<DatabaseInstance>();
    _orderRepository = HybridOrderRepository(
      localDb: dbInstance.database,
      firestore: FirebaseFirestore.instance,
    );
    loadEmployeePerformance();
  }
  
  final RxList<EmployeeStats> employeeStats = <EmployeeStats>[].obs;
  final RxBool isLoading = false.obs;
  final Rx<DateTime> selectedStartDate = DateTime.now().subtract(const Duration(days: 30)).obs;
  final Rx<DateTime> selectedEndDate = DateTime.now().obs;



  Future<void> loadEmployeePerformance() async {
    isLoading.value = true;
    try {
      final orders = await _orderRepository.getOrders();
      
      // Tarih filtreleme
      final filteredOrders = orders.where((order) =>
        order.orderDate.isAfter(selectedStartDate.value) &&
        order.orderDate.isBefore(selectedEndDate.value.add(const Duration(days: 1))) &&
        (order.status == 'completed' || order.status == 'partial_refunded')
      ).toList();

      // Çalışan bazında grouping (şimdilik dummy data - gerçekte userId ile)
      final Map<String, List<models.Order>> employeeOrders = {};
      
      // Örnek veri - gerçekte Order modelinde employeeId/userId olmalı
      for (var order in filteredOrders) {
        final employeeId = 'cashier_1'; // Gerçekte order.employeeId
        if (!employeeOrders.containsKey(employeeId)) {
          employeeOrders[employeeId] = [];
        }
        employeeOrders[employeeId]!.add(order);
      }

      // İstatistikleri hesapla
      final stats = employeeOrders.entries.map((entry) {
        final orders = entry.value;
        final totalSales = orders.fold(0.0, (sum, order) => sum + order.totalAmount);
        final avgSale = orders.isNotEmpty ? totalSales / orders.length : 0.0;

        return EmployeeStats(
          employeeId: entry.key,
          employeeName: 'Kasiyer 1', // Gerçekte user.name
          totalOrders: orders.length,
          totalSales: totalSales,
          averageSale: avgSale,
          topSaleAmount: orders.isEmpty ? 0.0 : orders.map((o) => o.totalAmount).reduce((a, b) => a > b ? a : b),
        );
      }).toList();

      // Toplam satışa göre sırala
      stats.sort((a, b) => b.totalSales.compareTo(a.totalSales));
      
      employeeStats.assignAll(stats);
    } catch (e) {
      print('Performans yükleme hatası: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    selectedStartDate.value = start;
    selectedEndDate.value = end;
    loadEmployeePerformance();
  }
}

class EmployeeStats {
  final String employeeId;
  final String employeeName;
  final int totalOrders;
  final double totalSales;
  final double averageSale;
  final double topSaleAmount;

  EmployeeStats({
    required this.employeeId,
    required this.employeeName,
    required this.totalOrders,
    required this.totalSales,
    required this.averageSale,
    required this.topSaleAmount,
  });
}
