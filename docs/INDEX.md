# 📚 PosPro TR - Dokümantasyon İndeksi

> Tüm proje dökümanlarına hızlı erişim rehberi

---

## 🎯 Hızlı Navigasyon

### 📘 Ana Dokümantasyon

| Doküman | Açıklama | Hedef Kitle |
|---------|----------|-------------|
| **[README.md](../README.md)** | Projenin ana tanıtım dosyası, teknik genel bakış | Geliştiriciler, Teknik Ekip |
| **[KULLANIM_REHBERI.md](../KULLANIM_REHBERI.md)** | Mobil uygulama kullanım kılavuzu | Son Kullanıcılar, Kasiyerler |

### 🏗️ Mimari Dokümantasyon

| Doküman | İçerik | Format |
|---------|--------|--------|
| **[INFOGRAPHIC_ARCHITECTURE.md](./INFOGRAPHIC_ARCHITECTURE.md)** | 🎨 **İnfografik mimari** - Tüm sistem görsel diyagramlarla | Görsel + Kod |
| **[ARCHITECTURE.md](./ARCHITECTURE.md)** | 📐 Detaylı sistem mimarisi açıklaması | Tekst + Kod |
| **[VISUAL_ARCHITECTURE.md](./VISUAL_ARCHITECTURE.md)** | 📊 ASCII diyagramlar ile görsel mimari | ASCII Art |
| **[TECH_STACK.md](./TECH_STACK.md)** | 🛠️ Kullanılan teknolojiler listesi | Tekst + Liste |
| **[MEDIATOR_AND_API_IMPLEMENTATION.md](./MEDIATOR_AND_API_IMPLEMENTATION.md)** | 🔌 Mediator pattern ve API entegrasyonu | Tekst + Kod |

---

## 📁 Dokümantasyon Yapısı

```
docs/
├── 🎨 INFOGRAPHIC_ARCHITECTURE.md    # ⭐ BAŞLANGIÇ NOKTASI
│   ├─ Sistem mimarisi görsel harita
│   ├─ Veri akış diyagramları
│   ├─ Teknoloji yığını infografiği
│   ├─ Database schema görsel
│   └─ Kullanıcı akış diyagramları
│
├── 📐 ARCHITECTURE.md
│   ├─ Clean Architecture katmanları
│   ├─ MVVM pattern açıklaması
│   ├─ Proje klasör yapısı
│   ├─ Veri akış detayları
│   └─ Design pattern'ler
│
├── 📊 VISUAL_ARCHITECTURE.md
│   ├─ ASCII diyagramlar
│   ├─ Katman yapısı
│   ├─ Komponent iletişimi
│   └─ Error handling akışı
│
├── 🛠️ TECH_STACK.md
│   ├─ Frontend teknolojileri
│   ├─ Backend servisleri
│   ├─ Database çözümleri
│   └─ Kullanılan paketler
│
├── 🔌 MEDIATOR_AND_API_IMPLEMENTATION.md
│   ├─ Mediator pattern implementasyonu
│   ├─ Event-driven architecture
│   └─ REST API entegrasyonu
│
└── 📚 INDEX.md (Bu dosya)
    └─ Tüm dokümanlara hızlı erişim
```

---

## 🎯 Kime Göre Hangi Doküman?

### 👨‍💼 Proje Yöneticisi / Müşteri
```
1. README.md (Genel Bakış)
   └─ Proje özellikleri, teknik yetenekler
   
2. INFOGRAPHIC_ARCHITECTURE.md
   └─ Sistem mimarisi görsel özet
   
3. KULLANIM_REHBERI.md
   └─ Uygulamanın nasıl kullanılacağı
```

### 👨‍💻 Backend/Frontend Geliştirici
```
1. ARCHITECTURE.md
   └─ Detaylı mimari açıklama
   
2. TECH_STACK.md
   └─ Teknoloji ve paket listesi
   
3. MEDIATOR_AND_API_IMPLEMENTATION.md
   └─ API ve event system
   
4. README.md
   └─ Kod örnekleri ve pattern'ler
```

### 🎨 UI/UX Tasarımcı
```
1. INFOGRAPHIC_ARCHITECTURE.md
   └─ Kullanıcı akış diyagramları
   
2. KULLANIM_REHBERI.md
   └─ Ekran akışları ve özellikler
```

### 🧪 QA / Test Mühendisi
```
1. KULLANIM_REHBERI.md
   └─ Tüm özellikler ve kullanım senaryoları
   
2. ARCHITECTURE.md
   └─ Test stratejisi bölümü
   
3. INFOGRAPHIC_ARCHITECTURE.md
   └─ İş akış diyagramları
```

### 🎓 Yeni Geliştirici (Onboarding)
```
Önerilen Okuma Sırası:
1. README.md → Genel bakış
2. INFOGRAPHIC_ARCHITECTURE.md → Görsel mimari
3. ARCHITECTURE.md → Detaylı mimari
4. TECH_STACK.md → Teknolojiler
5. MEDIATOR_AND_API_IMPLEMENTATION.md → Event system
```

---

## 📊 Dokümantasyon İstatistikleri

