import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../data/models/customer_model.dart';
import '../controllers/customer_controller.dart';
import '../../../register/presentation/controllers/register_controller.dart';
import '../../../orders/data/repositories/hybrid_order_repository.dart';
import '../../../orders/data/models/order_model.dart' as models;
import '../../../../core/database/database_instance.dart';
import '../../../../core/services/firebase_service.dart';

class CustomerDetailScreen extends StatelessWidget {
  final Customer customer;
  final CustomerController _customerController = Get.find<CustomerController>();
  late final HybridOrderRepository _orderRepository;

  CustomerDetailScreen({super.key, required this.customer}) {
    final dbInstance = Get.find<DatabaseInstance>();
    _orderRepository = HybridOrderRepository(
      localDb: dbInstance.database,
      firestore: FirebaseService.instance.firestore,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Müşterinin güncel verisini takip etmek için reaktif değişken
    final Rx<Customer> currentCustomer = customer.obs;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(customer.name, style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.cardGradient,
          ),
        ),
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(currentCustomer),
            const SizedBox(height: 20),
            _buildBalanceCard(context, currentCustomer),
            const SizedBox(height: 20),
            Text(
              'İşlem Geçmişi',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildTransactionHistory(),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(Rx<Customer> customer) {
    return Card(
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.primary),
                  ),
                  child: Center(
                    child: Text(
                      customer.value.name.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.value.name,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (customer.value.phone != null)
                        Text(
                          customer.value.phone!,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                      if (customer.value.email != null)
                        Text(
                          customer.value.email!,
                          style: TextStyle(color: AppTheme.textSecondary),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (customer.value.note != null && customer.value.note!.isNotEmpty) ...[
              const Divider(color: Colors.white10, height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.note, size: 16, color: AppTheme.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customer.value.note!,
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, Rx<Customer> customer) {
    return Obx(() {
      final balance = customer.value.balance;
      final isDebt = balance > 0;
      
      return Card(
        color: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Güncel Bakiye',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                '₺${balance.abs().toStringAsFixed(2)}',
                style: TextStyle(
                  color: isDebt ? Colors.red : (balance < 0 ? Colors.green : AppTheme.textPrimary),
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                isDebt ? 'Borçlu' : (balance < 0 ? 'Alacaklı' : 'Bakiye Yok'),
                style: TextStyle(
                  color: isDebt ? Colors.red : (balance < 0 ? Colors.green : AppTheme.textSecondary),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _showPaymentDialog(context, customer),
                  icon: const Icon(Icons.payment, color: Colors.white),
                  label: const Text('Tahsilat Yap', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _showPaymentDialog(BuildContext context, Rx<Customer> customer) {
    final amountController = TextEditingController();
    
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tahsilat Yap',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 24),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Tutar',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  prefixText: '₺ ',
                  prefixStyle: TextStyle(color: AppTheme.primary, fontSize: 24),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                autofocus: true,
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
                      onPressed: () async {
                        final amount = double.tryParse(amountController.text);
                        if (amount != null && amount > 0) {
                          // 1. Kasa Kontrolü
                          final registerController = Get.isRegistered<RegisterController>() 
                              ? Get.find<RegisterController>() 
                              : Get.put(RegisterController());

                          if (registerController.currentRegister.value == null) {
                            Get.snackbar('Hata', 'Tahsilat yapabilmek için kasa açık olmalıdır');
                            return;
                          }

                          Get.back();
                          
                          // 2. Müşteri Bakiyesini Düş (Tahsilat = Bakiye Azalır)
                          await _customerController.updateBalance(customer.value.id!, -amount);
                          
                          // 3. Kasaya Para Girişi (Tahsilat = Kasa Artar)
                          // Tahsilat genellikle nakit veya kartla yapılır. Şimdilik varsayılan nakit.
                          // İleride ödeme yöntemi seçimi eklenebilir.
                          await registerController.updateSales(amount, 'cash');
                          
                          // UI Güncelleme (Manuel olarak, çünkü stream değil)
                          customer.value = customer.value.copyWith(
                            balance: customer.value.balance - amount
                          );
                          
                          Get.snackbar(
                            'Başarılı', 
                            'Tahsilat alındı: ₺${amount.toStringAsFixed(2)}',
                            backgroundColor: Colors.green,
                            colorText: Colors.white
                          );
                        } else {
                          Get.snackbar('Hata', 'Geçerli bir tutar girin');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Onayla', style: TextStyle(color: Colors.white)),
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

  Widget _buildTransactionHistory() {
    return FutureBuilder<List<models.Order>>(
      future: _orderRepository.getOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Hata: ${snapshot.error}',
                style: TextStyle(color: AppTheme.error),
              ),
            ),
          );
        }

        final allOrders = snapshot.data ?? [];
        final customerOrders = allOrders
            .where((order) => order.customerId == customer.id)
            .toList()
          ..sort((a, b) => b.orderDate.compareTo(a.orderDate));

        if (customerOrders.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Henüz işlem yok',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: customerOrders.length,
          itemBuilder: (context, index) {
            final order = customerOrders[index];
            return Card(
              color: AppTheme.surface,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getStatusIcon(order.status),
                    color: _getStatusColor(order.status),
                    size: 20,
                  ),
                ),
                title: Text(
                  'Sipariş #${order.id?.substring(0, 8) ?? "---"}',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  DateFormat('dd MMM yyyy, HH:mm', 'tr_TR').format(order.orderDate),
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₺${order.totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _getStatusText(order.status),
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'refunded':
        return Colors.red;
      case 'partial_refunded':
        return Colors.orange;
      default:
        return AppTheme.textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed':
        return Icons.check_circle;
      case 'refunded':
        return Icons.cancel;
      case 'partial_refunded':
        return Icons.warning;
      default:
        return Icons.shopping_bag;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'completed':
        return 'Tamamlandı';
      case 'refunded':
        return 'İade Edildi';
      case 'partial_refunded':
        return 'Kısmi İade';
      default:
        return status;
    }
  }
}
