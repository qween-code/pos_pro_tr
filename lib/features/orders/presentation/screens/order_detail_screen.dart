import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/order_controller.dart';
import '../../data/models/order_model.dart';

class OrderDetailScreen extends StatelessWidget {
  final Order order;
  final OrderController _orderController = Get.find();

  OrderDetailScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Sipariş Detayı #${order.id?.substring(0, 8)}'),
        actions: [
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
                  const Text('Sipariş Öğeleri', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.productName ?? 'Bilinmeyen Ürün'),
                          subtitle: Text('Miktar: ${item.quantity} x ${item.unitPrice.toStringAsFixed(2)} ₺'),
                          trailing: Text('${item.totalPrice.toStringAsFixed(2)} ₺'),
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
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color)),
        ],
      ),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'Bekliyor';
      case 'completed': return 'Tamamlandı';
      case 'cancelled': return 'İptal Edildi';
      default: return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'completed': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  void _showDeleteConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Siparişi Sil'),
        content: const Text('Bu siparişi silmek istediğinizden emin misiniz?'),
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