import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_constants.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);

    return await openDatabase(
      path,
      version: AppConstants.databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Discounts tablosunu düzelt (yorum satırını kaldır)
      try {
        await db.execute('DROP TABLE IF EXISTS discounts');
        await db.execute('''
          CREATE TABLE discounts (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            discountType TEXT NOT NULL,
            discountValue REAL NOT NULL,
            startDate TEXT NOT NULL,
            endDate TEXT NOT NULL,
            isActive INTEGER DEFAULT 1
          )
        ''');
      } catch (e) {
        debugPrint('Discounts tablosu güncelleme hatası: $e');
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Ürünler tablosu
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        category TEXT,
        barcode TEXT,
        taxRate REAL DEFAULT ${AppConstants.kdvOrani10}
      )
    ''');

    // Müşteriler tablosu
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        loyaltyPoints INTEGER DEFAULT 0
      )
    ''');

    // Siparişler tablosu
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER,
        orderDate TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        taxAmount REAL NOT NULL,
        discountAmount REAL DEFAULT 0,
        paymentMethod TEXT,
        status TEXT DEFAULT 'pending',
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');

    // Sipariş öğeleri tablosu
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        productId INTEGER NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        taxRate REAL NOT NULL,
        FOREIGN KEY (orderId) REFERENCES orders (id),
        FOREIGN KEY (productId) REFERENCES products (id)
      )
    ''');

    // Ödemeler tablosu
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        amount REAL NOT NULL,
        paymentMethod TEXT NOT NULL,
        paymentDate TEXT NOT NULL,
        transactionId TEXT,
        FOREIGN KEY (orderId) REFERENCES orders (id)
      )
    ''');

    // İndirimler tablosu
    // discountType: 'percentage' veya 'fixed'
    await db.execute('''
      CREATE TABLE discounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        discountType TEXT NOT NULL,
        discountValue REAL NOT NULL,
        startDate TEXT NOT NULL,
        endDate TEXT NOT NULL,
        isActive INTEGER DEFAULT 1
      )
    ''');

    // Sync queue tablosu (çevrimdışı değişiklikleri takip etmek için)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_name TEXT NOT NULL,
        document_id TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT,
        timestamp INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
  }

  // Veritabanını kapatma
  Future<void> close() async {
    final db = await database;
    db.close();
  }
}