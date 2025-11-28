# POS Pro TR - Log İzleme Rehberi

## 📊 Terminal Komutları

### Flutter Logları
```bash
# Flutter loglarını canlı izle
flutter logs

# Son 50 satırı göster
adb logcat -d -s flutter:* | Select-Object -Last 50
```

### Firebase Logları
```bash
# Firebase/Firestore loglarını izle
adb logcat -d | Select-String -Pattern "Firebase|Firestore|Auth|FCM" | Select-Object -Last 20
```

### Hata ve Uyarılar
```bash
# Tüm hataları ve uyarıları izle
adb logcat -d | Select-String -Pattern "Error|Exception|ANR|FATAL" | Select-Object -Last 30
```

### Uygulama Durumu
```bash
# Uygulama çalışıyor mu kontrol et
adb shell "ps | grep pos_pro"

# Aktif activity'leri göster
adb shell dumpsys activity activities | Select-String -Pattern "pos_pro|MainActivity"
```

### Log Temizleme
```bash
# Log buffer'ı temizle
adb logcat -c
```

## 🔍 İzlenmesi Gerekenler

### Normal Loglar
- ✅ Firebase başlatıldı
- ✅ SQLite veritabanı hazır
- ✅ Bildirim servisi hazır
- ✅ Connectivity monitoring başlatıldı
- ✅ Stok izleme başlatıldı

### Hata Durumları
- ❌ ANR (Application Not Responding)
- ❌ Firebase bağlantı hataları
- ❌ SQLite hataları
- ❌ Exception'lar
- ❌ Null check hataları

## 📱 Uygulama Kontrolü

### Uygulamayı Başlat
```bash
adb shell am start -n com.example.pos_pro_tr/.MainActivity
```

### Uygulamayı Kapat
```bash
adb shell am force-stop com.example.pos_pro_tr
```

### Uygulama Bilgileri
```bash
adb shell dumpsys package com.example.pos_pro_tr
```

## 🐛 Sorun Giderme

### Uygulama Açılmıyorsa
1. Logları kontrol et: `adb logcat -d | Select-String -Pattern "FATAL|Exception"`
2. Uygulamayı kapat ve yeniden başlat
3. APK'yı yeniden yükle

### Firebase Bağlantı Sorunu
1. Firebase loglarını kontrol et
2. İnternet bağlantısını kontrol et
3. Firebase Console'da proje durumunu kontrol et

### ANR Hatası
1. ANR loglarını kontrol et
2. Uygulama performansını kontrol et
3. Ağır işlemleri async yap

## 📝 Log Formatı

```
Timestamp | PID | TID | Level | Tag | Message
```

Örnek:
```
11-28 07:52:13.236 12313 14436 W mple.pos_pro_tr: Message
```

## 🎯 Önemli Log Seviyeleri

- **V**: Verbose (en detaylı)
- **D**: Debug (debug bilgileri)
- **I**: Info (bilgi)
- **W**: Warning (uyarı)
- **E**: Error (hata)
- **F**: Fatal (kritik hata)

