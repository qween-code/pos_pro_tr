import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart' as pos_order;

class OrderRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _orderCollectionName = 'orders';
  final String _orderItemsCollectionName = 'order_items';

  Future<String> insertOrder(pos_order.Order order, List<pos_order.OrderItem> items) async {
    // Sipariş oluşturma
    final orderDocRef = await _firestore.collection(_orderCollectionName).add(order.toJson());
    final orderId = orderDocRef.id;

    // Sipariş öğelerini oluşturma
    for (var item in items) {
      await _firestore.collection(_orderItemsCollectionName).add({
        ...item.toJson(),
        'orderId': orderId,
      });
    }

    return orderId;
  }

  Future<List<pos_order.Order>> getOrders({int limit = 100}) async {
    final querySnapshot = await _firestore.collection(_orderCollectionName)
      .orderBy('orderDate', descending: true)
      .limit(limit)
      .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return pos_order.Order.fromJson(data);
    }).toList();
  }

  // Pagination ile siparişleri getir
  Future<List<pos_order.Order>> getOrdersPaginated({
    int limit = 50,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore.collection(_orderCollectionName)
      .orderBy('orderDate', descending: true)
      .limit(limit);
    
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }
    
    final querySnapshot = await query.get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id;
      return pos_order.Order.fromJson(data);
    }).toList();
  }

  Future<void> updateOrder(pos_order.Order order) async {
    if (order.id == null) throw Exception('Sipariş ID bulunamadı');
    await _firestore.collection(_orderCollectionName).doc(order.id).update(order.toJson());
  }

  Future<void> deleteOrder(String id) async {
    // Siparişi sil
    await _firestore.collection(_orderCollectionName).doc(id).delete();

    // İlgili sipariş öğelerini sil
    final itemsQuery = await _firestore.collection(_orderItemsCollectionName)
      .where('orderId', isEqualTo: id)
      .get();

    for (var doc in itemsQuery.docs) {
      await doc.reference.delete();
    }
  }

  Future<pos_order.Order?> getOrderById(String id) async {
    final doc = await _firestore.collection(_orderCollectionName).doc(id).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return pos_order.Order.fromJson(data);
    }
    return null;
  }

  Future<List<pos_order.OrderItem>> getOrderItems(String orderId) async {
    final querySnapshot = await _firestore.collection(_orderItemsCollectionName)
      .where('orderId', isEqualTo: orderId)
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return pos_order.OrderItem.fromJson(data);
    }).toList();
  }

  Future<List<pos_order.Order>> getOrdersByCustomerId(String customerId) async {
    final querySnapshot = await _firestore.collection(_orderCollectionName)
      .where('customerId', isEqualTo: customerId)
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return pos_order.Order.fromJson(data);
    }).toList();
  }

  Future<List<pos_order.Order>> getOrdersByDateRange(DateTime startDate, DateTime endDate) async {
    final querySnapshot = await _firestore.collection(_orderCollectionName)
      .where('orderDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
      .where('orderDate', isLessThanOrEqualTo: endDate.toIso8601String())
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return pos_order.Order.fromJson(data);
    }).toList();
  }

  Future<List<pos_order.Order>> getOrdersByStatus(String status) async {
    final querySnapshot = await _firestore.collection(_orderCollectionName)
      .where('status', isEqualTo: status)
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return pos_order.Order.fromJson(data);
    }).toList();
  }

  Future<double> getTotalSalesForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final querySnapshot = await _firestore.collection(_orderCollectionName)
      .where('orderDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
      .where('orderDate', isLessThanOrEqualTo: endOfDay.toIso8601String())
      .where('status', isEqualTo: 'completed')
      .get();

    double total = 0.0;
    for (var doc in querySnapshot.docs) {
      total += doc.data()['totalAmount'] ?? 0.0;
    }
    return total;
  }
}