# SpendSense — Smart Expense Tracker App  

<p align="center">
  <img src="img/logo_withtext.png" width="600" alt="SpendSense Logo"/>
</p>

A modern Flutter-based money management application built with **Supabase**, **Flutter**, and **Material Design 3**.  
SpendSense membantu pengguna mencatat pemasukan, pengeluaran, dan transfer antar akun secara cepat, aman, dan intuitif.

---

## 📋 Getting Started

### 📱 **Cara Termudah: Install APK (Recommended)**

Langsung install aplikasi di Android tanpa perlu setup development environment!

#### **1️⃣ Download APK**
1. Buka halaman [Releases](https://github.com/aryabimasantoso21/spendsense/releases)
2. Download file **`spendsense-v0.2.0.apk`** dari release terbaru

#### **2️⃣ Install di Android**
1. **Transfer APK ke HP Android** (via USB, Bluetooth, atau download langsung di HP)
2. **Buka file APK** di HP
3. Jika muncul peringatan "Install dari sumber tidak dikenal":
   - Buka **Settings** → **Security** → Aktifkan **Unknown Sources** atau **Install Unknown Apps**
4. Klik **Install** dan tunggu hingga selesai
5. Buka aplikasi **SpendSense** dan mulai gunakan! 🎉

#### **3️⃣ Buat Akun**
1. Buka aplikasi SpendSense
2. Klik tombol **Register** untuk membuat akun baru
3. Isi **Username**, **Email**, dan **Password**
4. Login dan mulai kelola keuangan Anda!

> **Catatan**: Backend menggunakan Supabase yang sudah dikonfigurasi, jadi Anda bisa langsung menggunakan aplikasi tanpa setup tambahan!

---

### 🛠️ **Untuk Developer: Build dari Source Code**

Jika Anda ingin build aplikasi dari source code atau berkontribusi dalam development:

<details>
<summary><b>Klik untuk melihat panduan developer</b></summary>

#### **Prerequisites**

Pastikan komputer Anda telah menginstal software berikut:

- **Git** → https://git-scm.com/downloads  
- **VS Code** → https://code.visualstudio.com  
- **Flutter SDK** → https://docs.flutter.dev/get-started/install  
- Pastikan `flutter doctor` centang hijau semua ✅
- **Android Studio** (untuk emulator Android)
- **Xcode** (untuk iOS - hanya macOS)

#### **Clone Repository**

```bash
git clone https://github.com/aryabimasantoso21/spendsense.git
cd spendsense
```

#### **Install Flutter Dependencies**

```bash
flutter pub get
```

#### **Setup Backend (Optional - Sudah Ada Default)**

#### **Setup Backend (Optional - Sudah Ada Default)**

Aplikasi sudah terhubung ke backend Supabase default. Jika Anda ingin menggunakan backend sendiri:

##### **Step 1: Buat Project Supabase**
1. Buka https://supabase.com  
2. Login / Sign Up dengan akun Google atau Email  
3. Klik tombol **New Project**  
4. Masukkan nama project: **SpendSense**  
5. Buat password database yang kuat  
6. Pilih region terdekat (contoh: Singapore)
7. Klik **Create Project**  
8. Tunggu hingga status menjadi hijau/aktif (~2-3 menit)

##### **Step 2: Create Table Database**

1. Di dashboard Supabase, buka menu **SQL Editor**
2. Copy dan paste SQL query di bawah ini → klik **Run**:

```sql
-- RESET TABEL (jalankan ini jika ada tabel lama)
DROP TABLE IF EXISTS transactions CASCADE;
DROP TABLE IF EXISTS accounts CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- USERS TABLE
CREATE TABLE users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(255),
  email TEXT UNIQUE NOT NULL,
  password TEXT,
  total_balance DOUBLE PRECISION DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- CATEGORIES TABLE
CREATE TABLE categories (
  category_id SERIAL PRIMARY KEY,
  type VARCHAR(50) NOT NULL,
  name VARCHAR(100) NOT NULL
);

-- ACCOUNTS TABLE
CREATE TABLE accounts (
  account_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  account_name VARCHAR(100) NOT NULL,
  account_type VARCHAR(50) NOT NULL,
  balance DOUBLE PRECISION DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- TRANSACTIONS TABLE
CREATE TABLE transactions (
  transaction_id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
  account_id INTEGER REFERENCES accounts(account_id) ON DELETE CASCADE,
  destination_account_id INTEGER REFERENCES accounts(account_id) ON DELETE SET NULL,
  category_id INTEGER REFERENCES categories(category_id) ON DELETE SET NULL,
  type VARCHAR(50) NOT NULL,
  amount DOUBLE PRECISION NOT NULL,
  description VARCHAR(255),
  date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- SEED DEFAULT CATEGORIES
INSERT INTO categories (type, name) VALUES
('income', 'Gaji'),
('income', 'Hadiah'),
('income', 'Investasi'),
('expense', 'Makanan & Minuman'),
('expense', 'Transportasi'),
('expense', 'Belanja'),
('expense', 'Tagihan'),
('expense', 'Hiburan'),
('expense', 'Kesehatan'),
('expense', 'Pendidikan');
```

##### **Step 3: Dapatkan Supabase Credentials**
1. Di dashboard Supabase, buka menu **Settings** → **API**
2. Copy **Project URL** dan **anon key**
3. Buka file `lib/data/services/supabase_service.dart` di VS Code
4. Cari dan ganti variable:
   ```dart
    Future<void> init() async {
        await Supabase.initialize(
            url: 'YOUR_PROJECT_URL',
            anonKey: 'YOUR_ANON_KEY',
    );
    
   ```
   Ganti dengan URL dan key dari Supabase Anda

##### **Step 4: Enable Authentication**
1. Di dashboard Supabase, buka menu **Authentication** → **Providers**
2. Cari provider **Email** dan pastikan toggle aktif (warna biru)
3. Konfigurasi email templates jika diperlukan

#### **Build & Run**

##### **🤖 Android (Emulator atau Device)**

###### **Opsi 1: Menggunakan Android Emulator**

```bash
# Lihat emulator yang tersedia
flutter emulators

# Buka emulator tertentu (ganti <nama> dengan nama emulator)
flutter emulators --launch <nama>

# Jalankan aplikasi
flutter run
```

###### **Opsi 2: Menggunakan Device Android Fisik**

```bash
# Aktifkan USB Debugging di device Android
# Settings → About → Tekan Build Number 7x → Developer Options → USB Debugging

# Hubungkan device via USB
# Cek device yang terdeteksi
flutter devices

# Jalankan aplikasi
flutter run
```

###### **Build APK Release**
```bash
flutter build apk --release
# APK akan tersimpan di: build/app/outputs/flutter-apk/app-release.apk
```

##### **🍎 iOS (macOS only)**

```bash
cd ios
pod install
cd ..
open -a Simulator
flutter run
```

##### **🌐 Web**

```bash
flutter run -d chrome
```

##### **🪟 Windows**

```bash
flutter run -d windows
```

</details>

---

## 🚀 Quick Start Guide

### **Langkah Cepat Mulai Menggunakan SpendSense:**

1. **Download & Install APK** dari [GitHub Releases](https://github.com/aryabimasantoso21/spendsense/releases)
2. **Register akun baru** dengan email dan password
3. **Tambah akun pertama** (Bank/Cash/E-Wallet) dengan saldo awal
4. **Catat transaksi pertama** - Expense, Income, atau Transfer
5. **Buat budget** untuk kontrol pengeluaran per kategori
6. **Lihat statistik** pengeluaran Anda di tab Statistics

🎉 Selamat! Anda sudah siap mengelola keuangan dengan SpendSense!

---

## 🎯 Deskripsi Proyek

**SpendSense** adalah aplikasi manajemen keuangan pribadi yang dirancang untuk memudahkan pengguna dalam:

- 💰 **Mencatat Transaksi** - Mencatat pemasukan (income), pengeluaran (expense), dan transfer antar akun
- 🏦 **Mengelola Akun** - Membuat dan mengelola berbagai akun (Bank, Cash, E-Wallet)
- 📊 **Visualisasi Data** - Melihat statistik pengeluaran dan pemasukan dalam bentuk chart/grafik
- 🔐 **Keamanan Data** - Setiap user hanya bisa melihat data miliknya sendiri
- 🌐 **Multi-Platform** - Tersedia untuk Android, iOS, Web, Windows, dan Linux

### 🚀 Fitur Utama

#### **Manajemen Pengguna**
- ✅ Registrasi & Login dengan Email
- ✅ Penyimpanan total balance per user
- ✅ Isolasi data: setiap user hanya melihat datanya sendiri

#### **Manajemen Akun**
- ✅ Tambah akun (Bank / Cash / E-Wallet)
- ✅ Penyimpanan saldo untuk masing-masing akun
- ✅ Transfer uang antar akun

#### **Manajemen Transaksi**
- ✅ Pencatatan **Income**, **Expense**, dan **Transfer**
- ✅ Pengkategorian otomatis berdasarkan jenis transaksi
- ✅ List transaksi yang terurut otomatis berdasarkan tanggal (terbaru di atas)

#### **Kategori Default**
Aplikasi memiliki kategori awal seperti:
- **Income**: Gaji, Hadiah, Investasi  
- **Expense**: Makanan & Minuman, Transportasi, Belanja, Tagihan, Hiburan, Kesehatan, Pendidikan

### 🛠️ **Tech Stack**

| Teknologi | Versi | Fungsi |
|-----------|-------|--------|
| **Flutter** | ^3.9.2 | Framework UI cross-platform |
| **Dart** | ^3.9.2 | Programming language |
| **Supabase** | ^2.10.3 | Backend & Database (PostgreSQL) |
| **Material Design 3** | - | UI Design System |
| **FL Chart** | ^0.68.0 | Data visualization library |
| **Image Picker** | ^1.2.1 | Galeri & Camera picker |
| **Shared Preferences** | ^2.2.2 | Local storage |
| **IntL** | ^0.20.2 | Internationalization |

---

## 📁 Struktur Folder & Database

### **📂 Project Folder Structure**

```
spendsense/
├── 📄 pubspec.yaml                # Konfigurasi project & dependencies
├── 📄 analysis_options.yaml       # Analisis code style
├── 📄 l10n.yaml                   # Konfigurasi localization
├── 📄 README.md                   # Dokumentasi project
│
├── 📂 lib/                        # 🎯 SOURCE CODE UTAMA
│   ├── 📄 main.dart              # Entry point aplikasi
│   │
│   ├── 📂 data/                   # Data Layer
│   │   ├── 📂 models/            # Model data structure
│   │   │   ├── account_model.dart        # Model untuk Account
│   │   │   ├── budget_model.dart         # Model untuk Budget
│   │   │   ├── category_model.dart       # Model untuk Category
│   │   │   └── transaction_model.dart    # Model untuk Transaction
│   │   │
│   │   └── 📂 services/          # API & Database services
│   │       ├── supabase_service.dart      # Supabase backend connector
│   │       ├── local_storage_service.dart # Local storage (SharedPreferences)
│   │       └── theme_service.dart         # Theme management (Light/Dark)
│   │
│   ├── 📂 presentation/           # Presentation Layer
│   │   ├── 📂 pages/             # Main application pages
│   │   │   ├── splash_screen.dart           # Loading screen pertama
│   │   │   ├── login_page.dart              # Login page
│   │   │   ├── register_page.dart           # Register page
│   │   │   ├── home_page.dart               # Home/Dashboard
│   │   │   ├── transactions_page.dart       # List transaksi
│   │   │   ├── transactions_page_new.dart   # New transactions view
│   │   │   ├── add_transaction_page.dart    # Add/Edit transaction
│   │   │   ├── accounts_page.dart           # List accounts
│   │   │   ├── add_account_page.dart        # Add/Edit account
│   │   │   ├── edit_account_balance_page.dart # Edit balance
│   │   │   ├── add_budget_page.dart         # Add/Edit budget
│   │   │   ├── budget_detail_page.dart      # Budget detail & tracking
│   │   │   ├── statistics_page.dart         # Charts & analytics
│   │   │   └── settings_page.dart           # Settings & preferences
│   │   │
│   │   └── 📂 widgets/           # Reusable UI Components
│   │       ├── account_card.dart         # Account card widget
│   │       ├── budget_card.dart          # Budget card widget (main)
│   │       ├── budget_card_item.dart     # Budget card item (list)
│   │       └── transaction_card.dart     # Transaction card widget
│   │
│   ├── 📂 utils/                  # Utility & Helper Functions
│   │   ├── constants.dart         # App colors, strings, sizes, styles
│   │   └── formatters.dart        # Formatters untuk currency, date, dll
│   │
│   └── 📂 l10n/                   # Localization (Multi-language)
│       ├── app_en.arb           # English translations
│       ├── app_localizations.dart
│       └── app_localizations_en.dart
│
├── 📂 android/                    # Android Native Code
│   ├── 📄 build.gradle.kts       # Gradle configuration
│   ├── 📄 local.properties       # Local Android SDK path
│   ├── 📄 gradle.properties      # Gradle properties
│   ├── 📄 settings.gradle.kts
│   ├── 📂 app/
│   │   ├── build.gradle.kts
│   │   └── 📂 src/
│   │       ├── main/
│   │       ├── debug/
│   │       └── profile/
│   └── 📂 gradle/
│       └── wrapper/
│
├── 📂 ios/                        # iOS Native Code
│   ├── 📂 Flutter/               # Flutter iOS configuration
│   ├── 📂 Runner/                # iOS app resources
│   ├── 📂 Runner.xcodeproj/      # Xcode project
│   ├── 📂 Runner.xcworkspace/    # Cocoapods workspace
│   └── 📂 RunnerTests/           # iOS tests
│
├── 📂 macos/                      # macOS Platform
│   ├── 📂 Flutter/               # Flutter macOS configuration
│   ├── 📂 Runner/                # macOS app resources
│   └── 📂 Runner.xcodeproj/      # Xcode project
│
├── 📂 web/                        # Web Platform
│   ├── 📄 index.html             # Web entry point
│   ├── 📄 manifest.json          # Web app manifest
│   └── 📂 icons/                 # Web icons
│
├── 📂 windows/                    # Windows Platform
│   ├── 📄 CMakeLists.txt
│   ├── 📂 runner/
│   └── 📂 flutter/
│
├── 📂 linux/                      # Linux Platform
│   ├── 📄 CMakeLists.txt
│   ├── 📂 runner/
│   └── 📂 flutter/
│
├── 📂 test/                       # Unit & Widget Tests
│   └── 📄 widget_test.dart      # Widget test example
│
├── 📂 build/                      # Build
│   ├── 📂 flutter_assets/        # Compiled assets
│   └── 📂 reports/               # Build reports
│
└── 📂 img/                        # Assets (Images & Icons)
    ├── 📂 ss_light/             # Light mode screenshots
    │   ├── ss_splash.png
    │   ├── ss_login.png
    │   ├── ss_home.png
    │   ├── ss_stats.png
    │   ├── ss_history.png
    │   ├── ss_accounts.png
    │   ├── ss_input.png
    │   ├── ss_budget.png
    │   └── ss_profile.png
    ├── 📂 ss_dark/              # Dark mode screenshots
    │   ├── ss_home_dark.png
    │   ├── ss_stats_dark.png
    │   ├── ss_history_dark.png
    │   ├── ss_accounts_dark.png
    │   └── ss_profile_dark.png
    ├── 📄 logo.png              # App logo
    └── 📄 logo_withtext.png     # Logo with text
```

### **📊 Database Schema (Supabase PostgreSQL)**

#### **Users Table**
```
users
├── user_id (SERIAL PRIMARY KEY)
├── username (VARCHAR 255)
├── email (TEXT UNIQUE NOT NULL)
├── password (TEXT - hashed by Supabase Auth)
├── total_balance (DOUBLE PRECISION, DEFAULT 0)
└── created_at (TIMESTAMP WITH TIME ZONE, DEFAULT NOW())
```
**Fungsi**: Menyimpan data user yang register/login

---

#### **Categories Table**
```
categories
├── category_id (SERIAL PRIMARY KEY)
├── type (VARCHAR 50: 'income' atau 'expense')
└── name (VARCHAR 100: 'Gaji', 'Makanan', dll)
```
**Fungsi**: Kategori transaksi yang bisa dipilih user
**Default Categories**:
- Income: Gaji, Hadiah, Investasi
- Expense: Makanan & Minuman, Transportasi, Belanja, Tagihan, Hiburan, Kesehatan, Pendidikan

---

#### **Accounts Table**
```
accounts
├── account_id (SERIAL PRIMARY KEY)
├── user_id (INTEGER FK → users)
├── account_name (VARCHAR 100: 'BCA', 'Cash', dll)
├── account_type (VARCHAR 50: 'Bank', 'Cash', 'E-Wallet')
├── balance (DOUBLE PRECISION, DEFAULT 0)
└── created_at (TIMESTAMP WITH TIME ZONE, DEFAULT NOW())
```
**Fungsi**: Menyimpan akun user (bank, cash, e-wallet)
**Relations**: Satu user bisa punya banyak accounts

---

#### **Transactions Table**
```
transactions
├── transaction_id (SERIAL PRIMARY KEY)
├── user_id (INTEGER FK → users)
├── account_id (INTEGER FK → accounts)
├── destination_account_id (INTEGER FK → accounts, NULLABLE)
├── category_id (INTEGER FK → categories, NULLABLE)
├── type (VARCHAR 50: 'expense', 'income', 'transfer')
├── amount (DOUBLE PRECISION NOT NULL)
├── description (VARCHAR 255, NULLABLE)
├── date (TIMESTAMP WITH TIME ZONE, DEFAULT NOW())
└── created_at (TIMESTAMP WITH TIME ZONE, DEFAULT NOW())
```
**Fungsi**: Menyimpan semua transaksi user
**Relations**:
- Linked ke user, account, dan category
- destination_account_id hanya digunakan untuk transfer type
- Auto-update account balance setiap kali ada transaksi baru

---

#### **Budgets Table**
```
budgets
├── budget_id (SERIAL PRIMARY KEY)
├── user_id (INTEGER FK → users)
├── title (VARCHAR 255)
├── amount (DOUBLE PRECISION)
├── category_id (INTEGER FK → categories, NULLABLE)
├── period (VARCHAR 50: 'monthly', 'yearly')
├── created_at (TIMESTAMP WITH TIME ZONE, DEFAULT NOW())
└── updated_at (TIMESTAMP WITH TIME ZONE, DEFAULT NOW())
```
**Fungsi**: Menyimpan budget yang dibuat user
**Relations**: Linked ke user dan category
**Features**:
- Auto-track pengeluaran vs budget amount
- Calculate spent amount dari transactions
- Display progress percentage

### **📚 Database Relationships Diagram**

```
┌──────────────┐
│    users     │
│   (user_id)  │
└──────┬───────┘
       │
       ├─────────────────┬──────────────────┬──────────────────┐
       │                 │                  │                  │
       ▼                 ▼                  ▼                  ▼
  ┌─────────┐    ┌──────────────┐   ┌────────────┐   ┌───────────────┐
  │ accounts │    │ transactions │   │  budgets   │   │ profiles      │
  └─────────┘    └──────────────┘   └────────────┘   └───────────────┘
       │                 │                  │
       │                 ├──────────────────┤
       │                 │                  │
       │                 ▼                  ▼
       │          ┌──────────────┐
       └─────────▶│  categories  │
                  └──────────────┘
```

---

### **🔐 Security Features (Row Level Security)**

Semua table memiliki RLS policies:
- User hanya bisa akses datanya sendiri (based on `user_id`)
- Query otomatis di-filter: `WHERE user_id = auth.uid()`
- Zero chance data leak antar user

### **📝 Catatan Database**

| Aspek | Detail |
|-------|--------|
| **Database Type** | PostgreSQL (via Supabase) |
| **Real-time Sync** | ✅ Enabled (subscribe to changes) |
| **Backup** | ✅ Auto-backup by Supabase |
| **API** | ✅ Auto-generated REST API |
| **Authentication** | ✅ Built-in JWT & RLS |
| **Offline Support** | ✅ Local cache via SharedPreferences |

---

## ⚙️ Troubleshooting

### **❌ 1. `flutter doctor` ada yang tidak centang**

**Solusi:**
```bash
flutter doctor -v
# Ikuti instruksi yang diberikan untuk fix setiap issues
```

### **❌ 2. Dependencies Conflict atau Error**

**Solusi:**
```bash
flutter pub get
flutter pub upgrade
flutter clean
flutter pub get
```

### **❌ 3. Build Cache Issue**

**Solusi:**
```bash
flutter clean
flutter pub get
flutter run
```

### **❌ 4. Android Emulator tidak mau jalan**

**Solusi:**
```bash
# Lihat emulator yang tersedia
flutter emulators

# Buka emulator dengan verbose
flutter emulators --launch <nama> -v
```

### **❌ 5. Supabase Connection Error**

**Periksa:**
- ✅ Pastikan credentials (`SUPABASE_URL` dan `SUPABASE_ANON_KEY`) sudah benar di `main.dart`
- ✅ Cek koneksi internet
- ✅ Verifikasi project Supabase sudah aktif di dashboard
- ✅ Pastikan tabel sudah dibuat di database

### **❌ 6. iOS Pod Install Error** (macOS only)

**Solusi:**
```bash
cd ios
rm -rf Pods
pod install --repo-update
cd ..
flutter clean
flutter pub get
flutter run
```

---

## 📱 Screenshot & Demo

### Light Mode
- Splash — ![Splash](img/ss_light/ss_splash.png)
- Login — ![Login](img/ss_light/ss_login.png)
- Home — ![Home](img/ss_light/ss_home.png)
- Stats — ![Stats](img/ss_light/ss_stats.png)
- History — ![History](img/ss_light/ss_history.png)
- Accounts — ![Accounts](img/ss_light/ss_accounts.png)
- Input — ![Input](img/ss_light/ss_input.png)
- Budget — ![Budget](img/ss_light/ss_budget.png)
- Profile — ![Profile](img/ss_light/ss_profile.png)

### Dark Mode
- Home — ![Home Dark](img/ss_dark/ss_home_dark.png)
- Stats — ![Stats Dark](img/ss_dark/ss_stats_dark.png)
- History — ![History Dark](img/ss_dark/ss_history_dark.png)
- Accounts — ![Accounts Dark](img/ss_dark/ss_accounts_dark.png)
- Profile — ![Profile Dark](img/ss_dark/ss_profile_dark.png)

---

## 📚 Resources & Documentation

- **Flutter Documentation**: https://docs.flutter.dev
- **Supabase Documentation**: https://supabase.com/docs
- **Material Design 3**: https://m3.material.io
- **Dart Language**: https://dart.dev/guides

---

## 👥 Kontributor

- **Developer**: 
  1. Aryabima Kurnia Pratama Santoso
  2. Daniel Bara Seftino
  3. Oryza Reynaleta Wibowo
  4. Tiffany Catherine Prasetya
  5. Farrel Aditya Rosyidi
  6. Rafael Dimas Kristianto
  7. Javed Amani Syauki
- **GitHub**: https://github.com/aryabimasantoso21

---

## 📞 Contact & Support

- **Email**: 
  1. aryabimasantoso21@gmail.com
  2. farreladitya003@gmail.com
  3. dimasrafael62@gmail.com
  4. javedamani124@gmail.com
  5. anielbara12345@gmail.com
  6. tiffanycatherine08@gmail.com
  7. oryzareyyy@gmail.com
- **Repository**: https://github.com/aryabimasantoso21/spendsense
- **Issues**: https://github.com/aryabimasantoso21/spendsense/issues

---

## 📄 License

Proyek ini bersifat open-source dengan izin kontributor

---

**Last Updated**: Desember 2025
