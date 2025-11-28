import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/payment_controller.dart';
import '../../data/models/payment_model.dart';
import 'payment_detail_screen.dart';

class PaymentListScreen extends StatelessWidget {
  final PaymentController _paymentController = Get.put(PaymentController());

  PaymentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ödemeler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _paymentController.fetchPayments(),
          ),
        ],
      ),
      body: Obx(() {
        if (_paymentController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_paymentController.payments.isEmpty) {
          return const Center(child: Text('Ödeme bulunamadı'));
        }
        return ListView.builder(
          itemCount: _paymentController.payments.length,
          itemBuilder: (context, index) {
            final Payment payment = _paymentController.payments[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text('${payment.amount.toStringAsFixed(2)} ₺ - ${payment.paymentMethod}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Sipariş: ${payment.orderNumber ?? 'Bilinmiyor'}'),
                    Text('Müşteri: ${payment.customerName ?? 'Misafir'}'),
                    Text('Tarih: ${DateFormat('dd.MM.yyyy HH:mm').format(payment.paymentDate)}'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.visibility),
                  onPressed: () => Get.to(() => PaymentDetailScreen(payment: payment)),
                ),
                onTap: () => Get.to(() => PaymentDetailScreen(payment: payment)),
              ),
            );
          },
        );
      }),
    );
  }
}