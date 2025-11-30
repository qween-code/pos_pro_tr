import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../orders/data/models/order_model.dart' as models;
import '../../../orders/data/repositories/hybrid_order_repository.dart';
import '../../../../core/database/database_instance.dart';

class ReportController extends GetxController {
  late final HybridOrderRepository _orderRepository;

  @override
  void onInit() {
    super.onInit();
    final dbInstance = Get.find<DatabaseInstance>();
    _orderRepository = HybridOrderRepository(
      localDb: dbInstance.database,
      firestore: FirebaseFirestore.instance,
    );
  }
  
  final RxBool isLoading = false.obs;
  final RxList<models.Order> allOrders = <models.Order>[].obs;
  
  // Filtreler
  final Rx<DateTime> startDate = DateTime.now().obs;
  final Rx<DateTime> endDate = DateTime.now().obs;
  final RxString selectedPeriod = 'daily'.obs; // daily, weekly, monthly, custom

  // Özet Veriler (Geri eklendi)
  final RxDouble totalSales = 0.0.obs;
  final RxInt totalOrders = 0.obs;
  final RxDouble averageOrderValue = 0.0.obs;
  
  // Grafik Verileri (Geri eklendi)
  final RxMap<String, double> salesByPaymentMethod = <String, double>{}.obs;
  final RxList<DailySalesData> weeklySales = <DailySalesData>[].obs;
  final RxList<ProductSalesData> topProducts = <ProductSalesData>[].obs;

  // Detaylı Rapor Verileri
  final RxList<ProductSalesData> productSales = <ProductSalesData>[].obs;
  final RxList<CashierSalesData> cashierSales = <CashierSalesData>[].obs;
  final RxList<BranchSalesData> branchSales = <BranchSalesData>[].obs;

  @override
  void onReady() {
    super.onReady();
    setPeriod('daily');
  }

  void setPeriod(String period) {
    selectedPeriod.value = period;
    final now = DateTime.now();
    
    switch (period) {
      case 'daily':
        startDate.value = DateTime(now.year, now.month, now.day);
        endDate.value = now;
        break;
      case 'weekly':
        startDate.value = now.subtract(const Duration(days: 7));
        endDate.value = now;
        break;
      case 'monthly':
        startDate.value = DateTime(now.year, now.month, 1);
        endDate.value = now;
        break;
      // custom durumunda tarihleri elle set edeceğiz
    }
    
    fetchReportData();
  }

  Future<void> updateDateRange(DateTime start, DateTime end) async {
    startDate.value = start;
    endDate.value = end;
    selectedPeriod.value = 'custom';
    await fetchReportData();
  }

