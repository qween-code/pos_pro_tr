import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/orders/data/models/order_model.dart' as model;
import '../../features/products/data/models/product_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> processRefund({
    required model.Order order,
    required Map<String, int> refundQuantities,
    required List<model.OrderItem> orderItems,
  }) async {
    return _firestore.runTransaction((transaction) async {
      // 1. Ürün Stoklarını Güncelle (Okuma ve Yazma)
      for (var item in orderItems) {
        final quantityToRefund = refundQuantities[item.id] ?? 0;
        if (quantityToRefund > 0 && !item.productId.startsWith('manual_item')) {
          final productRef = _firestore.collection('products').doc(item.productId);
          final productSnapshot = await transaction.get(productRef);

          if (productSnapshot.exists) {
            final currentStock = productSnapshot.data()?['stock'] ?? 0;
            transaction.update(productRef, {'stock': currentStock + quantityToRefund});
          }
        }
      }

      // 2. Sipariş Durumunu Güncelle
      final orderRef = _firestore.collection('orders').doc(order.id);
      
      // Tüm ürünler iade edildi mi kontrolü
      bool allRefunded = true;
      for (var item in orderItems) {
        final quantityToRefund = refundQuantities[item.id] ?? 0;
        if (quantityToRefund < item.quantity) {
          allRefunded = false;
          break;
        }
      }

      final newStatus = allRefunded ? 'refunded' : 'partial_refunded';
      transaction.update(orderRef, {'status': newStatus});

      // Not: Kasa (Register) güncellemesi burada yapılmıyor çünkü RegisterController
      // ayrı bir mantıkla çalışıyor ve genellikle günlük ciro takibi için kullanılıyor.
      // Register güncellemesi Transaction dışında yapılabilir veya Register yapısı
      // Transaction'a uygun hale getirilebilir. Şimdilik kritik veri (Stok ve Sipariş)
      // Transaction içinde korunuyor.
    });
  }
}
