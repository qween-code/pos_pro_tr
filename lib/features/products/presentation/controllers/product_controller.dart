import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class ProductController extends GetxController {
  final ProductRepository _productRepository = ProductRepository();
  final RxList<Product> products = <Product>[].obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    isLoading.value = true;
    try {
      final List<Product> productList = await _productRepository.getProducts();
      products.assignAll(productList);
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Ürünler yüklenemedi');
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
      if (oldProduct != null && product.stock <= 10 && oldProduct.stock > 10) {
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
    try {
      return await _productRepository.searchProducts(query);
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Arama yapılamadı');
      return [];
    }
  }

  Future<List<Product>> getLowStockProducts(int threshold) async {
    try {
      return await _productRepository.getLowStockProducts(threshold);
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Düşük stok ürünleri alınamadı');
      return [];
    }
  }
}