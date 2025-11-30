import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  final RxString storeName = 'POS PRO TR'.obs;
  final RxString storeAddress = 'Market & Mağaza'.obs;
  final RxString storePhone = ''.obs;
  final RxString receiptFooter = 'Teşekkür Ederiz'.obs;
  final RxDouble defaultTaxRate = 0.18.obs;
  final RxBool isDarkMode = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadSettings();
  }

  Future<void> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    storeName.value = prefs.getString('storeName') ?? 'POS PRO TR';
    storeAddress.value = prefs.getString('storeAddress') ?? 'Market & Mağaza';
    storePhone.value = prefs.getString('storePhone') ?? '';
    receiptFooter.value = prefs.getString('receiptFooter') ?? 'Teşekkür Ederiz';
    defaultTaxRate.value = prefs.getDouble('defaultTaxRate') ?? 0.18;
    isDarkMode.value = prefs.getBool('isDarkMode') ?? true;
    
    // Temayı uygula
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
  }

  Future<void> saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('storeName', storeName.value);
    await prefs.setString('storeAddress', storeAddress.value);
    await prefs.setString('storePhone', storePhone.value);
    await prefs.setString('receiptFooter', receiptFooter.value);
    await prefs.setDouble('defaultTaxRate', defaultTaxRate.value);
    await prefs.setBool('isDarkMode', isDarkMode.value);
    
    Get.snackbar('Başarılı', 'Ayarlar kaydedildi', 
      backgroundColor: Colors.green, colorText: Colors.white);
  }

  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    Get.changeThemeMode(isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
    saveSettings();
  }
}
