import 'dart:async';
import 'package:drift/drift.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../models/user_model.dart';
import '../../../../core/database/app_database.dart';

class HybridUserRepository {
  final AppDatabase _localDb;
  final FirebaseFirestore? _firestore; // Nullable for desktop
  
  StreamSubscription<QuerySnapshot>? _firebaseListener;

  HybridUserRepository({
    required AppDatabase localDb,
    FirebaseFirestore? firestore, // Optional
  })  : _localDb = localDb,
        _firestore = firestore {
    if (_firestore != null && !Platform.isWindows && !Platform.isLinux) {
      _startFirebaseListener();
    }
  }

  void _startFirebaseListener() {
    _firebaseListener = _firestore!.collection('users').snapshots().listen(
      (snapshot) async {
        for (final change in snapshot.docChanges) {
          final data = change.doc.data();
          if (data == null) continue;

          final userId = change.doc.id;

          try {
            switch (change.type) {
              case DocumentChangeType.added:
              case DocumentChangeType.modified:
                await _upsertToSQLite(userId, data);
                break;
              case DocumentChangeType.removed:
                await (_localDb.delete(_localDb.users)
                      ..where((t) => t.id.equals(userId)))
                    .go();
                break;
            }
          } catch (e) {
            debugPrint('❌ Firebase listener hatası (User $userId): $e');
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
    
    await _localDb.into(_localDb.users).insert(
      UsersCompanion.insert(
        id: id,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        role: data['role'] ?? 'user',
        createdAt: data['createdAt'] != null
            ? (data['createdAt'] as Timestamp).toDate()
            : now,
        updatedAt: now,
        syncedToFirebase: const Value(true),
      ),
      mode: InsertMode.insertOrReplace,
    );
  }

  Future<void> saveUser(UserModel user) async {
    final now = DateTime.now();

    try {
      await _localDb.into(_localDb.users).insert(
        UsersCompanion.insert(
          id: user.id,
          name: user.name,
          email: user.email,
          role: user.role,
          createdAt: now,
          updatedAt: now,
          syncedToFirebase: const Value(false),
        ),
        mode: InsertMode.insertOrReplace,
      );

      _firestore?.collection('users').doc(user.id).set({
        'name': user.name,
        'email': user.email,
        'role': user.role,
        'updatedAt': Timestamp.fromDate(now),
      }, SetOptions(merge: true)).then((_) {
        (_localDb.update(_localDb.users)..where((t) => t.id.equals(user.id)))
            .write(const UsersCompanion(syncedToFirebase: Value(true)));
      }).catchError((e) {
        debugPrint('❌ Firebase yazma hatası: $e');
      });
    } catch (e) {
      debugPrint('❌ Kullanıcı kaydetme hatası: $e');
      rethrow;
    }
  }

  Future<UserModel?> getUser(String id) async {
    final user = await (_localDb.select(_localDb.users)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();

    if (user != null) {
      return UserModel(
        id: user.id,
        name: user.name,
        email: user.email,
        role: user.role,
      );
    }
    return null;
  }
  
  void dispose() {
    _firebaseListener?.cancel();
  }
}
