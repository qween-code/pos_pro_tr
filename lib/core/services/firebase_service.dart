import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Firebase servislerini platform-safe şekilde sağlayan wrapper
class FirebaseService {
  static FirebaseService? _instance;
  FirebaseFirestore? _firestore;

  FirebaseService._() {
    _initializeFirestore();
  }

  static FirebaseService get instance {
    _instance ??= FirebaseService._();
    return _instance!;
  }

  void _initializeFirestore() {
    // Sadece mobile platformlarda Firebase'i başlat
    if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
      try {
        _firestore = FirebaseFirestore.instance;
        debugPrint('✅ Firebase initialized for mobile platform');
      } catch (e) {
        debugPrint('⚠️ Firebase initialization failed: $e');
      }
    } else {
      debugPrint('ℹ️ Firebase skipped for desktop platform (${Platform.operatingSystem})');
    }
  }

  /// Firestore instance'ı döndürür (null olabilir - desktop platformlarda)
  FirebaseFirestore? get firestore => _firestore;

  /// Firestore'un kullanılabilir olup olmadığını kontrol eder
  bool get isFirestoreAvailable => _firestore != null;

  /// Platform bilgisi
  bool get isMobile => !Platform.isWindows && !Platform.isLinux && !Platform.isMacOS;
  bool get isDesktop => Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  /// Firestore işlemlerini güvenli şekilde çalıştırır
  /// Desktop'ta işlem yapılmaz, sadece log basılır
  Future<T?> safeFirestoreOperation<T>({
    required String operationName,
    required Future<T> Function(FirebaseFirestore firestore) operation,
    T? fallbackValue,
  }) async {
    if (_firestore == null) {
      debugPrint('⚠️ Firestore operation skipped on desktop: $operationName');
      return fallbackValue;
    }

    try {
      return await operation(_firestore!);
    } catch (e) {
      debugPrint('❌ Firestore operation failed ($operationName): $e');
      return fallbackValue;
    }
  }

  /// Collection reference'ı güvenli şekilde döndürür
  CollectionReference? collection(String path) {
    return _firestore?.collection(path);
  }

  /// Document reference'ı güvenli şekilde döndürür
  DocumentReference? doc(String path) {
    return _firestore?.doc(path);
  }
}
