# 📘 PosPro TR - Mobil Kullanım Rehberi

Hoş geldiniz! Bu rehber, PosPro mobil POS sisteminin tüm özelliklerini ve kullanım senaryolarını detaylı olarak açıklar.

**Platform Desteği:** Android (6.0+) ve iOS (12.0+)  
**Versiyon:** 1.0.1+3  
**Son Güncelleme:** Aralık 2025

---

## 📱 İlk Kurulum

### 1. Uygulamayı İndirme
- **Android**: Google Play Store'dan "PosPro TR" arayın
- **iOS**: App Store'dan "PosPro TR" arayın
- Alternatif: APK/IPA dosyasını sistem yöneticinizden edinin

### 2. İlk Giriş
1. Uygulamayı açın
2. **Email** ve **Şifre** ile giriş yapın
3. Veya **Google ile Giriş** seçeneğini kullanın
4. İlk girişte gerekli izinler:
   - 📷 **Kamera**: Barkod okuma için
   - 📥 **Depolama**: Raporları kaydetmek için
   - 🔔 **Bildirimler**: Stok uyarıları için

### 3. İnternet Bağlantısı
- ✅ **İlk senkronizasyon** için internet gereklidir
- ✅ Sonrasında **tamamen çevrimdışı** çalışabilir
- ✅ Veriler otomatik olarak buluta yedeklenir (internet olduğunda)

---

## 🏠 Ana Ekran (Dashboard)

Ana ekranda günlük performansınızı görürsünüz:

### Özet Kartlar
- 💰 **Günlük Ciro**: O günkü toplam satış tutarı
- 📦 **Sipariş Sayısı**: Tamamlanan işlem adedi
- 👤 **Kasiyer Performansı**: Sizin satışlarınızın toplamı
- ⚠️ **Kritik Stok**: Düşük stoklu ürün sayısı

### Hızlı Erişim Butonları
- 🛒 **Yeni Satış**: POS ekranına git
- 📦 **Ürünler**: Ürün yönetimi
- 👥 **Müşteriler**: Müşteri listesi
- 📊 **Raporlar**: Detaylı analizler

---

## 🛒 Satış İşlemleri (POS Ekranı)

### Yeni Satış Başlatma

#### Adım 1: Ürün Ekleme (3 Yöntem)

**Yöntem 1: Barkod Okutma** (En Hızlı)
1. Sağ üstteki **📷 Kamera** ikonuna tıklayın
2. Barkodu telefonun kamerasına tutun
3. Ürün otomatik olarak sepete eklenir
4. Birden fazla ürün için tekrarlayın

**Yöntem 2: Manuel Arama**
1. Üstteki **🔍 Arama** çubuğuna tıklayın
2. Ürün adı veya barkod yazın
3. Listeden ürüne dokunun
4. Ürün sepete eklenir

**Yöntem 3: Ürün Listesinden Seçim**
1. Aşağıdaki ürün listesinde gezinin
2. İstediğiniz ürüne dokunun
3. Miktar otomatik "1" olarak eklenir

#### Adım 2: Miktar Ayarlama
- **➕ Artır**: Ürün miktarını +1 artırır
- **➖ Azalt**: Ürün miktarını -1 azaltır
- **🗑️ Kaldır**: Ürünü sepetten çıkarır
- Veya miktara dokunup **sayısal klavye** ile girin

#### Adım 3: Müşteri Seçimi (Opsiyonel)
1. **Müşteri Seç** butonuna tıklayın
2. Listeden müşteriyi seçin veya arayın
3. **Yeni Müşteri Ekle** ile kayıt yapın
4. Müşteri seçildiğinde:
   - İsim üstte görünür
   - Veresiye seçeneği aktif olur
   - Müşteri geçmişi gösterilir

#### Adım 4: İndirim Uygulama (Opsiyonel)
1. **İndirim** butonuna tıklayın
2. İndirim türünü seçin:
   - 📊 **Yüzde (%)**: Örn. %10
   - 💵 **Tutar (₺)**: Örn. 50₺
3. Değeri girin ve **Uygula**
4. İndirim tutarı sepette görünür

---

## 💳 Ödeme Alma

### Ödeme Ekranı
"Ödeme Al" butonuna tıkladığınızda:
- 💰 **Toplam Tutar**: KDV dahil toplam
- 📝 **Ürün Özeti**: Sepet içeriği
- 💳 **Ödeme Seçenekleri**: Ödeme yöntemleri

### Ödeme Yöntemleri

