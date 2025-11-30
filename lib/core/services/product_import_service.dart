import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/products/data/models/product_model.dart';
import '../../features/products/data/repositories/hybrid_product_repository.dart';
import '../../core/database/database_instance.dart';

class ProductImportService {
  late final HybridProductRepository _productRepository;

  ProductImportService() {
    final dbInstance = Get.find<DatabaseInstance>();
    _productRepository = HybridProductRepository(
      localDb: dbInstance.database,
      firestore: FirebaseFirestore.instance,
    );
  }

  Future<void> importProducts() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'json'],
      );

      if (result != null) {
        File file = File(result.files.single.path!);
        String extension = result.files.single.extension!;

        List<Product> products = [];

        if (extension == 'csv') {
          products = await _parseCsv(file);
        } else if (extension == 'xlsx') {
          products = await _parseExcel(file);
        } else if (extension == 'json') {
          products = await _parseJson(file);
        }

        if (products.isNotEmpty) {
          _showPreviewDialog(products);
        } else {
          Get.snackbar('Hata', 'Dosyada ürün bulunamadı veya format hatalı');
        }
      }
    } catch (e) {
      Get.snackbar('Hata', 'Dosya okuma hatası: $e');
    }
  }

  Future<List<Product>> _parseCsv(File file) async {
    final input = file.openRead();
    final fields = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();
    
    // Header kontrolü (Basitçe ilk satırı atla)
    if (fields.isEmpty) return [];
    
    List<Product> products = [];
    // 1. satırdan başla
    for (int i = 1; i < fields.length; i++) {
      var row = fields[i];
      if (row.length >= 4) {
        products.add(Product(
          name: row[0].toString(),
          price: double.tryParse(row[1].toString()) ?? 0,
          stock: int.tryParse(row[2].toString()) ?? 0,
          category: row[3].toString(),
          barcode: row.length > 4 ? row[4].toString() : '',
          taxRate: 0.20, // Varsayılan
        ));
      }
    }
    return products;
  }

  Future<List<Product>> _parseExcel(File file) async {
    var bytes = file.readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    List<Product> products = [];

    for (var table in excel.tables.keys) {
      var sheet = excel.tables[table];
      if (sheet == null) continue;
      
      // İlk satır header varsayılıyor
      for (int i = 1; i < sheet.maxRows; i++) {
        var row = sheet.row(i);
        if (row.isEmpty) continue;

        // Excel hücresi null olabilir veya value property'si farklı olabilir
        // Basit bir okuma mantığı
        String name = row[0]?.value?.toString() ?? '';
        double price = double.tryParse(row[1]?.value?.toString() ?? '0') ?? 0;
        int stock = int.tryParse(row[2]?.value?.toString() ?? '0') ?? 0;
        String category = row[3]?.value?.toString() ?? '';
        String barcode = row.length > 4 ? (row[4]?.value?.toString() ?? '') : '';

        if (name.isNotEmpty) {
          products.add(Product(
            name: name,
            price: price,
            stock: stock,
            category: category,
            barcode: barcode,
            taxRate: 0.20,
          ));
        }
      }
    }
    return products;
  }

  Future<List<Product>> _parseJson(File file) async {
    String content = await file.readAsString();
    List<dynamic> jsonList = jsonDecode(content);
    return jsonList.map((e) => Product.fromJson(e)).toList();
  }

  void _showPreviewDialog(List<Product> products) {
    Get.defaultDialog(
      title: 'İçe Aktarma Önizleme',
      content: SizedBox(
        height: 300,
        width: 400,
        child: Column(
          children: [
            Text('${products.length} ürün bulundu.'),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final p = products[index];
                  return ListTile(
                    title: Text(p.name),
                    subtitle: Text('${p.price} TL - Stok: ${p.stock}'),
                    dense: true,
                  );
                },
              ),
            ),
          ],
        ),
      ),
      textConfirm: 'İçe Aktar',
      textCancel: 'İptal',
      onConfirm: () async {
        Get.back();
        await _saveProducts(products);
      },
    );
  }

  Future<void> _saveProducts(List<Product> products) async {
    int successCount = 0;
    for (var product in products) {
      try {
        await _productRepository.insertProduct(product);
        successCount++;
      } catch (e) {
        debugPrint('Ürün ekleme hatası: ${product.name} - $e');
      }
    }
    Get.snackbar('Başarılı', '$successCount ürün başarıyla eklendi',
        backgroundColor: Colors.green, colorText: Colors.white);
  }
  
  Future<void> downloadTemplate() async {
    // Taslak indirme mantığı (Şimdilik sadece bilgi verelim veya dummy dosya oluşturalım)
    // Gerçek bir uygulamada asset'ten dosya kopyalanabilir.
    Get.snackbar('Bilgi', 'Taslak dosya formatı:\nAd, Fiyat, Stok, Kategori, Barkod', duration: const Duration(seconds: 5));
  }

  void showImportOptions(BuildContext context) {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Toplu Ürün İçe Aktarma',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.file_upload, color: Colors.blue),
              title: const Text('Dosya Seç ve İçe Aktar'),
              subtitle: const Text('CSV, Excel veya JSON dosyası'),
              onTap: () {
                Get.back();
                importProducts();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download, color: Colors.green),
              title: const Text('Şablon İndir'),
              subtitle: const Text('Örnek dosya formatını görün'),
              onTap: () {
                Get.back();
                downloadTemplate();
              },
            ),
          ],
        ),
      ),
    );
  }
}
