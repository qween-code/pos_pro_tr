import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../data/models/product_model.dart';
import '../controllers/product_controller.dart';
import '../../../../core/constants/theme_constants.dart';

class ProductAddEditScreen extends StatelessWidget {
  final Product? product;
  final ProductController _productController = Get.find();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _categoryController = TextEditingController();
  final _barcodeController = TextEditingController();
  final _taxRateController = TextEditingController();
  final _criticalStockController = TextEditingController();
  final RxString _selectedImagePath = ''.obs;

  ProductAddEditScreen({super.key, this.product}) {
    if (product != null) {
      _nameController.text = product!.name;
      _priceController.text = product!.price.toStringAsFixed(2);
      _stockController.text = product!.stock.toString();
      _categoryController.text = product!.category ?? '';
      _barcodeController.text = product!.barcode ?? '';
      _taxRateController.text = (product!.taxRate * 100).toStringAsFixed(0);
      _criticalStockController.text = product!.criticalStockLevel.toString();
      _selectedImagePath.value = product!.imageUrl ?? '';
    } else {
      _taxRateController.text = '10'; // Varsayılan KDV oranı %10
      _criticalStockController.text = '11'; // Varsayılan kritik stok
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          product == null ? 'Ürün Ekle' : 'Ürün Düzenle',
          style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppTheme.cardGradient,
          ),
        ),
        iconTheme: IconThemeData(color: AppTheme.textPrimary),
        actions: [
          if (product != null)
            IconButton(
              icon: Icon(Icons.delete, color: AppTheme.error),
              onPressed: () => _showDeleteConfirmationDialog(),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resim Seçme Alanı
              Center(
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Obx(() {
                    final path = _selectedImagePath.value;
                    ImageProvider? imageProvider;
                    
                    if (path.isNotEmpty) {
                      if (File(path).existsSync()) {
                        imageProvider = FileImage(File(path));
                      } else if (path.startsWith('http')) {
                        imageProvider = NetworkImage(path);
                      }
                    }

                    return Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.5)),
                        image: imageProvider != null
                            ? DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: path.isEmpty
                          ? Icon(Icons.add_a_photo, size: 40, color: AppTheme.textSecondary)
                          : null,
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Temel Bilgiler'),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _nameController,
                label: 'Ürün Adı',
                icon: Icons.inventory_2_outlined,
                validator: (value) => value?.isEmpty ?? true ? 'Lütfen ürün adını girin' : null,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _priceController,
                      label: 'Fiyat',
                      icon: Icons.attach_money,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Gerekli';
                        if (double.tryParse(value!) == null) return 'Geçersiz';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      controller: _stockController,
                      label: 'Stok',
                      icon: Icons.numbers,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (value) {
                        if (value?.isEmpty ?? true) return 'Gerekli';
                        if (int.tryParse(value!) == null) return 'Geçersiz';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Detaylar'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _categoryController.text.isNotEmpty && ['Elektronik', 'Giyim', 'Gıda', 'Kırtasiye', 'Kozmetik', 'Ev & Yaşam', 'Diğer'].contains(_categoryController.text) 
                    ? _categoryController.text 
                    : null,
                items: ['Elektronik', 'Giyim', 'Gıda', 'Kırtasiye', 'Kozmetik', 'Ev & Yaşam', 'Diğer']
                    .map((label) => DropdownMenuItem(
                          value: label,
                          child: Text(label),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _categoryController.text = value;
                  }
                },
                decoration: InputDecoration(
                  labelText: 'Kategori',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  prefixIcon: Icon(Icons.category_outlined, color: AppTheme.primary),
                  filled: true,
                  fillColor: AppTheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primary),
                  ),
                ),
                validator: (value) => value == null ? 'Lütfen kategori seçin' : null,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _barcodeController,
                label: 'Barkod',
                icon: Icons.qr_code,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _taxRateController,
                label: 'KDV Oranı (%)',
                icon: Icons.percent,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Gerekli';
                  if (int.tryParse(value!) == null) return 'Geçersiz';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _criticalStockController,
                label: 'Kritik Stok Seviyesi',
                icon: Icons.warning_amber_rounded,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Gerekli';
                  if (int.tryParse(value!) == null) return 'Geçersiz';
                  return null;
                },
              ),

              const SizedBox(height: 32),
              Obx(() {
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: AppTheme.primaryGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _productController.isLoading.value
                        ? null
                        : () {
                            if (_formKey.currentState!.validate()) {
                              final Product newProduct = Product(
                                id: product?.id,
                                name: _nameController.text,
                                price: double.parse(_priceController.text),
                                stock: int.parse(_stockController.text),
                                category: _categoryController.text.isEmpty ? 'Genel' : _categoryController.text,
                                barcode: _barcodeController.text.isEmpty ? null : _barcodeController.text,
                                taxRate: double.parse(_taxRateController.text) / 100,
                                criticalStockLevel: int.parse(_criticalStockController.text),
                                imageUrl: _selectedImagePath.value.isEmpty ? null : _selectedImagePath.value,
                              );
                              if (product == null) {
                                _productController.addProduct(newProduct);
                              } else {
                                _productController.updateProduct(newProduct);
                              }
                            }
                          },
                    child: _productController.isLoading.value
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : Text(
                            product == null ? 'ÜRÜN EKLE' : 'DEĞİŞİKLİKLERİ KAYDET',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 1,
                            ),
                          ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: AppTheme.primary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      style: TextStyle(color: AppTheme.textPrimary),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppTheme.textSecondary),
        prefixIcon: Icon(icon, color: AppTheme.primary),
        filled: true,
        fillColor: AppTheme.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.error),
        ),
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, size: 48, color: AppTheme.error),
              const SizedBox(height: 16),
              Text(
                'Ürünü Sil',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${product!.name} ürününü silmek istediğinizden emin misiniz?',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSecondary),
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
                        Get.back();
                        _productController.deleteProduct(product!.id.toString());
                        Get.back();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Sil', style: TextStyle(color: Colors.white)),
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
  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );
      
      if (result != null && result.files.isNotEmpty && result.files.first.path != null) {
        _selectedImagePath.value = result.files.first.path!;
        Get.snackbar(
          'Başarılı',
          'Resim seçildi',
          backgroundColor: Colors.green.withOpacity(0.8),
          colorText: Colors.white,
          duration: const Duration(seconds: 1),
        );
      }
    } catch (e) {
      debugPrint('Resim seçme hatası: $e');
      Get.snackbar(
        'Hata',
        'Resim seçilemedi. Lütfen tekrar deneyin.',
        backgroundColor: Colors.red.withOpacity(0.8),
        colorText: Colors.white,
      );
    }
  }
}