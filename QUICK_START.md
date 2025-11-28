# POS Pro TR - Hızlı Başlangıç Rehberi

## 🚀 Canlı Sistemi Ayağa Kaldırma (5 Adım)

### Adım 1: Firebase Yapılandırması (5 dakika)

```bash
# 1. Firebase CLI ile giriş yap
firebase login

# 2. Projeyi seç
firebase use pos-pro-tr-2025

# 3. Firestore index'lerini deploy et
firebase deploy --only firestore:indexes

# 4. Firestore rules'u deploy et
firebase deploy --only firestore:rules
```

**Kontrol:**
- Firebase Console'da Firestore Database aktif mi?
- Authentication > Sign-in method > Email/Password aktif mi?

### Adım 2: Android Release Build (10 dakika)

```bash
# 1. Proje dizinine git
cd pos_pro_tr

# 2. Dependencies'leri yükle
flutter pub get

# 3. Release APK oluştur
flutter build apk --release
```

**Çıktı:** `build/app/outputs/flutter-apk/app-release.apk`

### Adım 3: Test Cihazına Yükleme (2 dakika)

```bash
# USB ile bağlı cihaza yükle
flutter install --release

# VEYA APK'yı manuel yükle
adb install build/app/outputs/flutter-apk/app-release.apk
```

### Adım 4: İlk Kullanıcı Oluşturma

1. Uygulamayı aç
2. "Kayıt Ol" butonuna tıkla
3. Email ve şifre gir
4. Giriş yap

**Not:** İlk kullanıcı otomatik olarak admin rolü alır (Firestore rules'a göre)

### Adım 5: İlk Verileri Ekleme

1. **Ürün Ekle:**
   - Ana ekran > Ürünler
   - + butonuna tıkla
   - Ürün bilgilerini gir
   - Kaydet

2. **Müşteri Ekle:**
   - Ana ekran > Müşteriler
   - + butonuna tıkla
   - Müşteri bilgilerini gir
   - Kaydet

3. **İlk Sipariş:**
   - Ana ekran > Siparişler
   - + butonuna tıkla
   - Ürün seç, miktar gir
   - Müşteri seç (opsiyonel)
   - Siparişi tamamla

## ✅ Sistem Hazır!

Artık sisteminiz canlıda çalışıyor. Şimdi yapabilecekleriniz:

- ✅ Ürün yönetimi
- ✅ Müşteri yönetimi
- ✅ Sipariş oluşturma
- ✅ Ödeme kaydetme
- ✅ Raporlama
- ✅ Barkod okuma
- ✅ Offline çalışma
- ✅ Bildirimler

## 📱 Google Play Store'a Yükleme (Opsiyonel)

### App Bundle Oluştur
```bash
flutter build appbundle --release
```

### Play Console'a Yükle
1. https://play.google.com/console
2. Yeni uygulama oluştur
3. `app-release.aab` dosyasını yükle
4. Uygulama bilgilerini doldur
5. Yayınla

## 🔧 Sorun Giderme

### Build Hatası
```bash
flutter clean
flutter pub get
flutter build apk --release
```

### Firebase Bağlantı Hatası
- `google-services.json` dosyasını kontrol et
- Firebase Console'da proje aktif mi kontrol et

### Index Hatası
- Firestore Console > Indexes bölümüne git
- Index'lerin oluşmasını bekle (5-10 dakika)

## 📊 Monitoring

### Firebase Console
- Analytics: Kullanıcı davranışları
- Firestore: Veri durumu
- Authentication: Kullanıcı sayısı
- Cloud Messaging: Bildirim durumu

### Uygulama İçi
- Connectivity indicator: Network durumu
- Sync status: Senkronizasyon durumu
- Error logs: Hata kayıtları

## 🎯 Sonraki Adımlar

1. **Yazıcı Entegrasyonu**: Fiş yazdırma
2. **Detaylı Raporlar**: Daha kapsamlı analiz
3. **Kullanıcı Rolleri**: Admin, Manager, Cashier
4. **Multi-store**: Çoklu mağaza desteği
5. **Export/Import**: Veri aktarımı

