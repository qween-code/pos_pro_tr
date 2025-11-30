import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../orders/data/repositories/hybrid_order_repository.dart';
import '../../../orders/data/models/order_model.dart' as models;
import '../../../../core/database/database_instance.dart';
import 'package:get/get.dart' hide Value;

/// Satış Analizi Ekranı
class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final HybridOrderRepository _orderRepository;

  String selectedPeriod = 'today';
  String? selectedBranch;
  List<String> branches = [];
  bool isLoading = false;

  double totalSales = 0.0;
  int totalOrders = 0;
  Map<String, double> paymentMethods = {};
  Map<int, double> hourlySales = {};
  List<TopProduct> topProducts = [];
  Map<String, double> cashierPerformance = {};

  @override
  void initState() {
    super.initState();
    // HybridOrderRepository'yi başlat
    final dbInstance = Get.find<DatabaseInstance>();
    _orderRepository = HybridOrderRepository(
      localDb: dbInstance.database,
      firestore: _firestore,
    );
    _loadBranches();
    _loadData();
  }

  Future<void> _loadBranches() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'cashier')
          .get();

      final branchSet = <String>{};
      for (var doc in snapshot.docs) {
        final region = doc.data()['region'] as String?;
        if (region != null && region.isNotEmpty) {
          branchSet.add(region);
        }
      }

      setState(() {
        branches = branchSet.toList()..sort();
      });
    } catch (e) {
      debugPrint('❌ Şube yükleme hatası: $e');
    }
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);

    try {
      final now = DateTime.now();
      DateTime startDate;

      switch (selectedPeriod) {
        case 'today':
          startDate = DateTime(now.year, now.month, now.day);
          break;
        case 'week':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case 'month':
          startDate = DateTime(now.year, now.month, 1);
          break;
        default:
          startDate = DateTime(now.year, now.month, now.day);
      }

      // Siparişleri lokal'den çek (HybridOrderRepository kullan)
      final allOrders = await _orderRepository.getOrders();
      
      // Tarih ve şube filtresi uygula
      final filteredOrders = allOrders.where((order) {
        // Tarih filtresi
        if (order.orderDate.isBefore(startDate)) return false;
        
        // Şube filtresi
        if (selectedBranch != null && order.branchId != selectedBranch) return false;
        
        // Sadece tamamlanmış siparişleri al
        if (order.status != 'completed') return false;
        
        return true;
      }).toList();

      double sales = 0.0;
      Map<String, double> payments = {};
      Map<String, double> cashiers = {};
      Map<int, double> hourly = {
        for (var i = 0; i < 24; i++) i: 0.0
      };
      Map<String, TopProduct> products = {};

      // Siparişleri işle
      for (final order in filteredOrders) {
        final amount = order.totalAmount;
        final method = order.paymentMethod;
        final orderDate = order.orderDate;

        sales += amount;

        // Ödeme yöntemi
        payments[method] = (payments[method] ?? 0.0) + amount;

        // Kasiyer Performansı
        final cashierName = order.cashierName ?? 'Bilinmeyen';
        cashiers[cashierName] = (cashiers[cashierName] ?? 0.0) + amount;

        // Saatlik satış
        final hour = orderDate.hour;
        hourly[hour] = (hourly[hour] ?? 0.0) + amount;

        // En çok satan ürünler
        for (var item in order.items) {
          final productName = item.productName;
          final quantity = item.quantity;
          final total = item.total;

          if (!products.containsKey(productName)) {
            products[productName] = TopProduct(
              name: productName,
              quantity: 0,
              totalSales: 0.0,
            );
          }
          products[productName]!.quantity += quantity;
          products[productName]!.totalSales += total;
        }
      }

      // En çok satanları sırala
      final sortedProducts = products.values.toList()
        ..sort((a, b) => b.totalSales.compareTo(a.totalSales));

      setState(() {
        totalSales = sales;
        totalOrders = filteredOrders.length;
        paymentMethods = payments;
        cashierPerformance = cashiers;
        hourlySales = hourly;
        topProducts = sortedProducts.take(10).toList();
        isLoading = false;
      });

      debugPrint('📊 Satış analizi yüklendi: ₺${sales.toStringAsFixed(2)} - ${filteredOrders.length} sipariş');
    } catch (e) {
      debugPrint('❌ Satış analizi hatası: $e');
      setState(() => isLoading = false);
      Get.snackbar(
        'Hata',
        'Veriler yüklenirken bir hata oluştu',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Satış Analizi', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _showZReportDialog,
            tooltip: 'Z Raporu',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPeriodSelector(),
                  const SizedBox(height: 24),
                  _buildSummaryCards(),
                  const SizedBox(height: 24),
                  _buildHourlySalesChart(),
                  const SizedBox(height: 24),
                  _buildPaymentMethodsChart(),
                  const SizedBox(height: 24),

                  _buildCashierPerformanceChart(), // Added chart
                  const SizedBox(height: 24),
                  _buildTopProducts(),
                ],
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildPeriodChip('Bugün', 'today'),
            const SizedBox(width: 8),
            _buildPeriodChip('Bu Hafta', 'week'),
            const SizedBox(width: 8),
            _buildPeriodChip('Bu Ay', 'month'),
          ],
        ),
        if (branches.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildBranchSelector(),
        ],
      ],
    );
  }

  Widget _buildBranchSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildBranchChip('Tüm Şubeler', null),
          const SizedBox(width: 8),
          ...branches.map((branch) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: _buildBranchChip(branch, branch),
          )),
        ],
      ),
    );
  }

  Widget _buildBranchChip(String label, String? value) {
    final isSelected = selectedBranch == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => selectedBranch = selected ? value : null);
        _loadData();
      },
      selectedColor: Colors.blue,
      backgroundColor: AppTheme.surface,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : AppTheme.textSecondary,
      ),
    );
  }

  Widget _buildPeriodChip(String label, String value) {
    final isSelected = selectedPeriod == value;
    return Expanded(
      child: ChoiceChip(
        label: Center(child: Text(label)),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setState(() => selectedPeriod = value);
            _loadData();
          }
        },
        selectedColor: AppTheme.primary,
        backgroundColor: AppTheme.surface,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [

        Expanded(
          child: _buildSummaryCard(
            'Toplam Satış\n(${_getPeriodLabel()})',
            '₺${totalSales.toStringAsFixed(2)}',
            Icons.attach_money,
            Colors.green,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildSummaryCard(
            'Sipariş Sayısı\n(${_getPeriodLabel()})',
            totalOrders.toString(),
            Icons.shopping_bag,
            Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlySalesChart() {
    final dataPoints = hourlySales.entries
        .where((e) => e.value > 0)
        .map((e) => FlSpot(e.key.toDouble(), e.value))
        .toList();

    if (dataPoints.isEmpty) {
      return _buildEmptyChart('Saatlik Satış Analizi');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saatlik Satış Grafiği',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 4,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}:00',
                          style: const TextStyle(color: Colors.white70, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: dataPoints,
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsChart() {
    if (paymentMethods.isEmpty) {
      return _buildEmptyChart('Ödeme Yöntemi Dağılımı');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ödeme Yöntemleri',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...paymentMethods.entries.map((entry) {
            final percent = (entry.value / totalSales * 100);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(color: Colors.white),
                      ),
                      Text(
                        '₺${entry.value.toStringAsFixed(2)} (${percent.toStringAsFixed(1)}%)',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: Colors.white12,
                    color: entry.key == 'Nakit' ? Colors.green : Colors.blue,
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    if (topProducts.isEmpty) {
      return _buildEmptyChart('En Çok Satan Ürünler');
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'En Çok Satan Ürünler',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...topProducts.asMap().entries.map((entry) {
            final index = entry.key;
            final product = entry.value;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: index < 3 ? AppTheme.primary.withOpacity(0.2) : Colors.white12,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: index < 3 ? AppTheme.primary : Colors.white70,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${product.quantity} adet',
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '₺${product.totalSales.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  String _getPeriodLabel() {
    switch (selectedPeriod) {
      case 'today':
        return 'Bugün';
      case 'week':
        return 'Bu Hafta';
      case 'month':
        return 'Bu Ay';
      default:
        return '';
    }
  }

  Widget _buildCashierPerformanceChart() {
    if (cashierPerformance.isEmpty) {
      return _buildEmptyChart('Kasiyer Performansı');
    }

    final sortedCashiers = cashierPerformance.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kasiyer Performansı',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ...sortedCashiers.map((e) {
            final percentage = totalSales > 0 ? (e.value / totalSales) : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        e.key,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        '₺${e.value.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.white10,
                      color: AppTheme.primary,
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(String title) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Icon(
            Icons.analytics_outlined,
            size: 48,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bu dönem için veri yok',
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showZReportDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: AppTheme.primary),
            const SizedBox(width: 8),
            const Text('Z Raporu (Gün Sonu)'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now())}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _buildReportRow('Toplam Satış:', '₺${totalSales.toStringAsFixed(2)}', isBold: true),
              _buildReportRow('Toplam Sipariş:', '$totalOrders Adet'),
              const Divider(),
              const Text('Ödeme Dağılımı:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...paymentMethods.entries.map((e) => _buildReportRow(
                e.key, 
                '₺${e.value.toStringAsFixed(2)}'
              )),
              const Divider(),
              const Text('En Çok Satanlar (Top 5):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...topProducts.take(5).map((p) => _buildReportRow(
                p.name, 
                '${p.quantity} Adet'
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Get.back();
              Get.snackbar(
                'Başarılı', 
                'Z Raporu yazıcıya gönderildi',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            icon: const Icon(Icons.print),
            label: const Text('Yazdır'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildReportRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }
}

class TopProduct {
  final String name;
  int quantity;
  double totalSales;

  TopProduct({
    required this.name,
    required this.quantity,
    required this.totalSales,
  });
}
