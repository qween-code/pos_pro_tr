import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../register/presentation/controllers/register_controller.dart';
import '../../../register/presentation/screens/open_register_screen.dart';
import '../../../register/presentation/screens/close_register_screen.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

/// Ana kontrol paneli - Dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  double todaySales = 0.0;
  int todayOrders = 0;
  int lowStockCount = 0;
  int totalCustomers = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => isLoading = true);
    
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);

      // Günlük satış ve sipariş sayısı
      final ordersSnapshot = await _firestore
          .collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();

      double sales = 0.0;
      int completedOrders = 0;
      
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        // Sadece tamamlanmış siparişleri say
        if (data['status'] == 'completed') {
          sales += (data['totalAmount'] as num?)?.toDouble() ?? 0.0;
          completedOrders++;
        }
      }

      // Düşük stok
      final productsSnapshot = await _firestore
          .collection('products')
          .where('stock', isLessThan: 10)
          .get();

      // Müşteri sayısı
      final customersSnapshot = await _firestore.collection('customers').get();

      setState(() {
        todaySales = sales;
        todayOrders = completedOrders;
        lowStockCount = productsSnapshot.docs.length;
        totalCustomers = customersSnapshot.docs.length;
        isLoading = false;
      });

      debugPrint('📊 Dashboard yüklendi: ₺${sales.toStringAsFixed(2)}, $todayOrders sipariş');
    } catch (e) {
      debugPrint('❌ Dashboard yükleme hatası: $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final registerController = Get.put(RegisterController());
    final authController = Get.find<AuthController>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadDashboardData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(authController),
                const SizedBox(height: 24),
                _buildRegisterStatus(registerController),
                const SizedBox(height: 24),
                _buildStats(),
                const SizedBox(height: 24),
                _buildQuickActions(authController),
                const SizedBox(height: 24),
                _buildMenuGrid(authController),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AuthController authController) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hoş Geldiniz',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Text(
                authController.currentUser.value?.name ?? 'Kullanıcı',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now()),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: _loadDashboardData,
                tooltip: 'Yenile',
              ),
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: () {
                  Get.defaultDialog(
                    title: 'Çıkış Yap',
                    middleText: 'Çıkış yapmak istediğinizden emin misiniz?',
                    textConfirm: 'Evet',
                    textCancel: 'Hayır',
                    confirmTextColor: Colors.white,
                    onConfirm: () {
                      Get.back();
                      Get.offAllNamed('/login');
                    },
                  );
                },
                tooltip: 'Çıkış Yap',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterStatus(RegisterController controller) {
    return Obx(() {
      final isOpen = controller.currentRegister.value != null;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: InkWell(
          onTap: () {
            if (isOpen) {
              Get.to(() => CloseRegisterScreen());
            } else {
              Get.to(() => OpenRegisterScreen());
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isOpen ? Colors.green : Colors.red,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isOpen ? Colors.green : Colors.red).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isOpen ? Icons.lock_open : Icons.lock,
                    color: isOpen ? Colors.green : Colors.red,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOpen ? 'KASA AÇIK' : 'KASA KAPALI',
                        style: TextStyle(
                          color: isOpen ? Colors.green : Colors.red,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOpen ? 'İşlemlere devam edebilirsiniz' : 'Kasayı açmak için dokunun',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white54,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStats() {
    if (isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bugünün Özeti',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Satış',
                  '₺${todaySales.toStringAsFixed(2)}',
                  Icons.attach_money,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Sipariş',
                  todayOrders.toString(),
                  Icons.shopping_bag,
                  Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Düşük Stok',
                  lowStockCount.toString(),
                  Icons.warning,
                  Colors.orange,
                  onTap: () => Get.toNamed('/products', arguments: {'filter': 'low_stock'}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Müşteri',
                  totalCustomers.toString(),
                  Icons.people,
                  Colors.purple,
                  onTap: () => Get.toNamed('/customers'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 24),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
        ],
      ),
      ),
    );
  }

  Widget _buildQuickActions(AuthController authController) {
    final isAdmin = authController.isAdmin;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hızlı Erişim',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildQuickActionButton(
                  'Yeni Satış',
                  Icons.point_of_sale,
                  AppTheme.primary,
                  () => Get.toNamed('/orders/create'),
                ),
              ),
              const SizedBox(width: 12),
              if (isAdmin)
                Expanded(
                  child: _buildQuickActionButton(
                    'Raporlar',
                    Icons.analytics,
                    Colors.purple,
                    () => Get.toNamed('/reports'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuGrid(AuthController authController) {
    final isAdmin = authController.isAdmin;

    final menuItems = [
      {
        'icon': Icons.inventory_2,
        'title': 'Ürünler',
        'route': '/products',
        'color': Colors.blue,
        'admin': false
      },
      {
        'icon': Icons.people,
        'title': 'Müşteriler',
        'route': '/customers',
        'color': Colors.purple,
        'admin': false
      },
      {
        'icon': Icons.receipt_long,
        'title': 'Siparişler',
        'route': '/orders',
        'color': Colors.orange,
        'admin': false
      },
      {
        'icon': Icons.payments,
        'title': 'Ödemeler',
        'route': '/payments',
        'color': Colors.green,
        'admin': true
      },
      {
        'icon': Icons.people_outline,
        'title': 'Çalışan Performansı',
        'route': '/reports/cashier',
        'color': Colors.teal,
        'admin': true
      },
      {
        'icon': Icons.settings,
        'title': 'Ayarlar',
        'route': '/settings',
        'color': Colors.blueGrey,
        'admin': true
      },
    ];

    final filteredItems = menuItems.where((item) {
      if (isAdmin) return true;
      return !(item['admin'] as bool);
    }).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Menü',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.3,
            ),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              return _buildMenuItem(
                item['title'] as String,
                item['icon'] as IconData,
                item['color'] as Color,
                () => Get.toNamed(item['route'] as String),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}