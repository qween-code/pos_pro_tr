import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/theme_constants.dart';
import '../controllers/report_controller.dart';
import 'product_analytics_screen.dart';

class ReportScreen extends StatelessWidget {
  final ReportController _controller = Get.put(ReportController());

  ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: Obx(() {
                if (_controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _controller.fetchReportData,
                  color: AppTheme.primary,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        _buildQuickAccess(),
                        const SizedBox(height: 24),
                        _buildPeriodSelector(),
                        const SizedBox(height: 24),
                        _buildSalesOverview(),
                        const SizedBox(height: 24),
                        _buildMetricsGrid(),
                        const SizedBox(height: 24),
                        _buildTopProducts(),
                        const SizedBox(height: 24),
                        _buildPaymentBreakdown(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernAppBar() {
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                      'Raporlar & Analiz',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Satış performansınızı izleyin',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => _controller.fetchReportData(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.refresh, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildAccessCard(
              'Çalışan Performansı',
              Icons.people_rounded,
              const Color(0xFF8B5CF6),
              () => Get.toNamed('/reports/cashier'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildAccessCard(
              'Z Raporu',
              Icons.receipt_long_rounded,
              const Color(0xFFF59E0B),
              () => Get.toNamed('/reports/sales'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildAccessCard(
              'Ürün Analizi',
              Icons.inventory_2_rounded,
              const Color(0xFF10B981),
              () => Get.to(() => const AdvancedProductAnalyticsScreen()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccessCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dönem Seçimi',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPeriodChip(
                  'Bugün',
                  () {
                    final now = DateTime.now();
                    _controller.setDateRange(
                      DateTime(now.year, now.month, now.day),
                      now,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPeriodChip(
                  'Bu Hafta',
                  () {
                    final now = DateTime.now();
                    _controller.setDateRange(
                      now.subtract(const Duration(days: 7)),
                      now,
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPeriodChip(
                  'Bu Ay',
                  () {
                    final now = DateTime.now();
                    _controller.setDateRange(
                      DateTime(now.year, now.month, 1),
                      now,
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSalesOverview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Satış Özeti',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Toplam Ciro',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Obx(() => FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '₺${_controller.totalSales.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Obx(() => Text(
                      '${_controller.totalOrders.value} Sipariş',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    )),
                    const SizedBox(width: 16),
                    Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Obx(() => Text(
                      'Ort. ₺${_controller.averageOrderValue.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    )),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Performans Metrikleri',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildMetricCard(
                  'Günlük Ortalama',
                  '₺${(_controller.totalSales.value / 30).toStringAsFixed(0)}',
                  Icons.calendar_today,
                  const Color(0xFF3B82F6),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildMetricCard(
                  'En Yüksek Satış',
                  '₺${_controller.highestSale.value.toStringAsFixed(0)}',
                  Icons.trending_up,
                  const Color(0xFF10B981),
                )),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProducts() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'En Çok Satan Ürünler',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final products = _controller.topProducts.take(5).toList();
            if (products.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Henüz ürün satışı yok',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (context, index) => const Divider(
                  color: AppTheme.textSecondary,
                  height: 1,
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '#${index + 1}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.productName,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product.quantity} adet',
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '₺${product.totalSales.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildPaymentBreakdown() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ödeme Yöntemleri',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() {
            final payments = _controller.paymentDistribution;
            if (payments.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppTheme.cardGradient,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    'Henüz ödeme yok',
                    style: TextStyle(color: AppTheme.textSecondary),
                  ),
                ),
              );
            }

            return Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppTheme.cardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: payments.entries.map((entry) {
                  final percentage = (_controller.totalSales.value > 0)
                      ? (entry.value / _controller.totalSales.value * 100)
                      : 0.0;
                  
                  Color color;
                  IconData icon;
                  
                  if (entry.key.toLowerCase().contains('nakit') || entry.key.toLowerCase().contains('cash')) {
                    color = const Color(0xFF10B981);
                    icon = Icons.money;
                  } else if (entry.key.toLowerCase().contains('kart') || entry.key.toLowerCase().contains('card')) {
                    color = const Color(0xFF3B82F6);
                    icon = Icons.credit_card;
                  } else {
                    color = const Color(0xFF8B5CF6);
                    icon = Icons.payment;
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(icon, color: color, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '₺${entry.value.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percentage / 100,
                            backgroundColor: color.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${percentage.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          }),
        ],
      ),
    );
  }
}