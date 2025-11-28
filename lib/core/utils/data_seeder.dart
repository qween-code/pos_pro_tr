import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../features/products/data/models/product_model.dart';
import '../../features/customers/data/models/customer_model.dart';

class DataSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> seedAll() async {
    try {
      await seedProducts();
      await seedCustomers();
      debugPrint('🌱 Tüm veriler başarıyla eklendi!');
    } catch (e) {
      debugPrint('❌ Veri ekleme hatası: $e');
      rethrow;
    }
  }

  Future<void> seedProducts() async {
    try {
      final products = [
        {
          'name': 'iPhone 15 Pro Max',
          'barcode': '194253408302',
          'price': 89999.0,
          'stock': 15,
          'taxRate': 0.20,
          'category': 'Elektronik',
        },
        {
          'name': 'MacBook Air M2',
          'barcode': '194253088231',
          'price': 42999.0,
          'stock': 8,
          'taxRate': 0.20,
          'category': 'Bilgisayar',
        },
        {
          'name': 'Sony WH-1000XM5',
          'barcode': '4548736132580',
          'price': 12499.0,
          'stock': 25,
          'taxRate': 0.20,
          'category': 'Aksesuar',
        },
        {
          'name': 'Samsung Galaxy S24 Ultra',
          'barcode': '880609483210',
          'price': 74999.0,
          'stock': 12,
          'taxRate': 0.20,
          'category': 'Elektronik',
        },
        {
          'name': 'Logitech MX Master 3S',
          'barcode': '097855173254',
          'price': 3999.0,
          'stock': 40,
          'taxRate': 0.20,
          'category': 'Aksesuar',
        },
        {
          'name': 'Nike Air Force 1',
          'barcode': '193154235689',
          'price': 4299.0,
          'stock': 30,
          'taxRate': 0.10,
          'category': 'Giyim',
        },
        {
          'name': 'Filtre Kahve (250g)',
          'barcode': '869054123654',
          'price': 280.0,
          'stock': 100,
          'taxRate': 0.01,
          'category': 'Gıda',
        },
      ];

      final batch = _firestore.batch();
      for (var productData in products) {
        final docRef = _firestore.collection('products').doc();
        batch.set(docRef, productData);
      }
      await batch.commit();
      debugPrint('✅ ${products.length} ürün eklendi');
    } catch (e) {
      debugPrint('❌ Ürün ekleme hatası: $e');
      rethrow;
    }
  }

  Future<void> seedCustomers() async {
    try {
      final customers = [
        {
          'name': 'Ahmet Yılmaz',
          'phone': '0532 123 45 67',
          'email': 'ahmet.yilmaz@email.com',
          'address': 'Kadıköy, İstanbul',
          'loyaltyPoints': 100,
        },
        {
          'name': 'Ayşe Demir',
          'phone': '0555 987 65 43',
          'email': 'ayse.demir@email.com',
          'address': 'Çankaya, Ankara',
          'loyaltyPoints': 50,
        },
        {
          'name': 'Mehmet Öz',
          'phone': '0544 222 33 44',
          'email': 'mehmet.oz@email.com',
          'address': 'Karşıyaka, İzmir',
          'loyaltyPoints': 0,
        },
        {
          'name': 'Zeynep Kaya',
          'phone': '0533 444 55 66',
          'email': 'zeynep.kaya@email.com',
          'address': 'Nilüfer, Bursa',
          'loyaltyPoints': 200,
        },
      ];

      final batch = _firestore.batch();
      for (var customerData in customers) {
        final docRef = _firestore.collection('customers').doc();
        batch.set(docRef, customerData);
      }
      await batch.commit();
      debugPrint('✅ ${customers.length} müşteri eklendi');
    } catch (e) {
      debugPrint('❌ Müşteri ekleme hatası: $e');
      rethrow;
    }
  }
}
