import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/order_controller.dart';
import '../../data/models/order_model.dart';
import '../../../../core/constants/theme_constants.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  final OrderController _orderController = Get.find();

  OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Sipariş Detayı #${order.id?.substring(0, 8)}'),
        backgroundColor: AppTheme.surface,
        actions: [
          if (order.status == 'completed' || order.status == 'partial_refunded')
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () => _showRefundDialog(),
              tooltip: 'İade',
            ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmationDialog(),
          ),
        ],
      ),
      body: FutureBuilder<List<OrderItem>>(
        future: _orderController.getOrderItems(order.id!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Sipariş öğesi bulunamadı'));
          }

          final items = snapshot.data!;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: AppTheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildInfoRow('Sipariş No:', order.id?.substring(0, 8) ?? 'Bilinmiyor'),
                          _buildInfoRow('Tarih:', DateFormat('dd.MM.yyyy HH:mm').format(order.orderDate)),
                          _buildInfoRow('Müşteri:', order.customerName ?? 'Misafir'),
                          _buildInfoRow('Durum:', _getStatusText(order.status),
                                       color: _getStatusColor(order.status)),
                          _buildInfoRow('Ödeme Yöntemi:', order.paymentMethod ?? 'Bilinmiyor'),
                          const Divider(),
                          _buildInfoRow('Ara Toplam:', '${(order.totalAmount - order.taxAmount + order.discountAmount).toStringAsFixed(2)} ₺'),
                          _buildInfoRow('KDV:', '${order.taxAmount.toStringAsFixed(2)} ₺'),
                          _buildInfoRow('İndirim:', '${order.discountAmount.toStringAsFixed(2)} ₺',
                                       color: Colors.red),
                          const Divider(),
                          _buildInfoRow('Toplam:', '${order.totalAmount.toStringAsFixed(2)} ₺',
                                       isBold: true, fontSize: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Sipariş Öğeleri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        color: AppTheme.surface,
                        child: ListTile(
                          title: Text(item.productName ?? 'Bilinmeyen Ürün', style: const TextStyle(color: AppTheme.textPrimary)),
                          subtitle: Text('Miktar: ${item.quantity} x ${item.unitPrice.toStringAsFixed(2)} ₺', style: const TextStyle(color: AppTheme.textSecondary)),
                          trailing: Text('${item.totalPrice.toStringAsFixed(2)} ₺', style: const TextStyle(color: AppTheme.textPrimary)),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color, bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: AppTheme.textSecondary)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color ?? AppTheme.textPrimary)),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Bekliyor';
      case 'completed': return 'Tamamlandı';
      case 'cancelled': return 'İptal Edildi';
      case 'refunded': return 'İade Edildi';
      case 'partial_refunded': return 'Kısmi İade';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'refunded': return Colors.purple;
      case 'partial_refunded': return Colors.blue;
      default: return Colors.grey;
    }
  }

  void _showRefundDialog() async {
    final items = await _orderController.getOrderItems(order.id!);
    
    if (items.isEmpty) {
      Get.snackbar('Hata', 'Sipariş öğeleri bulunamadı');
      return;
    }

    // Seçili öğeleri takip et
    final Map<String, int> selectedQuantities = {};

    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: StatefulBuilder(
          builder: (context, setState) {
            double refundTotal = 0.0;
            selectedQuantities.forEach((productId, qty) {
              final item = items.firstWhere((i) => i.productId == productId);
              refundTotal += item.unitPrice * qty;
            });

            return SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.undo, color: Colors.purple, size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Parçalı İade',
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'İade etmek istediğiniz ürünleri ve miktarlarını seçin',
                      style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    Container(
                      constraints: const BoxConstraints(maxHeight: 400),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final selectedQty = selectedQuantities[item.productId] ?? 0;

                          return Card(
                            color: AppTheme.background,
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName ?? 'Bilinmeyen',
                                    style: const TextStyle(
                                      color: AppTheme.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '₺${item.unitPrice.toStringAsFixed(2)} x ${item.quantity}',
                                    style: const TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: selectedQty > 0
                                            ? () {
                                                setState(() {
                                                  selectedQuantities[item.productId] = selectedQty - 1;
                                                  if (selectedQuantities[item.productId] == 0) {
                                                    selectedQuantities.remove(item.productId);
                                                  }
                                                });
                                              }
                                            : null,
                                        icon: const Icon(Icons.remove_circle_outline),
                                        color: AppTheme.primary,
                                        iconSize: 28,
                                      ),
                                      Expanded(
                                        child: Center(
                                          child: Text(
                                            '$selectedQty / ${item.quantity}',
                                            style: const TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: selectedQty < item.quantity
                                            ? () {
                                                setState(() {
                                                  selectedQuantities[item.productId] = selectedQty + 1;
                                                });
                                              }
                                            : null,
                                        icon: const Icon(Icons.add_circle_outline),
                                        color: AppTheme.primary,
                                        iconSize: 28,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'İade Toplamı:',
                            style: TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '₺${refundTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: AppTheme.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
                            onPressed: selectedQuantities.isEmpty
                                ? null
                                : () async {
                                    Get.back();
                                    
                                    // İade edilecek items'ı hazırla
                                    final List<Map<String, dynamic>> refundItems = [];
                                    selectedQuantities.forEach((productId, qty) {
                                      final item = items.firstWhere((i) => i.productId == productId);
                                      refundItems.add({
                                        'productId': productId,
                                        'quantity': qty,
                                        'unitPrice': item.unitPrice,
                                      });
                                    });

                                    // İade işlemini yap
                                    await _orderController.processPartialRefund(order.id!, refundItems);
                                    Get.back(); // Detail ekranından çık
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              disabledBackgroundColor: Colors.grey,
                            ),
                            child: const Text('İade Yap'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Siparişi Sil', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('Bu siparişi silmek istediğinizden emin misiniz?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _orderController.deleteOrder(order.id!);
              Get.back(); // Ekrandan çık
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}