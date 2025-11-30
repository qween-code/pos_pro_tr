import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../register/presentation/controllers/register_controller.dart';
import '../../../orders/data/models/order_model.dart' as models;
import '../../../orders/data/repositories/hybrid_order_repository.dart';
import '../../../../core/database/database_instance.dart';
import '../../../../core/mediator/app_mediator.dart';
import '../../../../core/events/app_events.dart';

class SalesAnalyticsScreen extends StatefulWidget {
  const SalesAnalyticsScreen({super.key});

  @override
  State<SalesAnalyticsScreen> createState() => _SalesAnalyticsScreenState();
}

class _SalesAnalyticsScreenState extends State<SalesAnalyticsScreen> {
  late final HybridOrderRepository _repository;
  final AppMediator _mediator = AppMediator();
  StreamSubscription? _refreshSubscription;

  bool isLoading = false;
  String selectedPeriod = 'today';

  // Data
  double totalSales = 0.0;
  int totalOrders = 0;
  Map<String, double> paymentMethods = {};
  List<models.Order> _currentFilteredOrders = [];
  List<models.Order> _allFetchedOrders = []; // Store raw data

  // Filters
  String? selectedBranch;
  String? selectedCashier;
  List<String> availableBranches = [];
  List<String> availableCashiers = [];

