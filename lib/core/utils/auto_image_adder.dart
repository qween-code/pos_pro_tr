import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'dart:io';

/// Otomatik resim ekleme scripti
/// main.dart'ta çağrılacak
class AutoImageAdder {
  FirebaseFirestore? _firestore;

  AutoImageAdder() {
    if (!Platform.isWindows && !Platform.isLinux) {
      _firestore = FirebaseFirestore.instance;
    }
  }

  Future<void> addImagesToAllProducts() async {
    if (_firestore == null) return;
    try {
      debugPrint('🖼️ Otomatik resim ekleme başlıyor...');

      final productsSnapshot = await _firestore!.collection('products').get();
      
      int updated = 0;
      int skipped = 0;

      for (var doc in productsSnapshot.docs) {
        final data = doc.data();
        
        // Zaten imageUrl varsa atla
        if (data.containsKey('imageUrl') && 
            data['imageUrl'] != null && 
            data['imageUrl'].toString().isNotEmpty) {
          skipped++;
          continue;
        }

        final category = data['category'] as String? ?? 'Diğer';
        final imageUrl = _getCategoryImage(category);
        final description = _getCategoryDescription(category);

        await doc.reference.update({
          'imageUrl': imageUrl,
          'description': description,
        });

        updated++;
        
        if (updated % 10 == 0) {
          debugPrint('✅ $updated ürün güncellendi...');
        }
      }

      debugPrint('✅ TAMAMLANDI! $updated ürün güncellendi, $skipped ürün zaten resimliydi');
    } catch (e) {
      debugPrint('❌ Hata: $e');
    }
  }

  String _getCategoryImage(String category) {
    final imageMap = {
      'Elektronik': 'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=400',
      'Bilgisayar': 'https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=400',
      'Aksesuar': 'https://images.unsplash.com/photo-1527814050087-3793815479db?w=400',
      'Giyim': 'https://images.unsplash.com/photo-1460353581641-37baddab0fa2?w=400',
      'Gıda': 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=400',
      'Ev Eşyası': 'https://images.unsplash.com/photo-1556911220-bff31c812dba?w=400',
      'Spor': 'https://images.unsplash.com/photo-1517836357463-d25dfeac3438?w=400',
      'Kitap': 'https://images.unsplash.com/photo-1495446815901-a7297e633e8d?w=400',
    };
    
    return imageMap[category] ?? 'https://images.unsplash.com/photo-1523275335684-37898b6baf30?w=400';
  }

  String _getCategoryDescription(String category) {
    final descriptions = {
      'Elektronik': 'Yüksek performanslı ve son teknoloji özelliklere sahip.',
      'Bilgisayar': 'Profesyonel kullanım için ideal, güçlü donanım.',
      'Aksesuar': 'Günlük kullanım için pratik ve şık tasarım.',
      'Giyim': 'Rahat ve kaliteli malzemeden üretilmiştir.',
      'Gıda': 'Taze ve lezzetli, doğal içeriklerle hazırlanmıştır.',
      'Ev Eşyası': 'Dayanıklı ve kullanışlı ev aletleri.',
      'Spor': 'Fitness ve egzersiz için ideal ekipman.',
      'Kitap': 'İlgi çekici içerik ile zenginleştirilmiş.',
    };
    
    return descriptions[category] ?? 'Kaliteli ürün.';
  }
}
