import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'payments';

  Future<String> insertPayment(Payment payment) async {
    final docRef = await _firestore.collection(_collectionName).add(payment.toJson());
    return docRef.id;
  }

  Future<List<Payment>> getPayments({int limit = 100}) async {
    final querySnapshot = await _firestore.collection(_collectionName)
      .orderBy('paymentDate', descending: true)
      .limit(limit)
      .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Payment.fromJson(data);
    }).toList();
  }

  Future<void> updatePayment(Payment payment) async {
    if (payment.id == null) throw Exception('Ödeme ID bulunamadı');
    await _firestore.collection(_collectionName).doc(payment.id).update(payment.toJson());
  }

  Future<void> deletePayment(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  Future<Payment?> getPaymentById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Payment.fromJson(data);
    }
    return null;
  }

  Future<List<Payment>> getPaymentsByOrderId(String orderId) async {
    final querySnapshot = await _firestore.collection(_collectionName)
      .where('orderId', isEqualTo: orderId)
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Payment.fromJson(data);
    }).toList();
  }

  Future<List<Payment>> getPaymentsByDateRange(DateTime startDate, DateTime endDate) async {
    final querySnapshot = await _firestore.collection(_collectionName)
      .where('paymentDate', isGreaterThanOrEqualTo: startDate.toIso8601String())
      .where('paymentDate', isLessThanOrEqualTo: endDate.toIso8601String())
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Payment.fromJson(data);
    }).toList();
  }

  Future<double> getTotalPaymentsForDate(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final querySnapshot = await _firestore.collection(_collectionName)
      .where('paymentDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
      .where('paymentDate', isLessThanOrEqualTo: endOfDay.toIso8601String())
      .get();

    double total = 0.0;
    for (var doc in querySnapshot.docs) {
      total += doc.data()['amount'] ?? 0.0;
    }
    return total;
  }

  Future<Map<String, double>> getPaymentMethodsSummary(DateTime date) async {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);

    final querySnapshot = await _firestore.collection(_collectionName)
      .where('paymentDate', isGreaterThanOrEqualTo: startOfDay.toIso8601String())
      .where('paymentDate', isLessThanOrEqualTo: endOfDay.toIso8601String())
      .get();

    final Map<String, double> summary = {};

    for (var doc in querySnapshot.docs) {
      final payment = Payment.fromJson(doc.data());
      summary[payment.paymentMethod] = (summary[payment.paymentMethod] ?? 0) + payment.amount;
    }

    return summary;
  }
}