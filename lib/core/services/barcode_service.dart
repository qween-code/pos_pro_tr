import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/products/data/models/product_model.dart';

import 'dart:io';

class BarcodeService {
  FirebaseFirestore? _firestore;

  BarcodeService() {
    if (!Platform.isWindows && !Platform.isLinux) {
      _firestore = FirebaseFirestore.instance;
    }
  }

  // Barkod ile ürün arama
  Future<Product?> findProductByBarcode(String barcode) async {
    if (_firestore == null) return null;
    try {
      final querySnapshot = await _firestore!
          .collection('products')
          .where('barcode', isEqualTo: barcode)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final doc = querySnapshot.docs.first;
        final data = doc.data();
        data['id'] = doc.id;
        return Product.fromJson(data);
      }
      return null;
    } catch (e) {
      throw Exception('Barkod okuma hatası: $e');
    }
  }

  // Barkod scanner controller oluşturma
  MobileScannerController createScannerController() {
    return MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  // Barkod formatını doğrulama
  bool isValidBarcode(String barcode) {
    // EAN-13, EAN-8, UPC-A, UPC-E, Code 128, Code 39 gibi formatları kontrol et
    final barcodeRegex = RegExp(r'^[0-9]{8,13}$|^[A-Z0-9]{1,}$');
    return barcodeRegex.hasMatch(barcode);
  }

  // Barkod türünü belirleme
  String getBarcodeType(String barcode) {
    if (barcode.length == 8) {
      return 'EAN-8';
    } else if (barcode.length == 12) {
      return 'UPC-A';
    } else if (barcode.length == 13) {
      return 'EAN-13';
    } else if (barcode.length <= 13) {
      return 'Code 128';
    } else {
      return 'Unknown';
    }
  }
}