#### 1. 💵 Nakit Ödeme
1. **Nakit** seçeneğine tıklayın
2. Alınan tutarı girin (otomatik toplam tutar doldurulur)
3. **Para Üstü** otomatik hesaplanır
4. **Ödemeyi Tamamla** butonuna tıklayın

#### 2. 💳 Kredi Kartı
1. **Kredi Kartı** seçeneğine tıklayın
2. Tutarı girin (tam tutar önerilir)
3. POS cihazından ödemeyi alın
4. **Ödemeyi Tamamla**

#### 3. 📝 Veresiye (Müşteri Seçimi Zorunlu!)
1. Önce müşteri seçin (yoksa seçenek gri görünür)
2. **Veresiye** seçeneğine tıklayın
3. Tutarı girin
4. Not ekleyin (opsiyonel)
5. **Ödemeyi Tamamla**

### Parçalı Ödeme (Kombine)
Farklı yöntemlerle ödeme alabilirsiniz:

**Örnek: 200₺'lik Satış**
1. **Nakit** seçin → 150₺ girin → **Ekle**
2. **Kredi Kartı** seçin → 50₺ girin → **Ekle**
3. Kalan tutar "0₺" olduğunda **Siparişi Tamamla**

---

## 🧾 Sipariş Fişi

Satış tamamlandıktan sonra otomatik açılır:

### Fiş İçeriği
- 📋 **Sipariş No**: Benzersiz sipariş numarası
- 📅 **Tarih ve Saat**: İşlem zamanı
- 👤 **Kasiyer**: İşlemi yapan kullanıcı
- 👥 **Müşteri**: Varsa müşteri bilgisi
- 📦 **Ürünler**: Ad, miktar, birim fiyat, toplam
- 💰 **Ödeme Detayı**: Nakit/Kart/Veresiye
- 💵 **Toplam**: KDV dahil toplam tutar

### Fiş İşlemleri
- 🖨️ **Yazdır**: Bluetooth yazıcıya gönder (yakında)
- 📤 **Paylaş**: PDF olarak paylaş (WhatsApp, Email)
- 📱 **QR Kod**: Dijital fiş için QR kod
- 🏠 **Ana Sayfaya Dön**: Yeni satışa başla

---

## 📦 Ürün Yönetimi

Alt menüden **Ürünler** sekmesine gidin.

### Yeni Ürün Ekleme
1. **➕ Yeni Ürün** butonuna tıklayın
2. Bilgileri doldurun:
   - **Ürün Adı**: Örn. "Çay Bardağı"
   - **Barkod**: Elle yazın veya barkod okutun
   - **Kategori**: Listeden seçin
   - **Satış Fiyatı**: Örn. 25.50
   - **Alış Fiyatı**: Kar marjı için (opsiyonel)
   - **Stok Miktarı**: Başlangıç stok
   - **Kritik Stok Seviyesi**: Uyarı için (örn. 10)
   - **KDV Oranı**: %1, %10, %20
3. 📸 **Fotoğraf Ekle** (opsiyonel)
4. **Kaydet** butonuna tıklayın

### Ürün Düzenleme
1. Ürün listesinde ürüne tıklayın
2. **✏️ Düzenle** ikonuna tıklayın
3. Değişiklikleri yapın
4. **Kaydet**

### Stok Güncelleme
- **Hızlı Stok Artırma**: Ürün kartında **+** butonuna basılı tutun
- **Hızlı Stok Azaltma**: Ürün kartında **-** butonuna basılı tutun
- **Detaylı Düzenleme**: Ürüne tıklayıp manuel girin

### Ürün Arama ve Filtreleme
- 🔍 **Arama**: Üstteki arama çubuğu
- 🏷️ **Kategori Filtresi**: Dropdown'dan kategori seçin
- ⚠️ **Kritik Stok**: Sadece düşük stoklular
- 💰 **Fiyat Sırala**: Artan/Azalan

---

## 👥 Müşteri Yönetimi

Alt menüden **Müşteriler** sekmesine gidin.

### Yeni Müşteri Ekleme
1. **➕ Yeni Müşteri** butonuna tıklayın
2. Bilgileri girin:
   - **Ad Soyad**: Örn. "Ahmet Yılmaz"
   - **Telefon**: 05xx xxx xx xx
   - **Email**: (opsiyonel)
   - **Adres**: (opsiyonel)
   - **Not**: Özel notlar
3. **Kaydet**

