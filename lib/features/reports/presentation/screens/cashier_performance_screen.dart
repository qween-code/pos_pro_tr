import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../orders/data/repositories/hybrid_order_repository.dart';
import '../../../../core/database/database_instance.dart';
import '../../../../core/mediator/app_mediator.dart';
import '../../../../core/events/app_events.dart';

/// Çalışan Performans Raporu Ekranı
class CashierPerformanceScreen extends StatefulWidget {
  const CashierPerformanceScreen({super.key});

  @override
  State<CashierPerformanceScreen> createState() => _CashierPerformanceScreenState();
}

class _CashierPerformanceScreenState extends State<CashierPerformanceScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late final HybridOrderRepository _repository;
  final AppMediator _mediator = AppMediator();
  StreamSubscription? _refreshSubscription;
  
  String selectedPeriod = 'today';
  String? selectedBranch;
  bool isLoading = false;
  
  List<String> branches = [];
  List<CashierPerformance> performances = [];
  double totalSales = 0.0;
  int totalOrders = 0;

  @override
  void initState() {
    super.initState();
    final dbInstance = Get.find<DatabaseInstance>();
    _repository = HybridOrderRepository(
      localDb: dbInstance.database,
      firestore: FirebaseFirestore.instance,
    );
    
    _refreshSubscription = _mediator.on<DashboardRefreshEvent>().listen((event) {
      if (event.source == 'order_sync') {
        _loadData();
      }
    });

    _checkAccess();
  }

  @override
  void dispose() {
    _refreshSubscription?.cancel();
    _repository.dispose();
    super.dispose();
  }

  Future<void> _checkAccess() async {
    final authController = Get.find<AuthController>();
    if (!authController.isAdmin) {
      Get.back();
      Get.snackbar(
        'Erişim Reddedildi',
        'Bu sayfayı görüntüleme yetkiniz yok',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }
    await _loadBranches();
    await _loadData();
  }

  Future<void> _loadBranches() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'cashier')
          .get();

      final branchSet = <String>{};
      for (var doc in snapshot.docs) {
        final region = doc.data()['region'] as String? ?? 'Ana Şube';
        branchSet.add(region);
      }

      setState(() {
        branches = branchSet.toList()..sort();
      });
      
      debugPrint('📊 Şubeler yüklendi: $branches');
    } catch (e) {
      debugPrint('❌ Şube yükleme hatası: $e');
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // 1. Tarih aralığını belirle
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

      debugPrint('📅 Tarih aralığı: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(now)}');

      // 2. Kasiyerleri çek (Firestore'dan devam, çünkü kullanıcılar local DB'de olmayabilir)
      // Şube filtresini Firestore query'sinde değil, local'de yapalım çünkü mevcut users'larda region field'ı olmayabilir
      var cashierQuery = _firestore
          .collection('users')
          .where('role', isEqualTo: 'cashier');

      final cashiersSnapshot = await cashierQuery.get();
      debugPrint('👥 Toplam kasiyer (raw): ${cashiersSnapshot.docs.length}');

      // 3. Performans haritası oluştur ve şube filtresini burada uygula
      final Map<String, CashierPerformance> perfMap = {};
      
      for (var doc in cashiersSnapshot.docs) {
        final data = doc.data();
        final region = data['region'] as String? ?? 'Ana Şube'; // Varsayılan şube
        
        // Şube filtresi varsa uygula
        if (selectedBranch != null && region != selectedBranch) {
          continue;
        }
        
        perfMap[doc.id] = CashierPerformance(
          id: doc.id,
          name: data['name'] ?? 'Bilinmeyen',
          branch: region,
          totalSales: 0.0,
          orderCount: 0,
        );
      }
      
      debugPrint('👥 Filtrelenmiş kasiyer sayısı: ${perfMap.length}');

      // 4. Siparişleri çek (Hybrid Repository'den)
      final orders = await _repository.getOrdersByDateRange(startDate, now.add(const Duration(days: 1)));

      debugPrint('📦 Toplam sipariş: ${orders.length}');

      // 5. Kasiyerleri ID ve Name'e göre map'le (çünkü bazı siparişlerde ID olmayabilir)
      final Map<String, CashierPerformance> perfByName = {};
      for (var perf in perfMap.values) {
        perfByName[perf.name] = perf;
      }

      // 6. Siparişleri kasiyerlere eşle
      int matchedOrders = 0;
      int unmatchedOrders = 0;
      
      for (var order in orders) {
        // Sadece tamamlanmış veya kısmi iadeli siparişleri işle
        if (order.status != 'completed' && order.status != 'partial_refunded') continue;
        
        final cashierId = order.cashierId;
        final cashierName = order.cashierName;
        final amount = order.totalAmount;

        // Önce ID ile eşleştir
        if (cashierId != null && perfMap.containsKey(cashierId)) {
          perfMap[cashierId]!.totalSales += amount;
          perfMap[cashierId]!.orderCount++;
          matchedOrders++;
        }
        // ID yoksa isimle eşleştir
        else if (cashierName != null && perfByName.containsKey(cashierName)) {
          perfByName[cashierName]!.totalSales += amount;
          perfByName[cashierName]!.orderCount++;
          matchedOrders++;
        } else {
          unmatchedOrders++;
          debugPrint('⚠️ Eşleşmeyen sipariş: ${order.id} (cashierId: $cashierId, cashierName: $cashierName)');
        }
      }

      debugPrint('✅ Eşleşen sipariş: $matchedOrders');
      debugPrint('⚠️ Eşleşmeyen sipariş: $unmatchedOrders');

      // 7. Sırala ve hesapla
      final sortedPerformances = perfMap.values.toList()
        ..sort((a, b) => b.totalSales.compareTo(a.totalSales));

      final total = sortedPerformances.fold(0.0, (sum, p) => sum + p.totalSales);
      final totalOrderCount = sortedPerformances.fold(0, (sum, p) => sum + p.orderCount);

      if (mounted) {
        setState(() {
          performances = sortedPerformances;
          totalSales = total;
          totalOrders = totalOrderCount;
        });
      }
    } catch (e) {
      debugPrint('❌ Veri yükleme hatası: $e');
      if (mounted) {
        Get.snackbar(
          'Hata',
          'Veriler yüklenirken bir hata oluştu: $e',
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Çalışan Performansı', style: TextStyle(color: Colors.white)),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilters(),
          _buildSummary(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      color: AppTheme.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Periyot Seçimi
          Row(
            children: [
              _buildPeriodChip('Bugün', 'today'),
              const SizedBox(width: 8),
              _buildPeriodChip('Bu Hafta', 'week'),
              const SizedBox(width: 8),
              _buildPeriodChip('Bu Ay', 'month'),
            ],
          ),
          const SizedBox(height: 12),
          // Şube Filtresi
          DropdownButtonFormField<String>(
            value: selectedBranch,
            decoration: InputDecoration(
              labelText: 'Şube',
              labelStyle: const TextStyle(color: Colors.white70),
              filled: true,
              fillColor: AppTheme.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            dropdownColor: AppTheme.surface,
            style: const TextStyle(color: Colors.white),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Tüm Şubeler'),
              ),
              ...branches.map((branch) => DropdownMenuItem(
                value: branch,
                child: Text(branch),
              )),
            ],
            onChanged: (value) {
              setState(() => selectedBranch = value);
              _loadData();
            },
          ),
        ],
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
        backgroundColor: AppTheme.background,
        labelStyle: TextStyle(
          color: isSelected ? Colors.black : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: _buildSummaryCard(
              'Toplam Satış',
              '₺${totalSales.toStringAsFixed(2)}',
              Icons.attach_money,
              Colors.green,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Toplam Sipariş',
              totalOrders.toString(),
              Icons.shopping_bag,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildSummaryCard(
              'Çalışan Sayısı',
              performances.length.toString(),
              Icons.people,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (performances.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.white.withOpacity(0.3)),
            const SizedBox(height: 16),
            const Text(
              'Bu dönemde satış yapan çalışan yok',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: performances.length,
      itemBuilder: (context, index) {
        final perf = performances[index];
        final rank = index + 1;
        final isTop3 = rank <= 3;

        return Card(
          color: isTop3 ? AppTheme.primary.withOpacity(0.1) : AppTheme.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isTop3 ? AppTheme.primary : Colors.white10,
              width: isTop3 ? 2 : 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Sıralama
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: isTop3 ? AppTheme.primary : Colors.white12,
                      child: Text(
                        '#$rank',
                        style: TextStyle(
                          color: isTop3 ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    if (rank == 1)
                      const Positioned(
                        right: 0,
                        bottom: 0,
                        child: Icon(Icons.emoji_events, color: Colors.amber, size: 20),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Bilgiler
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              perf.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.withOpacity(0.5)),
                            ),
                            child: Text(
                              perf.branch,
                              style: const TextStyle(color: Colors.blue, fontSize: 10),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Satış: ₺${perf.totalSales.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            'Sipariş: ${perf.orderCount}',
                            style: const TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ort. Sepet: ₺${perf.averageOrderValue.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class CashierPerformance {
  final String id;
  final String name;
  final String branch;
  double totalSales;
  int orderCount;

  CashierPerformance({
    required this.id,
    required this.name,
    required this.branch,
    required this.totalSales,
    required this.orderCount,
  });

  double get averageOrderValue => orderCount > 0 ? totalSales / orderCount : 0.0;
}
