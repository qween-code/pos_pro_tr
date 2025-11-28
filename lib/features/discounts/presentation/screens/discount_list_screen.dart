import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/discount_controller.dart';
import '../../data/models/discount_model.dart';
import 'discount_add_edit_screen.dart';

class DiscountListScreen extends StatelessWidget {
  final DiscountController _discountController = Get.put(DiscountController());

  DiscountListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('İndirimler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.to(() => DiscountAddEditScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _discountController.fetchDiscounts(),
          ),
        ],
      ),
      body: Obx(() {
        if (_discountController.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (_discountController.discounts.isEmpty) {
          return const Center(child: Text('İndirim bulunamadı'));
        }
        return ListView.builder(
          itemCount: _discountController.discounts.length,
          itemBuilder: (context, index) {
            final Discount discount = _discountController.discounts[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                title: Text(discount.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Değer: ${discount.displayValue}'),
                    Text('Tür: ${discount.discountType == 'percentage' ? 'Yüzde' : 'Sabit'}'),
                    Text('Geçerlilik: ${DateFormat('dd.MM.yyyy').format(discount.startDate)} - ${DateFormat('dd.MM.yyyy').format(discount.endDate)}'),
                    Text('Durum: ${discount.isActive ? 'Aktif' : 'Pasif'}',
                         style: TextStyle(
                           color: discount.isActive ? Colors.green : Colors.red,
                           fontWeight: FontWeight.bold,
                         )),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Get.to(() => DiscountAddEditScreen(discount: discount)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showDeleteConfirmationDialog(discount),
                    ),
                  ],
                ),
                onTap: () {
                  // İndirim detaylarına gitme işlemi eklenebilir
                },
              ),
            );
          },
        );
      }),
    );
  }

  void _showDeleteConfirmationDialog(Discount discount) {
    Get.dialog(
      AlertDialog(
        title: const Text('İndirimi Sil'),
        content: Text('${discount.name} indirimini silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _discountController.deleteDiscount(discount.id!);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}