### Müşteri Profili
Müşteriye tıklayınca görürsünüz:
- 📊 **Toplam Alışveriş**: Kaç sipariş vermiş
- 💰 **Toplam Harcama**: Ne kadar para harcamış
- 📝 **Veresiye Borcu**: Kalan borç (varsa)
- 📜 **Sipariş Geçmişi**: Tüm siparişleri
- 📞 **Hızlı Arama**: Telefonu arayın

### Veresiye Takibi
1. Müşteri profiline girin
2. **Borç Öde** butonuna tıklayın
3. Ödenen tutarı girin
4. Ödeme yöntemini seçin
5. **Kaydet**

---

## 📊 Raporlar ve Analizler

### Dashboard (Hızlı Özet)
Ana ekrandaki kartlar günlük özet gösterir.

### Gelişmiş Raporlar
**Raporlar** sekmesine gidin:

#### 1. 📈 Satış Analizi
- **Günlük**: Bugünkü satışlar
- **Haftalık**: Son 7 gün
- **Aylık**: Bu ay
- **Yıllık**: Bu yıl
- **Grafik**: Çizgi/Bar grafik
- **Dışa Aktar**: Excel/PDF

#### 2. 📦 Ürün Analizi
- **En Çok Satanlar**: Top 10 ürün
- **Kar Marjı**: Hangi ürün daha karlı
- **Stok Durumu**: Kritik stoklar
- **Kategori Bazlı**: Hangi kategori iyi satıyor

#### 3. 👤 Kasiyer Performansı
- **Günlük Satış**: Her kasiyerin günlük cirosu
- **Sipariş Sayısı**: Kim kaç sipariş aldı
- **Ortalama Sepet**: Sipariş başına ortalama tutar
- **Karşılaştırma**: Kasiyer performans tablosu

#### 4. 💰 Z Raporu (Kasa Kapatma)
1. **Kasa** sekmesine gidin
2. **Kasayı Kapat** butonuna tıklayın
3. Sayım yapın:
   - Kasadaki nakit tutarı girin
   - Sistem hesabıyla karşılaştırılır
   - Fark varsa uyarı verir
4. **Z Raporu Oluştur**:
   - PDF olarak kaydedilir
   - Email ile gönderilebilir

---

## 🔄 Senkronizasyon ve Yedekleme

### Otomatik Senkronizasyon
- ⏰ **Her 15 dakikada bir**: Veriler Firebase'e yedeklenir
- 📶 **İnternet olduğunda**: Bekleyen veriler senkronize edilir
- ✅ **Hata Toleransı**: Tekrar dener (max 3 kez)
- 🔔 **Bildirim**: Sync tamamlandığında bildirim

### Manuel Senkronizasyon
1. Sağ üst köşedeki **⚙️ Ayarlar**'a gidin
2. **Senkronize Et** butonuna tıklayın
3. İnternet bağlantısı gereklidir
4. İşlem tamamlandığında ✅ onay gösterilir

### Offline (Çevrimdışı) Mod
- ✅ **Tam İşlevsellik**: Tüm özellikler çalışır
- ✅ **Yerel Kayıt**: Veriler SQLite'a kaydedilir
- ✅ **Otomatik Sync**: İnternet geldiğinde yüklenir
- ⚠️ **Uyarı**: Cihazı sıfırlamayın (veri kaybı olabilir)

---

## 🔐 Kasa Yönetimi (Register)

### Kasayı Açma
1. Giriş yaptıktan sonra **Kasayı Aç** ekranı gelir
2. **Başlangıç Nakit** tutarını girin (örn. 500₺)
3. Not ekleyin (opsiyonel)
4. **Kasa Aç** butonuna tıklayın
5. Artık satış yapabilirsiniz

### Kasa Durumu
Üstteki banner'da görürsünüz:
- 💰 **Başlangıç**: 500₺
- 💵 **Mevcut**: 1,250₺ (satışlarla birlikte)
- ⏰ **Açılış Saati**: 09:00

### Kasayı Kapatma
1. **Kasa** sekmesine gidin
2. **Kasayı Kapat** butonuna tıklayın
3. **Fiili Sayım** yapın:
   - Kasadaki nakit tutarı girin
   - Sistem tutarıyla karşılaştırılır
4. **Fark varsa** neden belirtin
5. **Z Raporu** oluşturulur
6. Kasa kapalı, yeni gün için tekrar açmanız gerekir

---

## 🔔 Bildirimler ve Uyarılar

### Stok Uyarıları
- ⚠️ **Kritik Stok**: Ürün kritik seviyeye düştü
- 📦 **Sıfır Stok**: Ürün tükendi
- 📊 **Günlük Özet**: 18:00'de günlük satış özeti

