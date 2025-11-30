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
      version: 4, // Version 4 adds cashierName and branchId to orders
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    debugPrint('🔄 Database upgrade: $oldVersion -> $newVersion');
    
    if (oldVersion < 2) {
      // Discounts tablosunu güncelle
      try {
        await db.execute('DROP TABLE IF EXISTS discounts');
        await _createDiscountsTable(db);
      } catch (e) {
        debugPrint('❌ Discounts upgrade error: $e');
      }
    }
    
    if (oldVersion < 3) {
      // Tüm tabloları yeniden oluştur (tam schema için)
      debugPrint('🔄 Recreating all tables with complete schema...');
      
      // Eski tabloları yedekle
      List<String> backupTables = [];
      try {
        final tables = await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'"
        );
        backupTables = tables.map((t) => t['name'] as String).toList();
      } catch (e) {
        debugPrint('⚠️ Could not list tables: $e');
      }
      
      // Eski tabloları sil
      for (var table in backupTables) {
        try {
          await db.execute('DROP TABLE IF EXISTS $table');
        } catch (e) {
          debugPrint('⚠️ Could not drop table $table: $e');
        }
      }
      
      // Yeni tabloları oluştur
      await _onCreate(db, 4);
    } else if (oldVersion < 4) {
      // Sadece orders tablosuna yeni kolonları ekle
      debugPrint('🔄 Upgrading to v4: Adding cashierName and branchId to orders');
      try {
        await db.execute('ALTER TABLE orders ADD COLUMN cashierName TEXT');
        await db.execute('ALTER TABLE orders ADD COLUMN branchId TEXT');
      } catch (e) {
        debugPrint('⚠️ Upgrade v4 error: $e');
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    debugPrint('🔨 Creating database schema v$version');
    
    // Ürünler tablosu - TÜM alanlar dahil
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        stock INTEGER NOT NULL,
        category TEXT NOT NULL,
        imageUrl TEXT,
        barcode TEXT,
        taxRate REAL DEFAULT 18.0,
        isFavorite INTEGER DEFAULT 0,
        criticalStockLevel INTEGER DEFAULT 10
      )
    ''');
    debugPrint('✅ Products table created');

    // Müşteriler tablosu - TÜM alanlar dahil
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        email TEXT,
        address TEXT,
        note TEXT,
        balance REAL DEFAULT 0.0,
        loyaltyPoints INTEGER DEFAULT 0
      )
    ''');
    debugPrint('✅ Customers table created');

    // Siparişler tablosu
    await db.execute('''
      CREATE TABLE orders (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customerId INTEGER,
        customerName TEXT,
        orderDate TEXT NOT NULL,
        totalAmount REAL NOT NULL,
        taxAmount REAL NOT NULL,
        discountAmount REAL DEFAULT 0,
        paymentMethod TEXT,
        status TEXT DEFAULT 'completed',
        cashierName TEXT,
        branchId TEXT,
        FOREIGN KEY (customerId) REFERENCES customers (id)
      )
    ''');
    debugPrint('✅ Orders table created');

    // Sipariş öğeleri tablosu
    await db.execute('''
      CREATE TABLE order_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        orderId INTEGER NOT NULL,
        productId TEXT NOT NULL,
        productName TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        unitPrice REAL NOT NULL,
        taxRate REAL NOT NULL,
        totalPrice REAL NOT NULL,
        FOREIGN KEY (orderId) REFERENCES orders (id)
      )
    ''');
    debugPrint('✅ Order items table created');

    // Ödemeler tablosu (orders içinde payments JSON olarak tutulduğu için bu tablo opsiyonel)
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
    debugPrint('✅ Payments table created');

    // İndirimler tablosu
    await _createDiscountsTable(db);

    // Kasa (Register) tablosu
    await db.execute('''
      CREATE TABLE registers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        userName TEXT NOT NULL,
        openingTime TEXT NOT NULL,
        closingTime TEXT,
        openingBalance REAL NOT NULL,
        closingBalance REAL,
        totalCashSales REAL DEFAULT 0.0,
        totalCardSales REAL DEFAULT 0.0,
        totalOtherSales REAL DEFAULT 0.0,
        notes TEXT,
        status TEXT DEFAULT 'open'
      )
    ''');
    debugPrint('✅ Registers table created');

    // Sync queue tablosu (çevrimdışı değişiklikleri takip etmek için)
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        collection_name TEXT NOT NULL,
        document_id TEXT NOT NULL,
        action TEXT NOT NULL,
        data TEXT,
        timestamp INTEGER NOT NULL,
        synced INTEGER DEFAULT 0
      )
    ''');
    debugPrint('✅ Sync queue table created');
    
    // İndeksler oluştur (performans için)
    await _createIndexes(db);
    
    debugPrint('✅ Database schema creation completed');
  }

  Future<void> _createDiscountsTable(Database db) async {
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
    debugPrint('✅ Discounts table created');
  }

  Future<void> _createIndexes(Database db) async {
    try {
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_category ON products(category)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_date ON orders(orderDate)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_orders_customer ON orders(customerId)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_customers_phone ON customers(phone)');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_sync_queue_synced ON sync_queue(synced)');
      debugPrint('✅ Database indexes created');
    } catch (e) {
      debugPrint('⚠️ Index creation warning: $e');
    }
  }

  // Veritabanını tamamen sıfırla (development için)
  Future<void> resetDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, AppConstants.databaseName);
    
    // Önce bağlantıyı kapat
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
    
    // Veritabanı dosyasını sil
    await deleteDatabase(path);
    debugPrint('🗑️ Database deleted');
    
    // Yeni veritabanı oluştur
    _database = await _initDatabase();
    debugPrint('✅ Database reset completed');
  }

  // Veritabanını kapatma
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}