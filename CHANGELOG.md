# POS Pro TR - Değişiklik Günlüğü

## [1.0.1] - 2025-11-28

### 🔧 Düzeltmeler
- **ANR Hatası Düzeltildi**: Uygulama başlatma sırasında ana thread bloke olma sorunu çözüldü
- **Splash Screen Eklendi**: Uygulama açılışında splash screen gösterimi
- **Async Initialization**: Ağır işlemler async olarak yapılıyor, UI thread bloke edilmiyor
- **JSON Encoding/Decoding**: SyncService'de toString() yerine jsonEncode/jsonDecode kullanımı
- **Print Statements**: Tüm print() çağrıları debugPrint() ile değiştirildi
- **ConnectivityService Entegrasyonu**: SyncService'de ConnectivityService kullanımı
- **SQLite Syntax Hatası**: Discounts tablosunda SQL yorum satırı hatası düzeltildi
- **Database Migration**: Database version 2'ye yükseltildi, onUpgrade desteği eklendi
- **Connectivity Check**: _health koleksiyonu yerine products koleksiyonu kullanılıyor (izin sorunu çözüldü)

### ✨ Yeni Özellikler
- **Splash Screen**: Uygulama açılışında 2 saniye splash screen gösterimi
- **Otomatik Yönlendirme**: Firebase Auth durumuna göre login/home yönlendirmesi

### 🚀 Performans
- Uygulama başlatma süresi optimize edildi
- UI thread bloke edilmiyor
- Servisler paralel başlatılıyor

## [1.0.0] - 2025-11-27

### ✨ İlk Sürüm
- Müşteri Yönetimi
- Ürün Yönetimi
- Sipariş Yönetimi
- Ödeme Yönetimi
- İndirim Yönetimi
- Raporlama
- Firebase Authentication
- Offline Mode
- Barkod Okuma
- Push Bildirimleri
- Stok Yönetimi
- Connectivity Monitoring
- Performans Optimizasyonları

