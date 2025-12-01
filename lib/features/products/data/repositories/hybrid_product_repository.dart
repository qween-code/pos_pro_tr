import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart' as models;
import '../../../../core/database/app_database.dart' as db;

/// Hibrit Product Repository (SQLite + Firebase)
/// 
/// Okuma işlemleri: SQLite (Hızlı, Offline)
/// Yazma işlemleri: SQLite (Hemen) + Firebase (Arka planda)
/// Senkronizasyon: Firebase Listener -> SQLite
class HybridProductRepository {
  final db.AppDatabase _localDb;
  final FirebaseFirestore? _firestore; // Nullable for desktop
  final _uuid = const Uuid();
  
  // Firebase değişikliklerini dinlemek için
  StreamSubscription<QuerySnapshot>? _firebaseListener;

  HybridProductRepository({
    required db.AppDatabase localDb,
    FirebaseFirestore? firestore, // Optional
  })  : _localDb = localDb,
        _firestore = firestore {
    if (_firestore != null && !Platform.isWindows && !Platform.isLinux) {
      _startFirebaseListener();
    }
  }

  /// Firebase'deki değişiklikleri dinle ve yerel veritabanını güncelle
  void _startFirebaseListener() {
    _firebaseListener = _firestore!.collection('products').snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;

          final productId = change.doc.id;

          try {
            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                // Firebase'den gelen veriyi yerel veritabanına kaydet
                await _upsertToSQLite(productId, data);
                break;
              case DocumentChangeType.removed:
                // Firebase'den silinen veriyi yerel veritabanından sil
                await (_localDb.delete(_localDb.products)
                      ..where((t) => t.id.equals(productId)))
                    .go();
                break;
            }
          } catch (e) {
            debugPrint('❌ Firebase listener hatası (Product $productId): $e');
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Firebase stream hatası: $error');
      },
    );
  }

  /// Veriyi SQLite'a kaydet veya güncelle
  Future<void> _upsertToSQLite(String id, Map<String, dynamic> data) async {
    final now = DateTime.now();
    
    await _localDb.into(_localDb.products).insert(
      db.ProductsCompanion.insert(
        id: id,
        name: data['name'] ?? '',
        price: (data['price'] as num?)?.toDouble() ?? 0.0,
        stock: data['stock'] ?? 0,
        category: Value(data['category']),
        barcode: Value(data['barcode']),
        description: Value(data['description']),
        taxRate: Value((data['taxRate'] as num?)?.toDouble() ?? 0.18),
        criticalStockLevel: Value((data['criticalStockLevel'] as int?) ?? 11),
        imageUrl: Value(data['imageUrl']),
        createdAt: data['createdAt'] != null 
            ? (data['createdAt'] as Timestamp).toDate() 
            : now,
        updatedAt: now,
        syncedToFirebase: const Value(true), // Firebase'den geldiği için senkronize
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  /// Yeni ürün ekle
  Future<String> insertProduct(models.Product product) async {
    final id = product.id ?? _uuid.v4();
    final now = DateTime.now();

    try {
      // 1. Önce yerel veritabanına kaydet (Hemen UI güncellemesi için)
      await _localDb.into(_localDb.products).insert(
        db.ProductsCompanion.insert(
          id: id,
          name: product.name,
          price: product.price,
          stock: product.stock,
          category: Value(product.category),
          barcode: Value(product.barcode),
          description: Value(product.description),
          taxRate: Value(product.taxRate),
          criticalStockLevel: Value(product.criticalStockLevel),
          imageUrl: Value(product.imageUrl),
          createdAt: now,
          updatedAt: now,
          syncedToFirebase: const Value(false), // Henüz Firebase'e gitmedi
        ),
      );

      // 2. Firebase'e gönder (Arka planda)
      _firestore?.collection('products').doc(id).set({
        'name': product.name,
        'price': product.price,
        'stock': product.stock,
        'category': product.category,
        'barcode': product.barcode,
        'description': product.description,
        'taxRate': product.taxRate,
        'criticalStockLevel': product.criticalStockLevel,
        'imageUrl': product.imageUrl,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      }).then((_) {
        // Başarılı olursa syncedToFirebase = true yap
        (_localDb.update(_localDb.products)..where((t) => t.id.equals(id)))
            .write(const db.ProductsCompanion(syncedToFirebase: Value(true)));
      }).catchError((e) {
        debugPrint('❌ Firebase yazma hatası: $e');
        // Hata olursa syncedToFirebase false kalır, SyncService daha sonra halleder
      });

      return id;
    } catch (e) {
      debugPrint('❌ Ürün ekleme hatası: $e');
      rethrow;
    }
  }

  /// Ürünleri getir
  Future<List<models.Product>> getProducts() async {
    // Sadece yerel veritabanından oku (Hız için)
    final products = await _localDb.select(_localDb.products).get();
    return products.map(_toProductModel).toList();
  }

  /// ID'ye göre ürün getir
  Future<models.Product?> getProductById(String id) async {
    final product = await (_localDb.select(_localDb.products)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    
    return product != null ? _toProductModel(product) : null;
  }

  /// Barkoda göre ürün getir
  Future<models.Product?> getProductByBarcode(String barcode) async {
    final product = await (_localDb.select(_localDb.products)
          ..where((t) => t.barcode.equals(barcode)))
        .getSingleOrNull();
    
    return product != null ? _toProductModel(product) : null;
  }

  /// Kategoriye göre ürünleri getir
  Future<List<models.Product>> getProductsByCategory(String categoryId) async {
    final products = await (_localDb.select(_localDb.products)
          ..where((t) => t.category.equals(categoryId)))
        .get();
    
    return products.map(_toProductModel).toList();
  }

  /// Kritik stok seviyesinin altındaki ürünleri getir
  Future<List<models.Product>> getLowStockProducts(int threshold) async {
    final products = await (_localDb.select(_localDb.products)
          ..where((t) => t.stock.isSmallerOrEqualValue(threshold)))
        .get();
    
    return products.map(_toProductModel).toList();
  }

  /// Ürün güncelle
  Future<void> updateProduct(models.Product product) async {
    if (product.id == null) throw Exception('Ürün ID bulunamadı');
    
    final now = DateTime.now();

    try {
      // 1. Yerel güncelle
      await (_localDb.update(_localDb.products)
            ..where((t) => t.id.equals(product.id!)))
          .write(db.ProductsCompanion(
            name: Value(product.name),
            price: Value(product.price),
            stock: Value(product.stock),
            category: Value(product.category),
            barcode: Value(product.barcode),
            description: Value(product.description),
            taxRate: Value(product.taxRate),
            criticalStockLevel: Value(product.criticalStockLevel),
            imageUrl: Value(product.imageUrl),
            updatedAt: Value(now),
            syncedToFirebase: const Value(false),
          ));

      // 2. Firebase güncelle
      _firestore?.collection('products').doc(product.id).update({
        'name': product.name,
        'price': product.price,
        'stock': product.stock,
        'category': product.category,
        'barcode': product.barcode,
        'description': product.description,
        'taxRate': product.taxRate,
        'criticalStockLevel': product.criticalStockLevel,
        'imageUrl': product.imageUrl,
        'updatedAt': Timestamp.fromDate(now),
      }).then((_) {
        (_localDb.update(_localDb.products)..where((t) => t.id.equals(product.id!)))
            .write(const db.ProductsCompanion(syncedToFirebase: Value(true)));
      }).catchError((e) {
        debugPrint('❌ Firebase güncelleme hatası: $e');
      });
    } catch (e) {
      debugPrint('❌ Ürün güncelleme hatası: $e');
      rethrow;
    }
  }

  /// Ürün sil
  Future<void> deleteProduct(String id) async {
    try {
      // 1. Yerel sil
      await (_localDb.delete(_localDb.products)
            ..where((t) => t.id.equals(id)))
          .go();

      // 2. Firebase sil
      _firestore?.collection('products').doc(id).delete().catchError((e) {
        debugPrint('❌ Firebase silme hatası: $e');
      });
    } catch (e) {
      debugPrint('❌ Ürün silme hatası: $e');
      rethrow;
    }
  }

  /// Drift modelini Domain modeline çevir
  models.Product _toProductModel(db.Product data) {
    return models.Product(
      id: data.id,
      name: data.name,
      price: data.price,
      stock: data.stock,
      category: data.category ?? '',
      barcode: data.barcode,
      description: data.description,
      taxRate: data.taxRate,
      criticalStockLevel: data.criticalStockLevel,
      imageUrl: data.imageUrl,
    );
  }

  void dispose() {
    _firebaseListener?.cancel();
  }
}
