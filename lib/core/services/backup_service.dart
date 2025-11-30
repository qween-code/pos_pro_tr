import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'database_service.dart';
import 'package:sqflite/sqflite.dart';

class BackupService {
  final DatabaseService _databaseService = DatabaseService();

  // Tüm koleksiyonları yedekle (SQLite'dan)
  Future<String?> exportAllData() async {
    try {
      final backupData = <String, dynamic>{};
      backupData['exportDate'] = DateTime.now().toIso8601String();
      backupData['version'] = '1.0.0';
      backupData['source'] = 'sqlite';

      final db = await _databaseService.database;

      // Tabloları listele
      final tables = ['products', 'customers', 'orders', 'order_items', 'registers', 'payments'];
      
      for (var table in tables) {
        try {
          final data = await db.query(table);
          backupData[table] = data;
        } catch (e) {
          debugPrint('$table tablosu okunamadı: $e');
        }
      }

      // JSON string'e dönüştür
      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);

      // Dosyaya kaydet
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = 'pos_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      debugPrint('Yedekleme tamamlandı: ${file.path}');
      return file.path;
    } catch (e) {
      debugPrint('Yedekleme hatası: $e');
      return null;
    }
  }

  // Yedeklemeyi paylaş
  Future<void> shareBackup(String filePath) async {
    try {
      final xFile = XFile(filePath);
      await Share.shareXFiles(
        [xFile],
        subject: 'POS Pro TR Veritabanı Yedeği',
        text: 'POS Pro TR veritabanı yedeği ekli dosyada.',
      );
    } catch (e) {
      debugPrint('Paylaşım hatası: $e');
      rethrow;
    }
  }

  // Yedeklemeyi içe aktar (SQLite'a)
  Future<bool> importBackup() async {
    try {
      // Dosya seç
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result == null || result.files.isEmpty) {
        return false;
      }

      final file = File(result.files.first.path!);
      final jsonString = await file.readAsString();
      final backupData = jsonDecode(jsonString) as Map<String, dynamic>;

      // Veri doğrulama
      if (!backupData.containsKey('version') || !backupData.containsKey('exportDate')) {
        throw Exception('Geçersiz yedekleme dosyası');
      }

      final db = await _databaseService.database;
      
      // Transaction ile tüm verileri yükle
      await db.transaction((txn) async {
        // Tabloları temizle ve yeniden doldur
        final tables = ['products', 'customers', 'orders', 'order_items', 'registers', 'payments'];
        
        for (var table in tables) {
          if (backupData.containsKey(table)) {
            // Önce tabloyu temizle
            await txn.delete(table);
            
            // Verileri ekle
            for (var item in backupData[table] as List) {
              await txn.insert(table, item as Map<String, dynamic>, conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        }
      });

      debugPrint('İçe aktarma tamamlandı');
      return true;
    } catch (e) {
      debugPrint('İçe aktarma hatası: $e');
      return false;
    }
  }

  // Seçili tabloyu yedekle
  Future<String?> exportCollection(String tableName) async {
    try {
      final db = await _databaseService.database;
      final data = await db.query(tableName);

      final backupData = {
        'collection': tableName,
        'exportDate': DateTime.now().toIso8601String(),
        'data': data,
      };

      final jsonString = const JsonEncoder.withIndent('  ').convert(backupData);
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-').split('.')[0];
      final fileName = '${tableName}_backup_$timestamp.json';
      final file = File('${directory.path}/$fileName');
      await file.writeAsString(jsonString);

      return file.path;
    } catch (e) {
      debugPrint('Tablo yedekleme hatası: $e');
      return null;
    }
  }
}
