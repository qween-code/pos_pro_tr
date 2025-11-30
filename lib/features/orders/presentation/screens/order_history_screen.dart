import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/theme_constants.dart';
import '../controllers/order_controller.dart';
import '../../data/models/order_model.dart';

class OrderHistoryScreen extends StatelessWidget {
  final OrderController _orderController = Get.find<OrderController>();

  OrderHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Sipariş Geçmişi', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.cardGradient,
          ),
        ),
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
      ),
      body: Obx(() {
        if (_orderController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_orderController.orders.isEmpty) {
          return Center(
            child: Text(
              'Henüz sipariş bulunmuyor',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          );
        }

        // Siparişleri tarihe göre sırala (Yeniden eskiye)
        final sortedOrders = List<Order>.from(_orderController.orders)
          ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: sortedOrders.length,
          itemBuilder: (context, index) {
            final order = sortedOrders[index];
            return _buildOrderCard(order);
          },
        );
      }),
    );
  }

  Widget _buildOrderCard(Order order) {
    final dateFormat = DateFormat('dd.MM.yyyy HH:mm');
    final isRefunded = order.status == 'refunded';
    final isPartialRefunded = order.status == 'partial_refunded';

    return Card(
      color: AppTheme.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showOrderDetails(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '#${order.id?.substring(0, 8) ?? '...'}',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isRefunded 
                          ? Colors.red.withOpacity(0.1) 
                          : (isPartialRefunded ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      isRefunded ? 'İade Edildi' : (isPartialRefunded ? 'Kısmi İade' : 'Tamamlandı'),
                      style: TextStyle(
                        color: isRefunded 
                            ? Colors.red 
                            : (isPartialRefunded ? Colors.orange : Colors.green),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customerName ?? 'Misafir Müşteri',
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateFormat.format(order.orderDate),
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  Text(
                    '₺${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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

  void _showOrderDetails(Order order) async {
    final items = await _orderController.getOrderItems(order.id!);
    
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Sipariş Detayı',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Get.back(),
                  ),
                ],
              ),
              const Divider(color: Colors.white24),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName ?? 'Ürün',
                                  style: TextStyle(color: AppTheme.textPrimary),
                                ),
                                Text(
                                  '${item.quantity} x ₺${item.unitPrice.toStringAsFixed(2)}',
                                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '₺${item.total.toStringAsFixed(2)}',
                            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Divider(color: Colors.white24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Ödeme Yöntemi:', style: TextStyle(color: AppTheme.textSecondary)),
                  Text(order.paymentMethod ?? 'Bilinmiyor', style: TextStyle(color: AppTheme.textPrimary)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Toplam Tutar:', style: TextStyle(color: AppTheme.textSecondary)),
                  Text(
                    '₺${order.totalAmount.toStringAsFixed(2)}',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (order.status != 'refunded')
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Get.back();
                      _showRefundDialog(order, items);
                    },
                    icon: const Icon(Icons.replay, color: Colors.white),
                    label: const Text('İade İşlemi', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showRefundDialog(Order order, List<OrderItem> items) {
    final refundQuantities = <String, RxInt>{};
    for (var item in items) {
      refundQuantities[item.id!] = 0.obs;
    }

    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'İade Edilecek Ürünleri Seçin',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.productName ?? 'Ürün',
                              style: TextStyle(color: AppTheme.textPrimary),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                onPressed: () {
                                  if (refundQuantities[item.id]!.value > 0) {
                                    refundQuantities[item.id]!.value--;
                                  }
                                },
                              ),
                              Obx(() => Text(
                                '${refundQuantities[item.id]!.value}',
                                style: TextStyle(color: AppTheme.textPrimary, fontSize: 16),
                              )),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                onPressed: () {
                                  if (refundQuantities[item.id]!.value < item.quantity) {
                                    refundQuantities[item.id]!.value++;
                                  }
                                },
                              ),
                            ],
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
                    child: TextButton(
                      onPressed: () => Get.back(),
                      child: Text('İptal', style: TextStyle(color: AppTheme.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final quantities = refundQuantities.map((key, value) => MapEntry(key, value.value));
                        final totalRefundItems = quantities.values.fold(0, (sum, q) => sum + q);
                        
                        if (totalRefundItems > 0) {
                          Get.back();
                          _orderController.refundOrderItems(order, quantities);
                        } else {
                          Get.snackbar('Hata', 'En az bir ürün seçmelisiniz');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('İadeyi Onayla', style: TextStyle(color: Colors.white)),
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