  @override
  void initState() {
    super.initState();
    final dbInstance = Get.find<DatabaseInstance>();
    _repository = HybridOrderRepository(
      localDb: dbInstance.database,
      firestore: FirebaseFirestore.instance,
    );

    if (Get.arguments != null && Get.arguments is String) {
      selectedPeriod = Get.arguments;
    }
    
    _loadData();

    _refreshSubscription = _mediator.on<DashboardRefreshEvent>().listen((event) {
      if (event.source == 'order_sync') {
        _loadData();
      }
    });
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
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

      final orders = await _repository.getOrdersByDateRange(
        startDate, 
        now.add(const Duration(days: 1))
      );

      _allFetchedOrders = orders;
      
      // Extract available filters from all orders (not just valid ones, or maybe just valid ones?)
      // Let's extract from all fetched orders to be inclusive
      final branches = orders.map((o) => o.branchId ?? '').where((s) => s.isNotEmpty).toSet().toList();
      final cashiers = orders.map((o) => o.cashierName ?? '').where((s) => s.isNotEmpty).toSet().toList();
      
      if (mounted) {
        setState(() {
          availableBranches = branches;
          availableCashiers = cashiers;
        });
      }

      _processData();
      
    } catch (e) {
      debugPrint('❌ Veri yükleme hatası: $e');
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _processData() {
    var validOrders = _allFetchedOrders.where((o) => 
      o.status == 'completed' || o.status == 'partial_refunded'
    ).toList();

    // Apply filters
    if (selectedBranch != null) {
      validOrders = validOrders.where((o) => o.branchId == selectedBranch).toList();
    }
    if (selectedCashier != null) {
      validOrders = validOrders.where((o) => o.cashierName == selectedCashier).toList();
    }

    double total = 0.0;
    Map<String, double> payments = {};

    for (var order in validOrders) {
      total += order.totalAmount;
      
      if (order.payments.isNotEmpty) {
        for (var payment in order.payments) {
          payments[payment.method] = (payments[payment.method] ?? 0) + payment.amount;
        }
      } else {
        final method = order.paymentMethod ?? 'Nakit';
        payments[method] = (payments[method] ?? 0) + order.totalAmount;
      }
    }

    if (mounted) {
      setState(() {
        _currentFilteredOrders = validOrders;
        totalSales = total;
        totalOrders = validOrders.length;
        paymentMethods = payments;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildModernAppBar(),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      color: AppTheme.primary,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          children: [
                            const SizedBox(height: 16),
                            _buildPeriodSelector(),
                            const SizedBox(height: 16),
                            _buildFilters(),
                            const SizedBox(height: 24),
                            _buildZReportButton(),
                            const SizedBox(height: 24),
                            _buildSalesOverview(),
                            const SizedBox(height: 24),
                            _buildPaymentBreakdown(),
                            const SizedBox(height: 24),
                            _buildRecentOrders(),
                            const SizedBox(height: 80),
                          ],
                        ),
                      ),
                    ),
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
      child: Row(
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
                  'Satış Analizi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Z Raporu & Detaylı Analiz',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: _loadData,
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
    );
  }

  Widget _buildPeriodSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(child: _buildPeriodChip('Bugün', 'today')),
          const SizedBox(width: 8),
          Expanded(child: _buildPeriodChip('Bu Hafta', 'week')),
          const SizedBox(width: 8),
          Expanded(child: _buildPeriodChip('Bu Ay', 'month')),
        ],
      ),
    );
  }

  Widget _buildPeriodChip(String label, String period) {
    final isSelected = selectedPeriod == period;
    return InkWell(
      onTap: () {
        setState(() => selectedPeriod = period);
        _loadData();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.primary.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : AppTheme.textPrimary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildZReportButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: _showZReportDialog,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF59E0B).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.receipt_long, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Z Raporu Oluştur',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Kasayı kapat ve rapor al',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSalesOverview() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
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
                const Text(
                  'Toplam Satış',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '₺${totalSales.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$totalOrders Sipariş',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: paymentMethods.isEmpty
                ? const Center(
                    child: Text(
                      'Henüz ödeme yok',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : Column(
                    children: paymentMethods.entries.map((entry) {
                      final percentage = (totalSales > 0)
                          ? (entry.value / totalSales * 100)
                          : 0.0;
                      
                      Color color;
                      IconData icon;
                      
                      if (entry.key.toLowerCase().contains('nakit') || 
                          entry.key.toLowerCase().contains('cash')) {
                        color = const Color(0xFF10B981);
                        icon = Icons.money;
                      } else if (entry.key.toLowerCase().contains('kart') || 
                                 entry.key.toLowerCase().contains('card')) {
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
          ),
        ],
      ),
    );
  }

  Widget _buildRecentOrders() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Son Siparişler',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: AppTheme.cardGradient,
              borderRadius: BorderRadius.circular(16),
            ),
            child: _currentFilteredOrders.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'Henüz sipariş yok',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _currentFilteredOrders.take(10).length,
                    separatorBuilder: (context, index) => const Divider(
                      color: AppTheme.textSecondary,
                      height: 1,
                      indent: 16,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final order = _currentFilteredOrders[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.shopping_bag,
                                color: AppTheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    DateFormat('HH:mm • dd MMM', 'tr_TR').format(order.orderDate),
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    order.cashierName ?? 'Bilinmeyen',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '₺${order.totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showZReportDialog() {
    final registerController = Get.isRegistered<RegisterController>() 
        ? Get.find<RegisterController>() 
        : Get.put(RegisterController());
    
    final register = registerController.currentRegister.value;

    if (register == null) {
      Get.snackbar(
        'Uyarı',
        'Kasa açık değil. Önce kasayı açmalısınız.',
        backgroundColor: Colors.orange,
        colorText: Colors.white,
      );
      return;
    }

    final countedCashController = TextEditingController();
    final notesController = TextEditingController();

    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.receipt_long, color: Color(0xFFF59E0B), size: 32),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Z Raporu',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                _buildInfoRow('Açılış Bakiyesi', '₺${register.openingBalance.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _buildInfoRow('Nakit Satış', '₺${register.totalCashSales.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _buildInfoRow('Kart Satış', '₺${register.totalCardSales.toStringAsFixed(2)}'),
                const SizedBox(height: 12),
                _buildInfoRow(
                  'Beklenen Nakit', 
                  '₺${(register.openingBalance + register.totalCashSales).toStringAsFixed(2)}',
                  highlight: true,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: countedCashController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Sayılan Nakit',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Notlar (Opsiyonel)',
                    labelStyle: const TextStyle(color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppTheme.primary),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primary.withOpacity(0.5)),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppTheme.primary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('İptal', style: TextStyle(color: AppTheme.primary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final countedCash = double.tryParse(countedCashController.text);
                          if (countedCash == null) {
                            Get.snackbar('Hata', 'Geçerli bir tutar girin');
                            return;
                          }

                          Get.back();
                          await registerController.closeRegister(
                            countedCash,
                            notesController.text,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Kapat'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: highlight ? AppTheme.primary : AppTheme.textSecondary,
            fontSize: highlight ? 15 : 14,
            fontWeight: highlight ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: highlight ? AppTheme.primary : AppTheme.textPrimary,
            fontSize: highlight ? 16 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }


  Widget _buildFilters() {
    if (availableBranches.isEmpty && availableCashiers.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (availableBranches.isNotEmpty) ...[
            _buildFilterChip(
              label: selectedBranch ?? 'Tüm Şubeler',
              isSelected: selectedBranch != null,
              icon: Icons.store,
              onTap: () => _showSelectionDialog('Şube Seç', availableBranches, (val) {
                setState(() {
                  selectedBranch = val;
                  _processData();
                });
              }),
              onClear: () => setState(() { selectedBranch = null; _processData(); }),
            ),
            const SizedBox(width: 12),
          ],
          if (availableCashiers.isNotEmpty) ...[
            _buildFilterChip(
              label: selectedCashier ?? 'Tüm Kasiyerler',
              isSelected: selectedCashier != null,
              icon: Icons.person,
              onTap: () => _showSelectionDialog('Kasiyer Seç', availableCashiers, (val) {
                setState(() {
                  selectedCashier = val;
                  _processData();
                });
              }),
              onClear: () => setState(() { selectedCashier = null; _processData(); }),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required IconData icon,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primary : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: onClear,
                child: const Icon(Icons.close, size: 16, color: AppTheme.primary),
              ),
            ],
            if (!isSelected) ...[
              const SizedBox(width: 4),
              const Icon(Icons.arrow_drop_down, size: 16, color: AppTheme.textSecondary),
            ],
          ],
        ),
      ),
    );
  }

  void _showSelectionDialog(String title, List<String> items, Function(String) onSelect) {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 300,
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 300),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return ListTile(
                      title: Text(item, style: const TextStyle(color: AppTheme.textPrimary)),
                      onTap: () {
                        onSelect(item);
                        Get.back();
                      },
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
}
