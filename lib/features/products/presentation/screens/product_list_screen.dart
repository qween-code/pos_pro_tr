import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'dart:io';
import '../controllers/product_controller.dart';
import '../../data/models/product_model.dart';
import 'product_add_edit_screen.dart';
import '../../../../core/widgets/barcode_scanner_screen.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/product_import_service.dart';
import '../../../../core/constants/theme_constants.dart';

class ProductListScreen extends StatelessWidget {
  final ProductController _productController = Get.put(ProductController());

  ProductListScreen({super.key}) {
    // Eğer argüman varsa ve filter 'low_stock' ise filtrele
    if (Get.arguments != null && Get.arguments is Map && Get.arguments['filter'] == 'low_stock') {
      _productController.fetchProducts(filter: 'low_stock');
    } else {
      // Normal yükleme (eğer zaten yüklü değilse veya yenilemek istenirse)
      // _productController.fetchProducts(); // Zaten onReady'de çağrılıyor ama filtreyi sıfırlamak gerekebilir
      // Şimdilik sadece filtre varsa özel çağırıyoruz, yoksa onReady hallediyor.
      // Ancak geri gelince filtre kalabilir, o yüzden her girişte kontrol etmek iyi olabilir.
       _productController.fetchProducts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ürünler'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _scanBarcode(context),
            tooltip: 'Barkod Oku',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Get.to(() => ProductAddEditScreen()),
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(_productController),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.sort), // İkonu değiştirdim
            onPressed: () => _showSortFilterBottomSheet(context),
          ),
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: () => _showImportOptions(context),
            tooltip: 'Toplu Ürün Ekle',
          ),
        ],
      ),
      body: Obx(() {
        if (_productController.isLoading.value) {
          return ListView.builder(
            itemCount: 5,
            itemBuilder: (context, index) => const SkeletonListTile(),
          );
        }
        if (_productController.products.isEmpty) {
          return EmptyStateWidget(
            message: 'Henüz ürün eklenmemiş',
            icon: Icons.inventory_2_outlined,
            action: ElevatedButton.icon(
              onPressed: () => Get.to(() => ProductAddEditScreen()),
              icon: const Icon(Icons.add),
              label: const Text('İlk Ürünü Ekle'),
            ),
          );
        }
        return ListView.builder(
          itemCount: _productController.products.length,
          itemBuilder: (context, index) {
            final Product product = _productController.products[index];
            
            // Resim için widget oluştur
            Widget leadingWidget = CircleAvatar(
              backgroundColor: Colors.grey[300],
              child: Icon(Icons.inventory_2, color: Colors.grey[600]),
            );
            
            if (product.imageUrl != null && product.imageUrl!.isNotEmpty) {
              if (product.imageUrl!.startsWith('http')) {
                leadingWidget = CircleAvatar(
                  backgroundImage: NetworkImage(product.imageUrl!),
                  onBackgroundImageError: (_, __) {},
                );
              } else {
                final imageFile = File(product.imageUrl!);
                if (imageFile.existsSync()) {
                  leadingWidget = CircleAvatar(
                    backgroundImage: FileImage(imageFile),
                  );
                }
              }
            }
            
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: leadingWidget,
                title: Text(product.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${product.price} ₺ - KDV: %${(product.taxRate * 100).toStringAsFixed(0)}'),
                    Text('Stok: ${product.stock}'),
                    if (product.category != null) Text('Kategori: ${product.category}'),
                    if (product.stock <= 5) Text(
                      'DÜŞÜK STOK!',
                      style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => Get.to(() => ProductAddEditScreen(product: product)),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showDeleteConfirmationDialog(product),
                    ),
                  ],
                ),
                onTap: () {
                  // Ürün detaylarına gitme işlemi eklenebilir
                },
              ),
            );
          },
        );
      }),
    );
  }

  void _showDeleteConfirmationDialog(Product product) {
    Get.dialog(
      AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text('${product.name} ürününü silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              _productController.deleteProduct(product.id.toString());
            },
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _scanBarcode(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          onBarcodeScanned: (product) {
            if (product != null) {
              Get.to(() => ProductAddEditScreen(product: product));
            } else {
              ErrorHandler.showInfoMessage('Barkod ile eşleşen ürün bulunamadı');
            }
          },
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext context) {
    final categoryController = TextEditingController();
    final stockController = TextEditingController();

    Get.dialog(
      AlertDialog(
        title: const Text('Ürünleri Filtrele'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(labelText: 'Kategori'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Minimum Stok'),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              // Filtreleme işlemi burada yapılacak
              // TODO: Filtreleme implementasyonu eklenecek
            },
            child: const Text('Filtrele'),
          ),
        ],
      ),
    );
  }

  void _showImportOptions(BuildContext context) {
    final importService = Get.put(ProductImportService());
    importService.showImportOptions(context);
  }

  void _showSortFilterBottomSheet(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sıralama ve Filtreleme',
                style: TextStyle(
                  fontSize: 20, 
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sıralama', 
                style: TextStyle(
                  color: AppTheme.primary, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              ListTile(
                leading: Icon(Icons.sort_by_alpha, color: AppTheme.primary),
                title: Text('İsim (A-Z)', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  _productController.sortProducts('name_asc');
                  Get.back();
                },
              ),
              ListTile(
                leading: Icon(Icons.arrow_upward, color: AppTheme.primary),
                title: Text('Fiyat (Artan)', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  _productController.sortProducts('price_asc');
                  Get.back();
                },
              ),
              ListTile(
                leading: Icon(Icons.arrow_downward, color: AppTheme.primary),
                title: Text('Fiyat (Azalan)', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  _productController.sortProducts('price_desc');
                  Get.back();
                },
              ),
              ListTile(
                leading: Icon(Icons.inventory, color: AppTheme.primary),
                title: Text('Stok (Azalan)', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  _productController.sortProducts('stock_desc');
                  Get.back();
                },
              ),
              Divider(color: AppTheme.textSecondary.withOpacity(0.3)),
              Text(
                'Filtreleme', 
                style: TextStyle(
                  color: AppTheme.primary, 
                  fontWeight: FontWeight.bold,
                ),
              ),
              ListTile(
                leading: const Icon(Icons.warning, color: Colors.red),
                title: Text('Sadece Kritik Stok', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  _productController.fetchProducts(filter: 'low_stock');
                  Get.back();
                },
              ),
              Theme(
                data: ThemeData(
                  dividerColor: Colors.transparent,
                  unselectedWidgetColor: AppTheme.textSecondary,
                ),
                child: ExpansionTile(
                  leading: const Icon(Icons.category, color: Colors.blue),
                  title: Text('Kategoriye Göre Filtrele', style: TextStyle(color: AppTheme.textPrimary)),
                  iconColor: AppTheme.textPrimary,
                  collapsedIconColor: AppTheme.textSecondary,
                  children: ['Elektronik', 'Giyim', 'Gıda', 'Kırtasiye', 'Kozmetik', 'Ev & Yaşam', 'Diğer'].map((category) {
                    return ListTile(
                      title: Text(category, style: TextStyle(color: AppTheme.textPrimary)),
                      onTap: () {
                        _productController.fetchProducts(category: category);
                        Get.back();
                      },
                    );
                  }).toList(),
                ),
              ),
              ListTile(
                leading: Icon(Icons.clear_all, color: AppTheme.textSecondary),
                title: Text('Filtreleri Temizle', style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  _productController.fetchProducts();
                  Get.back();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ProductSearchDelegate extends SearchDelegate<Product?> {
  final ProductController controller;

  ProductSearchDelegate(this.controller, {String? initialQuery}) {
    if (initialQuery != null) {
      query = initialQuery;
    }
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    return FutureBuilder<List<Product>>(
      future: controller.searchProducts(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }
        
        final results = snapshot.data ?? [];
        
        if (results.isEmpty) {
          return const Center(child: Text('Ürün bulunamadı'));
        }
        
        return ListView.builder(
          itemCount: results.length,
          itemBuilder: (context, index) {
            final product = results[index];
            return ListTile(
              title: Text(product.name),
              subtitle: Text('${product.price} TL'),
              onTap: () {
                close(context, product);
                Get.to(() => ProductAddEditScreen(product: product));
              },
            );
          },
        );
      },
    );
  }
}