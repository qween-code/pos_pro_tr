import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/customer_model.dart' as models;
import '../../../../core/database/app_database.dart' as db;

class HybridCustomerRepository {
  final db.AppDatabase _localDb;
  final FirebaseFirestore? _firestore; // Nullable for desktop
  final _uuid = const Uuid();
  
  StreamSubscription<QuerySnapshot>? _firebaseListener;

  HybridCustomerRepository({
    required db.AppDatabase localDb,
    FirebaseFirestore? firestore, // Optional
  })  : _localDb = localDb,
        _firestore = firestore {
    if (_firestore != null && !Platform.isWindows && !Platform.isLinux) {
      _startFirebaseListener();
    }
  }

  void _startFirebaseListener() {
    _firebaseListener = _firestore!.collection('customers').snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;

          final customerId = change.doc.id;

          try {
            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                await _upsertToSQLite(customerId, data);
                break;
              case DocumentChangeType.removed:
                await (_localDb.delete(_localDb.customers)
                      ..where((t) => t.id.equals(customerId)))
                    .go();
                break;
            }
          } catch (e) {
            debugPrint('❌ Firebase listener hatası (Customer $customerId): $e');
          }
        }
      },
      onError: (error) {
        debugPrint('❌ Firebase stream hatası: $error');
      },
    );
  }

  Future<void> _upsertToSQLite(String id, Map<String, dynamic> data) async {
    final now = DateTime.now();
    
    await _localDb.into(_localDb.customers).insert(
      db.CustomersCompanion.insert(
        id: id,
        name: data['name'] ?? '',
        phone: Value(data['phone']),
        email: Value(data['email']),
        address: Value(data['address']),
        note: Value(data['note']),
        balance: Value((data['balance'] as num?)?.toDouble() ?? 0.0),
        loyaltyPoints: Value(data['loyaltyPoints'] ?? 0),
        totalShopping: Value((data['totalShopping'] as num?)?.toDouble() ?? 0.0),
        visitCount: Value(data['visitCount'] ?? 0),
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : now,
        updatedAt: now,
        syncedToFirebase: const Value(true),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<String> addCustomer(models.Customer customer) async {
    final id = customer.id ?? _uuid.v4();
    final now = DateTime.now();

    try {
      await _localDb.into(_localDb.customers).insert(
        db.CustomersCompanion.insert(
          id: id,
          name: customer.name,
          phone: Value(customer.phone),
          email: Value(customer.email),
          address: Value(customer.address),
          note: Value(customer.note),
          balance: Value(customer.balance),
          loyaltyPoints: Value(customer.loyaltyPoints),
          createdAt: now,
          updatedAt: now,
          syncedToFirebase: const Value(false),
        ),
      );

      _firestore?.collection('customers').doc(id).set({
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email,
        'address': customer.address,
        'note': customer.note,
        'balance': customer.balance,
        'loyaltyPoints': customer.loyaltyPoints,
        'totalShopping': 0.0,
        'visitCount': 0,
        'createdAt': Timestamp.fromDate(now),
        'updatedAt': Timestamp.fromDate(now),
      }).then((_) {
        (_localDb.update(_localDb.customers)..where((t) => t.id.equals(id)))
            .write(const db.CustomersCompanion(syncedToFirebase: Value(true)));
      }).catchError((e) {
        debugPrint('❌ Firebase yazma hatası: $e');
      });

      return id;
    } catch (e) {
      debugPrint('❌ Müşteri ekleme hatası: $e');
      rethrow;
    }
  }

  Future<List<models.Customer>> getCustomers({int limit = 1000}) async {
    final customers = await (_localDb.select(_localDb.customers)
          ..limit(limit))
        .get();

    return customers.map(_toCustomerModel).toList();
  }

  Future<models.Customer?> getCustomerById(String id) async {
    final customer = await (_localDb.select(_localDb.customers)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    return customer != null ? _toCustomerModel(customer) : null;
  }

  Future<List<models.Customer>> searchCustomers(String query) async {
    final customers = await (_localDb.select(_localDb.customers)
          ..where((t) => t.name.like('%$query%') | t.phone.like('%$query%')))
        .get();

    return customers.map(_toCustomerModel).toList();
  }

  Future<void> updateCustomer(models.Customer customer) async {
    if (customer.id == null) throw Exception('Müşteri ID bulunamadı');

    final now = DateTime.now();

    try {
      await (_localDb.update(_localDb.customers)
            ..where((t) => t.id.equals(customer.id!)))
          .write(db.CustomersCompanion(
            name: Value(customer.name),
            phone: Value(customer.phone),
            email: Value(customer.email),
            address: Value(customer.address),
            note: Value(customer.note),
            balance: Value(customer.balance),
            loyaltyPoints: Value(customer.loyaltyPoints),
            updatedAt: Value(now),
            syncedToFirebase: const Value(false),
          ));

      _firestore?.collection('customers').doc(customer.id).update({
        'name': customer.name,
        'phone': customer.phone,
        'email': customer.email,
        'address': customer.address,
        'note': customer.note,
        'balance': customer.balance,
        'loyaltyPoints': customer.loyaltyPoints,
        'updatedAt': Timestamp.fromDate(now),
      }).then((_) {
        (_localDb.update(_localDb.customers)..where((t) => t.id.equals(customer.id!)))
            .write(const db.CustomersCompanion(syncedToFirebase: Value(true)));
      }).catchError((e) {
        debugPrint('❌ Firebase güncelleme hatası: $e');
      });
    } catch (e) {
      debugPrint('❌ Müşteri güncelleme hatası: $e');
      rethrow;
    }
  }

  Future<void> updateBalance(String id, double amount) async {
    try {
      final customer = await getCustomerById(id);
      if (customer == null) return;

      final newBalance = customer.balance + amount;
      
      // Update SQLite
      await (_localDb.update(_localDb.customers)..where((t) => t.id.equals(id)))
          .write(db.CustomersCompanion(
            balance: Value(newBalance),
            syncedToFirebase: const Value(false),
          ));

      // Update Firebase
      _firestore?.collection('customers').doc(id).update({
        'balance': FieldValue.increment(amount),
      }).then((_) {
         (_localDb.update(_localDb.customers)..where((t) => t.id.equals(id)))
            .write(const db.CustomersCompanion(syncedToFirebase: Value(true)));
      }).catchError((e) {
        debugPrint('❌ Firebase bakiye güncelleme hatası: $e');
      });
    } catch (e) {
      debugPrint('❌ Bakiye güncelleme hatası: $e');
      rethrow;
    }
  }

  Future<void> deleteCustomer(String id) async {
    try {
      await (_localDb.delete(_localDb.customers)..where((t) => t.id.equals(id))).go();

      _firestore?.collection('customers').doc(id).delete().catchError((e) {
        debugPrint('❌ Firebase silme hatası: $e');
      });
    } catch (e) {
      debugPrint('❌ Müşteri silme hatası: $e');
      rethrow;
    }
  }

  models.Customer _toCustomerModel(db.Customer data) {
    return models.Customer(
      id: data.id,
      name: data.name,
      phone: data.phone,
      email: data.email,
      address: data.address,
      note: data.note,
      balance: data.balance,
      loyaltyPoints: data.loyaltyPoints,
    );
  }

  void dispose() {
    _firebaseListener?.cancel();
  }
}
