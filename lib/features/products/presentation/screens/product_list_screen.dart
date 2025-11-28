import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/product_controller.dart';
import '../../data/models/product_model.dart';
import 'product_add_edit_screen.dart';
import '../../../../core/widgets/barcode_scanner_screen.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/error_widget.dart';
import '../../../../core/utils/error_handler.dart';

class ProductListScreen extends StatelessWidget {
  final ProductController _productController = Get.put(ProductController());

  ProductListScreen({super.key});

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
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context),
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
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
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
}

class ProductSearchDelegate extends SearchDelegate {
  final ProductController _productController;

  ProductSearchDelegate(this._productController);

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
    if (query.isEmpty) {
      return const Center(child: Text('Arama yapmak için ürün adı girin'));
    }

    return FutureBuilder<List<Product>>(
      future: _productController.searchProducts(query),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('Ürün bulunamadı'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final Product product = snapshot.data![index];
            return ListTile(
              title: Text(product.name),
              subtitle: Text('${product.price} ₺ - Stok: ${product.stock}'),
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