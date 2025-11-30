import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/theme_constants.dart';
import '../controllers/register_controller.dart';

class CloseRegisterScreen extends StatelessWidget {
  final RegisterController controller = Get.find<RegisterController>();
  final TextEditingController actualCashController = TextEditingController();
  final TextEditingController notesController = TextEditingController();

  CloseRegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Kasa verilerini al
    final register = controller.currentRegister.value!;
    final expectedCash = register.openingBalance + register.totalCashSales;
    final totalSales = register.totalCashSales + register.totalCardSales + register.totalOtherSales;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Z Raporu & Kapanış'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Özet Kartı
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'GÜN SONU ÖZETİ',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Divider(color: Colors.grey),
                      const SizedBox(height: 16),
                      _buildSummaryRow('Açılış Bakiyesi', register.openingBalance),
                      _buildSummaryRow('Nakit Satışlar', register.totalCashSales),
                      _buildSummaryRow('Kredi Kartı', register.totalCardSales),
                      _buildSummaryRow('Diğer', register.totalOtherSales),
                      const Divider(color: Colors.grey),
                      _buildSummaryRow('TOPLAM CİRO', totalSales, isTotal: true),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppTheme.primary),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Kasada Olması Gereken:',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            Text(
                              '₺${expectedCash.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Kapanış Formu
                const Text(
                  'Kapanış İşlemleri',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: actualCashController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Sayım Sonucu (Kasada Olan Nakit)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.money, color: AppTheme.secondary),
                    suffixText: '₺',
                    suffixStyle: const TextStyle(color: Colors.white),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: notesController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Notlar (Varsa fark sebebi)',
                    labelStyle: const TextStyle(color: Colors.grey),
                    prefixIcon: const Icon(Icons.note, color: Colors.grey),
                    filled: true,
                    fillColor: AppTheme.surface,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: Obx(() => ElevatedButton(
                    onPressed: controller.isLoading.value
                        ? null
                        : () async {
                            if (actualCashController.text.isEmpty) {
                              Get.snackbar('Hata', 'Lütfen kasa sayım sonucunu girin');
                              return;
                            }
                            
                            // Onay Dialogu
                            Get.defaultDialog(
                              title: 'Z Raporu Onayı',
                              middleText: 'Kasa kapatılacak ve gün sonu raporu oluşturulacak. Emin misiniz?',
                              textConfirm: 'EVET, KAPAT',
                              textCancel: 'İPTAL',
                              confirmTextColor: Colors.white,
                              onConfirm: () async {
                                Get.back(); // Dialog kapat
                                final actual = double.tryParse(actualCashController.text) ?? 0.0;
                                final success = await controller.closeRegister(
                                  actual,
                                  notesController.text,
                                );
                                if (success) {
                                  Get.back(); // Ekranı kapat
                                }
                              },
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: controller.isLoading.value
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Z RAPORU AL VE KAPAT',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? Colors.white : Colors.grey[400],
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '₺${amount.toStringAsFixed(2)}',
            style: TextStyle(
              color: isTotal ? AppTheme.secondary : Colors.white,
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
