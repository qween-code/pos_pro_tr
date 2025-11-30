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
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(),
            Expanded(
              child: Obx(() {
                if (_orderController.isLoading.value) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
                }

                if (_orderController.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                        const SizedBox(height: 16),
                        const Text(
                          'Henüz sipariş bulunmuyor',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                // Siparişleri tarihe göre sırala (Yeniden eskiye)
                final sortedOrders = List<Order>.from(_orderController.orders)
                  ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: sortedOrders.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final order = sortedOrders[index];
                    return _buildOrderCard(order);
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() {
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
              child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Sipariş Geçmişi',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final dateFormat = DateFormat('dd MMM yyyy • HH:mm', 'tr_TR');
    final isRefunded = order.status == 'refunded';
    final isPartialRefunded = order.status == 'partial_refunded';
    final isCompleted = order.status == 'completed';

    Color statusColor = Colors.grey;
    String statusText = order.status;
    IconData statusIcon = Icons.info_outline;

    if (isRefunded) {
      statusColor = Colors.red;
      statusText = 'İade Edildi';
      statusIcon = Icons.replay;
    } else if (isPartialRefunded) {
      statusColor = Colors.orange;
      statusText = 'Kısmi İade';
      statusIcon = Icons.replay_circle_filled;
    } else if (isCompleted) {
      statusColor = Colors.green;
      statusText = 'Tamamlandı';
      statusIcon = Icons.check_circle;
    }

    return Container(
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showOrderDetails(order),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: statusColor.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(statusIcon, size: 14, color: statusColor),
                          const SizedBox(width: 6),
                          Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '#${order.id?.substring(0, 8) ?? '...'}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                        fontFamily: 'Monospace',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: AppTheme.primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order.customerName ?? 'Misafir Müşteri',
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(order.orderDate),
                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₺${order.totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.paymentMethod ?? 'Nakit',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
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

  void _showOrderDetails(Order order) async {
    final items = await _orderController.getOrderItems(order.id!);
    
    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Sipariş Detayı',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (order.status == 'completed' || order.status == 'partial_refunded')
                  TextButton.icon(
                    onPressed: () {
                      Get.back();
                      _showRefundDialog(order, items);
                    },
                    icon: const Icon(Icons.replay, color: Colors.orange, size: 18),
                    label: const Text('İade İşlemi', style: TextStyle(color: Colors.orange)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: items.length,
                separatorBuilder: (context, index) => const Divider(color: Colors.white10),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.textSecondary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName ?? 'Ürün',
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${item.quantity} adet x ₺${item.unitPrice.toStringAsFixed(2)}',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '₺${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white24, height: 32),
            _buildSummaryRow('Ara Toplam', '₺${(order.totalAmount - order.taxAmount + order.discountAmount).toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            _buildSummaryRow('KDV', '₺${order.taxAmount.toStringAsFixed(2)}'),
            if (order.discountAmount > 0) ...[
              const SizedBox(height: 8),
              _buildSummaryRow('İndirim', '-₺${order.discountAmount.toStringAsFixed(2)}', color: Colors.green),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Genel Toplam',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '₺${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      isScrollControlled: true,
      ignoreSafeArea: false,
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
        Text(value, style: TextStyle(color: color ?? AppTheme.textPrimary, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showRefundDialog(Order order, List<OrderItem> items) {
    final refundQuantities = <String, RxInt>{};
    for (var item in items) {
      refundQuantities[item.productId ?? item.id!] = 0.obs;
    }

    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.replay, color: Colors.orange),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'İade İşlemi',
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'İade edilecek ürünleri seçin',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final key = item.productId ?? item.id!;
                    
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.productName ?? 'Ürün',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₺${item.unitPrice.toStringAsFixed(2)}',
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline, color: AppTheme.textSecondary),
                                onPressed: () {
                                  if (refundQuantities[key]!.value > 0) {
                                    refundQuantities[key]!.value--;
                                  }
                                },
                              ),
                              Obx(() => SizedBox(
                                width: 30,
                                child: Text(
                                  '${refundQuantities[key]!.value}',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline, color: AppTheme.primary),
                                onPressed: () {
                                  if (refundQuantities[key]!.value < item.quantity) {
                                    refundQuantities[key]!.value++;
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
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.textSecondary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('İptal', style: TextStyle(color: AppTheme.textPrimary)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        final List<Map<String, dynamic>> refundItems = [];
                        
                        refundQuantities.forEach((key, value) {
                          if (value.value > 0) {
                            final item = items.firstWhere((i) => (i.productId ?? i.id) == key);
                            refundItems.add({
                              'productId': item.productId,
                              'quantity': value.value,
                              'unitPrice': item.unitPrice,
                            });
                          }
                        });
                        
                        if (refundItems.isNotEmpty) {
                          Get.back();
                          await _orderController.processPartialRefund(order.id!, refundItems);
                        } else {
                          Get.snackbar(
                            'Uyarı',
                            'En az bir ürün seçmelisiniz',
                            backgroundColor: Colors.orange,
                            colorText: Colors.white,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('İadeyi Onayla', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
