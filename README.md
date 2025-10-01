# 📚 Okul Kütüphanesi Yönetim Sistemi (Flutter & MSSQL)

Okul kütüphanesindeki kitapların, öğrencilerin ve ödünç verme/iade işlemlerinin kolayca yönetilmesi için tasarlanmış bir windows uygulamasıdır. **Flutter** ile geliştirilmiş olup, tüm veri yönetimi ve depolama işlemleri **Microsoft SQL Server (MSSQL)** veritabanı ile yapılmaktadır.

---

## 🌟 Temel Özellikler

* **Roman Yönetimi (CRUD):** Türkçe ve Yabancı Romanlar için ayrı ekranlar üzerinden kitap **ekleme, düzenleme, silme** ve **listeleme** işlemleri.
* **Ödünç İşlemleri:** Kitapları öğrencilere ödünç verme ve iade alma kayıtlarını tutma. Kayıtları arama ve **iade edilmeyenleri filtreleme** yeteneği.
* **Ayarlanabilir Veritabanı:** Uygulama içinden **MSSQL bağlantı IP adresi** ve **Port numarası** gibi kritik ayarları kolayca yapılandırma ve kalıcı olarak kaydetme.
* **Merkezi Veri Servisi:** `SqlService` sınıfı sayesinde tek bir bağlantı örneği üzerinden tüm veri işlemlerinin güvenilir bir şekilde yönetimi.

---https://github.com/Kompetankedi/kutuphaneFlutter/edit/master/README.md

## 🛠️ Teknolojiler

| Kategori | Teknoloji | Amaç |
| :--- | :--- | :--- |
| **Mobil Geliştirme** | Flutter (Dart) | Çapraz platform mobil uygulama geliştirme. |
| **Veritabanı** | Microsoft SQL Server (MSSQL) | Tüm kütüphane verilerini depolama ve yönetme. |
| **MSSQL Kütüphanesi** | `mssql_connection` | Flutter uygulamasından MSSQL'e doğrudan bağlantı. |
| **Yerel Depolama** | `shared_preferences` | Uygulama ayarlarını (IP/Port) cihazda kalıcı tutma. |

---

## ⚙️ Kurulum ve Başlangıç

### 1. Veritabanı Hazırlığı (MSSQL)

Uygulamanın çalışması için gerekli MSSQL veritabanını kurun ve bağlantı bilgilerini ayarlayın.

1.  **Veritabanı Adı:** Varsayılan olarak **`dbkutuphane`** kullanılmaktadır.
2.  **Kullanıcı Adı/Şifre:** Bağlantı için varsayılan kimlik bilgileri:
    * **Kullanıcı Adı:** `flutter`
    * **Şifre:** `pro`
3.  **Tablolar:** Uygulamanın beklediği **`TrRoman`**, **`YabanciRoman`**, **`Oislemler`** gibi tabloların veritabanınızda oluşturulduğundan emin olun.

### 2. Flutter Uygulamasını Çalıştırma

1.  Projeyi klonlayın ve klasöre girin:
    ```bash
    git clone https://github.com/Kompetankedi/kutuphaneFlutter.git
    cd kutuphaneFlutter-master
    ```
2.  Bağımlılıkları yükleyin:
    ```bash
    flutter pub get
    ```
3.  Uygulamayı çalıştırın (tercihen bir emülatör veya fiziksel cihazda):
    ```bash
    flutter run
    ```

### 3. Uygulama İçi Bağlantı Ayarları

Uygulama çalıştıktan sonra, ana menüdeki **Ayarlar** (`SettingsScreen`) ekranına giderek MSSQL sunucunuzun doğru **IP adresini** ve **Port numarasını** (Varsayılan: `1433`) girip kaydedin. Uygulama, bağlantıyı bu ayarlara göre yapacaktır.

---

## 📂 Önemli Dosyalar

| Dosya Adı | İşlev |
| :--- | :--- |
| `sql_service.dart` | Tüm MSSQL bağlantısı, ayar yükleme/kaydetme ve CRUD işlemlerini yöneten merkezi katman. |
| `settings_screen.dart` | Kullanıcının MSSQL IP ve Port ayarlarını yapabildiği arayüz. |
| `tr_roman_screen.dart` | Türkçe Roman listeleme, arama ve yönetimi (CRUD). |
| `odunc_islemleri_screen.dart` | Ödünç ve iade kayıtlarını yöneten ana ekran. |
| `add_edit_odunc_screen.dart` | Yeni ödünç kaydı ekleme veya mevcut kaydı düzenleme (iade etme) formu. |
| `main.dart` | Uygulamanın giriş noktası ve ana menü (`MainMenuScreen`). |
