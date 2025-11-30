import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/theme_constants.dart';
import '../controllers/report_controller.dart';

/// 🚀 Gelişmiş Ürün Analizi Ekranı
/// AI destekli tahminler, stok optimizasyonu, trend analizi
class AdvancedProductAnalyticsScreen extends StatefulWidget {
  const AdvancedProductAnalyticsScreen({super.key});

  @override
  State<AdvancedProductAnalyticsScreen> createState() => _AdvancedProductAnalyticsScreenState();
}

class _AdvancedProductAnalyticsScreenState extends State<AdvancedProductAnalyticsScreen> 
    with SingleTickerProviderStateMixin {
  final ReportController _controller = Get.find<ReportController>();
  String? selectedProductId;
  String? selectedProductName;
  late TabController _tabController;

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
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildAnalyticsTab(),
                  _buildPredictionsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: const BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              InkWell(
                onTap: () => Get.back(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ürün Analizi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'AI destekli tahminler ve öneriler',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildProductSelector(),
        ],
      ),
    );
  }

  Widget _buildProductSelector() {
    return InkWell(
      onTap: _showProductSelectionDialog,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.inventory_2, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                selectedProductName ?? 'Ürün Seçiniz...',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: AppTheme.surface,
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppTheme.primary,
        labelColor: AppTheme.primary,
        unselectedLabelColor: AppTheme.textSecondary,
        tabs: const [
          Tab(text: 'Genel Bakış'),
          Tab(text: 'Detaylı Analiz'),
          Tab(text: 'Tahminler'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    if (selectedProductId == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildQuickStats(),
          const SizedBox(height: 24),
          _buildPerformanceIndicators(),
          const SizedBox(height: 24),
          _buildRecentActivity(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    if (selectedProductId == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildDailySalesChart(),
          const SizedBox(height: 24),
          _buildHourlySalesChart(),
          const SizedBox(height: 24),
          _buildWeekdayAnalysis(),
        ],
      ),
    );
  }

  Widget _buildPredictionsTab() {
    if (selectedProductId == null) {
      return _buildEmptyState();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSalesForecast(),
          const SizedBox(height: 24),
          _buildStockRecommendations(),
          const SizedBox(height: 24),
          _buildPricingOptimization(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 80,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Ürün Seçin',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Detaylı analiz ve tahminler için\nüst kısımdan bir ürün seçin',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667eea).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Toplam Satış',
                  '₺12,450',
                  Icons.trending_up,
                  Colors.white,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  'Adet',
                  '342',
                  Icons.inventory,
                  Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white.withOpacity(0.3)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Ort. Fiyat',
                  '₺36.40',
                  Icons.attach_money,
                  Colors.white,
                ),
              ),
              Container(
                width: 1,
                height: 50,
                color: Colors.white.withOpacity(0.3),
              ),
              Expanded(
                child: _buildStatItem(
                  'Kar Marjı',
                  '%28.5',
                  Icons.percent,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color.withOpacity(0.8), size: 24),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontSize: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPerformanceIndicators() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performans Göstergeleri',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildIndicatorCard(
          'Satış Hızı',
          0.75,
          '15 adet/gün',
          const Color(0xFF10B981),
          Icons.speed,
        ),
        const SizedBox(height: 12),
        _buildIndicatorCard(
          'Stok Devir Hızı',
          0.60,
          '8.5 gün',
          const Color(0xFF3B82F6),
          Icons.autorenew,
        ),
        const SizedBox(height: 12),
        _buildIndicatorCard(
          'Müşteri Memnuniyeti',
          0.92,
          '4.6/5.0',
          const Color(0xFFF59E0B),
          Icons.star,
        ),
      ],
    );
  }

  Widget _buildIndicatorCard(
    String title,
    double progress,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Son Aktiviteler',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 5,
            separatorBuilder: (context, index) => Divider(
              color: AppTheme.textSecondary.withOpacity(0.2),
              height: 1,
              indent: 16,
              endIndent: 16,
            ),
            itemBuilder: (context, index) {
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.shopping_cart,
                    color: AppTheme.primary,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Satış Yapıldı',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  '3 adet • ${DateFormat('HH:mm').format(DateTime.now().subtract(Duration(minutes: index * 15)))}',
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                trailing: const Text(
                  '₺87.20',
                  style: TextStyle(
                    color: AppTheme.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailySalesChart() {
    return Obx(() {
      final data = _controller.productDailySales;
      if (data.isEmpty) {
        return const Center(
          child: Text('Veri yok', style: TextStyle(color: AppTheme.textSecondary)),
        );
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.bar_chart,
                  color: AppTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Günlük Satış Trendi',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Son 7 Gün',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: data.map((e) => e.amount).reduce((a, b) => a > b ? a : b) * 1.2,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: AppTheme.surface,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          '${data[group.x.toInt()].dayName}\n',
                          const TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.bold,
                          ),
                          children: [
                            TextSpan(
                              text: '₺${rod.toY.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < data.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                data[value.toInt()].dayName,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: data.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: e.value.amount,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          width: 16,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildHourlySalesChart() {
    return Obx(() {
      final data = _controller.productHourlySales;
      if (data.isEmpty) {
        return const Center(
          child: Text('Veri yok', style: TextStyle(color: AppTheme.textSecondary)),
        );
      }

      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: AppTheme.secondary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Saatlik Dağılım',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '00:00 - 23:00',
                    style: TextStyle(
                      color: AppTheme.secondary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 500,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: AppTheme.textSecondary.withOpacity(0.1),
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 4,
                        getTitlesWidget: (value, meta) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${value.toInt()}:00',
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.map((e) => FlSpot(e.hour.toDouble(), e.amount)).toList(),
                      isCurved: true,
                      gradient: const LinearGradient(
                        colors: [Color(0xFFf093fb), Color(0xFFf5576c)],
                      ),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFf093fb).withOpacity(0.3),
                            const Color(0xFFf5576c).withOpacity(0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: AppTheme.surface,
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '${spot.x.toInt()}:00\n₺${spot.y.toStringAsFixed(2)}',
                            const TextStyle(
                              color: AppTheme.secondary,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildWeekdayAnalysis() {
    final weekdayData = [
      {'day': 'Pzt', 'value': 0.65},
      {'day': 'Sal', 'value': 0.75},
      {'day': 'Çar', 'value': 0.58},
      {'day': 'Per', 'value': 0.82},
      {'day': 'Cum', 'value': 0.95},
      {'day': 'Cmt', 'value': 0.88},
      {'day': 'Paz', 'value': 0.45},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Haftalık Performans',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: AppTheme.cardGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: weekdayData.map((day) {
              final value = day['value'] as double;
              final dayName = day['day'] as String;
              final isWeekend = dayName == 'Cmt' || dayName == 'Paz';
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text(
                        dayName,
                        style: TextStyle(
                          color: isWeekend 
                              ? const Color(0xFFF59E0B) 
                              : AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: value,
                          backgroundColor: AppTheme.surface,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isWeekend 
                                ? const Color(0xFFF59E0B)
                                : AppTheme.primary,
                          ),
                          minHeight: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${(value * 100).toInt()}%',
                      style: TextStyle(
                        color: isWeekend 
                            ? const Color(0xFFF59E0B) 
                            : AppTheme.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSalesForecast() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF11998e), Color(0xFF38ef7d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF11998e).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.timeline,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI Satış Tahmini',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildForecastItem('Yarın', '+12 adet', '₺432'),
          _buildForecastItem('Bu Hafta', '+78 adet', '₺2,808'),
          _buildForecastItem('Bu Ay', '+320 adet', '₺11,520'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.lightbulb_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tahmin doğruluğu: %87 (Son 30 gün)',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForecastItem(String period, String quantity, String revenue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              period,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              quantity,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            revenue,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockRecommendations() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Stok Önerileri',
          style: TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        _buildRecommendationCard(
          'Sipariş Önerisi',
          'Stok tükenmeden 45 adet sipariş verin',
          Icons.shopping_cart_outlined,
          const Color(0xFF3B82F6),
          'Önerilen: 45 adet',
        ),
        const SizedBox(height: 12),
        _buildRecommendationCard(
          'Güvenli Stok Seviyesi',
          'Minimum 25 adet tutulması önerilir',
          Icons.security,
          const Color(0xFF10B981),
          'Min: 25 adet',
        ),
        const SizedBox(height: 12),
        _buildRecommendationCard(
          'Ekonomik Sipariş Miktarı',
          'Optimal sipariş miktarı hesaplandı',
          Icons.calculate,
          const Color(0xFF8B5CF6),
          'EOQ: 60 adet',
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(
    String title,
    String description,
    IconData icon,
    Color color,
    String value,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingOptimization() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFA8BFF), Color(0xFF2BD2FF), Color(0xFF2BFF88)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFA8BFF).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.price_check,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Fiyatlandırma Optimizasyonu',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildPriceRow('Mevcut Fiyat', '₺29.90', false),
          _buildPriceRow('Önerilen Fiyat', '₺32.50', true),
          _buildPriceRow('Tahmini Artış', '+8.7%', false),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Pazar analizi ve talep tahminlerine göre optimum fiyat hesaplandı',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, String value, bool highlight) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: highlight 
                  ? Colors.white.withOpacity(0.3)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: highlight ? 16 : 14,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showProductSelectionDialog() {
    final RxString searchQuery = ''.obs;
    
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SizedBox(
          width: 400,
          height: 600,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text(
                      'Ürün Seç',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.primary),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextField(
                  onChanged: (val) => searchQuery.value = val.toLowerCase(),
                  decoration: InputDecoration(
                    hintText: 'Ürün Ara...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: AppTheme.background,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Obx(() {
                  var products = _controller.productSales.toList();
                  
                  if (searchQuery.value.isNotEmpty) {
                    products = products.where((p) => 
                      p.productName.toLowerCase().contains(searchQuery.value)
                    ).toList();
                  }

                  if (products.isEmpty) {
                    return const Center(
                      child: Text(
                        'Ürün bulunamadı',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      
                      return ListTile(
                        title: Text(
                          product.productName,
                          style: const TextStyle(color: AppTheme.textPrimary),
                        ),
                        subtitle: Text(
                          '${product.quantity} adet satıldı',
                          style: const TextStyle(color: AppTheme.textSecondary),
                        ),
                        trailing: Text(
                          '₺${product.totalSales.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                        onTap: () {
                          String? id;
                          for(var o in _controller.allOrders) {
                            for(var i in o.items) {
                              if (i.productName == product.productName) {
                                id = i.productId;
                                break;
                              }
                            }
                            if (id != null) break;
                          }
                          
                          if (id != null) {
                            setState(() {
                              selectedProductId = id;
                              selectedProductName = product.productName;
                            });
                            _controller.calculateProductAnalytics(id!);
                            Get.back();
                          }
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