### Sistem Bildirimleri
- ✅ **Sync Tamamlandı**: Veriler buluta yedeklendi
- ❌ **Sync Hatası**: İnternet bağlantısını kontrol edin
- 🔐 **Kasa Açık**: Kasa açık unutmayın

### Bildirim Ayarları
1. **Ayarlar** > **Bildirimler**
2. Hangilerini istediğinizi seçin:
   - Stok uyarıları
   - Günlük raporlar
   - Sistem bildirimleri
3. **Kaydet**

---

## ⚙️ Ayarlar

### Genel Ayarlar
- 🌙 **Tema**: Açık/Koyu mod (varsayılan: Koyu)
- 🌐 **Dil**: Türkçe (şimdilik tek seçenek)
- 🔔 **Bildirimler**: Aç/Kapat

### Kasa Ayarları
- 💰 **Varsayılan Başlangıç Nakit**: Örn. 500₺
- 🧾 **Otomatik Fiş Yazdır**: Evet/Hayır
- 📊 **Günlük Z Raporu Saati**: Örn. 22:00

### Senkronizasyon Ayarları
- ⏰ **Otomatik Sync**: Aç/Kapat
- 🕐 **Sync Aralığı**: 15/30/60 dakika
- 📶 **Sadece Wi-Fi**: Mobil veri kullanma

### Yedekleme
- 📤 **Manuel Yedek Al**: Şimdi yedekle
- 📥 **Yedek Geri Yükle**: Önceki yedeği yükle
- ☁️ **Otomatik Bulut Yedek**: Firebase (otomatik)

---

## 🆘 Sık Sorulan Sorular (SSS)

### Sat benimleış işlemini nasıl iptal ederim?
- Sepeti temizlemek için sağ üstteki **🗑️ Sepeti Temizle** butonuna basın
- Tek ürün için ürünün yanındaki **X** ikonuna tıklayın

### İnternet olmadan çalışır mı?
- Evet! Uygulama **tamamen offline** çalışır
- İnternet olduğunda veriler otomatik senkronize edilir

### Veresiye borcu nasıl takip ederim?
- **Müşteriler** sekmesine gidin
- Müşteri profilinde **Borç Durumu** görünür
- **Borç Öde** ile ödeme alabilirsiniz

### Raporu nasıl dışa aktarırım?
- **Raporlar** > İstediğiniz rapor
- **Dışa Aktar** butonuna tıklayın
- **PDF** veya **Excel** seçin

### Birden fazla cihazdan kullanabilir miyim?
- Evet! Aynı hesapla giriş yapın
- Veriler otomatik senkronize edilir
- Aynı anda birden fazla kasiyer çalışabilir

### Kasa farkı çıkarsa ne yapmalıyım?
- **Kasayı Kapat** ekranında fark gösterilir
- Nedeni belirtin (örn. "Hatalı sayım")
- Z Raporunda kayıt altına alınır

---

## 🎯 İpuçları ve En İyi Uygulamalar

### Hızlı Satış İçin
- 📷 **Barkod okumayı** kullanın (en hızlı yöntem)
- 🔄 **Favori ürünleri** üst sıralarda tutun
- ⌨️ **Kısayol tuşları**: Sık kullanılan ürünler için

### Stok Yönetimi
- ⚠️ **Kritik stok seviyesini** mantıklı belirleyin
- 📊 **Haftalık stok kontrolü** yapın
- 🔔 **Bildirimleri** açık tutun

### Veri Güvenliği
- 💾 **Düzenli yedekleme** yapın
- 🔐 **Güçlü şifre** kullanın
- 📱 **Cihazı güncel** tutun

### Performans
- 🗑️ **Eski kayıtları** arşivleyin (6 aydan eskiler)
- 📷 **Ürün fotoğraflarını** sıkıştırın
- 🔄 **Uygulamayı güncelleyin** (yeni özellikler için)

---

## 📞 Destek ve İletişim

### Teknik Destek
Sorun yaşarsanız:
1. **Ayarlar** > **Yardım & Destek**
2. Sorun bildirim formu doldurun
3. Veya sistem yöneticinize başvurun

### Geri Bildirim
Önerilerinizi bekliyoruz:
- 📧 İletişim formu (Ayarlar içinde)
- ⭐ Uygulama içi değerlendirme

---

**Son Güncelleme:** Aralık 2025  
**Versiyon:** 1.0.1+3  
**Platform:** Android & iOS

---

✨ **İyi satışlar!** 🛒
