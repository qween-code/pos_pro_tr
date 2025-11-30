import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/database/database_instance.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/hybrid_product_repository.dart';

class ProductController extends GetxController {
  late final HybridProductRepository _productRepository;
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    // Hibrit repository'yi initialize et
    _productRepository = HybridProductRepository(
      localDb: db,
      firestore: firestore,
    );
  }

  @override
  void onClose() {
    _productRepository.dispose(); // Listener'ı temizle
    super.onClose();
  }

  @override
  void onReady() {
    super.onReady();
    fetchProducts();
  }

  Future<void> fetchProducts({String? filter, String? category}) async {
    isLoading.value = true;
    try {
      final List<Product> productList = await _productRepository.getProducts();
      
      if (filter == 'low_stock') {
        products.assignAll(productList.where((p) => p.stock <= p.criticalStockLevel).toList());
      } else if (category != null) {
        products.assignAll(productList.where((p) => p.category == category).toList());
      } else {
        products.assignAll(productList);
      }
    } catch (e) {
      debugPrint('Ürünler yüklenemedi: $e');
      // Hata durumunda boş liste ile devam et
      products.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addProduct(Product product) async {
    isLoading.value = true;
    try {
      await _productRepository.insertProduct(product);
      await fetchProducts();
      Get.back();
      ErrorHandler.showSuccessMessage('Ürün başarıyla eklendi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Ürün eklenemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateProduct(Product product) async {
    isLoading.value = true;
    try {
      // Eski ürün bilgisini al (stok kontrolü için)
      Product? oldProduct;
      if (product.id != null) {
        oldProduct = await _productRepository.getProductById(product.id.toString());
      }

      await _productRepository.updateProduct(product);
      await fetchProducts();

      // Stok uyarısı kontrolü
      if (oldProduct != null && product.stock <= product.criticalStockLevel && oldProduct.stock > product.criticalStockLevel) {
        try {
          final notificationService = NotificationService();
          await notificationService.sendStockAlertNotification(
            productName: product.name,
            stock: product.stock,
          );
        } catch (e) {
          debugPrint('Stok uyarı bildirimi gönderilemedi: $e');
        }
      }

      Get.back();
      ErrorHandler.showSuccessMessage('Ürün başarıyla güncellendi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Ürün güncellenemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteProduct(String id) async {
    isLoading.value = true;
    try {
      await _productRepository.deleteProduct(id);
      await fetchProducts();
      ErrorHandler.showSuccessMessage('Ürün başarıyla silindi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Ürün silinemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) return [];
    
    // Bellekteki listeden arama yap (Daha hızlı ve az maliyetli)
    final lowercaseQuery = query.toLowerCase();
    return products.where((p) {
      return p.name.toLowerCase().contains(lowercaseQuery) ||
             (p.barcode != null && p.barcode!.contains(query)) ||
             (p.category != null && p.category!.toLowerCase().contains(lowercaseQuery));
    }).toList();
  }

  Future<List<Product>> getLowStockProducts(int threshold) async {
    try {
      return await _productRepository.getLowStockProducts(threshold);
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Düşük stok ürünleri alınamadı');
      return [];
    }
  }
  // Favori Ürünler
  List<Product> get favoriteProducts => products.where((p) => p.isFavorite).toList();

  Future<void> toggleFavorite(Product product) async {
    try {
      final updatedProduct = product.copyWith(isFavorite: !product.isFavorite);
      await _productRepository.updateProduct(updatedProduct);
      
      // Listeyi güncelle
      final index = products.indexWhere((p) => p.id == product.id);
      if (index != -1) {
        products[index] = updatedProduct;
      }
      
      Get.snackbar(
        'Başarılı',
        updatedProduct.isFavorite ? 'Favorilere eklendi' : 'Favorilerden çıkarıldı',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        duration: const Duration(seconds: 1),
      );
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Favori durumu güncellenemedi');
    }
  }
  // Kritik Stoktaki Ürünler
  List<Product> get criticalStockProducts => products.where((p) => p.stock <= p.criticalStockLevel).toList();

  void sortProducts(String criteria) {
    switch (criteria) {
      case 'name_asc':
        products.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'price_asc':
        products.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        products.sort((a, b) => b.price.compareTo(a.price));
        break;
      case 'stock_desc':
        products.sort((a, b) => b.stock.compareTo(a.stock));
        break;
    }
  }
}