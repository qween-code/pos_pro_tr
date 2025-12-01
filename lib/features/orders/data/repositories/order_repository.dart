import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart' as pos_order;
import '../../../../core/services/firebase_service.dart';

class OrderRepository {
  final FirebaseFirestore? _firestore = FirebaseService.instance.firestore;
  final String _orderCollectionName = 'orders';
  final String _orderItemsCollectionName = 'order_items';

  Future<String> insertOrder(pos_order.Order order, List<pos_order.OrderItem> items) async {
    // Sipariş nesnesine öğeleri ekle (denormalizasyon için)
    final orderWithItems = order.copyWith(items: items);
    
    if (_firestore == null) return 'offline_order_${DateTime.now().millisecondsSinceEpoch}';

    // Sipariş oluşturma
    final orderDocRef = await _firestore!.collection(_orderCollectionName).add(orderWithItems.toJson());
    final orderId = orderDocRef.id;

    // Sipariş öğelerini ayrıca oluşturma (geriye dönük uyumluluk ve detaylı sorgular için)
    for (var item in items) {
      await _firestore!.collection(_orderItemsCollectionName).add({
        ...item.toJson(),
        'orderId': orderId,
      });
    }

    return orderId;
  }

  Future<List<pos_order.Order>> getOrders({int limit = 2000}) async {
    if (_firestore == null) return [];
    final querySnapshot = await _firestore!.collection(_orderCollectionName)
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
    if (_firestore == null) return [];
    Query query = _firestore!.collection(_orderCollectionName)
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

  Future<void> updateOrderStatus(String orderId, String status) async {
    if (_firestore == null) return;
    await _firestore!.collection(_orderCollectionName).doc(orderId).update({
      'status': status,
    });
  }


  Future<void> updateOrder(pos_order.Order order) async {
    if (_firestore == null) return;
    if (order.id == null) throw Exception('Sipariş ID bulunamadı');
    await _firestore!.collection(_orderCollectionName).doc(order.id).update(order.toJson());
  }

  Future<void> deleteOrder(String id) async {
    if (_firestore == null) return;
    // Siparişi sil
    await _firestore!.collection(_orderCollectionName).doc(id).delete();

    // İlgili sipariş öğelerini sil
    final itemsQuery = await _firestore!.collection(_orderItemsCollectionName)
      .where('orderId', isEqualTo: id)
      .get();

    for (var doc in itemsQuery.docs) {
      await doc.reference.delete();
    }
  }

  Future<pos_order.Order?> getOrderById(String id) async {
    if (_firestore == null) return null;
    final doc = await _firestore!.collection(_orderCollectionName).doc(id).get();
    if (doc.exists && doc.data() != null) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return pos_order.Order.fromJson(data);
    }
    return null;
  }

  Future<List<pos_order.OrderItem>> getOrderItems(String orderId) async {
    if (_firestore == null) return [];
    final querySnapshot = await _firestore!.collection(_orderItemsCollectionName)
      .where('orderId', isEqualTo: orderId)
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return pos_order.OrderItem.fromJson(data);
    }).toList();
  }

  Future<List<pos_order.Order>> getOrdersByCustomerId(String customerId) async {
    if (_firestore == null) return [];
    final querySnapshot = await _firestore!.collection(_orderCollectionName)
      .where('customerId', isEqualTo: customerId)
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return pos_order.Order.fromJson(data);
    }).toList();
  }

  Future<List<pos_order.Order>> getOrdersByDateRange(DateTime startDate, DateTime endDate) async {
    if (_firestore == null) return [];
    final querySnapshot = await _firestore!.collection(_orderCollectionName)
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
    if (_firestore == null) return [];
    final querySnapshot = await _firestore!.collection(_orderCollectionName)
      .where('status', isEqualTo: status)
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return pos_order.Order.fromJson(data);
    }).toList();
  }

  Future<double> getTotalSalesForDate(DateTime date) async {
    if (_firestore == null) return 0.0;
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final querySnapshot = await _firestore!.collection(_orderCollectionName)
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