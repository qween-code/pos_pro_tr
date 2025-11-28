import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _connectivityController = StreamController<bool>.broadcast();
  bool _isOnline = true;
  Timer? _connectivityTimer;

  // Connectivity durumu stream'i
  Stream<bool> get connectivityStream => _connectivityController.stream;

  // Mevcut durum
  bool get isOnline => _isOnline;

  // Connectivity kontrolünü başlat
  void startMonitoring() {
    // İlk kontrol
    _checkConnectivity();

    // Her 10 saniyede bir kontrol et
    _connectivityTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _checkConnectivity();
    });
  }

  // Connectivity kontrolünü durdur
  void stopMonitoring() {
    _connectivityTimer?.cancel();
    _connectivityTimer = null;
  }

  // Connectivity durumunu kontrol et
  Future<void> _checkConnectivity() async {
    try {
      // Firestore'dan küçük bir sorgu yaparak bağlantıyı test et
      // products koleksiyonunu kullan (her zaman erişilebilir olmalı)
      await _firestore.collection('products').limit(1).get(
        const GetOptions(source: Source.server),
      );
      
      if (!_isOnline) {
        _isOnline = true;
        _connectivityController.add(true);
        debugPrint('İnternet bağlantısı sağlandı');
      }
    } catch (e) {
      if (_isOnline) {
        _isOnline = false;
        _connectivityController.add(false);
        debugPrint('İnternet bağlantısı kesildi: $e');
      }
    }
  }

  // Manuel connectivity kontrolü
  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isOnline;
  }

  // Dispose
  void dispose() {
    stopMonitoring();
    _connectivityController.close();
  }
}

