import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/report_controller.dart';
import 'package:fl_chart/fl_chart.dart';

class ReportScreen extends StatelessWidget {
  final ReportController _reportController = Get.put(ReportController());

  ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Raporlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDate(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _reportController.fetchDailyReport();
              _reportController.fetchTopSellingProducts();
              _reportController.fetchCustomerStatistics();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Tarih seçimi
              Obx(() => Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('dd MMMM yyyy').format(_reportController.selectedDate.value),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Günlük Rapor',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
              )),

              const SizedBox(height: 16),

              // Özet kartlar
              _buildSummaryCards(),

              const SizedBox(height: 16),

              // Ödeme yöntemleri dağılımı
              _buildPaymentMethodsChart(),

              const SizedBox(height: 16),

              // En çok satan ürünler
              _buildTopSellingProducts(),

              const SizedBox(height: 16),

              // Müşteri istatistikleri
              _buildCustomerStatistics(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Obx(() => Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            title: 'Toplam Satış',
            value: '${_reportController.dailyTotalSales.value.toStringAsFixed(2)} ₺',
            icon: Icons.shopping_cart,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildSummaryCard(
            title: 'Toplam Ödeme',
            value: '${_reportController.dailyTotalPayments.value.toStringAsFixed(2)} ₺',
            icon: Icons.payment,
            color: Colors.green,
          ),
        ),
      ],
    ));
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(color: color)),
              ],
            ),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsChart() {
    return Obx(() {
      if (_reportController.paymentMethodsSummary.isEmpty) {
        return const Card(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(child: Text('Ödeme yöntemi verisi bulunamadı')),
          ),
        );
      }

      final entries = _reportController.paymentMethodsSummary.entries;
      final total = _reportController.paymentMethodsSummary.values.fold(0.0, (sum, amount) => sum + amount);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Ödeme Yöntemleri Dağılımı', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PieChart(
                  PieChartData(
                    sections: entries.map((entry) {
                      final percentage = (entry.value / total) * 100;
                      return PieChartSectionData(
                        color: _getPaymentMethodColor(entry.key),
                        value: entry.value,
                        title: '${percentage.toStringAsFixed(1)}%',
                        radius: 50,
                        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                      );
                    }).toList(),
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: entries.map((entry) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: _getPaymentMethodColor(entry.key),
                      child: Text(entry.key.substring(0, 1), style: const TextStyle(color: Colors.white)),
                    ),
                    label: Text('${entry.key}: ${entry.value.toStringAsFixed(2)} ₺'),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      );
    });
  }

  Color _getPaymentMethodColor(String method) {
    switch (method) {
      case 'Nakit': return Colors.blue;
      case 'Kredi Kartı': return Colors.green;
      case 'Banka Kartı': return Colors.orange;
      case 'Havale': return Colors.purple;
      default: return Colors.grey;
    }
  }

  Widget _buildTopSellingProducts() {
    return Obx(() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('En Çok Satan Ürünler', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ..._reportController.topSellingProducts.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(child: Text(entry.key)),
                    Text('${entry.value} adet'),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: _reportController.topSellingProducts.isEmpty
                  ? 0
                  : _reportController.topSellingProducts.first.value / 20,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildCustomerStatistics() {
    return Obx(() => Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Müşteri İstatistikleri', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatisticItem(
                    title: 'Toplam Müşteri',
                    value: _reportController.totalCustomers.value.toString(),
                    icon: Icons.people,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatisticItem(
                    title: 'Bugün Yeni',
                    value: _reportController.newCustomersToday.value.toString(),
                    icon: Icons.person_add,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ));
  }

  Widget _buildStatisticItem({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: Colors.grey),
            const SizedBox(width: 4),
            Text(title, style: const TextStyle(fontSize: 14)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _reportController.selectedDate.value,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != _reportController.selectedDate.value) {
      _reportController.changeDate(picked);
    }
  }
}