import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/register_model.dart';
import '../../../../core/services/firebase_service.dart';

import 'dart:io';

class RegisterRepository {
  FirebaseFirestore? _firestore;
  final String _collection = 'registers';

  RegisterRepository() {
    _firestore = FirebaseService.instance.firestore;
  }

  // Aktif (açık) kasayı getir
  Future<RegisterModel?> getOpenRegister() async {
    if (_firestore == null) return null; // Desktop offline mode
    try {
      final snapshot = await _firestore!
          .collection(_collection)
          .where('status', isEqualTo: 'open')
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final data = snapshot.docs.first.data();
        data['id'] = snapshot.docs.first.id;
        return RegisterModel.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting open register: $e');
      return null;
    }
  }

  // Yeni kasa aç
  Future<RegisterModel> openRegister(RegisterModel register) async {
    if (_firestore == null) {
      // Desktop offline mode: Return dummy register with ID
      return register.copyWith(id: 'offline_register_${DateTime.now().millisecondsSinceEpoch}');
    }
    final docRef = _firestore!.collection(_collection).doc();
    final newRegister = register.copyWith(id: docRef.id);
    await docRef.set(newRegister.toJson());
    return newRegister;
  }

  // Kasayı kapat (Z Raporu)
  Future<void> closeRegister(String id, double closingBalance, String notes) async {
    if (_firestore == null) return;
    await _firestore!.collection(_collection).doc(id).update({
      'closingTime': Timestamp.now(),
      'closingBalance': closingBalance,
      'status': 'closed',
      'notes': notes,
    });
  }

  // Satış yapıldığında kasa toplamlarını güncelle
  Future<void> updateSales(String id, double amount, String paymentMethod) async {
    if (_firestore == null) return;
    final docRef = _firestore!.collection(_collection).doc(id);
    
    if (paymentMethod == 'cash') {
      await docRef.update({
        'totalCashSales': FieldValue.increment(amount),
      });
    } else if (paymentMethod == 'card') {
      await docRef.update({
        'totalCardSales': FieldValue.increment(amount),
      });
    } else {
      await docRef.update({
        'totalOtherSales': FieldValue.increment(amount),
      });
    }
  }

  // Geçmiş kasa kayıtlarını getir
  Future<List<RegisterModel>> getRegisterHistory() async {
    if (_firestore == null) return [];
    final snapshot = await _firestore!
        .collection(_collection)
        .orderBy('openingTime', descending: true)
        .limit(20)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return RegisterModel.fromJson(data);
    }).toList();
  }
}
