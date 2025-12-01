# 🏪 PosPro TR - Modern Mobile Point of Sale System

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Integrated-FFCA28?logo=firebase)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart)](https://dart.dev)
[![Android](https://img.shields.io/badge/Android-Ready-3DDC84?logo=android)](https://www.android.com)
[![iOS](https://img.shields.io/badge/iOS-Ready-000000?logo=apple)](https://www.apple.com/ios)

**Enterprise-grade mobile Point of Sale system built with Flutter, designed specifically for Turkish retail businesses.**

---

## 🎯 Project Overview

PosPro TR is a comprehensive, **offline-first** mobile POS system combining local SQLite storage with Firebase cloud synchronization. Built with **Clean Architecture** and **MVVM pattern**, it provides a robust, scalable solution for modern retail operations on mobile platforms.

### ✨ Core Features

#### 🛒 Sales Management
- Multi-item orders with real-time calculations
- Multiple payment methods (Cash, Card, Credit)
- Partial payments support
- Customer account integration
- Order parking and retrieval

#### 📊 Advanced Analytics
- **Real-time dashboard** (< 1 second updates)
- **Cashier performance tracking** (per-cashier sales analysis)
- Hourly sales patterns
- Top products analysis
- Branch-wise reporting
- Z-Report generation

#### 💾 Hybrid Data Architecture
- **Offline-first**: Local SQLite (< 100ms operations)
- **Background Firebase sync**: Every 15 minutes
- Automatic conflict resolution
- Zero data loss guarantee
- WorkManager for reliable sync

#### 📦 Inventory Management
- User-configurable critical stock levels
- Real-time low stock alerts
- Barcode scanning (mobile_scanner)
- Category-based organization
- Product image management

#### 🔐 Security & Authentication
- Firebase Authentication
- Google Sign-In integration
- Role-based access control (Admin, Cashier, Manager)
- Cash register (drawer) management
- Audit trail for all transactions

#### 📱 Modern UI/UX
- Dark theme optimized
- Mobile-responsive design
- Full Turkish language support
- Touch-optimized interface
- FlChart data visualization
- Tablet support

#### 🔌 REST API Support
- RESTful API client (Dio)
- ERP integration ready
- Third-party service connectivity
- Automatic retry mechanism
- JWT authentication support

---

## 🏗️ Architecture

### Clean Architecture + MVVM

```
┌─────────────────────────┐
│   Presentation Layer    │  ← Views, Controllers (GetX)
├─────────────────────────┤
│     Domain Layer        │  ← Business Logic (optional)
├─────────────────────────┤
│      Data Layer         │  ← Repositories, Models
│  ┌─────────┬─────────┐  │
│  │ SQLite  │Firebase │  │  ← Hybrid Storage
│  │(Drift)  │(Cloud)  │  │
│  └─────────┴─────────┘  │
└─────────────────────────┘
```

**Key Patterns**:
- ✅ MVVM (Model-View-ViewModel)
- ✅ Repository Pattern
- ✅ Dependency Injection (GetX)
- ✅ Observer Pattern (Reactive state)
- ✅ Singleton (Database instance)

👉 **[Full Architecture Documentation](./docs/ARCHITECTURE.md)**

---

## 📁 Project Structure

```
lib/
├── core/                    # Core utilities
│   ├── constants/          # App constants
│   ├── database/           # Drift SQLite database
│   ├── services/           # Background services, PDF, etc.
│   └── utils/              # Helpers, validators
│
├── features/               # Feature modules (MVVM)
│   │
│   ├── auth/              # Authentication
│   │   ├── data/          # Models, Repositories
│   │   └── presentation/  # Controllers, Screens, Widgets
│   │
│   ├── products/          # Product management
│   ├── orders/            # Order processing (POS)
│   ├── customers/         # Customer management
│   ├── reports/           # Analytics & reporting
│   ├── register/          # Cash register
│   └── branches/          # Multi-branch support
│
└── main.dart              # App entry point
```

---

## 🚀 Quick Start

### Prerequisites

- **Flutter SDK**: 3.0+ 
- **Dart**: 3.0+
- Android Studio / VS Code
- Firebase account

### Installation

1. **Clone repository**
   ```bash
   git clone <repository-url>
   cd pos_pro_tr
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   ```bash
   flutterfire configure
   ```

4. **Generate database code**
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

5. **Run application**
   ```bash
   # Android (Physical Device or Emulator)
   flutter run -d <device-id>
   
   # iOS (Requires macOS)
   flutter run -d <ios-device-id>
   
   # List available devices
   flutter devices
   ```

👉 **[Detailed Quick Start Guide](./docs/QUICK_START.md)**

---

## 📖 Documentation

| Document | Description |
|----------|-------------|
| [📐 ARCHITECTURE.md](./docs/ARCHITECTURE.md) | System architecture, MVVM, Clean Architecture |
| [🎨 VISUAL_ARCHITECTURE.md](./docs/VISUAL_ARCHITECTURE.md) | Visual diagrams and flowcharts |
| [📡 API_DOCUMENTATION.md](./docs/API_DOCUMENTATION.md) | API reference, data models |
| [🚀 QUICK_START.md](./docs/QUICK_START.md) | Installation and setup guide |
| [📚 KULLANIM_REHBERI.md](./docs/KULLANIM_REHBERI.md) | User manual (Turkish) |
| [🔧 TECH_STACK.md](./docs/TECH_STACK.md) | Complete technology stack |

---

## 🔧 Technology Stack

### Frontend
- **Flutter** 3.x - Cross-platform framework
- **GetX** 4.6.6 - State management, DI, routing
- **FlChart** 0.66.2 - Data visualization

### Backend & Database
- **Firebase**
  - Authentication (with Google Sign-In)
  - Firestore (Cloud NoSQL database)
  - Cloud Messaging (notifications)
- **Drift** 2.18.0 - Type-safe SQLite ORM
- **WorkManager** 0.9.0 - Background task scheduling

### Key Libraries
| Library | Version | Purpose |
|---------|---------|---------|
| `cloud_firestore` | 5.6.12 | Cloud database |
| `drift` | 2.18.0 | Local SQLite ORM |
| `get` | 4.6.6 | State management |
| `mobile_scanner` | 5.2.3 | Barcode scanning |
| `fl_chart` | 0.66.2 | Charts & graphs |
| `pdf` | 3.11.1 | Receipt generation |
| `workmanager` | 0.9.0 | Background sync |

**[Complete Tech Stack →](./docs/TECH_STACK.md)**

---

## 📊 Performance Metrics

| Metric | Value |
|--------|-------|
| **Local DB Operations** | < 100ms |
| **Sales Analytics Update** | < 1 second |
| **Background Sync Interval** | Every 15 minutes |
| **Offline Capability** | Full functionality |
| **Image Optimization** | Automatic compression |

---

## 🔒 Security

- ✅ Firebase Authentication (Email/Password + Google)
- ✅ Role-based access control (Admin, Cashier, Manager)
- ✅ Encrypted HTTPS communications
- ✅ Input validation & sanitization
- ✅ Firestore security rules
- ✅ Audit logging for transactions

---

## 🌍 Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| **Android** | ✅ Production Ready | Min SDK 23 (Android 6.0+) |
| **iOS** | ✅ Production Ready | iOS 12.0+ |
| **Tablets** | ✅ Supported | Android & iOS tablets |

**Primary Focus**: This application is optimized for **mobile platforms** (Android & iOS) with full offline-first capabilities and cloud synchronization.

---

## 📱 Mobile Experience

### Android & iOS
- **Native Performance**: Optimized for mobile devices
- **Offline-First**: Full functionality without internet
- **Barcode Scanner**: Quick product lookup
- **Touch Optimized**: Designed for touchscreen use
- **Portrait & Landscape**: Supports both orientations

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests  
flutter test integration_test/

# Generate coverage
flutter test --coverage
```

**Current Test Coverage**: TBD

---

## 🤝 Contributing

This is a **proprietary project** developed for internal use. 

For collaboration or partnership inquiries, please contact the project owner.

---

## 📄 License

**Proprietary License** - All rights reserved.

This software is proprietary and confidential. Unauthorized copying, modification, distribution, or use of this software, via any medium, is strictly prohibited.

---

## 📞 Contact & Support

For technical support, bug reports, or feature requests, please contact your system administrator or project maintainer.

**Documentation**: [docs/](./docs/)

---

## 🎯 Roadmap

### Completed ✅
- [x] Core POS functionality
- [x] Offline-first architecture
- [x] Firebase integration
- [x] Background synchronization
- [x] Analytics dashboard
- [x] Multi-branch support
- [x] **Advanced Product Analytics (AI-Powered)**
- [x] **Digital Receipt System**
- [x] **Real-time Cross-Device Sync**

### In Progress 🚧
- [ ] iOS production testing
- [ ] Comprehensive unit tests
- [ ] CI/CD pipeline for mobile builds
- [ ] App Store & Play Store optimization

### Planned 📋
- [ ] Multi-language support (English, Arabic)
- [ ] Enhanced inventory forecasting with AI
- [ ] Bluetooth thermal printer support
- [ ] NFC payment integration
- [ ] Customer loyalty program

---

## � Acknowledgments

Built with ❤️ using **Flutter** and **Firebase**.

**Development Stack**:
- Clean Architecture principles
- MVVM pattern
- GetX for state management
- Drift for type-safe database operations

---

**Version**: 1.0.1+3  
**Last Updated**: December 2025  
**Platform**: Android & iOS
