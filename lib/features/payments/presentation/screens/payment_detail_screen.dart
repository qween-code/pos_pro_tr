import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/payment_controller.dart';
import '../../data/models/payment_model.dart';

class PaymentDetailScreen extends StatelessWidget {
  final Payment payment;
  final PaymentController _paymentController = Get.find();

  PaymentDetailScreen({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödeme Detayı'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () => _showDeleteConfirmationDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
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
                      _buildInfoRow('Ödeme Tutarı:', '${payment.amount.toStringAsFixed(2)} ₺',
                                   isBold: true, fontSize: 18),
                      const Divider(),
                      _buildInfoRow('Ödeme Yöntemi:', payment.paymentMethod),
                      _buildInfoRow('Sipariş No:', payment.orderNumber ?? 'Bilinmiyor'),
                      _buildInfoRow('Müşteri:', payment.customerName ?? 'Misafir'),
                      _buildInfoRow('Tarih:', DateFormat('dd.MM.yyyy HH:mm').format(payment.paymentDate)),
                      if (payment.transactionId != null)
                        _buildInfoRow('İşlem ID:', payment.transactionId!),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Buraya sipariş detayları eklenebilir
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, double fontSize = 16}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(value, style: TextStyle(fontSize: fontSize, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    Get.dialog(
      AlertDialog(
        title: const Text('Ödemeyi Sil'),
        content: const Text('Bu ödemeyi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _paymentController.deletePayment(payment.id!);
              Get.back(); // Ekrandan çık
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}