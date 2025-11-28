# 🏪 POS Pro TR - Modern Point of Sale System

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Firebase](https://img.shields.io/badge/Firebase-Cloud-FFCA28?logo=firebase)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![License](https://img.shields.io/badge/License-Proprietary-red)
![Status](https://img.shields.io/badge/Status-MVP%20Ready-success)

**Türkiye'nin modern, bulut tabanlı satış noktası sistemi**

[Demo](#-demo) • [Özellikler](#-temel-özellikler) • [Kurulum](#-kurulum) • [Dokümantasyon](#-dokümantasyon)

</div>

---

## 📱 Demo

<div align="center">
  <img src="https://via.placeholder.com/800x400/0A192F/64FFDA?text=POS+Pro+TR+Demo" alt="Demo"/>
  <p><em>Modern dark theme arayüzü ile profesyonel kullanıcı deneyimi</em></p>
</div>

---

## ✨ Temel Özellikler

### 💼 İş Yönetimi
- 📦 **Ürün Yönetimi** - Stok takibi, barkod okuma, kategori desteği
- 👥 **Müşteri Yönetimi** - CRM, sadakat puanları, müşteri profilleri
- 🛒 **Sipariş Yönetimi** - Hızlı sipariş oluşturma, durum takibi
- 💰 **Ödeme Yönetimi** - Çoklu ödeme yöntemi, taksit desteği
- 🎁 **İndirim Kampanyaları** - Yüzde/sabit indirim, tarih aralıklı kampanyalar

### 📊 Raporlama & Analiz
- 📈 **Canlı Dashboard** - Günlük satış, sipariş, müşteri istatistikleri
- 📉 **Grafik Raporlar** - fl_chart ile profesyonel grafikler
- 💳 **Ödeme Analizi** - Ödeme yöntemi dağılımı, trend analizi
- 🏆 **En Çok Satanlar** - Ürün performans raporları

### 🔧 Teknik Özellikler
- ☁️ **Firebase Backend** - Firestore, Authentication, Cloud Messaging
- 📱 **Cross-Platform** - Android & iOS desteği
- 🌙 **Modern UI/UX** - Dark theme, responsive tasarım
- 📶 **Offline Mod** - Çevrimdışı çalışma, otomatik senkronizasyon
- 🔐 **Güvenlik** - Firebase Auth, role-based access control
- 🔔 **Bildirimler** - Sipariş, ödeme, stok uyarıları

---

## 🚀 Kurulum

### Gereksinimler
- Flutter SDK 3.x+
- Dart 3.x+
- Android Studio / VS Code
- Firebase Account

### Adım 1: Projeyi Klonlayın
```bash
git clone https://github.com/KULLANICI/pos_pro_tr.git
cd pos_pro_tr
```

### Adım 2: Bağımlılıkları Yükleyin
```bash
flutter pub get
```

### Adım 3: Firebase Yapılandırması
```bash
# Firebase CLI kurulumu
npm install -g firebase-tools

# Firebase giriş
firebase login

# FlutterFire yapılandırması
flutterfire configure
```

### Adım 4: Çalıştırın
```bash
flutter run
```

---

## 🏗️ Mimari

```
lib/
├── core/                    # Çekirdek servisler
│   ├── constants/           # Sabitler, tema
│   ├── services/            # Firebase, Auth, Sync, Notification
│   ├── utils/               # Helpers, validators
│   └── widgets/             # Ortak widget'lar
├── features/                # Özellik modülleri
│   ├── auth/                # Kimlik doğrulama
│   ├── products/            # Ürün yönetimi
│   ├── customers/           # Müşteri yönetimi
│   ├── orders/              # Sipariş yönetimi
│   ├── payments/            # Ödeme yönetimi
│   ├── discounts/           # İndirim yönetimi
│   └── reports/             # Raporlama
└── app.dart                 # Ana uygulama
```

**Mimari Prensipler:**
- ✅ MVVM (Model-View-ViewModel)
- ✅ Clean Architecture
- ✅ Separation of Concerns
- ✅ Repository Pattern

---

## 🛠️ Teknoloji Stack

### Frontend
- **Flutter 3.x** - Cross-platform framework
- **GetX** - State management & routing
- **fl_chart** - Grafik raporlar

### Backend & Services
- **Firebase Firestore** - NoSQL cloud database
- **Firebase Authentication** - Kullanıcı yönetimi
- **Firebase Cloud Messaging** - Push notifications
- **Firebase Storage** - Dosya depolama

### Entegrasyonlar
- **İyzico** - Sanal POS entegrasyonu
- **E-Fatura** - GİB uyumlu faturalama
- **Mobile Scanner** - Barkod okuma

### Dev Tools
- **Firebase Emulator** - Yerel geliştirme
- **Android Studio** - IDE
- **Git** - Version control

Detaylı bilgi için: [TECH_STACK.md](TECH_STACK.md)

---

## 💳 Ödeme & Entegrasyonlar

### Desteklenen Ödeme Yöntemleri
- 💳 Kredi Kartı (İyzico)
- 💰 Nakit
- 🏦 Havale/EFT
- 📱 QR Kod (yakında)

### E-Fatura Desteği
- ✅ GİB uyumlu UBL-TR XML
- ✅ E-Fatura & E-Arşiv
- ✅ Otomatik fatura kesme
- ✅ PDF indirme

Detaylı bilgi için: [PAYMENT_INTEGRATION_GUIDE.md](PAYMENT_INTEGRATION_GUIDE.md)

---

## 📊 Firebase Yapılandırması

### Firestore Collections
```
pos-pro-tr-2025/
├── products          # Ürünler
├── customers         # Müşteriler
├── orders            # Siparişler
├── order_items       # Sipariş kalemleri
├── payments          # Ödemeler
├── discounts         # İndirimler
└── users             # Kullanıcılar
```

### Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Development rules - Production'da güncellenecek
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

⚠️ **Önemli:** Production ortamında security rules güncellenmeli!

---

## 🧪 Test

### Unit Tests
```bash
flutter test
```

### Widget Tests
```bash
flutter test test/widget_test.dart
```

### Integration Tests
```bash
flutter drive --driver=test_driver/integration_test.dart
```

---

## 📈 Performans

- ⚡ **Hızlı Başlatma** - Splash screen ile optimize edilmiş
- 🔄 **Lazy Loading** - Pagination desteği
- 💾 **Offline Cache** - SQLite persistence
- 📦 **Küçük APK** - ~20MB (debug), ~15MB (release)

---

## 🔐 Güvenlik

- ✅ Firebase Authentication
- ✅ Role-based access (Admin/User)
- ✅ Secure API communication (HTTPS)
- ✅ PCI DSS uyumlu ödeme (İyzico)
- ✅ Data encryption at rest

---

## 📝 Changelog

### v1.0.1 (28 Kasım 2025)
- ✅ Firebase entegrasyonu
- ✅ Tüm CRUD işlemleri
- ✅ Modern UI/UX
- ✅ Offline mod
- ✅ Push notifications
- ✅ E-Fatura altyapısı
- ✅ İyzico ödeme entegrasyonu

[Detaylı changelog için tıklayın](CHANGELOG.md)

---

## 🗺️ Roadmap

### Q1 2026
- [ ] Google Sign-In
- [ ] Apple Pay entegrasyon
- [ ] Detaylı raporlar
- [ ] Multi-language support

### Q2 2026
- [ ] iOS release
- [ ] Web dashboard
- [ ] Franchise yönetimi
- [ ] İleri seviye analytics

### Q3 2026
- [ ] AI-powered insights
- [ ] Müşteri segmentasyonu
- [ ] Automated marketing
- [ ] Inventory predictions

---

## 🤝 Katkıda Bulunma

Bu proje şu an proprietary bir projedir. Katkıda bulunmak için lütfen iletişime geçin.

---

## 📄 Lisans

Copyright © 2025 [ŞİRKET ADI]. Tüm hakları saklıdır.

Bu yazılım proprietary bir üründür. Kaynak kodun kullanımı, kopyalanması veya dağıtılması yazılı izin olmadan yasaktır.

---

## 📞 İletişim & Destek

- 📧 **Email:** destek@pospro.com
- 🌐 **Website:** https://pospro.com
- 📱 **WhatsApp:** +90 XXX XXX XX XX
- 💬 **Slack:** [POS Pro Community](https://pospro.slack.com)

---

## 🙏 Teşekkürler

- [Flutter Team](https://flutter.dev) - Amazing framework
- [Firebase](https://firebase.google.com) - Backend infrastructure
- [GetX](https://pub.dev/packages/get) - State management
- [İyzico](https://iyzico.com) - Payment gateway
- Turkish developer community 🇹🇷

---

<div align="center">

**Made with ❤️ in Turkey 🇹🇷**

[⬆ Başa Dön](#-pos-pro-tr---modern-point-of-sale-system)

</div>
