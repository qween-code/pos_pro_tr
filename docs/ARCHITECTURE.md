# 🏗️ PosPro TR - System Architecture

## Table of Contents
1. [Overview](#overview)
2. [Architecture Pattern](#architecture-pattern)
3. [Layer Structure](#layer-structure)
4. [Data Flow](#data-flow)
5. [Key Components](#key-components)
6. [Design Patterns](#design-patterns)

---

## 1. Overview

PosPro TR implements **Clean Architecture** with **MVVM (Model-View-ViewModel)** pattern, ensuring:

- ✅ Separation of Concerns
- ✅ Testability
- ✅ Scalability
- ✅ Maintainability
- ✅ Mobile Platform Optimization

---

## 2. Architecture Pattern

### Clean Architecture Layers

```
┌─────────────────────────────────────────────────────────┐
│                    Presentation Layer                    │
│  (UI, Screens, Widgets, Controllers/ViewModels)         │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                    Domain Layer                          │
│         (Business Logic, Use Cases, Entities)            │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                     Data Layer                           │
│     (Repositories, Models, Data Sources)                 │
│   ┌─────────────────────┬──────────────────────┐       │
│   │   Local (SQLite)    │   Remote (Firebase)  │       │
│   └─────────────────────┴──────────────────────┘       │
└─────────────────────────────────────────────────────────┘
```

### MVVM Implementation

```
┌──────────┐         ┌──────────────┐         ┌───────────┐
│   View   │◄────────│  ViewModel   │◄────────│   Model   │
│ (Screen) │         │ (Controller) │         │  (Data)   │
└──────────┘         └──────────────┘         └───────────┘
     │                      │                        │
     │                      │                        │
   Widgets            State Management         Repositories
   UI Logic            Business Logic          Data Access
```

---

## 3. Layer Structure

### 📁 Project Structure

```
lib/
├── core/                           # Core utilities
│   ├── constants/
│   │   ├── app_constants.dart     # App-wide constants
│   │   └── theme_constants.dart   # UI theming
│   │
│   ├── database/
│   │   ├── app_database.dart      # Drift database definition
│   │   ├── app_database.g.dart    # Generated code
│   │   └── database_instance.dart # Singleton instance
│   │
│   ├── services/
│   │   ├── auth_service.dart      # Authentication
│   │   ├── notification_service.dart
│   │   ├── sync_service.dart      # Data synchronization
│   │   ├── background_sync_service.dart  # WorkManager
│   │   └── pdf_service.dart       # Report generation
│   │
│   └── utils/
│       ├── error_handler.dart     # Error management
│       ├── validators.dart        # Input validation
│       └── helpers.dart           # Utility functions
│
├── features/                      # Feature modules
│   │
│   ├── auth/                      # Authentication feature
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── user_model.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── usecases/
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── auth_controller.dart     # ViewModel
│   │       ├── screens/
│   │       │   └── login_screen.dart        # View
│   │       └── widgets/
│   │
│   ├── products/                  # Product management
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   └── product_model.dart
│   │   │   └── repositories/
│   │   │       └── hybrid_product_repository.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── product_controller.dart  # ViewModel
│   │       ├── screens/
│   │       │   ├── product_list_screen.dart
│   │       │   └── product_add_edit_screen.dart
│   │       └── widgets/
│   │
│   ├── orders/                    # Order processing
│   │   ├── data/
│   │   │   ├── models/
│   │   │   │   ├── order_model.dart
│   │   │   │   ├── order_item.dart
│   │   │   │   └── payment_detail.dart
│   │   │   └── repositories/
│   │   │       └── hybrid_order_repository.dart
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── order_controller.dart
│   │       ├── screens/
│   │       │   └── pos_screen.dart
│   │       └── widgets/
│   │
│   ├── customers/                 # Customer management
│   │   ├── data/
│   │   │   ├── models/
│   │   │   └── repositories/
│   │   └── presentation/
│   │
│   ├── reports/                   # Analytics & reporting
│   │   └── presentation/
│   │       ├── controllers/
│   │       │   └── report_controller.dart
│   │       └── screens/
│   │           └── sales_analytics_screen.dart
│   │
│   ├── register/                  # Cash register
│   │   ├── data/
│   │   └── presentation/
│   │       └── controllers/
│   │           └── register_controller.dart
│   │
│   └── branches/                  # Multi-branch support
│
├── firebase_options.dart          # Firebase configuration
└── main.dart                      # App entry point
```

---

## 4. Data Flow

### 🔄 Hybrid Data Architecture

PosPro TR uses a **hybrid architecture** combining local and cloud storage:

```
┌────────────────────────────────────────────────────────┐
│                    User Action                          │
│              (e.g., Create Order)                       │
└─────────────────────┬──────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│               ViewModel (Controller)                     │
│         Validates & Processes Business Logic            │
└─────────────────────┬───────────────────────────────────┘
                      │
                      ▼
┌─────────────────────────────────────────────────────────┐
│            Hybrid Repository Pattern                     │
│  ┌──────────────────────┬──────────────────────────┐   │
│  │                      │                          │   │
│  ▼                      ▼                          │   │
│ ┌──────────┐    ┌──────────────┐                  │   │
│ │  Local   │    │   Firebase   │                  │   │
│ │ (SQLite) │    │ (Firestore)  │                  │   │
│ │          │    │              │                  │   │
│ │ INSTANT  │    │  Background  │                  │   │
│ │ < 100ms  │    │  Sync (15m)  │                  │   │
│ └────┬─────┘    └──────┬───────┘                  │   │
│      │                 │                          │   │
│      └────────┬────────┘                          │   │
└───────────────┼────────────────────────────────────┘   │
                │                                        │
                ▼                                        │
┌────────────────────────────────────────────────────┐  │
│           UI Updates (Reactive)                     │  │
│         GetX Observables (.obs)                     │  │
└────────────────────────────────────────────────────┘  │
                                                         │
              Background Sync Service                    │
              (WorkManager - Every 15min)                │
              Syncs unsynchronized data ◄────────────────┘
```

### Example: Order Creation Flow

```dart
// 1. VIEW: User clicks "Complete Order"
onPressed: () => orderController.addOrder()

// 2. VIEWMODEL: Business logic
Future<void> addOrder() async {
  // Validate
  if (currentOrderItems.isEmpty) return;
  
  // Get cashier info
  final cashierName = registerController.currentRegister.value?.userName;
  
  // Create model
  final Order newOrder = Order(...);
  
  // 3. REPOSITORY: Save to local (INSTANT)
  final orderId = await _orderRepository.createOrder(newOrder);
  // ✅ Order saved to SQLite (< 100ms)
  
  // 4. REPOSITORY: Queue for Firebase sync
  // (Happens in background via WorkManager)
  
  // 5. UPDATE VIEW
  clearOrder();
  showSuccessDialog();
}

// 6. BACKGROUND: WorkManager syncs to Firebase (within 15min)
```

---

## 5. Key Components

### 🎯 Core Services

#### 1. **Background Sync Service**
```dart
// lib/core/services/background_sync_service.dart

class BackgroundSyncService {
  // Initializes WorkManager for background tasks
  static Future<void> initialize()
  
  // Registers periodic sync (every 15 minutes)
  static Future<void> registerPeriodicSync()
  
  // One-time manual sync
  static Future<void> runOneTimeSync()
}
```

**Purpose**: Ensures data synchronization even when app is closed

#### 2. **Hybrid Repository Pattern**
```dart
// Example: lib/features/orders/data/repositories/hybrid_order_repository.dart

class HybridOrderRepository {
  final AppDatabase localDb;      // SQLite
  final FirebaseFirestore firestore; // Cloud
  
  // CREATE: Save locally first, then sync to Firebase
  Future<String> createOrder(Order order) async {
    // 1. Save to local SQLite (INSTANT)
    await localDb.into(localDb.orders).insert(...);
    
    // 2. Save to Firebase (Background)
    firestore.collection('orders').doc(id).set(...);
    
    return id;
  }
  
  // READ: Always from local (fast)
  Future<List<Order>> getOrders() async {
    final data = await localDb.select(localDb.orders).get();
    return data.map(_toOrderModel).toList();
  }
}
```

**Benefits**:
- ✅ Instant UI response (< 100ms)
- ✅ Works offline
- ✅ Automatic cloud backup
- ✅ Cross-device sync

#### 3. **State Management (GetX)**
```dart
// Example ViewModel
class OrderController extends GetxController {
  // Observable state
  final RxList<Order> orders = <Order>[].obs;
  final RxBool isLoading = false.obs;
  final RxDouble currentTotal = 0.0.obs;
  
  // Computed properties
  double get totalWithTax => currentTotal.value * 1.18;
  
  // Actions
  Future<void> addOrder() async { ... }
  void clearOrder() { ... }
}

// Usage in View
Obx(() => Text('Total: ${orderController.currentTotal}'))
```

---

## 6. Design Patterns

### 🎨 Pattern Implementations

#### 1. **Repository Pattern**
- **Purpose**: Abstract data source details
- **Implementation**: `HybridOrderRepository`, `HybridProductRepository`
- **Benefit**: Easy to switch between local/remote

#### 2. **Singleton Pattern**
- **Purpose**: Single database instance
- **Implementation**: `DatabaseInstance`
- **Benefit**: Resource efficiency

#### 3. **Observer Pattern**
- **Purpose**: Reactive UI updates
- **Implementation**: GetX `.obs`
- **Benefit**: Automatic UI refresh

#### 4. **Dependency Injection**
- **Purpose**: Loose coupling
- **Implementation**: GetX `Get.put()` / `Get.find()`
- **Benefit**: Testability

#### 5. **Factory Pattern**
- **Purpose**: Object creation
- **Implementation**: `.fromJson()` / `.toJson()`
- **Benefit**: Serialization

---

## 📊 Performance Optimizations

### Database
- **Indexing**: Primary keys on ID fields
- **Batch operations**: Multiple inserts in single transaction
- **Lazy loading**: Pagination for large lists

### UI
- **Lazy builders**: `ListView.builder` for lists
- **Const widgets**: Immutable widgets cached
- **Image caching**: Firebase Storage + local cache

### Sync
- **Incremental sync**: Only unsynchronized data
- **Compression**: Reduced payload size
- **Retry logic**: Exponential backoff

---

## 🔒 Security Architecture

### Authentication Flow
```
┌──────────┐    ┌──────────────┐    ┌──────────────┐
│  User    │───▶│  Firebase    │───▶│  Firestore   │
│          │    │     Auth     │    │   Rules      │
└──────────┘    └──────────────┘    └──────────────┘
     │                 │                     │
     │           JWT Token              Row-level
     │           Validated              Security
     │
  Stored in
 GetStorage
```

### Data Security
- **Local**: SQLite encrypted (future)
- **Transit**: HTTPS only
- **Rest**: Firebase encryption
- **Access**: Role-based permissions

---

## 📈 Scalability Considerations

### Current Capacity
- **Users**: Unlimited (Firebase Auth)
- **Products**: Tested up to 10,000 items
- **Orders**: Unlimited (pagination)
- **Branches**: Multi-branch supported

### Future Improvements
- [ ] Database sharding
- [ ] CDN for images
- [ ] Real-time sync (Firestore streams)
- [ ] GraphQL API
- [ ] Microservices architecture

---

## 🧪 Testing Strategy

### Unit Tests
```dart
// Test ViewModel logic
test('Add order calculates total correctly', () {
  final controller = OrderController();
  controller.addItem(product, quantity: 2);
  expect(controller.currentTotal.value, 200.0);
});
```

### Integration Tests
```dart
// Test Repository
test('Hybrid repository saves to both local and cloud', () async {
  final repo = HybridOrderRepository();
  final order = Order(...);
  await repo.createOrder(order);
  
  // Verify local
  final local = await repo.getOrders();
  expect(local.length, 1);
  
  // Verify cloud (with delay)
  await Future.delayed(Duration(seconds: 2));
  final cloud = await firestore.collection('orders').get();
  expect(cloud.docs.length, 1);
});
```

### Widget Tests
```dart
// Test UI
testWidgets('Order screen displays total', (tester) async {
  await tester.pumpWidget(MyApp());
  expect(find.text('Total: ₺0.00'), findsOneWidget);
});
```

---

## 📚 Further Reading

- [Clean Architecture by Uncle Bob](https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html)
- [MVVM Pattern](https://en.wikipedia.org/wiki/Model%E2%80%93view%E2%80%93viewmodel)
- [Flutter Architecture Samples](https://github.com/brianegan/flutter_architecture_samples)
- [GetX Documentation](https://pub.dev/packages/get)
- [Drift (SQLite) Documentation](https://drift.simonbinder.eu/)

---

**Last Updated**: December 2025  
**Platform**: Android & iOS Mobile
