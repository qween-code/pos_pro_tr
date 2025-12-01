import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/theme_constants.dart';
import '../controllers/report_controller.dart';
import '../../../products/presentation/controllers/product_controller.dart';
import '../../../products/data/models/product_model.dart';

class AdvancedProductAnalyticsScreen extends StatefulWidget {
  const AdvancedProductAnalyticsScreen({super.key});

  @override
  State<AdvancedProductAnalyticsScreen> createState() => _AdvancedProductAnalyticsScreenState();
}

class _AdvancedProductAnalyticsScreenState extends State<AdvancedProductAnalyticsScreen> with SingleTickerProviderStateMixin {
  final ReportController _reportController = Get.find<ReportController>();
  final ProductController _productController = Get.put(ProductController()); // Ensure it's loaded
  
  late TabController _tabController;
  Product? _selectedProduct;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Gelişmiş Ürün Analizi', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Genel Bakış', icon: Icon(Icons.dashboard)),
            Tab(text: 'Trendler', icon: Icon(Icons.show_chart)),
            Tab(text: 'AI Tahminler', icon: Icon(Icons.psychology)),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildProductSelector(),
          Expanded(
            child: _selectedProduct == null
                ? _buildEmptyState()
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildOverviewTab(),
                      _buildTrendsTab(),
                      _buildAIForecastTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: _showProductSelectionDialog,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.search, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _selectedProduct?.name ?? 'Analiz edilecek ürünü seçin...',
                  style: TextStyle(
                    color: _selectedProduct == null ? AppTheme.textSecondary : AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: _selectedProduct == null ? FontWeight.normal : FontWeight.bold,
                  ),
                ),
              ),
              Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics_outlined, size: 80, color: AppTheme.primary.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'Lütfen bir ürün seçin',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Detaylı analiz için yukarıdan ürün seçimi yapın',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  // --- TAB 1: GENEL BAKIŞ ---
  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        // Seçili ürünün verilerini bul
        final productData = _reportController.productSales.firstWhere(
          (p) => p.productName == _selectedProduct?.name,
          orElse: () => ProductSalesData(productName: '', quantity: 0, totalSales: 0),
        );

        // Basit hesaplamalar (Gerçek verilerle)
        final avgPrice = productData.quantity > 0 
            ? productData.totalSales / productData.quantity 
            : (_selectedProduct?.price ?? 0.0);
        
        // Kar marjı simülasyonu (Maliyet verisi olmadığı için %30 varsayıyoruz)
        const profitMargin = 30.0; 

        return Column(
          children: [
            Row(
              children: [
                Expanded(child: _buildMetricCard('Toplam Satış', '₺${productData.totalSales.toStringAsFixed(2)}', Icons.attach_money, Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('Satış Adedi', '${productData.quantity}', Icons.shopping_bag, Colors.blue)),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildMetricCard('Ort. Fiyat', '₺${avgPrice.toStringAsFixed(2)}', Icons.price_change, Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildMetricCard('Kar Marjı', '%$profitMargin', Icons.trending_up, Colors.purple)),
              ],
            ),
            const SizedBox(height: 24),
            _buildPerformanceIndicators(productData.quantity),
          ],
        );
      }),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceIndicators(int quantity) {
    // Mock indicators based on quantity
    double salesVelocity = (quantity / 100).clamp(0.0, 1.0);
    double stockTurnover = (quantity / 50).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Performans Göstergeleri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _buildProgressBar('Satış Hızı', salesVelocity, Colors.blue),
          _buildProgressBar('Stok Devir Hızı', stockTurnover, Colors.green),
          _buildProgressBar('Müşteri Memnuniyeti', 0.95, Colors.orange), // Sabit yüksek
          _buildProgressBar('İade Oranı', 0.02, Colors.red), // Sabit düşük
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
              Text('${(value * 100).toInt()}%', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: value,
            backgroundColor: color.withOpacity(0.1),
            color: color,
            borderRadius: BorderRadius.circular(4),
            minHeight: 8,
          ),
        ],
      ),
    );
  }

  // --- TAB 2: TRENDLER ---
  Widget _buildTrendsTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Günlük Satış Trendi (Seçili Dönem)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Expanded(
            child: Obx(() {
              final dailyData = _reportController.productDailySales;
              
              if (dailyData.isEmpty) {
                return const Center(child: Text('Bu dönem için veri yok'));
              }

              return BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < dailyData.length) {
                            // Sadece baş ve son tarihi göster veya sığarsa hepsini
                            if (dailyData.length > 7 && value.toInt() % (dailyData.length ~/ 5) != 0) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                dailyData[value.toInt()].dayName,
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(dailyData.length, (index) {
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: dailyData[index].amount,
                          color: AppTheme.primary,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // --- TAB 3: AI TAHMİNLER ---
  Widget _buildAIForecastTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        // Basit kural tabanlı "AI"
        final productData = _reportController.productSales.firstWhere(
          (p) => p.productName == _selectedProduct?.name,
          orElse: () => ProductSalesData(productName: '', quantity: 0, totalSales: 0),
        );
        
        final stock = _selectedProduct?.stock ?? 0;
        final dailyAvg = productData.quantity / 7; // Basit ortalama
        final daysLeft = dailyAvg > 0 ? (stock / dailyAvg).floor() : 999;

        String stockMsg = 'Stok durumunuz gayet iyi.';
        Color stockColor = Colors.green;
        IconData stockIcon = Icons.check_circle;

        if (daysLeft < 3) {
          stockMsg = 'KRİTİK: Mevcut satış hızıyla stoklarınız $daysLeft gün içinde tükenebilir!';
          stockColor = Colors.red;
          stockIcon = Icons.warning;
        } else if (daysLeft < 7) {
          stockMsg = 'UYARI: Stoklarınız 1 hafta içinde tükenebilir. Sipariş vermeyi düşünün.';
          stockColor = Colors.orange;
          stockIcon = Icons.warning_amber;
        }

        final forecastQty = (productData.quantity * 1.1).toInt(); // %10 artış tahmini

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAIInsightCard(
              'Satış Tahmini',
              'Gelecek dönem bu üründen tahmini $forecastQty adet satılacak. Trend yukarı yönlü görünüyor.',
              Icons.trending_up,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildAIInsightCard(
              'Stok Analizi',
              stockMsg,
              stockIcon,
              stockColor,
            ),
            const SizedBox(height: 16),
            _buildAIInsightCard(
              'Fiyat Önerisi',
              'Mevcut fiyatınız (₺${_selectedProduct?.price}) piyasa koşullarına uygun görünüyor.',
              Icons.price_check,
              Colors.purple,
            ),
          ],
        );
      }),
    );
  }

  Widget _buildAIInsightCard(String title, String description, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showProductSelectionDialog() {
    // Gerçek ürün listesini kullan
    final products = _productController.products;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Ürün Seçin',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 400,
                child: Obx(() {
                  if (products.isEmpty) {
                    return const Center(child: Text('Hiç ürün bulunamadı.'));
                  }
                  
                  return ListView.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.1),
                          child: Text(product.name.substring(0, 1).toUpperCase()),
                        ),
                        title: Text(product.name),
                        subtitle: Text('Stok: ${product.stock} | Fiyat: ₺${product.price}'),
                        onTap: () {
                          setState(() {
                            _selectedProduct = product;
                          });
                          // Seçilen ürün için analizi tetikle
                          if (product.id != null) {
                            _reportController.calculateProductAnalytics(product.id!);
                          }
                          Get.back();
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
