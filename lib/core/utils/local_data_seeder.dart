import 'dart:math';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../features/products/data/models/product_model.dart';
import '../../features/products/data/repositories/hybrid_product_repository.dart';
import '../../features/customers/data/models/customer_model.dart';
import '../../features/customers/data/repositories/hybrid_customer_repository.dart';
import '../../features/orders/data/models/order_model.dart';
import '../../features/orders/data/repositories/hybrid_order_repository.dart';
import '../../features/auth/data/models/user_model.dart';
import '../../features/auth/data/repositories/hybrid_user_repository.dart';
import '../database/database_instance.dart';

class LocalDataSeeder {
  late final HybridProductRepository _productRepository;
  late final HybridCustomerRepository _customerRepository;
  late final HybridOrderRepository _orderRepository;
  late final HybridUserRepository _userRepository;

  LocalDataSeeder() {
    final dbInstance = Get.find<DatabaseInstance>();
    // Windows'ta firestore null olduğu için sadece local çalışır
    _productRepository = HybridProductRepository(localDb: dbInstance.database, firestore: null);
    _customerRepository = HybridCustomerRepository(localDb: dbInstance.database, firestore: null);
    _orderRepository = HybridOrderRepository(localDb: dbInstance.database, firestore: null);
    _userRepository = HybridUserRepository(localDb: dbInstance.database, firestore: null);
  }

  Future<void> seedAll() async {
    debugPrint('🌱 Local Data Seeding Başlatılıyor...');
    
    await _seedUsers();
    await _seedProducts();
    await _seedCustomers();
    await _seedOrders();
    
    debugPrint('✅ Local Data Seeding Tamamlandı!');
  }

  Future<void> _seedUsers() async {
    // HybridUserRepository'de toplu get olmadığı için doğrudan eklemeyi deniyoruz (insertOrReplace)
    debugPrint('👤 Kullanıcılar oluşturuluyor...');
    final cashier = UserModel(
      id: 'cashier_1',
      email: 'kasiyer@pospro.com',
      name: 'Ahmet Yılmaz',
      role: 'cashier',
      region: 'Ana Şube',
    );
    await _userRepository.saveUser(cashier);
  }

  Future<void> _seedProducts() async {
    final products = await _productRepository.getProducts();
    if (products.isNotEmpty) return;

    debugPrint('📦 Ürünler oluşturuluyor...');
    final demoProducts = [
      Product(
        name: 'iPhone 15 Pro',
        barcode: '869000000001',
        price: 64999.0,
        stock: 15,
        category: 'Elektronik',
        description: '256GB Titanyum',
        taxRate: 0.20,
      ),
      Product(
        name: 'Samsung S24 Ultra',
        barcode: '869000000002',
        price: 59999.0,
        stock: 10,
        category: 'Elektronik',
        description: '512GB Siyah',
        taxRate: 0.20,
      ),
      Product(
        name: 'MacBook Air M2',
        barcode: '869000000003',
        price: 42999.0,
        stock: 5,
        category: 'Bilgisayar',
        description: '13 inç Uzay Grisi',
        taxRate: 0.20,
      ),
      Product(
        name: 'AirPods Pro 2',
        barcode: '869000000004',
        price: 8999.0,
        stock: 50,
        category: 'Aksesuar',
        description: 'USB-C MagSafe',
        taxRate: 0.20,
      ),
      Product(
        name: 'Logitech MX Master 3S',
        barcode: '869000000005',
        price: 3499.0,
        stock: 25,
        category: 'Aksesuar',
        description: 'Ergonomik Mouse',
        taxRate: 0.20,
      ),
      Product(
        name: 'Sony WH-1000XM5',
        barcode: '869000000006',
        price: 12999.0,
        stock: 8,
        category: 'Elektronik',
        description: 'Gürültü Engelleyici Kulaklık',
        taxRate: 0.20,
      ),
      Product(
        name: 'iPad Air 5',
        barcode: '869000000007',
        price: 24999.0,
        stock: 12,
        category: 'Tablet',
        description: '64GB Wi-Fi Mavi',
        taxRate: 0.20,
      ),
       Product(
        name: 'USB-C Kablo 2m',
        barcode: '869000000008',
        price: 499.0,
        stock: 100,
        category: 'Aksesuar',
        description: 'Örgülü Hızlı Şarj',
        taxRate: 0.20,
      ),
    ];

    for (var p in demoProducts) {
      await _productRepository.insertProduct(p);
    }
  }

  Future<void> _seedCustomers() async {
    final customers = await _customerRepository.getCustomers();
    if (customers.isNotEmpty) return;

    debugPrint('👥 Müşteriler oluşturuluyor...');
    final demoCustomers = [
      Customer(
        name: 'Mehmet Demir',
        phone: '0532 100 0001',
        email: 'mehmet@gmail.com',
        address: 'İstanbul, Kadıköy',
        balance: 0,
      ),
      Customer(
        name: 'Ayşe Kaya',
        phone: '0532 100 0002',
        email: 'ayse@hotmail.com',
        address: 'İzmir, Karşıyaka',
        balance: -1500, // Alacaklı
      ),
      Customer(
        name: 'Ali Yılmaz',
        phone: '0532 100 0003',
        email: 'ali@yahoo.com',
        address: 'Ankara, Çankaya',
        balance: 5000, // Borçlu
      ),
    ];

    for (var c in demoCustomers) {
      await _customerRepository.addCustomer(c);
    }
  }

  Future<void> _seedOrders() async {
    final orders = await _orderRepository.getOrders();
    if (orders.isNotEmpty) return;

    debugPrint('🛒 Geçmiş siparişler oluşturuluyor...');
    
    final products = await _productRepository.getProducts();
    if (products.isEmpty) return;

    final random = Random();
    final now = DateTime.now();

    // Son 7 gün için rastgele satışlar
    for (int i = 0; i < 20; i++) {
      final daysAgo = random.nextInt(7);
      final orderDate = now.subtract(Duration(days: daysAgo, hours: random.nextInt(10)));
      
      // Rastgele ürün seç
      final product = products[random.nextInt(products.length)];
      final quantity = random.nextInt(3) + 1;
      final totalAmount = product.price * quantity;
      final orderId = 'order_${now.millisecondsSinceEpoch}_$i';

      final orderItem = OrderItem(
        orderId: orderId,
        productId: product.id!,
        productName: product.name,
        quantity: quantity,
        unitPrice: product.price,
        taxRate: product.taxRate,
      );

      final order = Order(
        id: orderId,
        orderDate: orderDate,
        totalAmount: totalAmount,
        taxAmount: totalAmount * 0.18, // Yaklaşık KDV
        discountAmount: 0,
        status: 'completed',
        paymentMethod: random.nextBool() ? 'cash' : 'credit_card',
        cashierId: 'cashier_1',
        cashierName: 'Ahmet Yılmaz',
        items: [orderItem],
        payments: [], // Basit tutmak için boş
      );

      await _orderRepository.createOrder(order);
    }
  }
}
