import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/theme_constants.dart';
import '../../../../core/services/backup_service.dart';
import '../../../../core/utils/data_seeder.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  final SettingsController _controller = Get.put(SettingsController());
  
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storeAddressController = TextEditingController();
  final TextEditingController _storePhoneController = TextEditingController();
  final TextEditingController _receiptFooterController = TextEditingController();
  final TextEditingController _taxRateController = TextEditingController();

  SettingsScreen({super.key}) {
    // Controller değerlerini text field'lara ata
    ever(_controller.storeName, (val) => _storeNameController.text = val);
    ever(_controller.storeAddress, (val) => _storeAddressController.text = val);
    ever(_controller.storePhone, (val) => _storePhoneController.text = val);
    ever(_controller.receiptFooter, (val) => _receiptFooterController.text = val);
    ever(_controller.defaultTaxRate, (val) => _taxRateController.text = val.toString());
    
    // İlk değerleri yükle
    _storeNameController.text = _controller.storeName.value;
    _storeAddressController.text = _controller.storeAddress.value;
    _storePhoneController.text = _controller.storePhone.value;
    _receiptFooterController.text = _controller.receiptFooter.value;
    _taxRateController.text = _controller.defaultTaxRate.value.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text('Ayarlar', style: TextStyle(color: AppTheme.textPrimary)),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.cardGradient,
          ),
        ),
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: AppTheme.textPrimary),
            onPressed: () {
              _controller.storeName.value = _storeNameController.text;
              _controller.storeAddress.value = _storeAddressController.text;
              _controller.storePhone.value = _storePhoneController.text;
              _controller.receiptFooter.value = _receiptFooterController.text;
              _controller.defaultTaxRate.value = double.tryParse(_taxRateController.text) ?? 0.18;
              _controller.saveSettings();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Mağaza Bilgileri'),
            _buildTextField('Mağaza Adı', _storeNameController, Icons.store),
            _buildTextField('Adres', _storeAddressController, Icons.location_on),
            _buildTextField('Telefon', _storePhoneController, Icons.phone),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Fiş Ayarları'),
            _buildTextField('Fiş Alt Bilgisi', _receiptFooterController, Icons.receipt),
            
            const SizedBox(height: 24),
            _buildSectionHeader('Genel Ayarlar'),
            _buildTextField('Varsayılan KDV Oranı (0.18 gibi)', _taxRateController, Icons.percent, isNumber: true),
            
            const SizedBox(height: 16),
            Obx(() => SwitchListTile(
              title: Text('Karanlık Mod', style: TextStyle(color: AppTheme.textPrimary)),
              value: _controller.isDarkMode.value,
              onChanged: (val) => _controller.toggleTheme(),
              secondary: Icon(Icons.dark_mode, color: AppTheme.textPrimary),
              activeColor: AppTheme.primary,
            )),
            
            const SizedBox(height: 32),
            _buildSectionHeader('Veritabanı Yedekleme'),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Get.dialog(
                        const Center(child: CircularProgressIndicator()),
                        barrierDismissible: false,
                      );
                      
                      final backupService = BackupService();
                      final filePath = await backupService.exportAllData();
                      
                      Get.back(); // Dialog'u kapat
                      
                      if (filePath != null) {
                        Get.defaultDialog(
                          title: 'Yedekleme Başarılı',
                          middleText: 'Veritabanı yedeklendi. Paylaşmak ister misiniz?',
                          textConfirm: 'Paylaş',
                          textCancel: 'Kapat',
                          confirmTextColor: Colors.white,
                          onConfirm: () async {
                            Get.back();
                            await backupService.shareBackup(filePath);
                          },
                        );
                      } else {
                        Get.snackbar('Hata', 'Yedekleme başarısız oldu',
                          backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                    icon: const Icon(Icons.backup, color: Colors.white),
                    label: const Text('Yedekle', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      final confirm = await Get.defaultDialog<bool>(
                        title: 'Uyarı',
                        middleText: 'Mevcut veriler silinip yedeğiniz geri yüklenecek. Devam edilsin mi?',
                        textConfirm: 'Evet',
                        textCancel: 'İptal',
                        confirmTextColor: Colors.white,
                        onConfirm: () => Get.back(result: true),
                        onCancel: () => Get.back(result: false),
                      );
                      
                      if (confirm == true) {
                        Get.dialog(
                          const Center(child: CircularProgressIndicator()),
                          barrierDismissible: false,
                        );
                        
                        final backupService = BackupService();
                        final success = await backupService.importBackup();
                        
                        Get.back();
                        
                        if (success) {
                          Get.snackbar('Başarılı', 'Veritabanı geri yüklendi',
                            backgroundColor: Colors.green, colorText: Colors.white);
                        } else {
                          Get.snackbar('Hata', 'Geri yükleme başarısız',
                            backgroundColor: Colors.red, colorText: Colors.white);
                        }
                      }
                    },
                    icon: const Icon(Icons.restore, color: Colors.white),
                    label: const Text('Geri Yükle', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('Geliştirici Araçları'),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final confirm = await Get.defaultDialog<bool>(
                    title: 'Veri Tohumlama',
                    middleText: '500 ürün, 200 müşteri, 40 çalışan ve 1500 sipariş eklenecek. Bu işlem biraz sürebilir. Devam edilsin mi?',
                    textConfirm: 'Başlat',
                    textCancel: 'İptal',
                    confirmTextColor: Colors.white,
                    onConfirm: () => Get.back(result: true),
                    onCancel: () => Get.back(result: false),
                  );
                  
                  if (confirm == true) {
                    Get.dialog(
                      const Center(child: CircularProgressIndicator()),
                      barrierDismissible: false,
                    );
                    
                    try {
                      // DataSeeder'ı lazy load yapalım ki import sorunu olmasın
                      // Ancak burada import eklememiz gerekecek
                      // Şimdilik import'u yukarı ekleyip burada kullanacağız
                      final seeder = DataSeeder();
                      await seeder.seedAll();
                      
                      Get.back(); // Dialog kapat
                      Get.snackbar('Başarılı', 'Tüm veriler başarıyla eklendi!',
                        backgroundColor: Colors.green, colorText: Colors.white);
                    } catch (e) {
                      Get.back();
                      Get.snackbar('Hata', 'Veri ekleme hatası: $e',
                        backgroundColor: Colors.red, colorText: Colors.white);
                    }
                  }
                },
                icon: const Icon(Icons.cloud_upload, color: Colors.white),
                label: const Text('Örnek Verileri Yükle (Seed)', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: AppTheme.primary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: AppTheme.textSecondary),
          prefixIcon: Icon(icon, color: AppTheme.textSecondary),
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppTheme.primary),
          ),
        ),
      ),
    );
  }
}