| Doküman | Satır Sayısı | Boyut | Karmaşıklık |
|---------|--------------|-------|-------------|
| README.md | ~1,385 | 48 KB | ⭐⭐⭐⭐⭐ |
| KULLANIM_REHBERI.md | ~442 | 13 KB | ⭐⭐ |
| INFOGRAPHIC_ARCHITECTURE.md | ~600+ | ~25 KB | ⭐⭐⭐⭐ |
| ARCHITECTURE.md | ~469 | 18 KB | ⭐⭐⭐⭐ |
| VISUAL_ARCHITECTURE.md | ~395 | 27 KB | ⭐⭐⭐ |
| TECH_STACK.md | ~226 | 6 KB | ⭐⭐ |
| MEDIATOR_AND_API_IMPLEMENTATION.md | ~200 | 7 KB | ⭐⭐⭐⭐ |

**Toplam:** ~3,700+ satır kapsamlı dokümantasyon

---

## 🔍 Anahtar Kelimeler ile Arama

### Mimari Pattern'leri Ararken
- **MVVM** → ARCHITECTURE.md, INFOGRAPHIC_ARCHITECTURE.md
- **Repository Pattern** → ARCHITECTURE.md, README.md
- **Clean Architecture** → ARCHITECTURE.md, README.md
- **Mediator Pattern** → MEDIATOR_AND_API_IMPLEMENTATION.md, README.md

### Teknoloji Ararken
- **Flutter** → TECH_STACK.md, README.md
- **GetX** → TECH_STACK.md, ARCHITECTURE.md, README.md
- **Drift/SQLite** → TECH_STACK.md, README.md
- **Firebase** → TECH_STACK.md, ARCHITECTURE.md

### Özellik Ararken
- **Satış İşlemi** → KULLANIM_REHBERI.md, INFOGRAPHIC_ARCHITECTURE.md
- **Barkod Okuma** → KULLANIM_REHBERI.md, TECH_STACK.md
- **Raporlama** → KULLANIM_REHBERI.md, README.md
- **Offline Sync** → ARCHITECTURE.md, README.md

### Veri Akışı Ararken
- **Hybrid Repository** → ARCHITECTURE.md, INFOGRAPHIC_ARCHITECTURE.md
- **Background Sync** → ARCHITECTURE.md, README.md
- **State Management** → ARCHITECTURE.md, INFOGRAPHIC_ARCHITECTURE.md

---

## ✨ En Popüler Bölümler

### 🥇 En Çok Başvurulan
1. **README.md** - Database Schema (SQL kodları)
2. **INFOGRAPHIC_ARCHITECTURE.md** - Veri akış diyagramları
3. **KULLANIM_REHBERI.md** - Satış işlemi adımları
4. **ARCHITECTURE.md** - Hybrid Repository pattern

### 🏆 En Detaylı Açıklamalar
1. **README.md** - GetX State Management örnekleri
2. **ARCHITECTURE.md** - Clean Architecture katmanları
3. **MEDIATOR_AND_API_IMPLEMENTATION.md** - Event system

### 🎨 En Görsel İçerik
1. **INFOGRAPHIC_ARCHITECTURE.md** - ASCII + açıklama
2. **VISUAL_ARCHITECTURE.md** - Saf ASCII diyagramlar
3. **README.md** - Kod + diyagram karışımı

---

## 📝 Dokümantasyon Güncellemeleri

### Son Güncellemeler
- **Aralık 2025**: Tüm dokümantasyon oluşturuldu
- **INFOGRAPHIC_ARCHITECTURE.md**: YENİ - Görsel mimari rehberi eklendi
- **INDEX.md**: YENİ - Navigasyon dosyası eklendi

### Planlanan Eklemeler
- [ ] API Endpoint listesi
- [ ] Test coverage raporları
- [ ] Deployment rehberi
- [ ] Troubleshooting guide

---

## 🚀 Hızlı Başlangıç Akışı

### Yeni Başlayanlar İçin 5 Dakikalık Tur

```
1. README.md (İlk 100 satır okuyun)
   ↓
2. INFOGRAPHIC_ARCHITECTURE.md (Görsel diyagramlara bakın)
   ↓
3. KULLANIM_REHBERI.md (Uygulama nasıl çalışır?)
   ↓
4. ARCHITECTURE.md (Kodlamaya başlamadan önce)
   ↓
5. TECH_STACK.md (Hangi teknolojiler var?)
```

### Geliştirmeye Başlarken

```
1. ARCHITECTURE.md
   └─ Proje Yapısı bölümü (Hangi dosya nerede?)
   
2. README.md
   └─ GetX State Management (Nasıl kod yazılır?)
   
3. MEDIATOR_AND_API_IMPLEMENTATION.md
   └─ Event system (Modüller arası iletişim)
```

---

## 📞 Destek ve İletişim

- **Teknik Sorular**: README.md içindeki kod örnekleri
- **Kullanım Sorunları**: KULLANIM_REHBERI.md
- **Mimari Kararlar**: ARCHITECTURE.md
- **Görsel Anlatım**: INFOGRAPHIC_ARCHITECTURE.md

---

## 📌 Önemli Notlar

⚠️ **Dikkat:**
- Tüm dokümantasyon **Türkçe** dilindedir
- Kod örnekleri **Flutter/Dart** ile yazılmıştır
- Diyagramlar **UTF-8** encoding gerektirir
- Markdown görüntüleyici gereklidir

✅ **Önerilen Markdown Görüntüleyiciler:**
- VS Code (Markdown Preview Enhanced)
- Typora
- GitHub/GitLab web arayüzü
- Obsidian

---

**Dokümantasyon Versiyonu:** 1.0  
**Son Güncelleme:** Aralık 2025  
**Toplam Sayfa:** 7 ana doküman  
**Toplam Kelime:** ~15,000+
