import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../controllers/order_controller.dart';
import '../../../products/presentation/controllers/product_controller.dart';
import '../../../products/data/models/product_model.dart';
import '../../../customers/presentation/controllers/customer_controller.dart';
import '../../../customers/data/models/customer_model.dart';
import '../../../../core/widgets/barcode_scanner_screen.dart';
import '../../../../core/utils/error_handler.dart';
import '../../../../core/constants/theme_constants.dart';
import 'order_receipt_screen.dart';

class OrderCreateScreen extends StatefulWidget {
  const OrderCreateScreen({super.key});

  @override
  State<OrderCreateScreen> createState() => _OrderCreateScreenState();
}

class _OrderCreateScreenState extends State<OrderCreateScreen> {
  final orderController = Get.find<OrderController>();
  final productController = Get.find<ProductController>();
  
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: _buildAppBar(),
      body: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text(
        'Yeni Satış',
        style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
      ),
      backgroundColor: AppTheme.surface,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: AppTheme.primary),
      actions: [
        IconButton(
          icon: const Icon(Icons.qr_code_scanner),
          onPressed: _scanBarcodeForProduct,
          tooltip: 'Barkod Oku',
        ),
        Obx(() {
          final parkedCount = orderController.parkedOrders.length;
          return Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.pause_circle_outline),
                onPressed: _showPendingOrdersDialog,
                tooltip: 'Bekleyen Siparişler',
              ),
              if (parkedCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.error,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '$parkedCount',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          );
        }),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTabletLayout() {
    return Row(
      children: [
        // Left: Products (60%)
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildQuickActionsBar(),
              _buildSearchBar(),
              Expanded(child: _buildProductGrid()),
            ],
          ),
        ),
        // Right: Cart (40%)
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(-2, 0)),
              ],
            ),
            child: _buildCart(),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Column(
      children: [
        _buildQuickActionsBar(),
        _buildSearchBar(),
        Expanded(child: _buildProductGrid()),
        _buildMobileCartSummary(),
      ],
    );
  }

  Widget _buildQuickActionsBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildQuickButton(
              icon: Icons.person_add_outlined,
              label: 'Müşteri',
              onTap: _showCustomerSelectionDialog,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickButton(
              icon: Icons.add_box_outlined,
              label: 'Manuel',
              onTap: _showManualItemDialog,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _buildQuickButton(
              icon: Icons.pause_circle_outlined,
              label: 'Park',
              onTap: () {
                orderController.parkOrder();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: AppTheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        style: const TextStyle(color: AppTheme.textPrimary),
        decoration: InputDecoration(
          hintText: 'Ürün ara...',
          hintStyle: const TextStyle(color: AppTheme.textSecondary),
          prefixIcon: const Icon(Icons.search, color: AppTheme.primary),
          filled: true,
          fillColor: AppTheme.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase();
          });
        },
      ),
    );
  }

  Widget _buildProductGrid() {
    return Obx(() {
      var products = productController.products.toList();
      
      // Apply search filter
      if (_searchQuery.isNotEmpty) {
        products = products.where((p) {
          return p.name.toLowerCase().contains(_searchQuery) ||
                 (p.barcode != null && p.barcode!.contains(_searchQuery)) ||
                 (p.category != null && p.category!.toLowerCase().contains(_searchQuery));
        }).toList();
      }

      if (products.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
              const SizedBox(height: 16),
              const Text('Ürün bulunamadı', style: TextStyle(color: AppTheme.textSecondary)),
            ],
          ),
        );
      }

      return GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return _buildProductCard(products[index]);
        },
      );
    });
  }

  Widget _buildProductCard(Product product) {
    return InkWell(
      onTap: () => _showQuantityDialog(product),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image
            Container(
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primary.withOpacity(0.2), AppTheme.secondary.withOpacity(0.1)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              clipBehavior: Clip.hardEdge,
              child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                  ? Image.network(
                      product.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: AppTheme.primary.withOpacity(0.7),
                        ),
                      ),
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                : null,
                            color: AppTheme.primary,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.inventory_2_outlined,
                        size: 48,
                        color: AppTheme.primary.withOpacity(0.7),
                      ),
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₺${product.price.toStringAsFixed(2)}',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: product.stock > 10
                                ? AppTheme.primary.withOpacity(0.2)
                                : AppTheme.error.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${product.stock}',
                            style: TextStyle(
                              color: product.stock > 10 ? AppTheme.primary : AppTheme.error,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
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
    );
  }

  Widget _buildCart() {
    return Column(
      children: [
        // Customer Info
        Obx(() {
          final customer = orderController.selectedCustomer.value;
          final hasCustomer = customer != null;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: hasCustomer
                  ? LinearGradient(
                      colors: [AppTheme.primary.withOpacity(0.15), AppTheme.primary.withOpacity(0.05)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: hasCustomer ? null : AppTheme.background,
              border: Border(bottom: BorderSide(color: AppTheme.primary.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: hasCustomer ? Border.all(color: AppTheme.primary, width: 2) : null,
                  ),
                  child: CircleAvatar(
                    backgroundColor: hasCustomer ? AppTheme.primary.withOpacity(0.3) : AppTheme.primary.withOpacity(0.2),
                    child: Icon(
                      hasCustomer ? Icons.person : Icons.person_outline,
                      color: AppTheme.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            customer?.name ?? 'Müşteri seçilmedi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: hasCustomer ? AppTheme.primary : AppTheme.textSecondary,
                            ),
                          ),
                          if (hasCustomer) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppTheme.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                '✓',
                                style: TextStyle(color: AppTheme.background, fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (customer != null)
                        Text(
                          customer.phone ?? '',
                          style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20, color: AppTheme.primary),
                  onPressed: _showCustomerSelectionDialog,
                ),
              ],
            ),
          );
        }),

        // Cart Items
        Expanded(
          child: Obx(() {
            final items = orderController.currentOrderItems;
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 64, color: AppTheme.textSecondary.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    const Text('Sepet boş', style: TextStyle(color: AppTheme.textSecondary)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                return Dismissible(
                  key: Key(item.productId),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 20),
                    decoration: BoxDecoration(
                      color: AppTheme.error,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (direction) {
                    orderController.removeFromOrder(item.productId);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: AppTheme.cardGradient,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName ?? 'Ürün',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '₺${item.unitPrice.toStringAsFixed(2)} × ${item.quantity}',
                                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 20),
                              color: AppTheme.error,
                              onPressed: () {
                                if (item.quantity > 1) {
                                  orderController.updateQuantity(item.productId, item.quantity - 1);
                                } else {
                                  orderController.removeFromOrder(item.productId);
                                }
                              },
                            ),
                            Text(
                              '${item.quantity}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 20),
                              color: AppTheme.primary,
                              onPressed: () {
                                orderController.updateQuantity(item.productId, item.quantity + 1);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₺${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }),
        ),

        // Summary & Checkout
        _buildCartSummary(),
      ],
    );
  }

  Widget _buildCartSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.cardGradient,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Column(
        children: [
          Obx(() => _buildSummaryRow('Ara Toplam', orderController.currentTotal.value)),
          Obx(() => _buildSummaryRow('KDV', orderController.currentTax.value)),
          Obx(() {
            if (orderController.currentDiscount.value > 0) {
              return _buildSummaryRow('İndirim', -orderController.currentDiscount.value, isDiscount: true);
            }
            return const SizedBox.shrink();
          }),
          const Divider(height: 24, color: AppTheme.primary),
          Obx(() {
            final total = orderController.currentTotal.value;
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('TOPLAM', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                Text(
                  '₺${total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                if (orderController.currentOrderItems.isEmpty) {
                  ErrorHandler.handleValidationError('Sepet boş!');
                  return;
                }
                _showConfirmOrderDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: AppTheme.background,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: const Text(
                'ÖDEME AL',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileCartSummary() {
    return Obx(() {
      final itemCount = orderController.currentOrderItems.length;
      final total = orderController.currentTotal.value;

      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppTheme.cardGradient,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, -2)),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$itemCount Ürün', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(
                      '₺${total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.primary),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (itemCount == 0) {
                    ErrorHandler.handleValidationError('Sepet boş!');
                    return;
                  }
                  _showMobileCartDialog();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.background,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Sepete Git', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildSummaryRow(String label, double amount, {bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
          Text(
            '₺${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isDiscount ? AppTheme.error : AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  void _showMobileCartDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.all(16),
        child: SizedBox(
          height: Get.height * 0.8,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: _buildCart(),
          ),
        ),
      ),
    );
  }

  void _showQuantityDialog(Product product) {
    final quantityController = TextEditingController(text: '1');
    
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                product.name,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '₺${product.price.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, color: AppTheme.primary, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Miktar',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  suffixText: 'Adet',
                  suffixStyle: const TextStyle(color: AppTheme.textSecondary),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('İptal', style: TextStyle(color: AppTheme.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final quantity = int.tryParse(quantityController.text) ?? 1;
                        if (quantity > 0) {
                          orderController.addToOrder(product, quantity);
                          Get.back();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Ekle'),
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
    final customerController = Get.find<CustomerController>();
    customerController.fetchCustomers();
    final RxString searchQuery = ''.obs;

    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SizedBox(
          width: 400,
          height: 600,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text('Müşteri Seç', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.primary),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                child: TextField(
                  onChanged: (val) => searchQuery.value = val.toLowerCase(),
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'İsim veya Telefon ile ara...',
                    hintStyle: const TextStyle(color: AppTheme.textSecondary),
                    prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondary),
                    filled: true,
                    fillColor: AppTheme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Divider(height: 1, color: AppTheme.primary.withOpacity(0.2)),
              Expanded(
                child: Obx(() {
                  var customers = customerController.customers.toList();
                  
                  if (searchQuery.value.isNotEmpty) {
                    customers = customers.where((c) => 
                      c.name.toLowerCase().contains(searchQuery.value) ||
                      (c.phone != null && c.phone!.contains(searchQuery.value))
                    ).toList();
                  }

                  if (customers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Müşteri bulunamadı', style: TextStyle(color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          if (searchQuery.value.isNotEmpty)
                            TextButton.icon(
                              onPressed: () {
                                // Hızlı müşteri ekleme özelliği eklenebilir
                                // Şimdilik sadece kapatıyoruz
                                Get.back();
                                // TODO: Navigate to add customer screen with pre-filled name
                              }, 
                              icon: const Icon(Icons.person_add),
                              label: const Text('Yeni Müşteri Ekle'),
                            ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: customers.length,
                    itemBuilder: (context, index) {
                      final customer = customers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.primary.withOpacity(0.2),
                          child: Text(
                            customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                            style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(customer.name, style: const TextStyle(color: AppTheme.textPrimary)),
                        subtitle: Text(customer.phone ?? '', style: const TextStyle(color: AppTheme.textSecondary)),
                        onTap: () {
                          orderController.setCustomer(customer);
                          Get.back();
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

  void _showConfirmOrderDialog() {
    // Reset payments initially
    orderController.clearPayments();
    
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SizedBox(
          width: 450,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                const Text(
                  'Ödeme Ekranı',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                const SizedBox(height: 24),
                
                // Totals
                Obx(() {
                  final total = orderController.currentTotal.value;
                  final remaining = orderController.remainingAmount;
                  
                  return Column(
                    children: [
                      _buildInfoRow('Toplam Tutar', '₺${total.toStringAsFixed(2)}', isBold: true),
                      const SizedBox(height: 8),
                      _buildInfoRow('Kalan Tutar', '₺${remaining.toStringAsFixed(2)}', 
                        color: remaining > 0.01 ? AppTheme.error : AppTheme.primary, isBold: true, fontSize: 20),
                    ],
                  );
                }),
                
                const Divider(height: 32),
                
                // Payment List
                Flexible(
                  child: Obx(() {
                    final payments = orderController.currentPayments;
                    if (payments.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Text('Henüz ödeme eklenmedi', style: TextStyle(color: AppTheme.textSecondary)),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      itemCount: payments.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final payment = payments[index];
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.background,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(payment.method, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                              Row(
                                children: [
                                  Text('₺${payment.amount.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textPrimary)),
                                  const SizedBox(width: 8),
                                  InkWell(
                                    onTap: () {
                                      orderController.clearPayments(); // Simple reset for now
                                    },
                                    child: const Icon(Icons.close, size: 16, color: AppTheme.error),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ),
                
                const SizedBox(height: 24),
                
                // Payment Buttons
                Obx(() {
                  final remaining = orderController.remainingAmount;
                  if (remaining <= 0.01) return const SizedBox.shrink();
                  
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildPaymentActionButton('Nakit', Icons.money, AppTheme.primary, remaining)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildPaymentActionButton('Kredi Kartı', Icons.credit_card, AppTheme.secondary, remaining)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(child: _buildPaymentActionButton('Yemek Kartı', Icons.restaurant, Colors.orange, remaining)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildPaymentActionButton('Veresiye', Icons.account_balance_wallet, Colors.red, remaining)),
                        ],
                      ),
                    ],
                  );
                }),
                
                const SizedBox(height: 24),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Get.back(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('İptal', style: TextStyle(color: AppTheme.primary)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Obx(() {
                        final remaining = orderController.remainingAmount;
                        final isComplete = remaining <= 0.01;
                        
                        return ElevatedButton(
                          onPressed: isComplete ? () async {
                            final newOrder = await orderController.addOrder();
                            if (newOrder != null) {
                              // Önce bu ekranı kapat
                              Get.back();
                              // Sonra fiş ekranını aç
                              Get.to(() => OrderReceiptScreen(order: newOrder));
                            }
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.background,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            disabledBackgroundColor: Colors.grey.shade300,
                          ),
                          child: const Text('Siparişi Tamamla', style: TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }),
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

  Widget _buildPaymentActionButton(String label, IconData icon, Color color, double maxAmount) {
    return ElevatedButton.icon(
      onPressed: () {
        _showAmountInputDialog(label, maxAmount);
      },
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showAmountInputDialog(String method, double maxAmount) {
    final controller = TextEditingController(text: maxAmount.toStringAsFixed(2));
    
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$method Tutarı', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  suffixText: '₺',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppTheme.background,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Get.back(), 
                    child: const Text('İptal', style: TextStyle(color: AppTheme.textSecondary))
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(controller.text.replaceAll(',', '.')) ?? 0.0;
                      if (amount > 0 && amount <= maxAmount + 0.01) {
                        orderController.addPayment(method, amount);
                        Get.back();
                      } else {
                        ErrorHandler.handleValidationError('Geçersiz tutar!');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: AppTheme.background,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Ekle'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isBold = false, Color? color, double? fontSize}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: AppTheme.textSecondary, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        Text(value, style: TextStyle(
          color: color ?? AppTheme.textPrimary, 
          fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          fontSize: fontSize,
        )),
      ],
    );
  }

  void _scanBarcodeForProduct() {
    Get.to(() => BarcodeScannerScreen(
      onBarcodeScanned: (product) {
        Get.back();
        if (product != null) {
          _showQuantityDialog(product);
        } else {
          ErrorHandler.handleValidationError('Ürün bulunamadı!');
        }
      },
    ));
  }

  void _showPendingOrdersDialog() {
    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SizedBox(
          width: 400,
          height: 500,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    const Text('Bekleyen Siparişler', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppTheme.primary),
                      onPressed: () => Get.back(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: AppTheme.primary.withOpacity(0.2)),
              Expanded(
                child: Obx(() {
                  final orders = orderController.parkedOrders;
                  if (orders.isEmpty) {
                    return const Center(child: Text('Bekleyen sipariş yok', style: TextStyle(color: AppTheme.textSecondary)));
                  }

                  return ListView.builder(
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Color(0xFFFFA500),
                          child: Icon(Icons.pause, color: AppTheme.background),
                        ),
                        title: Text(order.note, style: const TextStyle(color: AppTheme.textPrimary)),
                        subtitle: Text('${order.items.length} ürün - ₺${order.totalAmount.toStringAsFixed(2)}', style: const TextStyle(color: AppTheme.textSecondary)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: AppTheme.error),
                          onPressed: () {
                            orderController.deletePendingOrder(order);
                          },
                        ),
                        onTap: () {
                          orderController.resumeOrder(order);
                          Get.back();
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

  void _showManualItemDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final quantityController = TextEditingController(text: '1');

    Get.dialog(
      Dialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Manuel Ürün Ekle', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Ürün Adı',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Fiyat',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  prefixText: '₺',
                  prefixStyle: const TextStyle(color: AppTheme.textPrimary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppTheme.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Miktar',
                  labelStyle: const TextStyle(color: AppTheme.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.primary),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('İptal', style: TextStyle(color: AppTheme.primary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final name = nameController.text;
                        final price = double.tryParse(priceController.text) ?? 0.0;
                        final quantity = int.tryParse(quantityController.text) ?? 1;

                        if (name.isNotEmpty && price > 0 && quantity > 0) {
                          orderController.addManualItem(name, price, quantity);
                          Get.back();
                        } else {
                          ErrorHandler.handleValidationError('Lütfen tüm alanları doldurun!');
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: AppTheme.background,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Ekle'),
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