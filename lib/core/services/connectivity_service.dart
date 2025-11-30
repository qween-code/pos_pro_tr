import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'sync_service.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final _connectivityController = StreamController<bool>.broadcast();
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool get isOnline => _isOnline;

  void startMonitoring() {
    // İlk durumu kontrol et
    _checkConnectivity();

    // Değişiklikleri dinle
    _subscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _updateConnectionStatus(results);
    });
  }

  void stopMonitoring() {
    _subscription?.cancel();
    _connectivityController.close();
  }

  Future<void> _checkConnectivity() async {
    final results = await _connectivity.checkConnectivity();
    _updateConnectionStatus(results);
  }

  void _updateConnectionStatus(List<ConnectivityResult> results) {
    // none içermiyorsa online kabul et
    bool isConnected = !results.contains(ConnectivityResult.none);
    
    if (isConnected != _isOnline) {
      _isOnline = isConnected;
      _connectivityController.add(_isOnline);
      debugPrint('Bağlantı durumu değişti: ${_isOnline ? "Online" : "Offline"}');
      
      if (_isOnline) {
        // İnternet geldiyse senkronizasyonu başlat
        final syncService = SyncService();
        syncService.syncAll();
        Get.snackbar('Bağlantı', 'İnternet bağlantısı sağlandı. Veriler senkronize ediliyor.',
          backgroundColor: Colors.green, colorText: Colors.white);
      } else {
        Get.snackbar('Bağlantı', 'İnternet bağlantısı kesildi. Çevrimdışı mod aktif.',
          backgroundColor: Colors.red, colorText: Colors.white);
      }
    }
  }

  Future<bool> checkConnectivity() async {
    await _checkConnectivity();
    return _isOnline;
  }
}

