import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/discount_model.dart';

class DiscountRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'discounts';

  Future<String> insertDiscount(Discount discount) async {
    final docRef = await _firestore.collection(_collectionName).add(discount.toJson());
    return docRef.id;
  }

  Future<List<Discount>> getDiscounts({int limit = 100}) async {
    final querySnapshot = await _firestore.collection(_collectionName)
      .limit(limit)
      .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Discount.fromJson(data);
    }).toList();
  }

  Future<void> updateDiscount(Discount discount) async {
    if (discount.id == null) throw Exception('İndirim ID bulunamadı');
    await _firestore.collection(_collectionName).doc(discount.id).update(discount.toJson());
  }

  Future<void> deleteDiscount(String id) async {
    await _firestore.collection(_collectionName).doc(id).delete();
  }

  Future<Discount?> getDiscountById(String id) async {
    final doc = await _firestore.collection(_collectionName).doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Discount.fromJson(data);
    }
    return null;
  }

  Future<List<Discount>> getActiveDiscounts() async {
    final now = DateTime.now();
    final querySnapshot = await _firestore.collection(_collectionName)
      .where('isActive', isEqualTo: true)
      .where('startDate', isLessThanOrEqualTo: now.toIso8601String())
      .where('endDate', isGreaterThanOrEqualTo: now.toIso8601String())
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Discount.fromJson(data);
    }).toList();
  }

  Future<List<Discount>> getDiscountsByName(String name) async {
    final querySnapshot = await _firestore.collection(_collectionName)
      .where('name', isEqualTo: name)
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Discount.fromJson(data);
    }).toList();
  }
}