  Future<void> fetchReportData() async {
    isLoading.value = true;
    try {
      // Tüm siparişleri çek (gerçek uygulamada tarih aralığına göre query yapılmalı)
      final orders = await _orderRepository.getOrders();
      
      // Tarih aralığına göre filtrele
      final filteredOrders = orders.where((o) => 
        o.orderDate.isAfter(startDate.value.subtract(const Duration(seconds: 1))) && 
        o.orderDate.isBefore(endDate.value.add(const Duration(days: 1)))
      ).toList();

      allOrders.assignAll(filteredOrders);
      
      _calculateSummary();
      _calculatePaymentMethods();
      _calculateWeeklySales(); // Bu grafik her zaman son 7 günü gösterebilir veya seçili aralığı
      await _calculateDetailedReports();
      
    } catch (e) {
      debugPrint('Rapor verileri alınamadı: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void _calculateSummary() {
    final validOrders = allOrders.where((o) => o.status == 'completed' || o.status == 'partial_refunded').toList();
    totalSales.value = validOrders.fold(0, (sum, order) => sum + order.totalAmount);
    totalOrders.value = validOrders.length;
    averageOrderValue.value = totalOrders.value > 0 ? totalSales.value / totalOrders.value : 0;
  }

  void _calculatePaymentMethods() {
    final Map<String, double> methods = {};
    for (var order in allOrders) {
      if (order.status != 'completed' && order.status != 'partial_refunded') continue;
      if (order.payments.isNotEmpty) {
        for (var payment in order.payments) {
          methods[payment.method] = (methods[payment.method] ?? 0) + payment.amount;
        }
      } else {
        final method = order.paymentMethod ?? 'Diğer';
        methods[method] = (methods[method] ?? 0) + order.totalAmount;
      }
    }
    salesByPaymentMethod.assignAll(methods);
  }

  void _calculateWeeklySales() {
    final now = DateTime.now();
    final List<DailySalesData> data = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayOrders = allOrders.where((o) => 
        (o.status == 'completed' || o.status == 'partial_refunded') &&
        o.orderDate.isAfter(dayStart) && 
        o.orderDate.isBefore(dayEnd)
      ).toList();
      final dayTotal = dayOrders.fold(0.0, (sum, o) => sum + o.totalAmount);
      data.add(DailySalesData(
        dayName: DateFormat('EEE', 'tr_TR').format(date),
        amount: dayTotal,
      ));
    }
    weeklySales.assignAll(data);
  }

  Future<void> _calculateDetailedReports() async {
    // Ürün Bazlı Rapor
    final Map<String, double> pSales = {};
    final Map<String, String> pNames = {};
    
    // Kasiyer Bazlı Rapor
    final Map<String, double> cSales = {};
    
    // Şube Bazlı Rapor
    final Map<String, double> bSales = {};

    for (var order in allOrders) {
      if (order.status != 'completed' && order.status != 'partial_refunded') continue;
      
      // Kasiyer Satışları
      final cashier = order.cashierName ?? 'Bilinmeyen';
      cSales[cashier] = (cSales[cashier] ?? 0) + order.totalAmount;
      
      // Şube Satışları
      final branch = order.branchId ?? 'Merkez'; // Branch ID yerine isim bulmak gerekebilir
      bSales[branch] = (bSales[branch] ?? 0) + order.totalAmount;

      // Ürün Satışları (Denormalize veriden çekiyoruz - HIZLI)
      final items = order.items;
      if (items.isNotEmpty) {
        for (var item in items) {
          pSales[item.productId] = (pSales[item.productId] ?? 0) + item.totalPrice;
          pNames[item.productId] = item.productName ?? 'Ürün ${item.productId}';
        }
      } else {
        // Eğer items boşsa (eski veri), repository'den çekmeyi dene (YAVAŞ ama gerekli olabilir)
        try {
           // Bu kısım sadece eski veriler için çalışır, performans için kaçınılmalı
           // final fetchedItems = await _orderRepository.getOrderItems(order.id!);
           // ...
        } catch (e) {
          // ignore
        }
      }
    }

    // Listelere dönüştür ve sırala
    productSales.assignAll(pSales.entries.map((e) => ProductSalesData(
      productName: pNames[e.key] ?? 'Bilinmeyen',
      amount: e.value,
    )).toList()..sort((a, b) => b.amount.compareTo(a.amount)));

    cashierSales.assignAll(cSales.entries.map((e) => CashierSalesData(
      cashierName: e.key,
      amount: e.value,
      orderCount: allOrders.where((o) => o.cashierName == e.key).length,
    )).toList()..sort((a, b) => b.amount.compareTo(a.amount)));
    
    branchSales.assignAll(bSales.entries.map((e) => BranchSalesData(
      branchName: e.key, // ID'den isme dönüşüm yapılabilir
      amount: e.value,
    )).toList()..sort((a, b) => b.amount.compareTo(a.amount)));
    
    // Top products widget'ı için de güncelle
    topProducts.assignAll(productSales.take(5).toList());
  }

  // ... _calculateWeeklySales ...
}

class CashierSalesData {
  final String cashierName;
  final double amount;
  final int orderCount;
  CashierSalesData({required this.cashierName, required this.amount, required this.orderCount});
}

class BranchSalesData {
  final String branchName;
  final double amount;
  BranchSalesData({required this.branchName, required this.amount});
}

class DailySalesData {
  final String dayName;
  final double amount;
  DailySalesData({required this.dayName, required this.amount});
}

class ProductSalesData {
  final String productName;
  final double amount;
  ProductSalesData({required this.productName, required this.amount});
}