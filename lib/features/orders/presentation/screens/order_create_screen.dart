import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/order_controller.dart';
import '../../../products/presentation/controllers/product_controller.dart';
import '../../../customers/presentation/controllers/customer_controller.dart';
import '../../../products/data/models/product_model.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../../core/widgets/barcode_scanner_screen.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/constants/theme_constants.dart';

class OrderCreateScreen extends StatelessWidget {
  final OrderController _orderController = Get.put(OrderController());
  final ProductController _productController = Get.put(ProductController());
  final CustomerController _customerController = Get.put(CustomerController());
  final _discountController = TextEditingController();

  OrderCreateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f1): () => _orderController.setPaymentMethod('Nakit'),
        const SingleActivator(LogicalKeyboardKey.f2): () => _orderController.setPaymentMethod('Kredi Kartı'),
        const SingleActivator(LogicalKeyboardKey.f3): () => _scanBarcodeForProduct(),
        const SingleActivator(LogicalKeyboardKey.f4): () => _showCustomerSelectionDialog(),
        const SingleActivator(LogicalKeyboardKey.f5): () => _showConfirmOrderDialog(),
        const SingleActivator(LogicalKeyboardKey.f9): () => _orderController.parkOrder(),
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            title: Text(
              'Yeni Satış',
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
              IconButton(
                icon: Icon(Icons.qr_code_scanner, color: AppTheme.primary),
                onPressed: () => _scanBarcodeForProduct(),
                tooltip: 'Barkod Oku (F3)',
              ),
            ],
          ),
          body: Column(
            children: [
              // Üst Bilgi Paneli
              _buildTopPanel(),
              
              // Sepet Özeti
              _buildCartSummary(),
              
              const Divider(height: 1, color: Colors.white12),
              
              // Hızlı Satış (Favoriler)
              _buildQuickSaleArea(),
              
              // Ürün Listesi
              Expanded(
                child: _buildProductGrid(),
              ),
              
              // Alt Toplam ve Ödeme Butonu
              _buildBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Üst Bilgi Kartları (Müşteri ve Ödeme) - Compact
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildCompactInfoButton(
                  icon: Icons.person,
                  label: _orderController.selectedCustomer.value?.name ?? 'Müşteri',
                  subLabel: _orderController.selectedCustomer.value == null ? 'Seçiniz' : '',
                  color: AppTheme.secondary,
                  onTap: () => _showCustomerSelectionDialog(),
                )),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Obx(() => _buildCompactInfoButton(
                  icon: Icons.payment,
                  label: _orderController.currentPaymentMethod.value,
                  subLabel: 'Ödeme',
                  color: AppTheme.primary,
                  onTap: () => _showPaymentMethodSelectionDialog(),
                )),
              ),
            ],
          ),
          
          // Bekleyen Siparişler (Varsa)
          Obx(() {
            if (_orderController.parkedOrders.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildCompactInfoButton(
                icon: Icons.pause_circle_filled,
                label: '${_orderController.parkedOrders.length} Bekleyen',
                subLabel: 'Sipariş',
                color: Colors.orange,
                onTap: () => _showPendingOrdersDialog(),
              ),
            );
          }),

          const SizedBox(height: 8),
          
          // İndirim Alanı - Compact
          SizedBox(
            height: 40,
            child: TextField(
              controller: _discountController,
              style: const TextStyle(fontSize: 14, color: AppTheme.textPrimary),
              decoration: InputDecoration(
                labelText: 'İndirim (₺)',
                labelStyle: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                filled: true,
                fillColor: AppTheme.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
              onChanged: (value) => _orderController.setDiscount(double.tryParse(value) ?? 0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactInfoButton({
    required IconData icon,
    required String label,
    required String subLabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (subLabel.isNotEmpty)
                    Text(subLabel, style: TextStyle(color: color.withOpacity(0.8), fontSize: 10)),
                  Text(
                    label,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Eski metodu kaldırıyoruz veya dummy olarak bırakıyoruz (hata vermemesi için)
  Widget _buildInfoButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return const SizedBox.shrink(); 
  }

  Widget _buildCartSummary() {
    return Obx(() {
      if (_orderController.currentOrderItems.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.shopping_cart_outlined, size: 48, color: AppTheme.textSecondary),
              const SizedBox(height: 8),
              Text(
                'Sepet Boş',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
              ),
            ],
          ),
        );
      }

      return Column(
        children: [
          // Aksiyon Butonları
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _showManualItemDialog(),
                  icon: const Icon(Icons.add_circle_outline, color: Colors.blue),
                  label: const Text('Manuel Ekle', style: TextStyle(color: Colors.blue)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.blue.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _orderController.parkOrder(),
                  icon: const Icon(Icons.pause_circle_filled, color: Colors.orange),
                  label: const Text('Beklet', style: TextStyle(color: Colors.orange)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.orange.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _orderController.currentOrderItems.length,
              itemBuilder: (context, index) {
                final item = _orderController.currentOrderItems[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName ?? 'Ürün',
                              style: TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${item.quantity}x ₺${item.unitPrice.toStringAsFixed(2)}',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₺${item.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.remove_circle_outline, color: AppTheme.error),
                        onPressed: () => _orderController.currentOrderItems.removeAt(index),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    });
  }

  Widget _buildQuickSaleArea() {
    return Obx(() {
      if (_productController.favoriteProducts.isEmpty) return const SizedBox.shrink();
      
      return Container(
        height: 60,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _productController.favoriteProducts.length,
          itemBuilder: (context, index) {
            final product = _productController.favoriteProducts[index];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ActionChip(
                backgroundColor: AppTheme.primary.withOpacity(0.2),
                label: Text(product.name, style: TextStyle(color: AppTheme.textPrimary)),
                avatar: const Icon(Icons.star, size: 16, color: Colors.orange),
                onPressed: () => _orderController.addToOrder(product, 1),
              ),
            );
          },
        ),
      );
    });
  }

  Widget _buildProductGrid() {
    return Obx(() {
      if (_productController.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_productController.products.isEmpty) {
        return Center(
          child: Text(
            'Ürün bulunamadı',
            style: TextStyle(color: AppTheme.textSecondary),
          ),
        );
      }
      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _productController.products.length,
        itemBuilder: (context, index) {
          final Product product = _productController.products[index];
          return _buildProductCard(product);
        },
      );
    });
  }

  Widget _buildProductCard(Product product) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showQuantityDialog(product),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ürün Resmi
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Container(
                  height: 100,
                  width: double.infinity,
                  color: AppTheme.background,
                  child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                      ? Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: AppTheme.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.inventory_2,
                                size: 40,
                                color: AppTheme.primary.withOpacity(0.5),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: AppTheme.primary,
                                strokeWidth: 2,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: AppTheme.primary.withOpacity(0.1),
                          child: Icon(
                            Icons.inventory_2,
                            size: 40,
                            color: AppTheme.primary.withOpacity(0.5),
                          ),
                        ),
                ),
              ),
              // Ürün Bilgileri
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ürün Adı
                      Expanded(
                        child: Text(
                          product.name,
                          style: TextStyle(
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Fiyat ve Stok
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              '₺${product.price.toStringAsFixed(0)}',
                              style: TextStyle(
                                color: AppTheme.secondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: product.stock > 10
                                  ? Colors.greenAccent.withOpacity(0.2)
                                  : AppTheme.error.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${product.stock}',
                              style: TextStyle(
                                color: product.stock > 10 ? Colors.greenAccent : AppTheme.error,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Obx(() => Column(
            children: [
              _buildSummaryRow('Ara Toplam', 
                (_orderController.currentTotal.value + _orderController.currentDiscount.value - _orderController.currentTax.value)),
              const SizedBox(height: 4),
              _buildSummaryRow('KDV', _orderController.currentTax.value),
              if (_orderController.currentDiscount.value > 0) ...[
                const SizedBox(height: 4),
                _buildSummaryRow('İndirim', -_orderController.currentDiscount.value, isDiscount: true),
              ],
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOPLAM',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '₺${_orderController.currentTotal.value.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          )),
          const SizedBox(height: 16),
          Container(
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
              onPressed: () => _showConfirmOrderDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'SİPARİŞİ TAMAMLA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDiscount ? AppTheme.error : AppTheme.textSecondary,
            fontSize: 14,
          ),
        ),
        Text(
          '${isDiscount ? '' : '₺'}${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isDiscount ? AppTheme.error : AppTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showQuantityDialog(Product product) {
    final quantityController = TextEditingController(text: '1');
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.name,
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Fiyat: ', style: TextStyle(color: AppTheme.textSecondary)),
                  Text(
                    '₺${product.price.toStringAsFixed(2)}',
                    style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 16),
                  Text('Stok: ', style: TextStyle(color: AppTheme.textSecondary)),
                  Text(
                    '${product.stock}',
                    style: TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: quantityController,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 18),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Miktar',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.background,
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
                        final quantity = int.tryParse(quantityController.text) ?? 1;
                        if (quantity > 0 && quantity <= product.stock) {
                          Get.back();
                          _orderController.addToOrder(product, quantity);
                          Get.snackbar(
                            'Başarılı',
                            '$quantity adet ${product.name} sepete eklendi',
                            backgroundColor: AppTheme.primary.withOpacity(0.2),
                            colorText: AppTheme.textPrimary,
                          );
                        } else {
                          Get.snackbar(
                            'Hata',
                            'Geçersiz miktar',
                            backgroundColor: AppTheme.error.withOpacity(0.2),
                            colorText: AppTheme.textPrimary,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Ekle', style: TextStyle(color: Colors.black)),
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

  void _showCustomerSelectionDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Müşteri Seç',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  if (_customerController.customers.isEmpty) {
                    return Center(
                      child: Text('Müşteri bulunamadı', style: TextStyle(color: AppTheme.textSecondary)),
                    );
                  }
                  return ListView.builder(
                    itemCount: _customerController.customers.length,
                    itemBuilder: (context, index) {
                      final customer = _customerController.customers[index];
                      return ListTile(
                        title: Text(customer.name, style: TextStyle(color: AppTheme.textPrimary)),
                        subtitle: Text(customer.phone ?? '', style: TextStyle(color: AppTheme.textSecondary)),
                        onTap: () {
                          _orderController.setCustomer(customer);
                          Get.back();
                          Get.snackbar(
                            'Başarılı',
                            '${customer.name} seçildi',
                            backgroundColor: AppTheme.primary.withOpacity(0.2),
                            colorText: AppTheme.textPrimary,
                          );
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPaymentMethodSelectionDialog() {
    final paymentMethods = ['Nakit', 'Kredi Kartı', 'Banka Kartı', 'Havale'];
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ödeme Yöntemi',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ...paymentMethods.map((method) => ListTile(
                title: Text(method, style: TextStyle(color: AppTheme.textPrimary)),
                onTap: () {
                  _orderController.setPaymentMethod(method);
                  Get.back();
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _scanBarcodeForProduct() async {
    await Get.to(() => BarcodeScannerScreen(
      onBarcodeScanned: (product) {
        if (product != null) {
          _showQuantityDialog(product);
        } else {
          ErrorHandler.showInfoMessage('Barkod ile eşleşen ürün bulunamadı');
        }
      },
    ));
  }

  void _showConfirmOrderDialog() {
    if (_orderController.currentOrderItems.isEmpty) {
      Get.snackbar(
        'Hata',
        'Sepete ürün ekleyin',
        backgroundColor: AppTheme.error.withOpacity(0.2),
        colorText: AppTheme.textPrimary,
      );
      return;
    }

    _orderController.clearPayments(); // Önceki ödemeleri temizle

    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Ödeme Al',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Tutar Bilgileri
              Obx(() => Column(
                children: [
                  _buildSummaryRow('Toplam Tutar', _orderController.currentTotal.value),
                  const Divider(color: Colors.white24, height: 24),
                  _buildPaymentSummaryRow('Kalan Tutar', _orderController.remainingAmount, 
                    isDiscount: false, 
                    valueColor: _orderController.remainingAmount > 0 ? AppTheme.error : Colors.green
                  ),
                ],
              )),
              
              const SizedBox(height: 24),

              // Ödeme Yöntemleri
              Obx(() {
                if (_orderController.remainingAmount <= 0.01) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.green, size: 32),
                        const SizedBox(width: 12),
                        Text(
                          'Ödeme Tamamlandı',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildPaymentButton('Nakit', Icons.money, Colors.green)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildPaymentButton('Kredi Kartı', Icons.credit_card, Colors.blue)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _buildPaymentButton('Yemek Kartı', Icons.restaurant, Colors.orange)),
                        const SizedBox(width: 12),
                        Expanded(child: _buildPaymentButton('Veresiye', Icons.account_balance_wallet, Colors.purple)),
                      ],
                    ),
                  ],
                );
              }),

              const SizedBox(height: 24),

              // Yapılan Ödemeler Listesi
              Expanded(
                child: Obx(() => ListView.builder(
                  itemCount: _orderController.currentPayments.length,
                  itemBuilder: (context, index) {
                    final payment = _orderController.currentPayments[index];
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.check, color: Colors.green, size: 16),
                      title: Text(payment.method, style: TextStyle(color: AppTheme.textPrimary)),
                      trailing: Text(
                        '₺${payment.amount.toStringAsFixed(2)}',
                        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                      ),
                    );
                  },
                )),
              ),

              const SizedBox(height: 16),

              // Alt Butonlar
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
                    child: Obx(() => ElevatedButton(
                      onPressed: _orderController.isLoading.value
                          ? null
                          : () {
                              if (_orderController.remainingAmount > 0.01) {
                                Get.snackbar('Hata', 'Lütfen ödemeyi tamamlayın');
                                return;
                              }
                              _orderController.addOrder();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orderController.remainingAmount <= 0.01 
                            ? Colors.green 
                            : AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _orderController.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Siparişi Tamamla', style: TextStyle(color: Colors.white)),
                    )),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentButton(String label, IconData icon, Color color) {
    return ElevatedButton.icon(
      onPressed: () => _showPaymentAmountDialog(label),
      icon: Icon(icon, color: Colors.white, size: 18),
      label: Text(label, style: const TextStyle(color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showPaymentAmountDialog(String method) {
    final controller = TextEditingController(
      text: _orderController.remainingAmount.toStringAsFixed(2)
    );
    
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$method Tutarı',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: TextStyle(color: AppTheme.textPrimary, fontSize: 24),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  prefixText: '₺ ',
                  prefixStyle: TextStyle(color: AppTheme.primary, fontSize: 24),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                autofocus: true,
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
                        final amount = double.tryParse(controller.text);
                        if (amount != null && amount > 0) {
                          Get.back();
                          _orderController.addPayment(method, amount);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Ekle', style: TextStyle(color: Colors.black)),
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

  Widget _buildPaymentSummaryRow(String label, double amount, {bool isDiscount = false, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDiscount ? AppTheme.error : AppTheme.textSecondary,
            fontSize: 16,
          ),
        ),
        Text(
          '${isDiscount ? '' : '₺'}${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: valueColor ?? (isDiscount ? AppTheme.error : AppTheme.textPrimary),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  void _showPendingOrdersDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 500),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Bekleyen Siparişler',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Obx(() {
                  if (_orderController.parkedOrders.isEmpty) {
                    return Center(
                      child: Text('Bekleyen sipariş yok', style: TextStyle(color: AppTheme.textSecondary)),
                    );
                  }
                  return ListView.builder(
                    itemCount: _orderController.parkedOrders.length,
                    itemBuilder: (context, index) {
                      final pending = _orderController.parkedOrders[index];
                      return Card(
                        color: AppTheme.background,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(
                            pending.note,
                            style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            '${pending.items.length} Ürün - ₺${pending.totalAmount.toStringAsFixed(2)}\n${pending.timestamp.hour}:${pending.timestamp.minute}',
                            style: TextStyle(color: AppTheme.textSecondary),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.play_circle_fill, color: Colors.green),
                                onPressed: () => _orderController.resumeOrder(pending),
                                tooltip: 'Devam Et',
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _orderController.deletePendingOrder(pending),
                                tooltip: 'Sil',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Get.back(),
                  child: Text('Kapat', style: TextStyle(color: AppTheme.textSecondary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showManualItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Manuel Ürün Ekle',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Ürün Adı (Opsiyonel)',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                style: TextStyle(color: AppTheme.textPrimary),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Fiyat',
                  labelStyle: TextStyle(color: AppTheme.textSecondary),
                  prefixText: '₺ ',
                  prefixStyle: TextStyle(color: AppTheme.primary),
                  filled: true,
                  fillColor: AppTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
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
                        final price = double.tryParse(priceController.text);
                        if (price != null && price > 0) {
                          _orderController.addManualItem(nameController.text, price, 1);
                          Get.back();
                        } else {
                          Get.snackbar('Hata', 'Geçerli bir fiyat girin');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Ekle', style: TextStyle(color: Colors.black)),
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
}