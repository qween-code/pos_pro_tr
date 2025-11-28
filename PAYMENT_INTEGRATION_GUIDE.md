# ÖDEME VE FATURA ENTEGRASYONLARpı REHBERİ

## 🏦 POS Terminal Entegrasyonları

### 1. İyzico (Öncelikli)
**Neden İyzico?**
- ✅ Türkiye'nin en popüler ödeme altyapısı
- ✅ RESTful API - kolay entegrasyon
- ✅ 3D Secure desteği
- ✅ Taksit seçenekleri
- ✅ Marketplace desteği

**Kurulum Adımları:**

```bash
# Gerekli paketler
flutter pub add http
flutter pub add crypto
```

**API Anahtarları:**
- Sandbox: https://sandbox-api.iyzipay.com
- Production: https://api.iyzipay.com
- Dashboard: https://merchant.iyzipay.com

**Kullanım:**
```dart
final iyzico = IyzicoProvider(
  apiKey: 'YOUR_API_KEY',
  secretKey: 'YOUR_SECRET_KEY',
);

final response = await iyzico.processPayment(paymentRequest);
```

**Fiyatlandırma:**
- Kurulum: Ücretsiz
- Komisyon: %2.99 + ₺0.25 (işlem başına)
- Aylık: ₺0

---

### 2. PayTR
**Özellikler:**
- ✅ Sanal POS
- ✅ BKM Express
- ✅ Havale/EFT
- ✅ Masterpass

**Komisyon:** %1.99 - %2.99

---

### 3. Param (İş Bankası)
**Özellikler:**
- ✅ İş Bankası altyapısı
- ✅ Kurumsal çözüm
- ✅ Yüksek güvenlik

---

## 📄 E-FATURA Entegrasyonu

### GİB (Gelir İdaresi Başkanlığı) E-Fatura

**Entegrasyon Süreci:**

1. **E-Fatura Mükellefi Olma**
   ```
   - GİB'e başvuru
   - E-imza temin etme
   - Entegrasyon testi
   ```

2. **Entegratör Seçimi**
   - Logo Tiger
   - Uyumsoft
   - Uyumsoft
   - SET E-Fatura
   - EFaturaTR

3. **UBL-TR XML Formatı**
   - Türkiye standart fatura formatı
   - XML generator hazırladım

**Kullanım:**
```dart
final einvoice = EInvoiceService(
  companyVkn: '1234567890',
  companyTitle: 'ŞİRKET A.Ş.',
  integrationUrl: 'https://efatura-entegrator.com/api',
  username: 'kullanici',
  password: 'sifre',
);

final response = await einvoice.createInvoice(invoiceData);
```

**E-Fatura vs E-Arşiv:**
- **E-Fatura:** Kurumsal müşteriler (VKN var)
- **E-Arşiv:** Bireysel müşteriler (VKN yok)

---

## 💳 Fiziksel POS Entegrasyonu

### Bluetooth POS Terminaller

**Önerilen Cihazlar:**
1. **Sunmi P2 Pro** (Android POS)
2. **PAX A920** (Android)
3. **Ingenico Move 5000** (Bluetooth)

**Flutter Bluetooth Paketi:**
```bash
flutter pub add flutter_bluetooth_serial
```

**Kullanım:**
```dart
// Bluetooth POS bağlantısı
final pos = BluetoothPOSService();
await pos.connect('POS_DEVICE_ADDRESS');
await pos.printReceipt(receiptData);
```

---

## 🔐 Güvenlik

### PCI DSS Uyumu
```dart
// Kart bilgilerini ASLA kaydetmeyin!
// Tokenization kullanın

final cardToken = await paymentProvider.tokenize(cardInfo);
// Sadece token'ı saklayın, kart numarasını değil
```

### SSL/TLS
```dart
// Tüm API çağrıları HTTPS üzerinden
SecurityContext context = SecurityContext.defaultContext;
```

---

## 📊 Test Kartları

### İyzico Test Kartları
```
Başarılı: 5528790000000008
CVV: 123
Expire: 12/30

3D Secure: 5528 7900 0000 0008
Password: test
```

---

## 💰 Maliyet Analizi

| Servis | Kurulum | Komisyon | Aylık |
|--------|---------|----------|-------|
| İyzico | ₺0 | %2.99 | ₺0 |
| PayTR | ₺0 | %1.99-2.99 | ₺0 |
| Param | ₺500 | %1.85 | ₺50 |

| E-Fatura Entegratörü | Kurulum | Aylık |
|---------------------|---------|-------|
| Logo Tiger | ₺1,500 | ₺200 |
| Uyumsoft | ₺1,000 | ₺150 |
| EFaturaTR | ₺800 | ₺100 |

---

## 🚀 Implementasyon Planı

### Faz 1: Sanal POS (1 hafta)
- [x] İyzico entegrasyonu
- [ ] PayTR entegrasyonu
- [ ] Test ortamı

### Faz 2: E-Fatura (2 hafta)
- [x] UBL-TR XML generator
- [ ] Entegratör seçimi
- [ ] GİB test ortamı
- [ ] Production onayı

### Faz 3: Fiziksel POS (1 hafta)
- [ ] Bluetooth POS entegrasyonu
- [ ] Fiş yazdırma
- [ ] Sunmi cihaz testi

### Faz 4: Raporlama (3 gün)
- [ ] Mali raporlar
- [ ] Z raporu
- [ ] Günlük ciro raporları

---

## 📞 Destek & Dokümantasyon

**İyzico:**
- Docs: https://dev.iyzipay.com
- Support: destek@iyzipay.com
- Tel: 0850 259 99

**GİB E-Fatura:**
- Portal: https://ebelge.gib.gov.tr
- Destek: 444 0 189

---

## ⚠️ Önemli Notlar

1. **Test önce, prod sonra!**
2. **Kart bilgilerini ASLA kaydetmeyin**
3. **Log'ları güvenli tutun**
4. **İadeleri takip edin**
5. **E-Fatura mükellef olun**
6. **Mali müşavirinizle çalışın**

---

## 📝 Kullanım Örneği

```dart
// 1. Sipariş oluştur
final order = await createOrder(items);

// 2. Ödeme al
final payment = await iyzico.processPayment(paymentRequest);

if (payment.success) {
  // 3. E-Fatura kes
  final invoice = await einvoice.createInvoice(invoiceData);
  
  // 4. PDF yazdır
  final pdf = await einvoice.downloadInvoicePDF(invoice.uuid);
  
  // 5. Müşteriye e-posta gönder
  await sendInvoiceEmail(customer, pdf);
}
```

---

**SON GÜNCELLEME:** 28 Kasım 2025
