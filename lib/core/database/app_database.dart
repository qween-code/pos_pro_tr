import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ========================================
// TABLO TANIMLARI
// ========================================

/// Ürünler Tablosu
class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get barcode => text().nullable()();
  TextColumn get description => text().nullable()(); // Added
  RealColumn get price => real()();
  IntColumn get stock => integer()();
  TextColumn get category => text().nullable()();
  RealColumn get taxRate => real().withDefault(const Constant(0.10))();
  IntColumn get criticalStockLevel => integer().withDefault(const Constant(10))();
  TextColumn get imageUrl => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToFirebase => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Müşteriler Tablosu
class Customers extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get phone => text().nullable()();
  TextColumn get email => text().nullable()();
  TextColumn get address => text().nullable()();
  TextColumn get note => text().nullable()(); // Added
  RealColumn get balance => real().withDefault(const Constant(0.0))(); // Added
  IntColumn get loyaltyPoints => integer().withDefault(const Constant(0))(); // Added
  RealColumn get totalShopping => real().withDefault(const Constant(0.0))();
  IntColumn get visitCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToFirebase => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Siparişler Tablosu
class Orders extends Table {
  TextColumn get id => text()();
  TextColumn get customerId => text().nullable()();
  DateTimeColumn get orderDate => dateTime()();
  RealColumn get totalAmount => real()();
  RealColumn get taxAmount => real()();
  RealColumn get discountAmount => real().withDefault(const Constant(0.0))();
  TextColumn get paymentMethod => text().nullable()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get customerName => text().nullable()();
  TextColumn get cashierName => text().nullable()();
  TextColumn get cashierId => text().nullable()();
  TextColumn get branchId => text().nullable()();
  TextColumn get items => text().nullable()(); // JSON string of order items
  TextColumn get payments => text().nullable()(); // JSON string of payment details
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToFirebase => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Kullanıcılar Tablosu
class Users extends Table {
  TextColumn get id => text()();
  TextColumn get email => text()();
  TextColumn get name => text()();
  TextColumn get role => text()(); // admin, cashier, manager
  TextColumn get region => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get syncedToFirebase => boolean().withDefault(const Constant(false))();
  
  @override
  Set<Column> get primaryKey => {id};
}

/// Senkronizasyon Kuyruğu Tablosu
class SyncQueue extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get targetTable => text()(); // products, orders, etc.
  TextColumn get recordId => text()(); // kaydın ID'si
  TextColumn get operation => text()(); // insert, update, delete
  TextColumn get data => text().nullable()(); // JSON data
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
}

// ========================================
// VERİTABANI SINIFI
// ========================================

@DriftDatabase(tables: [Products, Customers, Orders, Users, SyncQueue])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3; // Increment version for migration

  // ========================================
  // AÇILIŞ BAĞLANTISI
  // ========================================
  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'pos_pro_db',
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.js'),
      ),
    );
  }
  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            // Migration for version 2
          }
          if (from < 3) {
            // Add new columns to Orders table
            try {
              await m.addColumn(orders, orders.cashierId);
            } catch (e) {
              // Column might already exist
              print('Migration Error (cashierId): $e');
            }
            
            try {
              await m.addColumn(orders, orders.branchId);
            } catch (e) {
              // Column might already exist
              print('Migration Error (branchId): $e');
            }
          }
        },
      );
}
