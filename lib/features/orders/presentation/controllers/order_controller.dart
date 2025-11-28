import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/notification_service.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/repositories/product_repository.dart';
import '../../../customers/data/models/customer_model.dart';

class OrderController extends GetxController {
  final OrderRepository _orderRepository = OrderRepository();
  final ProductRepository _productRepository = ProductRepository();
  final RxList<Order> orders = <Order>[].obs;
  final RxList<OrderItem> currentOrderItems = <OrderItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxDouble currentTotal = 0.0.obs;
  final RxDouble currentTax = 0.0.obs;
  final RxDouble currentDiscount = 0.0.obs;
  final RxString currentPaymentMethod = 'Nakit'.obs;
  final Rx<Customer?> selectedCustomer = Rx<Customer?>(null);
  
  // Stok uyarı eşiği
  static const int stockAlertThreshold = 10;

  @override
  void onInit() {
    super.onInit();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    isLoading.value = true;
    try {
      final List<Order> orderList = await _orderRepository.getOrders();
      orders.assignAll(orderList);
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Siparişler yüklenemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addOrder() async {
    if (currentOrderItems.isEmpty) {
      ErrorHandler.handleValidationError('Siparişe ürün ekleyin');
      return;
    }

    isLoading.value = true;
    try {
      final Order newOrder = Order(
        customerId: selectedCustomer.value?.id.toString(),
        customerName: selectedCustomer.value?.name,
        orderDate: DateTime.now(),
        totalAmount: currentTotal.value,
        taxAmount: currentTax.value,
        discountAmount: currentDiscount.value,
        paymentMethod: currentPaymentMethod.value,
        status: 'completed',
      );

      final orderId = await _orderRepository.insertOrder(newOrder, currentOrderItems.toList());
      
      // Ürün stoklarını güncelle ve stok kontrolü yap
      await _updateProductStocks(currentOrderItems.toList());
      
      await fetchOrders();

      // Bildirim gönder
      try {
        final notificationService = NotificationService();
        await notificationService.sendOrderNotification(
          orderId: orderId,
          customerName: newOrder.customerName ?? 'Misafir',
          totalAmount: newOrder.totalAmount,
        );
      } catch (e) {
        // Bildirim hatası kritik değil, sessizce geç
        debugPrint('Bildirim gönderilemedi: $e');
      }

      // Sipariş tamamlandıktan sonra sepeti temizle
      clearOrder();

      Get.back();
      ErrorHandler.showSuccessMessage('Sipariş başarıyla oluşturuldu');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Sipariş oluşturulamadı');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> updateOrder(Order order) async {
    isLoading.value = true;
    try {
      await _orderRepository.updateOrder(order);
      await fetchOrders();
      Get.back();
      ErrorHandler.showSuccessMessage('Sipariş başarıyla güncellendi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Sipariş güncellenemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> deleteOrder(String id) async {
    isLoading.value = true;
    try {
      await _orderRepository.deleteOrder(id);
      await fetchOrders();
      ErrorHandler.showSuccessMessage('Sipariş başarıyla silindi');
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Sipariş silinemedi');
    } finally {
      isLoading.value = false;
    }
  }

  Future<List<OrderItem>> getOrderItems(String orderId) async {
    try {
      return await _orderRepository.getOrderItems(orderId);
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Sipariş öğeleri alınamadı');
      return [];
    }
  }

  // Sepet işlemleri
  void addToOrder(Product product, int quantity) {
    // Eğer ürün zaten sepette varsa miktarını güncelle
    final existingItemIndex = currentOrderItems.indexWhere((item) => item.productId == product.id.toString());

    if (existingItemIndex >= 0) {
      final existingItem = currentOrderItems[existingItemIndex];
      currentOrderItems[existingItemIndex] = OrderItem(
        id: existingItem.id,
        orderId: existingItem.orderId,
        productId: existingItem.productId,
        productName: existingItem.productName,
        quantity: existingItem.quantity + quantity,
        unitPrice: existingItem.unitPrice,
        taxRate: existingItem.taxRate,
      );
    } else {
      currentOrderItems.add(OrderItem(
        productId: product.id.toString(),
        productName: product.name,
        quantity: quantity,
        unitPrice: product.price,
        taxRate: product.taxRate,
        orderId: '', // Yeni siparişte boş olacak
      ));
    }

    calculateTotals();
  }

  void removeFromOrder(String productId) {
    currentOrderItems.removeWhere((item) => item.productId == productId);
    calculateTotals();
  }

  void updateQuantity(String productId, int newQuantity) {
    if (newQuantity <= 0) {
      removeFromOrder(productId);
      return;
    }

    final index = currentOrderItems.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      final item = currentOrderItems[index];
      currentOrderItems[index] = OrderItem(
        id: item.id,
        orderId: item.orderId,
        productId: item.productId,
        productName: item.productName,
        quantity: newQuantity,
        unitPrice: item.unitPrice,
        taxRate: item.taxRate,
      );
      calculateTotals();
    }
  }

  void calculateTotals() {
    double subtotal = 0;
    double taxTotal = 0;

    for (var item in currentOrderItems) {
      subtotal += item.totalPrice;
      taxTotal += item.totalTax;
    }

    currentTotal.value = subtotal + taxTotal - currentDiscount.value;
    currentTax.value = taxTotal;
  }

  void clearOrder() {
    currentOrderItems.clear();
    currentTotal.value = 0;
    currentTax.value = 0;
    currentDiscount.value = 0;
    currentPaymentMethod.value = 'Nakit';
    selectedCustomer.value = null;
  }

  // Ürün stoklarını güncelle ve stok uyarısı kontrolü yap
  Future<void> _updateProductStocks(List<OrderItem> items) async {
    final notificationService = NotificationService();
    
    for (var item in items) {
      try {
        // Ürünü getir
        final product = await _productRepository.getProductById(item.productId);
        if (product == null) continue;

        // Stoku güncelle
        final newStock = product.stock - item.quantity;
        if (newStock < 0) {
          ErrorHandler.handleValidationError('${product.name} için yeterli stok yok');
          continue;
        }

        // Ürünü güncelle
        final updatedProduct = Product(
          id: product.id,
          name: product.name,
          price: product.price,
          stock: newStock,
          category: product.category,
          barcode: product.barcode,
          taxRate: product.taxRate,
        );

        await _productRepository.updateProduct(updatedProduct);

        // Stok uyarısı kontrolü
        if (newStock <= stockAlertThreshold) {
          try {
            await notificationService.sendStockAlertNotification(
              productName: product.name,
              stock: newStock,
            );
          } catch (e) {
            debugPrint('Stok uyarı bildirimi gönderilemedi: $e');
          }
        }
      } catch (e) {
        debugPrint('Stok güncelleme hatası: $e');
        // Stok güncelleme hatası kritik değil, devam et
      }
    }
  }

  void setDiscount(double discount) {
    currentDiscount.value = discount;
    calculateTotals();
  }

  void setPaymentMethod(String method) {
    currentPaymentMethod.value = method;
  }

  void setCustomer(Customer? customer) {
    selectedCustomer.value = customer;
  }
}