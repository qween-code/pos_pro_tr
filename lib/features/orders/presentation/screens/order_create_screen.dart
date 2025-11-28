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
    return Scaffold(
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
            tooltip: 'Barkod Oku',
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
          
          // Ürün Listesi
          Expanded(
            child: _buildProductGrid(),
          ),
          
          // Alt Toplam ve Ödeme Butonu
          _buildBottomBar(),
        ],
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
          Row(
            children: [
              Expanded(
                child: Obx(() => _buildInfoButton(
                  icon: Icons.person_outline,
                  label: _orderController.selectedCustomer.value?.name ?? 'Müşteri Seç',
                  color: AppTheme.secondary,
                  onTap: () => _showCustomerSelectionDialog(),
                )),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Obx(() => _buildInfoButton(
                  icon: Icons.payment,
                  label: _orderController.currentPaymentMethod.value,
                  color: AppTheme.primary,
                  onTap: () => _showPaymentMethodSelectionDialog(),
                )),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _discountController,
            style: TextStyle(color: AppTheme.textPrimary),
            decoration: InputDecoration(
              labelText: 'İndirim',
              labelStyle: TextStyle(color: AppTheme.textSecondary),
              prefixText: '₺ ',
              prefixStyle: TextStyle(color: AppTheme.primary),
              filled: true,
              fillColor: AppTheme.background,
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
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
            ],
            onChanged: (value) {
              _orderController.setDiscount(double.tryParse(value) ?? 0);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
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

      return Container(
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
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.inventory_2, color: AppTheme.primary, size: 24),
                ),
                const SizedBox(height: 8),
                Text(
                  product.name,
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₺${product.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: product.stock > 10
                            ? Colors.greenAccent.withOpacity(0.1)
                            : AppTheme.error.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Stok: ${product.stock}',
                        style: TextStyle(
                          color: product.stock > 10 ? Colors.greenAccent : AppTheme.error,
                          fontSize: 11,
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

    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.check_circle_outline, size: 64, color: AppTheme.primary),
              const SizedBox(height: 16),
              Text(
                'Siparişi Onayla',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Obx(() => Column(
                children: [
                  _buildSummaryRow('Toplam', _orderController.currentTotal.value),
                  _buildSummaryRow('Ödeme', 0, isDiscount: false),
                ],
              )),
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
                    child: Obx(() => ElevatedButton(
                      onPressed: _orderController.isLoading.value
                          ? null
                          : () {
                              Get.back();
                              _orderController.addOrder();
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _orderController.isLoading.value
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Onayla', style: TextStyle(color: Colors.black)),
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
}