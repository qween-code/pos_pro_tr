import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/order_model.dart' as models;
import '../../../../core/database/app_database.dart' as db;
import '../../../../core/services/firestore_rest_service.dart';

/// Local-only repository for desktop platforms (Windows/Linux)
/// Uses SQLite for local storage and REST API for cloud sync
class LocalOrderRepository {
  final db.AppDatabase _localDb;
  final _uuid = const Uuid();

  LocalOrderRepository({required db.AppDatabase localDb}) : _localDb = localDb;

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

      // 🌐 Sync to cloud using REST API (async)
      PlatformSyncService.syncOrderToCloud(id, order.toJson()).catchError((e) {
        debugPrint('⚠️ Cloud sync failed: $e');
      });

      return id;
    } catch (e) {
      debugPrint('❌ Order creation error: $e');
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    await (_localDb.update(_localDb.orders)..where((t) => t.id.equals(orderId)))
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
    final order = await (_localDb.select(_localDb.orders)..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    return order != null ? _toOrderModel(order) : null;
  }

  Future<void> updateOrder(models.Order order) async {
    if (order.id == null) throw Exception('Order ID not found');

    final now = DateTime.now();
    final itemsJson = jsonEncode(order.items.map((e) => e.toJson()).toList());
    final paymentsJson = jsonEncode(order.payments.map((e) => e.toJson()).toList());

    await (_localDb.update(_localDb.orders)..where((t) => t.id.equals(order.id!)))
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
    ));
  }

  Future<void> deleteOrder(String id) async {
    await (_localDb.delete(_localDb.orders)..where((t) => t.id.equals(id))).go();
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
      debugPrint('❌ Order items parse error: $e');
    }

    if (data.payments != null) {
      try {
        final paymentsList = jsonDecode(data.payments!) as List;
        payments = paymentsList.map((e) => models.PaymentDetail.fromJson(e)).toList();
      } catch (e) {
        debugPrint('❌ Order payments parse error: $e');
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

  void dispose() {
    // No listeners to cancel
  }
}
