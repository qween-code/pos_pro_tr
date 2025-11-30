import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/database/database_instance.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/hybrid_order_repository.dart';
import '../../../products/data/models/product_model.dart';
import '../../../products/data/repositories/hybrid_product_repository.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../customers/data/repositories/hybrid_customer_repository.dart';
import '../../../register/presentation/controllers/register_controller.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/services/pdf_service.dart';
import '../../../../core/services/transaction_service.dart';

class OrderController extends GetxController {
  late final HybridOrderRepository _orderRepository;
  late final HybridCustomerRepository _customerRepository;
  late final HybridProductRepository _productRepository;
  
  final PdfService _pdfService = PdfService();

  final RxList<Order> orders = <Order>[].obs;
  final RxList<OrderItem> currentOrderItems = <OrderItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxDouble currentTotal = 0.0.obs;
  final RxDouble currentTax = 0.0.obs;
  final RxDouble currentDiscount = 0.0.obs;
  final RxString currentPaymentMethod = 'Nakit'.obs;
  final Rx<Customer?> selectedCustomer = Rx<Customer?>(null);
  
  @override
  void onInit() {
    super.onInit();
    _orderRepository = HybridOrderRepository(localDb: db, firestore: firestore);
    _customerRepository = HybridCustomerRepository(localDb: db, firestore: firestore);
    _productRepository = HybridProductRepository(localDb: db, firestore: firestore);
  }

  @override
  void onClose() {
    _orderRepository.dispose();
    _customerRepository.dispose();
    _productRepository.dispose();
    super.onClose();
  }

  
  // Stok uyarı eşiği
  static const int stockAlertThreshold = 10;

  // Bekleyen Siparişler (Park Edilenler)
  final RxList<PendingOrder> parkedOrders = <PendingOrder>[].obs;

  @override
  void onReady() {
    super.onReady();
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    isLoading.value = true;
    try {
      final List<Order> orderList = await _orderRepository.getOrders();
      orders.assignAll(orderList);
    } catch (e) {
      debugPrint('Siparişler yüklenemedi: $e');
      orders.clear();
    } finally {
      isLoading.value = false;
    }
  }

  // Parçalı Ödeme
  final RxList<PaymentDetail> currentPayments = <PaymentDetail>[].obs;

  double get remainingAmount {
    double paid = currentPayments.fold(0, (sum, p) => sum + p.amount);
    return currentTotal.value - paid;
  }

  void addPayment(String method, double amount) {
    if (amount <= 0) return;
    // Küçük küsurat hatalarını önlemek için epsilon kullanabiliriz ama şimdilik basit tutalım
    if (amount > remainingAmount + 0.01) { 
      ErrorHandler.handleValidationError('Kalan tutardan fazla ödeme yapılamaz');
      return;
    }
    
    currentPayments.add(PaymentDetail(method: method, amount: amount));
  }
  
  void clearPayments() {
    currentPayments.clear();
  }

