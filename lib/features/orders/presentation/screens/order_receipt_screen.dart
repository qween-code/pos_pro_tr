import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../data/models/order_model.dart';

/// 🧾 Modern Sipariş Fişi Ekranı
class OrderReceiptScreen extends StatelessWidget {
  final Order order;

  const OrderReceiptScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildSuccessAnimation(),
                    const SizedBox(height: 24),
                    _buildReceiptCard(),
                    const SizedBox(height: 24),
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
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
              child: const Icon(Icons.close, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sipariş Tamamlandı',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'İşlem başarılı',
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
    );
  }

  Widget _buildSuccessAnimation() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF34D399)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(
        Icons.check_rounded,
        color: Colors.white,
        size: 60,
      ),
    );
  }

  Widget _buildReceiptCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.textSecondary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sipariş Numarası
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sipariş No',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              Text(
                '#${order.id?.substring(0, 8) ?? 'N/A'}',
                style: const TextStyle(
                  color: AppTheme.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: AppTheme.textSecondary.withOpacity(0.2)),
          const SizedBox(height: 16),
          
          // Tarih & Saat
          _buildInfoRow(
            Icons.calendar_today,
            'Tarih',
            DateFormat('dd/MM/yyyy HH:mm').format(order.orderDate),
          ),
          const SizedBox(height: 12),
          
          // Kasiyer
          _buildInfoRow(
            Icons.person,
            'Kasiyer',
            order.cashierName ?? 'Bilinmeyen',
          ),
          const SizedBox(height: 12),
          
          // Şube
          if (order.branchId != null)
            _buildInfoRow(
              Icons.store,
              'Şube',
              order.branchId!,
            ),
          
          const SizedBox(height: 20),
          
          // Ürünler
          const Text(
            'Ürünler',
            style: TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          
          ...order.items.map((item) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${item.quantity}x ${item.productName}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                    ),
                  ),
                ),
                Text(
                  '₺${item.totalPrice.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          )),
          
          const SizedBox(height: 16),
          Divider(color: AppTheme.textSecondary.withOpacity(0.2)),
          const SizedBox(height: 16),
          
          // Özet
          _buildPriceRow('Ara Toplam', order.totalAmount - order.taxAmount),
          const SizedBox(height: 8),
          _buildPriceRow('KDV', order.taxAmount),
          if (order.discountAmount > 0) ...[
            const SizedBox(height: 8),
            _buildPriceRow('İndirim', -order.discountAmount, color: Colors.red),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'TOPLAM',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₺${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Ödeme Bilgileri
          if (order.payments.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Text(
              'Ödeme Bilgileri',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...order.payments.map((payment) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    _getPaymentIcon(payment.method),
                    color: AppTheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      payment.method,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  Text(
                    '₺${payment.amount.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: color ?? AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          '₺${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: color ?? AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Yazdırma işlemi
              Get.snackbar(
                'Bilgi',
                'Fiş yazdırma özelliği yakında eklenecek',
                backgroundColor: AppTheme.primary,
                colorText: Colors.white,
              );
            },
            icon: const Icon(Icons.print),
            label: const Text(
              'Fiş Yazdır',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Paylaşma işlemi
              Get.snackbar(
                'Bilgi',
                'Fiş paylaşma özelliği yakında eklenecek',
                backgroundColor: AppTheme.surface,
                colorText: AppTheme.textPrimary,
              );
            },
            icon: const Icon(Icons.share),
            label: const Text(
              'Fişi Paylaş',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppTheme.primary,
              side: const BorderSide(color: AppTheme.primary),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton.icon(
            onPressed: () => Get.back(),
            icon: const Icon(Icons.arrow_back),
            label: const Text(
              'Ana Sayfaya Dön',
              style: TextStyle(fontSize: 16),
            ),
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.textSecondary,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getPaymentIcon(String method) {
    final methodLower = method.toLowerCase();
    if (methodLower.contains('nakit') || methodLower.contains('cash')) {
      return Icons.money;
    } else if (methodLower.contains('kart') || methodLower.contains('card')) {
      return Icons.credit_card;
    } else if (methodLower.contains('meal') || methodLower.contains('ticket')) {
      return Icons.restaurant;
    } else {
      return Icons.payment;
    }
  }
}
