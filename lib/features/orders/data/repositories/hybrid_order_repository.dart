import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart' as models;
import '../../../../core/database/app_database.dart' as db;
import '../../../../core/mediator/app_mediator.dart';
import '../../../../core/events/app_events.dart';

class HybridOrderRepository {
  final db.AppDatabase _localDb;
  final FirebaseFirestore _firestore;
  final _uuid = const Uuid();
  
  StreamSubscription<QuerySnapshot>? _firebaseListener;

  HybridOrderRepository({
    required db.AppDatabase localDb,
    required FirebaseFirestore firestore,
  })  : _localDb = localDb,
        _firestore = firestore {
    _startFirebaseListener();
  }

  final AppMediator _mediator = AppMediator();

  void _startFirebaseListener() {
    _firebaseListener = _firestore.collection('orders').snapshots().listen(
      (snapshot) async {
        bool hasChanges = false;
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;

          final orderId = change.doc.id;

          try {
            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                await _upsertToSQLite(orderId, data);
                hasChanges = true;
                break;
              case DocumentChangeType.removed:
                await (_localDb.delete(_localDb.orders)
                      ..where((t) => t.id.equals(orderId)))
                    .go();
                hasChanges = true;
                break;
            }
          } catch (e) {
            debugPrint('❌ Firebase listener hatası (Order $orderId): $e');
          }
        }
        
        if (hasChanges) {
          _mediator.publish(DashboardRefreshEvent(source: 'order_sync'));
        }
      },
      onError: (error) {
        debugPrint('❌ Firebase stream hatası: $error');
      },
    );
  }

  Future<void> _upsertToSQLite(String id, Map<String, dynamic> data) async {
    final now = DateTime.now();
    
    // Serialize items and payments
    final itemsJson = jsonEncode(data['items'] ?? []);
    final paymentsJson = jsonEncode(data['payments'] ?? []);

    await _localDb.into(_localDb.orders).insert(
      db.OrdersCompanion.insert(
        id: id,
        customerId: Value(data['customerId']),
        orderDate: data['orderDate'] != null 
            ? (data['orderDate'] as Timestamp).toDate() 
            : now,
        totalAmount: (data['totalAmount'] as num?)?.toDouble() ?? 0.0,
        taxAmount: (data['taxAmount'] as num?)?.toDouble() ?? 0.0,
        discountAmount: Value((data['discountAmount'] as num?)?.toDouble() ?? 0.0),
        paymentMethod: Value(data['paymentMethod']),
        status: Value(data['status'] ?? 'pending'),
        customerName: Value(data['customerName']),
        cashierName: Value(data['cashierName']),
        cashierId: Value(data['cashierId']),
        branchId: Value(data['branchId']),
        items: Value(itemsJson),
        payments: Value(paymentsJson),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : now,
        updatedAt: now,
        syncedToFirebase: const Value(true),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<String> createOrder(models.Order order) async {
    final id = order.id ?? _uuid.v4();
    final now = DateTime.now();

    try {
      final itemsJson = jsonEncode(order.items.map((e) => e.toJson()).toList());
      final paymentsJson = jsonEncode(order.payments.map((e) => e.toJson()).toList());

      await _localDb.into(_localDb.orders).insert(
        db.OrdersCompanion.insert(
          id: id,
          customerId: Value(order.customerId),
          orderDate: order.orderDate,
          totalAmount: order.totalAmount,
          taxAmount: order.taxAmount,
          discountAmount: Value(order.discountAmount),
          paymentMethod: Value(order.paymentMethod),
          status: Value(order.status),
          customerName: Value(order.customerName),
          cashierName: Value(order.cashierName),
          cashierId: Value(order.cashierId),
          branchId: Value(order.branchId),
          items: Value(itemsJson),
          payments: Value(paymentsJson),
          createdAt: now,
          updatedAt: now,
          syncedToFirebase: const Value(false),
        ),
      );

      // Sync to Firebase
      _syncToFirebase(id, order.toJson());
      
      return id;
    } catch (e) {
      debugPrint('Sipariş oluşturma hatası: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    // 1. Update Firestore
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Firestore order update failed: $e');
      // If offline, we should still update local DB and mark for sync (not implemented here fully)
    }

    // 2. Update Local DB
    await (_localDb.update(_localDb.orders)
      ..where((t) => t.id.equals(orderId)))
      .write(db.OrdersCompanion(
        status: Value(status),
        updatedAt: Value(DateTime.now()),
      ));
  }


  Future<List<models.Order>> getOrders({int limit = 1000}) async {
    final orders = await (_localDb.select(_localDb.orders)
          ..orderBy([(t) => OrderingTerm(expression: t.orderDate, mode: OrderingMode.desc)])
          ..limit(limit))
        .get();

    return orders.map(_toOrderModel).toList();
  }

  Future<List<models.Order>> getOrdersByDateRange(DateTime startDate, DateTime endDate) async {
    final orders = await (_localDb.select(_localDb.orders)
          ..where((t) => t.orderDate.isBiggerOrEqualValue(startDate) & t.orderDate.isSmallerOrEqualValue(endDate))
          ..orderBy([(t) => OrderingTerm(expression: t.orderDate, mode: OrderingMode.desc)]))
        .get();

    return orders.map(_toOrderModel).toList();
  }

  Future<models.Order?> getOrderById(String id) async {
    final order = await (_localDb.select(_localDb.orders)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    return order != null ? _toOrderModel(order) : null;
  }

  models.Order _toOrderModel(db.Order data) {
    List<models.OrderItem> items = [];
    List<models.PaymentDetail> payments = [];

    try {
      final itemsJson = data.items;
      if (itemsJson != null && itemsJson.isNotEmpty) {
        final itemsList = jsonDecode(itemsJson) as List;
        items = itemsList.map((e) => models.OrderItem.fromJson(e)).toList();
      }
    } catch (e) {
      debugPrint('❌ Order items parse hatası: $e');
    }

    if (data.payments != null) {
      try {
        final paymentsList = jsonDecode(data.payments!) as List;
        payments = paymentsList.map((e) => models.PaymentDetail.fromJson(e)).toList();
      } catch (e) {
        debugPrint('❌ Order payments parse hatası: $e');
      }
    }

    return models.Order(
      id: data.id,
      customerId: data.customerId,
      orderDate: data.orderDate,
      totalAmount: data.totalAmount,
      taxAmount: data.taxAmount,
      discountAmount: data.discountAmount,
      paymentMethod: data.paymentMethod,
      status: data.status,
      customerName: data.customerName,
      cashierName: data.cashierName,
      branchId: data.branchId,
      items: items,
      payments: payments,
    );
  }

  Future<void> updateOrder(models.Order order) async {
    if (order.id == null) throw Exception('Sipariş ID bulunamadı');
    
    final now = DateTime.now();

    try {
      final itemsJson = jsonEncode(order.items.map((e) => e.toJson()).toList());
      final paymentsJson = jsonEncode(order.payments.map((e) => e.toJson()).toList());

      // 1. Yerel güncelle
      await (_localDb.update(_localDb.orders)
            ..where((t) => t.id.equals(order.id!)))
          .write(db.OrdersCompanion(
            customerId: Value(order.customerId),
            orderDate: Value(order.orderDate),
            totalAmount: Value(order.totalAmount),
            taxAmount: Value(order.taxAmount),
            discountAmount: Value(order.discountAmount),
            paymentMethod: Value(order.paymentMethod),
            status: Value(order.status),
            customerName: Value(order.customerName),
            cashierName: Value(order.cashierName),
            branchId: Value(order.branchId),
            items: Value(itemsJson),
            payments: Value(paymentsJson),
            updatedAt: Value(now),
            syncedToFirebase: const Value(false),
          ));

      // 2. Firebase güncelle
      _firestore.collection('orders').doc(order.id).update({
        'customerId': order.customerId,
        'orderDate': Timestamp.fromDate(order.orderDate),
        'totalAmount': order.totalAmount,
        'taxAmount': order.taxAmount,
        'discountAmount': order.discountAmount,
        'paymentMethod': order.paymentMethod,
        'status': order.status,
        'customerName': order.customerName,
        'cashierName': order.cashierName,
        'branchId': order.branchId,
        'items': order.items.map((e) => e.toJson()).toList(),
        'payments': order.payments.map((e) => e.toJson()).toList(),
        'updatedAt': Timestamp.fromDate(now),
      }).then((_) {
        (_localDb.update(_localDb.orders)..where((t) => t.id.equals(order.id!)))
            .write(const db.OrdersCompanion(syncedToFirebase: Value(true)));
      }).catchError((e) {
        debugPrint('❌ Firebase güncelleme hatası: $e');
      });
    } catch (e) {
      debugPrint('❌ Sipariş güncelleme hatası: $e');
      rethrow;
    }
  }

  Future<void> deleteOrder(String id) async {
    try {
      // 1. Yerel sil
      await (_localDb.delete(_localDb.orders)
            ..where((t) => t.id.equals(id)))
          .go();

      // 2. Firebase sil
      _firestore.collection('orders').doc(id).delete().catchError((e) {
        debugPrint('❌ Firebase silme hatası: $e');
      });
    } catch (e) {
      debugPrint('❌ Sipariş silme hatası: $e');
      rethrow;
    }
  }

  void dispose() {
    _firebaseListener?.cancel();
  }

  Future<void> _syncToFirebase(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('orders').doc(id).set({
        ...data,
        'orderDate': Timestamp.fromDate(DateTime.parse(data['orderDate'])),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      await (_localDb.update(_localDb.orders)..where((t) => t.id.equals(id)))
          .write(const db.OrdersCompanion(syncedToFirebase: Value(true)));
    } catch (e) {
      debugPrint('❌ Firebase sync hatası: $e');
    }
  }
}
