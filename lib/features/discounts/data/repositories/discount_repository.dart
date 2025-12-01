import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/discount_model.dart';
import '../../../../core/services/firebase_service.dart';

import 'dart:io';

class DiscountRepository {
  FirebaseFirestore? _firestore;
  final String _collectionName = 'discounts';

  DiscountRepository() {
    _firestore = FirebaseService.instance.firestore;
  }

  Future<String> insertDiscount(Discount discount) async {
    if (_firestore == null) return 'offline_discount_${DateTime.now().millisecondsSinceEpoch}';
    final docRef = await _firestore!.collection(_collectionName).add(discount.toJson());
    return docRef.id;
  }

  Future<List<Discount>> getDiscounts({int limit = 100}) async {
    if (_firestore == null) return [];
    final querySnapshot = await _firestore!.collection(_collectionName)
      .limit(limit)
      .get();
    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Discount.fromJson(data);
    }).toList();
  }

  Future<void> updateDiscount(Discount discount) async {
    if (_firestore == null) return;
    if (discount.id == null) throw Exception('İndirim ID bulunamadı');
    await _firestore!.collection(_collectionName).doc(discount.id).update(discount.toJson());
  }

  Future<void> deleteDiscount(String id) async {
    if (_firestore == null) return;
    await _firestore!.collection(_collectionName).doc(id).delete();
  }

  Future<Discount?> getDiscountById(String id) async {
    if (_firestore == null) return null;
    final doc = await _firestore!.collection(_collectionName).doc(id).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return Discount.fromJson(data);
    }
    return null;
  }

  Future<List<Discount>> getActiveDiscounts() async {
    if (_firestore == null) return [];
    final now = DateTime.now();
    final querySnapshot = await _firestore!.collection(_collectionName)
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
    if (_firestore == null) return [];
    final querySnapshot = await _firestore!.collection(_collectionName)
      .where('name', isEqualTo: name)
      .get();

    return querySnapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return Discount.fromJson(data);
    }).toList();
  }
}