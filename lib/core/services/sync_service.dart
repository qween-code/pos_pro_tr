import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';
import 'database_service.dart';
import '../../features/products/data/models/product_model.dart';
import '../../features/customers/data/models/customer_model.dart';
import '../../features/orders/data/models/order_model.dart' as pos_order;

class SyncService {
  FirebaseFirestore? _firestore;
  final DatabaseService _dbService = DatabaseService();

  SyncService() {
    if (!Platform.isWindows && !Platform.isLinux) {
      _firestore = FirebaseFirestore.instance;
    }
  }

  // Çevrimdışı değişiklikleri takip etmek için tablo
  static const String _syncQueueTable = 'sync_queue';

  // Sync queue tablosunu oluştur
  Future<void> _initSyncQueue() async {
    final db = await _dbService.database;
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $_syncQueueTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_name TEXT NOT NULL,
        document_id TEXT NOT NULL,
        action TEXT NOT NULL, -- 'create', 'update', 'delete'
        data TEXT, -- JSON string
        timestamp INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // Sync queue'ya ekle
  Future<void> _addToSyncQueue(
    String collection,
    String documentId,
    String action,
    Map<String, dynamic>? data,
  ) async {
    final db = await _dbService.database;
    await _initSyncQueue();
    
    // JSON string'e dönüştür
    String? dataJson;
    if (data != null) {
      try {
        dataJson = jsonEncode(data);
      } catch (e) {
        debugPrint('JSON encoding hatası: $e');
        dataJson = null;
      }
    }
    
    await db.insert(
      _syncQueueTable,
      {
        'collection_name': collection,
        'document_id': documentId,
        'action': action,
        'data': dataJson,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'synced': 0,
      },
    );
  }

  // Çevrimdışı ürün ekleme
  Future<void> addProductOffline(Product product) async {
    final db = await _dbService.database;
    
    // SQLite'a kaydet
    await db.insert('products', {
      'name': product.name,
      'price': product.price,
      'stock': product.stock,
      'category': product.category,
      'barcode': product.barcode,
      'taxRate': product.taxRate,
    });

    // Sync queue'ya ekle
    await _addToSyncQueue('products', '', 'create', product.toJson());
  }

  // Çevrimdışı müşteri ekleme
  Future<void> addCustomerOffline(Customer customer) async {
    final db = await _dbService.database;
    
    await db.insert('customers', {
      'name': customer.name,
      'phone': customer.phone,
      'email': customer.email,
      'address': customer.address,
      'loyaltyPoints': customer.loyaltyPoints,
    });

    await _addToSyncQueue('customers', '', 'create', customer.toJson());
  }

  // Çevrimdışı sipariş ekleme
  Future<void> addOrderOffline(pos_order.Order order, List<pos_order.OrderItem> items) async {
    final db = await _dbService.database;
    
    final orderId = await db.insert('orders', {
      'customerId': order.customerId,
      'orderDate': order.orderDate.toIso8601String(),
      'totalAmount': order.totalAmount,
      'taxAmount': order.taxAmount,
      'discountAmount': order.discountAmount,
      'paymentMethod': order.paymentMethod,
      'status': order.status,
    });

    for (var item in items) {
      await db.insert('order_items', {
        'orderId': orderId,
        'productId': item.productId,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
        'taxRate': item.taxRate,
      });
    }

    await _addToSyncQueue('orders', '', 'create', order.toJson());
  }

  // Online olduğunda tüm bekleyen değişiklikleri senkronize et
  Future<void> syncAll() async {
    if (_firestore == null) return;
    try {
      final db = await _dbService.database;
      await _initSyncQueue();

      // Senkronize edilmemiş kayıtları al
      final unsynced = await db.query(
        _syncQueueTable,
        where: 'synced = ?',
        whereArgs: [0],
        orderBy: 'timestamp ASC',
      );

      for (var record in unsynced) {
        try {
          final collection = record['collection_name'] as String;
          final action = record['action'] as String;
          final documentId = record['document_id'] as String;

          // Data'yı parse et
          Map<String, dynamic>? dataMap;
          if (record['data'] != null && record['data'] is String) {
            try {
              dataMap = jsonDecode(record['data'] as String) as Map<String, dynamic>;
            } catch (e) {
              debugPrint('JSON decoding hatası: $e');
              dataMap = null;
            }
          }

          switch (action) {
            case 'create':
              // Firestore'a ekle
              if (documentId.isEmpty) {
                await _firestore!.collection(collection).add(dataMap ?? {});
              } else {
                await _firestore!.collection(collection).doc(documentId).set(dataMap ?? {});
              }
              break;
            case 'update':
              if (documentId.isNotEmpty && dataMap != null) {
                await _firestore!.collection(collection).doc(documentId).update(dataMap);
              }
              break;
            case 'delete':
              if (documentId.isNotEmpty) {
                await _firestore!.collection(collection).doc(documentId).delete();
              }
              break;
          }

          // Senkronize edildi olarak işaretle
          await db.update(
            _syncQueueTable,
            {'synced': 1},
            where: 'id = ?',
            whereArgs: [record['id']],
          );
        } catch (e) {
          // Hata durumunda kaydı atla, bir sonraki sync'te tekrar dene
          debugPrint('Sync hatası: $e');
        }
      }
} catch (e) {
      debugPrint('Sync işlemi hatası: $e');
    }
  }

  // Firestore'dan SQLite'a veri çekme (ilk yükleme)
  Future<void> syncFromFirestore() async {
    if (_firestore == null) return;
    try {
      final db = await _dbService.database;

      // Ürünleri senkronize et
      final productsSnapshot = await _firestore!.collection('products').get();
      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        await db.insert(
          'products',
          {
            'id': int.tryParse(doc.id) ?? 0,
            'name': data['name'],
            'price': data['price'],
            'stock': data['stock'],
            'category': data['category'],
            'barcode': data['barcode'],
            'taxRate': data['taxRate'] ?? 0.10,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      // Müşterileri senkronize et
      final customersSnapshot = await _firestore!.collection('customers').get();
      for (var doc in customersSnapshot.docs) {
        final data = doc.data();
        await db.insert(
          'customers',
          {
            'id': int.tryParse(doc.id) ?? 0,
            'name': data['name'],
            'phone': data['phone'],
            'email': data['email'],
            'address': data['address'],
            'loyaltyPoints': data['loyaltyPoints'] ?? 0,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    } catch (e) {
      debugPrint('Firestore sync hatası: $e');
    }
  }

  // İnternet bağlantısını kontrol et (deprecated - ConnectivityService kullanın)
  @Deprecated('Use ConnectivityService.checkConnectivity() instead')
  Future<bool> isOnline() async {
    if (_firestore == null) return false;
    try {
      await _firestore!.collection('_health').limit(1).get();
      return true;
    } catch (e) {
      return false;
    }
  }
}

