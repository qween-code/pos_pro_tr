# POS Pro TR - Canlı Sistem Kurulum Rehberi

## 🚀 Production Deployment Adımları

### 1. Firebase Projesi Hazırlığı

#### 1.1 Firebase Console Kontrolleri
```bash
# Firebase projesine giriş yap
# https://console.firebase.google.com/
```

**Yapılacaklar:**
- ✅ Firestore Database oluşturuldu mu?
- ✅ Firestore API aktif mi?
- ✅ Authentication aktif mi? (Email/Password)
- ✅ Cloud Messaging aktif mi?
- ✅ Storage aktif mi? (gerekirse)

#### 1.2 Firestore Index'lerini Deploy Et
```bash
cd pos_pro_tr
firebase use pos-pro-tr-2025  # veya proje ID'niz
firebase deploy --only firestore:indexes
```

**Beklenen Süre:** 5-10 dakika (index'ler oluşturulurken)

#### 1.3 Firestore Rules'u Deploy Et
```bash
firebase deploy --only firestore:rules
```

### 2. Android APK Oluşturma

#### 2.1 Release Key Oluşturma (İlk Kez)
```bash
cd android/app
keytool -genkey -v -keystore pos-pro-release-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias pos-pro-key
```

**Not:** Key bilgilerini güvenli bir yerde saklayın!

#### 2.2 Key Store Yapılandırması
`android/key.properties` dosyası oluştur:
```properties
storePassword=your_store_password
keyPassword=your_key_password
keyAlias=pos-pro-key
storeFile=../app/pos-pro-release-key.jks
```

#### 2.3 Build Configuration
`android/app/build.gradle.kts` dosyasında release signing ekle:
```kotlin
signingConfigs {
    create("release") {
        val keystorePropertiesFile = rootProject.file("key.properties")
        val keystoreProperties = java.util.Properties()
        keystoreProperties.load(java.io.FileInputStream(keystorePropertiesFile))
        
        storeFile = file(keystoreProperties["storeFile"] as String)
        storePassword = keystoreProperties["storePassword"] as String
        keyAlias = keystoreProperties["keyAlias"] as String
        keyPassword = keystoreProperties["keyPassword"] as String
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}
```

#### 2.4 Release APK Oluştur
```bash
cd pos_pro_tr
flutter build apk --release
```

**Çıktı:** `build/app/outputs/flutter-apk/app-release.apk`

#### 2.5 App Bundle Oluştur (Google Play için)
```bash
flutter build appbundle --release
```

**Çıktı:** `build/app/outputs/bundle/release/app-release.aab`

### 3. iOS Build (Gelecekte)

#### 3.1 Xcode Yapılandırması
```bash
cd ios
pod install
open Runner.xcworkspace
```

#### 3.2 Archive Oluştur
- Xcode'da Product > Archive
- App Store Connect'e yükle

### 4. Firebase Yapılandırması

#### 4.1 google-services.json Kontrolü
- `android/app/google-services.json` dosyasının doğru olduğundan emin ol
- Production Firebase projesinden indirilmiş olmalı

#### 4.2 Firebase Options Kontrolü
- `lib/firebase_options.dart` dosyasının production projesi için oluşturulduğundan emin ol

**Yeniden oluşturma:**
```bash
flutterfire configure --project=pos-pro-tr-2025
```

### 5. Environment Variables (Opsiyonel)

#### 5.1 .env Dosyası Oluştur
```bash
# .env
FIREBASE_PROJECT_ID=pos-pro-tr-2025
API_BASE_URL=https://your-api.com
```

### 6. Test & Doğrulama

#### 6.1 Release Build Test
```bash
# Test cihazına yükle
flutter install --release

# veya APK'yı manuel yükle
adb install build/app/outputs/flutter-apk/app-release.apk
```

#### 6.2 Fonksiyon Testleri
- ✅ Giriş yapma
- ✅ Ürün ekleme/düzenleme
- ✅ Sipariş oluşturma
- ✅ Ödeme kaydetme
- ✅ Offline çalışma
- ✅ Bildirimler
- ✅ Barkod okuma

### 7. Google Play Store Yayınlama

#### 7.1 Play Console'a Giriş
- https://play.google.com/console
- Yeni uygulama oluştur

#### 7.2 Uygulama Bilgileri
- Uygulama adı: POS Pro TR
- Kısa açıklama
- Uzun açıklama
- Ekran görüntüleri
- Uygulama ikonu
- Feature graphic

#### 7.3 AAB Yükleme
- Production track'e app-release.aab yükle
- İçerik derecelendirmesi doldur
- Yayınlama

### 8. Monitoring & Analytics

#### 8.1 Firebase Analytics
- Firebase Console > Analytics
- Kullanıcı davranışlarını izle

#### 8.2 Crashlytics (Opsiyonel)
```yaml
# pubspec.yaml'a ekle
firebase_crashlytics: ^latest
```

#### 8.3 Performance Monitoring
- Firebase Performance Monitoring aktif et
- Uygulama performansını izle

### 9. Güvenlik Kontrolleri

#### 9.1 API Keys Kontrolü
- ✅ google-services.json güvenli mi?
- ✅ Firebase API keys exposed değil mi?
- ✅ Key store şifreleri güvenli mi?

#### 9.2 Firestore Rules Kontrolü
```bash
# Rules'u test et
firebase emulators:exec --only firestore "flutter test"
```

### 10. Backup & Recovery

#### 10.1 Firestore Backup
```bash
# Firebase Console > Firestore > Backup
# Otomatik backup ayarla
```

#### 10.2 Key Store Backup
- Key store dosyasını güvenli yere yedekle
- Şifreleri password manager'da sakla

## 📋 Deployment Checklist

### Pre-Deployment
- [ ] Firebase projesi hazır
- [ ] Firestore index'leri deploy edildi
- [ ] Firestore rules deploy edildi
- [ ] google-services.json güncel
- [ ] firebase_options.dart güncel
- [ ] Release key oluşturuldu
- [ ] key.properties yapılandırıldı

### Build
- [ ] Release APK oluşturuldu
- [ ] Release AAB oluşturuldu (Play Store için)
- [ ] Build başarılı
- [ ] APK/AAB boyutu kontrol edildi

### Testing
- [ ] Release build test edildi
- [ ] Tüm özellikler çalışıyor
- [ ] Offline mode test edildi
- [ ] Bildirimler test edildi
- [ ] Performance test edildi

### Deployment
- [ ] Google Play Console'a yüklendi
- [ ] Uygulama bilgileri dolduruldu
- [ ] İçerik derecelendirmesi yapıldı
- [ ] Production track'e yayınlandı

### Post-Deployment
- [ ] Monitoring aktif
- [ ] Analytics kontrol edildi
- [ ] Kullanıcı geri bildirimleri izleniyor
- [ ] Backup stratejisi aktif

## 🐛 Troubleshooting

### Build Hataları
```bash
# Clean build
flutter clean
flutter pub get
flutter build apk --release
```

### Firebase Bağlantı Hataları
- google-services.json kontrol et
- Firebase projesi aktif mi kontrol et
- İnternet bağlantısı kontrol et

### Index Hataları
- Firestore Console'da index durumunu kontrol et
- Index'lerin oluşmasını bekle (5-10 dakika)

## 📞 Destek

Sorun yaşarsanız:
1. Firebase Console loglarını kontrol edin
2. Flutter loglarını kontrol edin: `flutter logs`
3. Firebase Emulator ile test edin

