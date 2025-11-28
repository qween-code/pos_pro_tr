import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../features/auth/data/models/user_model.dart';

class StateService extends GetxService {
  // Kullanıcı durumu
  final Rx<UserModel?> _currentUser = Rx<UserModel?>(null);
  UserModel? get currentUser => _currentUser.value;
  set currentUser(UserModel? user) => _currentUser.value = user;

  // Tema durumu
  final RxBool _isDarkMode = false.obs;
  bool get isDarkMode => _isDarkMode.value;
  set isDarkMode(bool value) => _isDarkMode.value = value;

  // Uygulama genelinde yüklenme durumu
  final RxBool _isLoading = false.obs;
  bool get isLoading => _isLoading.value;
  set isLoading(bool value) => _isLoading.value = value;

  // Sepet durumu (sipariş oluşturma sırasında)
  final RxList<Map<String, dynamic>> _cartItems = <Map<String, dynamic>>[].obs;
  List<Map<String, dynamic>> get cartItems => _cartItems;
  set cartItems(List<Map<String, dynamic>> items) => _cartItems.value = items;

  Future<StateService> init() async {
    // Tema ayarlarını yükle
    _isDarkMode.value = false; // Varsayılan olarak açık tema

    // Kullanıcı durumunu yükle (daha sonra SharedPreferences ile kalıcı hale getirilebilir)

    return this;
  }

  // Sepete ürün ekleme
  void addToCart(Map<String, dynamic> item) {
    final existingIndex = _cartItems.indexWhere((i) => i['productId'] == item['productId']);
    if (existingIndex >= 0) {
      _cartItems[existingIndex]['quantity'] += item['quantity'];
    } else {
      _cartItems.add(item);
    }
  }

  // Sepetten ürün çıkarma
  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item['productId'] == productId);
  }

  // Sepet miktarını güncelleme
  void updateCartQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item['productId'] == productId);
    if (index >= 0) {
      _cartItems[index]['quantity'] = quantity;
    }
  }

  // Sepeti temizleme
  void clearCart() {
    _cartItems.clear();
  }

  // Toplam tutarı hesaplama
  double get cartTotal {
    return _cartItems.fold(0, (sum, item) {
      final price = item['price'] ?? 0.0;
      final quantity = item['quantity'] ?? 0;
      final taxRate = item['taxRate'] ?? 0.0;
      final total = price * quantity;
      final tax = total * taxRate;
      return sum + total + tax;
    });
  }

  // Toplam KDV hesaplama
  double get cartTaxTotal {
    return _cartItems.fold(0, (sum, item) {
      final price = item['price'] ?? 0.0;
      final quantity = item['quantity'] ?? 0;
      final taxRate = item['taxRate'] ?? 0.0;
      final total = price * quantity;
      final tax = total * taxRate;
      return sum + tax;
    });
  }

  // Tema değiştirme
  void toggleTheme() {
    _isDarkMode.value = !_isDarkMode.value;
  }

  // Tema verisini almak için
  ThemeMode get themeMode => _isDarkMode.value ? ThemeMode.dark : ThemeMode.light;
}