  Future<void> addOrder() async {
    // 1. Kasa Kontrolü
    final registerController = Get.isRegistered<RegisterController>() 
        ? Get.find<RegisterController>() 
        : Get.put(RegisterController());
        
    if (registerController.currentRegister.value == null) {
      ErrorHandler.handleValidationError('Satış yapabilmek için önce KASA AÇMALISINIZ!');
      return;
    }

    if (currentOrderItems.isEmpty) {
      ErrorHandler.handleValidationError('Siparişe ürün ekleyin');
      return;
    }
    
    // Parçalı ödeme kontrolü
    if (currentPayments.isNotEmpty && remainingAmount > 0.01) {
       ErrorHandler.handleValidationError('Ödeme tamamlanmadı. Kalan: ₺${remainingAmount.toStringAsFixed(2)}');
       return;
    }

    isLoading.value = true;
    try {
      // Ödeme listesini hazırla
      List<PaymentDetail> finalPayments = [];
      if (currentPayments.isNotEmpty) {
        finalPayments = List.from(currentPayments);
      } else {
        // Tek ödeme
        finalPayments.add(PaymentDetail(
          method: currentPaymentMethod.value, 
          amount: currentTotal.value
        ));
      }


      // Mevcut kasiyeri al (kasayı açan kişi bilgisi)
      final currentRegister = registerController.currentRegister.value;
      final cashierName = currentRegister?.userName ?? 'Bilinmeyen';
      final cashierId = currentRegister?.userId ?? '';
      
      // Branch bilgisi için AuthController kullan
      final authController = Get.find<AuthController>();
      final currentUser = authController.currentUser.value;
      
      final Order newOrder = Order(
        customerId: selectedCustomer.value?.id.toString(),
        customerName: selectedCustomer.value?.name,
        cashierName: cashierName,
        cashierId: cashierId,
        branchId: currentUser?.region ?? currentRegister?.id ?? '',
        orderDate: DateTime.now(),
        totalAmount: currentTotal.value,
        taxAmount: currentTax.value,
        discountAmount: currentDiscount.value,
        paymentMethod: finalPayments.length > 1 ? 'Parçalı' : finalPayments.first.method,
        status: 'completed',
        payments: finalPayments,
        items: currentOrderItems.toList(),
      );

      final orderId = await _orderRepository.createOrder(newOrder);
      
      // 2. Kasa Toplamlarını Güncelle (Her ödeme tipi için ayrı ayrı)
      for (var payment in finalPayments) {
        String paymentMethodKey = 'other';
        if (payment.method.toLowerCase().contains('nakit')) {
          paymentMethodKey = 'cash';
        } else if (payment.method.toLowerCase().contains('kart') || 
                   payment.method.toLowerCase().contains('kredi')) {
          paymentMethodKey = 'card';
        } else if (payment.method.toLowerCase().contains('veresiye')) {
          // Veresiye İşlemi: Müşteri bakiyesini artır
          if (newOrder.customerId != null) {
            await _customerRepository.updateBalance(newOrder.customerId!, payment.amount);
          }
          // Veresiye 'other' satış olarak kaydedilir (Ciroya dahil, kasaya dahil değil - RegisterController mantığına göre)
          paymentMethodKey = 'other';
        }
        
        await registerController.updateSales(payment.amount, paymentMethodKey);
      }
      
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
        debugPrint('Bildirim gönderilemedi: $e');
      }

      // Sipariş tamamlandıktan sonra sepeti temizle
      // Sipariş tamamlandıktan sonra sepeti temizle
      clearOrder();

      Get.back(); // Ödeme dialogunu kapat
      
      // Başarı dialogu göster
      _showSuccessDialog(newOrder.copyWith(id: orderId));
      
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Sipariş oluşturulamadı');
    } finally {
      isLoading.value = false;
    }
  }

  void _showSuccessDialog(Order order) {
    Get.defaultDialog(
      title: 'Sipariş Başarılı',
      titleStyle: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
      content: Column(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 64),
          SizedBox(height: 16),
          Text(
            'Sipariş #${order.id?.substring(0, 8) ?? "---"} oluşturuldu.',
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8),
          Text(
            'Tutar: ₺${order.totalAmount.toStringAsFixed(2)}',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(),
          child: Text('Kapat', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Get.back();
            printReceipt(order);
          },
          icon: Icon(Icons.print, color: Colors.white),
          label: Text('Fiş Yazdır', style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
        ),
      ],
    );
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
      final order = await _orderRepository.getOrderById(orderId);
      return order?.items ?? [];
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Sipariş öğeleri alınamadı');
      return [];
    }
  }

  // Sepet işlemleri
  void addToOrder(Product product, int quantity) {
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
        orderId: '',
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

  void addManualItem(String name, double price, int quantity) {
    currentOrderItems.add(OrderItem(
      productId: 'manual_item_${DateTime.now().millisecondsSinceEpoch}', // Benzersiz ID
      productName: name.isEmpty ? 'Muhtelif Ürün' : name,
      quantity: quantity,
      unitPrice: price,
      taxRate: 0.18, // Varsayılan KDV
      orderId: '',
    ));
    calculateTotals();
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

  Future<void> _updateProductStocks(List<OrderItem> items) async {
    final notificationService = NotificationService();
    
    for (var item in items) {
      try {
        final product = await _productRepository.getProductById(item.productId);
        if (product == null) continue;

        final newStock = product.stock - item.quantity;
        if (newStock < 0) {
          ErrorHandler.handleValidationError('${product.name} için yeterli stok yok');
          continue;
        }

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

  // --- Bekleyen Sipariş (Park Et) İşlemleri ---

  void parkOrder() {
    if (currentOrderItems.isEmpty) {
      ErrorHandler.handleValidationError('Beklemeye almak için sepet boş olamaz');
      return;
    }

    final pending = PendingOrder(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      items: List.from(currentOrderItems),
      customer: selectedCustomer.value,
      totalAmount: currentTotal.value,
      note: 'Bekleyen Sipariş #${parkedOrders.length + 1}',
    );

    parkedOrders.add(pending);
    clearOrder();
    Get.snackbar('Başarılı', 'Sipariş beklemeye alındı',
        backgroundColor: Colors.orange, colorText: Colors.white);
  }

  void resumeOrder(PendingOrder pending) {
    if (currentOrderItems.isNotEmpty) {
      Get.defaultDialog(
        title: 'Sepet Dolu',
        middleText: 'Mevcut sepet silinecek. Devam edilsin mi?',
        textConfirm: 'EVET',
        textCancel: 'İPTAL',
        confirmTextColor: Colors.white,
        onConfirm: () {
          Get.back();
          _loadPendingOrder(pending);
        },
      );
    } else {
      _loadPendingOrder(pending);
    }
  }

  void _loadPendingOrder(PendingOrder pending) {
    currentOrderItems.assignAll(pending.items);
    selectedCustomer.value = pending.customer;
    calculateTotals();
    parkedOrders.remove(pending);
    Get.back(); // Dialog varsa kapat
    Get.snackbar('Başarılı', 'Sipariş geri yüklendi',
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  void deletePendingOrder(PendingOrder pending) {
    parkedOrders.remove(pending);
  }



  Future<void> refundOrderItems(Order order, Map<String, int> refundQuantities) async {
    isLoading.value = true;
    try {
      final registerController = Get.isRegistered<RegisterController>() 
          ? Get.find<RegisterController>() 
          : Get.put(RegisterController());

      if (registerController.currentRegister.value == null) {
        ErrorHandler.handleValidationError('İade işlemi için kasa açık olmalıdır');
        return;
      }

      double totalRefundAmount = 0;
      bool allItemsRefunded = true;
      
      // Sipariş öğelerini al
      final orderItems = await getOrderItems(order.id!);
      
      // Transaction Service ile atomik işlem
      final transactionService = TransactionService();
      await transactionService.processRefund(
        order: order,
        refundQuantities: refundQuantities,
        orderItems: orderItems,
      );

      // Kasa Güncelleme (Transaction dışında - Opsiyonel)
      if (totalRefundAmount > 0) {
        String paymentMethodKey = 'cash';
        if (order.paymentMethod?.toLowerCase().contains('kart') == true) {
          paymentMethodKey = 'card';
        }
        await registerController.updateSales(-totalRefundAmount, paymentMethodKey);
      }
      
      await fetchOrders();
      Get.back(); // Dialog kapat
      ErrorHandler.showSuccessMessage('İade işlemi başarıyla tamamlandı. Tutar: ₺${totalRefundAmount.toStringAsFixed(2)}');

    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'İade işlemi başarısız');
    } finally {
      isLoading.value = false;
    }
  }
  Future<void> printReceipt(Order order) async {
    try {
      await _pdfService.printOrderReceipt(order);
    } catch (e) {
      ErrorHandler.handleApiError(e, customMessage: 'Fiş yazdırılamadı');
    }
  }
}

class PendingOrder {
  final String id;
  final DateTime timestamp;
  final List<OrderItem> items;
  final Customer? customer;
  final double totalAmount;
  final String note;

  PendingOrder({
    required this.id,
    required this.timestamp,
    required this.items,
    this.customer,
    required this.totalAmount,
    required this.note,
  });
}