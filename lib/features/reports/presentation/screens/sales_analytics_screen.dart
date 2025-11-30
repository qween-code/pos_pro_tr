import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../orders/presentation/controllers/order_controller.dart';
import '../../../orders/data/models/order_model.dart' as models;

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  // State Variables
  bool isLoading = false;
  String selectedPeriod = 'today'; // today, week, month
  String? selectedBranch;
  List<String> branches = [];

  // Data Variables
  double totalSales = 0.0;
  int totalOrders = 0;
  double averageBasket = 0.0;
  
  Map<String, double> paymentMethods = {};
  Map<int, double> hourlySales = {};
  List<TopProduct> topProducts = [];
  Map<String, double> cashierPerformance = {};
  
  // Detail Data
  List<models.Order> _currentFilteredOrders = [];

  @override
  void initState() {
    super.initState();
    _loadBranches();
    _loadData();
  }

  void _loadBranches() {
    final authController = Get.find<AuthController>();
    final user = authController.currentUser.value;
    
    if (user != null && user.role == 'admin') {
      // Admin için şubeleri manuel ekleyelim (Normalde API'den gelir)
      branches = ['Ana Şube', 'İstanbul', 'Ankara', 'İzmir'];
    } else if (user?.region != null) {
      branches = [user!.region!];
      selectedBranch = user.region;
    }
  }

  Future<void> _loadData() async {
    setState(() => isLoading = true);
    try {
      final orderController = Get.find<OrderController>();
      await orderController.fetchOrders();
      final orders = orderController.orders;

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

      final filteredOrders = orders.where((order) {
        if (order.orderDate.isBefore(startDate)) return false;
        if (selectedBranch != null && order.branchId != selectedBranch) return false;
        if (order.status != 'completed') return false;
        return true;
      }).toList();

      _currentFilteredOrders = filteredOrders;

      // Calculate Metrics
      double sales = 0.0;
      Map<String, double> payments = {};
      Map<String, double> cashiers = {};
      Map<int, double> hourly = {for (var i = 0; i < 24; i++) i: 0.0};
      Map<String, TopProduct> products = {};

      for (final order in filteredOrders) {
        final amount = order.totalAmount;
        final method = order.paymentMethod ?? 'Bilinmeyen';
        final cashier = order.cashierName ?? 'Bilinmeyen';
        final hour = order.orderDate.hour;

        sales += amount;
        payments[method] = (payments[method] ?? 0.0) + amount;
        cashiers[cashier] = (cashiers[cashier] ?? 0.0) + amount;
        hourly[hour] = (hourly[hour] ?? 0.0) + amount;

        for (var item in order.items) {
          final pName = item.productName ?? 'Bilinmeyen Ürün';
          if (!products.containsKey(pName)) {
            products[pName] = TopProduct(name: pName, quantity: 0, totalSales: 0.0);
          }
          products[pName]!.quantity += item.quantity;
          products[pName]!.totalSales += item.total;
        }
      }

      final sortedProducts = products.values.toList()
        ..sort((a, b) => b.totalSales.compareTo(a.totalSales));

      setState(() {
        totalSales = sales;
        totalOrders = filteredOrders.length;
        averageBasket = totalOrders > 0 ? totalSales / totalOrders : 0.0;
        paymentMethods = payments;
        cashierPerformance = cashiers;
        hourlySales = hourly;
        topProducts = sortedProducts.take(10).toList();
        isLoading = false;
      });

    } catch (e) {
      debugPrint('❌ Analiz hatası: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Light grey background for professional look
      appBar: _buildAppBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(),
                    const SizedBox(height: 24),
                    _buildMetricsGrid(),
                    const SizedBox(height: 24),
                    _buildMainChartSection(),
                    const SizedBox(height: 24),
                    _buildSplitSection(),
                    const SizedBox(height: 24),
                    _buildCashierPerformanceSection(),
                    const SizedBox(height: 40), // Bottom padding
                  ],
                ),
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'İşletme Özeti',
        style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: Colors.black87),
      actions: [
        IconButton(
          icon: const Icon(Icons.print_outlined),
          onPressed: _showZReportDialog,
          tooltip: 'Z Raporu Yazdır',
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: _loadData,
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeaderSection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hoş Geldiniz 👋',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('d MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now()),
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        _buildPeriodSelector(),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildPeriodBtn('Bugün', 'today'),
          _buildPeriodBtn('Bu Hafta', 'week'),
          _buildPeriodBtn('Bu Ay', 'month'),
        ],
      ),
    );
  }

  Widget _buildPeriodBtn(String label, String value) {
    final isSelected = selectedPeriod == value;
    return GestureDetector(
      onTap: () {
        setState(() => selectedPeriod = value);
        _loadData();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[600],
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Responsive grid: 2 columns on mobile, 4 on tablet
        final crossAxisCount = width < 600 ? 2 : 4;
        final aspectRatio = width < 600 ? 1.4 : 1.8;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: aspectRatio,
          children: [
            _buildMetricCard(
              title: 'Toplam Satış',
              value: '₺${totalSales.toStringAsFixed(2)}',
              icon: Icons.attach_money,
              color: const Color(0xFF10B981), // Emerald Green
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: _showOrderListDialog,
            ),
            _buildMetricCard(
              title: 'Sipariş Sayısı',
              value: '$totalOrders',
              icon: Icons.shopping_bag_outlined,
              color: const Color(0xFF3B82F6), // Blue
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: _showOrderListDialog,
            ),
            _buildMetricCard(
              title: 'Ort. Sepet',
              value: '₺${averageBasket.toStringAsFixed(2)}',
              icon: Icons.pie_chart_outline,
              color: const Color(0xFF8B5CF6), // Purple
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            _buildMetricCard(
              title: 'Aktif Kasiyer',
              value: '${cashierPerformance.length}',
              icon: Icons.people_outline,
              color: const Color(0xFFF59E0B), // Amber
              gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Gradient gradient,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative Circle
            Positioned(
              right: -20,
              top: -20,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainChartSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saatlik Satış Trendi',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: totalSales > 0 ? totalSales / 5 : 100,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.grey[200],
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 4, // Her 4 saatte bir etiket
                      getTitlesWidget: (value, meta) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            '${value.toInt()}:00',
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(24, (index) {
                      return FlSpot(index.toDouble(), hourlySales[index] ?? 0.0);
                    }),
                    isCurved: true,
                    color: AppTheme.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppTheme.primary.withOpacity(0.15),
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primary.withOpacity(0.3),
                          AppTheme.primary.withOpacity(0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                minX: 0,
                maxX: 23,
                minY: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 800) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildTopProductsCard()),
              const SizedBox(width: 24),
              Expanded(child: _buildPaymentMethodsCard()),
            ],
          );
        } else {
          return Column(
            children: [
              _buildTopProductsCard(),
              const SizedBox(height: 24),
              _buildPaymentMethodsCard(),
            ],
          );
        }
      },
    );
  }

  Widget _buildTopProductsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'En Çok Satan Ürünler',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          if (topProducts.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Veri yok')))
          else
            ...topProducts.take(5).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final product = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: index == 0 ? const Color(0xFFFFD700).withOpacity(0.2) : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '#${index + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: index == 0 ? const Color(0xFFB7950B) : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                          Text('${product.quantity} Adet', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                    ),
                    Text(
                      '₺${product.totalSales.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ödeme Yöntemleri',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: paymentMethods.isEmpty
                ? const Center(child: Text('Veri yok'))
                : PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: paymentMethods.entries.map((e) {
                        final isCash = e.key.toLowerCase().contains('nakit');
                        return PieChartSectionData(
                          color: isCash ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                          value: e.value,
                          title: '${((e.value / totalSales) * 100).toStringAsFixed(0)}%',
                          radius: 60,
                          titleStyle: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
          // Legend
          ...paymentMethods.entries.map((e) {
            final isCash = e.key.toLowerCase().contains('nakit');
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: isCash ? const Color(0xFF10B981) : const Color(0xFF3B82F6),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(e.key, style: const TextStyle(color: Colors.black87)),
                  const Spacer(),
                  Text('₺${e.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCashierPerformanceSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Personel Performansı',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          if (cashierPerformance.isEmpty)
            const Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Veri yok')))
          else
            ...cashierPerformance.entries.map((e) {
              final percentage = totalSales > 0 ? (e.value / totalSales) : 0.0;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          radius: 16,
                          child: Icon(Icons.person, size: 18, color: Colors.grey[600]),
                        ),
                        const SizedBox(width: 12),
                        Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Text('₺${e.value.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percentage,
                        backgroundColor: Colors.grey[100],
                        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        minHeight: 6,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _showOrderListDialog() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          height: 700,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sipariş Detayları',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        _getPeriodLabel(),
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Get.back(),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: _currentFilteredOrders.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text('Sipariş bulunamadı', style: TextStyle(color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView.separated(
                        itemCount: _currentFilteredOrders.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final order = _currentFilteredOrders[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              onTap: () => _showOrderDetailDialog(order),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '#${index + 1}',
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                'Sipariş #${order.id?.substring(0, 8) ?? "---"}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Row(
                                  children: [
                                  ],
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '₺${order.totalAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF10B981),
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      order.paymentMethod ?? "Diğer",
                                      style: TextStyle(color: Colors.grey[600], fontSize: 10),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showZReportDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.receipt_long, color: AppTheme.primary, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Z Raporu (Gün Sonu)',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),
              Text(
                DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
                style: const TextStyle(color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildReportRow('Toplam Satış', '₺${totalSales.toStringAsFixed(2)}', isBold: true),
              _buildReportRow('Toplam Sipariş', '$totalOrders Adet'),
              const Divider(height: 32, color: AppTheme.primary),
              ...paymentMethods.entries.map((e) => _buildReportRow(e.key, '₺${e.value.toStringAsFixed(2)}')),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Get.back();
                    Get.snackbar('Başarılı', 'Z Raporu yazdırılıyor...', backgroundColor: Colors.green, colorText: Colors.white);
                  },
                  icon: const Icon(Icons.print),
                  label: const Text('Yazdır ve Kapat'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: AppTheme.background,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppTheme.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(color: AppTheme.textPrimary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _showOrderDetailDialog(models.Order order) {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sipariş Detayları',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                      ),
                      Text(
                        '#${order.id?.substring(0, 8) ?? "---"}',
                        style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.primary),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow('Tarih', DateFormat('dd.MM.yyyy HH:mm').format(order.orderDate)),
                    const Divider(color: AppTheme.primary, height: 24),
                    _buildDetailRow('Kasiyer', order.cashierName ?? 'Bilinmeyen'),
                    const Divider(color: AppTheme.primary, height: 24),
                    _buildDetailRow('Müşteri', order.customerName ?? 'Misafir'),
                    const Divider(color: AppTheme.primary, height: 24),
                    _buildDetailRow('Ödeme Yöntemi', order.paymentMethod ?? 'Diğer'),
                    const Divider(color: AppTheme.primary, height: 24),
                    _buildDetailRow('Toplam Tutar', '₺${order.totalAmount.toStringAsFixed(2)}', isAmount: true),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Ürünler',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 12),
              Container(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: order.items.length,
                  separatorBuilder: (context, index) => const Divider(color: AppTheme.primary, height: 1),
                  itemBuilder: (context, index) {
                    final item = order.items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.productName ?? 'Ürün',
                              style: const TextStyle(color: AppTheme.textPrimary),
                            ),
                          ),
                          Text(
                            '${item.quantity}x',
                            style: const TextStyle(color: AppTheme.textSecondary),
                          ),
                          const SizedBox(width: 16),
                          Text(
                            '₺${item.totalPrice.toStringAsFixed(2)}',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Get.back();
                        Get.snackbar(
                          'Bilgi',
                          'İade işlemi özelliği yakında eklenecek',
                          backgroundColor: Colors.orange,
                          colorText: Colors.white,
                        );
                      },
                      icon: const Icon(Icons.replay_rounded),
                      label: const Text('İade İşlemi'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.error),
                        foregroundColor: AppTheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Get.back();
                        Get.snackbar(
                          'Bilgi',
                          'Yazdırma özelliği yakında eklenecek',
                          backgroundColor: Colors.blue,
                          colorText: Colors.white,
                        );
                      },
                      icon: const Icon(Icons.print_rounded),
                      label: const Text('Yazdır'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isAmount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(
          value,
          style: TextStyle(
            color: isAmount ? AppTheme.primary : AppTheme.textPrimary,
            fontWeight: isAmount ? FontWeight.bold : FontWeight.normal,
            fontSize: isAmount ? 16 : 14,
          ),
        ),
      ],
    );
  }

  String _getPeriodLabel() {
    switch (selectedPeriod) {
      case 'today': return 'Bugün';
      case 'week': return 'Bu Hafta';
      case 'month': return 'Bu Ay';
      default: return '';
    }
  }
}

class TopProduct {
  final String name;
  int quantity;
  double totalSales;

  TopProduct({required this.name, required this.quantity, required this.totalSales});
}
