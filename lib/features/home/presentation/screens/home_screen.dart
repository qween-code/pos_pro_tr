import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../register/presentation/controllers/register_controller.dart';
import '../../../register/presentation/screens/open_register_screen.dart';
import '../../../register/presentation/screens/close_register_screen.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/dashboard_controller.dart';

/// Ana Kontrol Paneli - Modern Dashboard
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    // DashboardController will load data onReady
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final registerController = Get.put(RegisterController());
    final authController = Get.find<AuthController>();
    final dashboardController = Get.put(DashboardController());

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: dashboardController.loadDashboardData,
          color: AppTheme.primary,
          backgroundColor: AppTheme.surface,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModernHeader(authController),
                  const SizedBox(height: 24),
                  _buildRegisterStatusCard(registerController),
                  const SizedBox(height: 24),
                  _buildQuickActions(authController),
                  const SizedBox(height: 24),
                  _buildRevenueCards(dashboardController),
                  const SizedBox(height: 24),
                  _buildMetricsGrid(dashboardController),
                  const SizedBox(height: 24),
                  _buildActionCards(authController),
                  const SizedBox(height: 80), // Increased bottom padding to prevent overflow
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernHeader(AuthController authController) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hoş Geldiniz 👋',
                      style: TextStyle(
                        color: AppTheme.background.withOpacity(0.8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      authController.currentUser.value?.name ?? 'Kullanıcı',
                      style: const TextStyle(
                        color: AppTheme.background,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildHeaderIconButton(Icons.refresh, _loadDashboardData),
                  const SizedBox(width: 8),
                  _buildHeaderIconButton(Icons.logout, () {
                    _showLogoutDialog();
                  }),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.background.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_today, size: 14, color: AppTheme.background.withOpacity(0.8)),
                const SizedBox(width: 8),
                Text(
                  DateFormat('dd MMMM yyyy, EEEE', 'tr_TR').format(DateTime.now()),
                  style: TextStyle(
                    color: AppTheme.background.withOpacity(0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _loadDashboardData() {
    final dashboardController = Get.find<DashboardController>();
    dashboardController.loadDashboardData();
  }

  Widget _buildHeaderIconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppTheme.background.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppTheme.background, size: 20),
      ),
    );
  }

  Widget _buildRegisterStatusCard(RegisterController controller) {
    return Obx(() {
      final isOpen = controller.currentRegister.value != null;
      final register = controller.currentRegister.value;
      
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: InkWell(
          onTap: () {
            if (isOpen) {
              Get.to(() => CloseRegisterScreen());
            } else {
              Get.to(() => OpenRegisterScreen());
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isOpen 
                    ? [const Color(0xFF10B981), const Color(0xFF34D399)]
                    : [const Color(0xFFEF4444), const Color(0xFFF87171)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: (isOpen ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isOpen ? Icons.lock_open_rounded : Icons.lock_rounded,
                    color: Colors.white,
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
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOpen 
                            ? 'Kasiyer: ${register?.userName ?? "---"}' 
                            : 'Kasayı açmak için dokunun',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white.withOpacity(0.7),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildQuickActions(AuthController authController) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickActionCard(
              'Yeni Satış',
              Icons.point_of_sale_rounded,
              AppTheme.primary,
              () => Get.toNamed('/orders/create'),
            ),
          ),
          const SizedBox(width: 12),
          if (authController.isAdmin)
            Expanded(
              child: _buildQuickActionCard(
                'Raporlar',
                Icons.analytics_rounded,
                const Color(0xFF8B5CF6),
                () => Get.toNamed('/reports'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
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
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueCards(DashboardController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gelir Özeti',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => Row(
            children: [
              Expanded(
                child: _buildRevenueCard(
                  'Bugün',
                  controller.todaysSales.value,
                  Icons.today,
                  const Color(0xFF3B82F6),
                  onTap: () => Get.toNamed('/reports', arguments: 'today'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRevenueCard(
                  'Bu Hafta',
                  controller.weeklySales.value,
                  Icons.calendar_view_week,
                  const Color(0xFF8B5CF6),
                  onTap: () => Get.toNamed('/reports', arguments: 'week'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRevenueCard(
                  'Bu Ay',
                  controller.monthlySales.value,
                  Icons.calendar_month,
                  const Color(0xFFEC4899),
                  onTap: () => Get.toNamed('/reports', arguments: 'month'),
                ),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildRevenueCard(String period, double amount, IconData icon, Color color, {VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              period,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '₺${amount.toStringAsFixed(2)}',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(DashboardController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İstatistikler',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Obx(() => GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.85, // Dikeyde daha fazla yer açıldı (1.0 -> 0.85)
            children: [
              _buildMetricCard(
                'Sipariş',
                controller.todaysOrders.value.toString(),
                Icons.shopping_bag_rounded,
                const Color(0xFF3B82F6),
                onTap: () => Get.toNamed('/orders'),
              ),
              _buildMetricCard(
                'Stok',
                controller.lowStockCount.value.toString(),
                Icons.inventory_2_rounded,
                const Color(0xFFF59E0B),
              ),
              _buildMetricCard(
                'Müşteri',
                controller.totalCustomers.value.toString(),
                Icons.people_alt_rounded,
                const Color(0xFF10B981),
              ),
            ],
          )),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
      ),
    );
  }

  Widget _buildActionCards(AuthController authController) {
    final isAdmin = authController.isAdmin;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hızlı Erişim',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActionTile(
            'Ürünler',
            'Envanter yönetimi',
            Icons.inventory_2_rounded,
            const Color(0xFF3B82F6),
            () => Get.toNamed('/products'),
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            'Müşteriler',
            'Müşteri veritabanı',
            Icons.people_rounded,
            const Color(0xFF8B5CF6),
            () => Get.toNamed('/customers'),
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            'Siparişler',
            'Sipariş geçmişi',
            Icons.receipt_long_rounded,
            const Color(0xFFF59E0B),
            () => Get.toNamed('/orders'),
          ),
          if (isAdmin) ...[
            const SizedBox(height: 12),
            _buildActionTile(
              'Ayarlar',
              'Uygulama ayarları',
              Icons.settings_rounded,
              const Color(0xFF6B7280),
              () => Get.toNamed('/settings'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppTheme.textSecondary.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.error.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: AppTheme.error, size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Çıkış Yap',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Çıkış yapmak istediğinizden emin misiniz?',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                textAlign: TextAlign.center,
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
                      onPressed: () {
                        Get.back();
                        Get.offAllNamed('/login');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Çıkış Yap'),
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
}