# SpendSense — Smart Expense Tracker App  

<p align="center">
  <img src="img/logo_withtext.png" width="600" alt="SpendSense Logo"/>
</p>

A modern Flutter-based money management application built with **Supabase**, **Flutter**, and **Material Design 3**.  
SpendSense membantu pengguna mencatat pemasukan, pengeluaran, dan transfer antar akun secara cepat, aman, dan intuitif.

---

## 🚀 Features

###  **Manajemen Pengguna**
- Registrasi & Login
- Menyimpan total balance per user
- Isolasi data: setiap user hanya melihat datanya sendiri

###  **Manajemen Akun**
- Tambah akun (Bank / Cash / E-Wallet)
- Menyimpan saldo masing-masing akun
- Mendukung transfer antar akun

###  **Manajemen Transaksi**
- Pencatatan **Income**, **Expense**, dan **Transfer**
- Pengkategorian otomatis berdasarkan jenis transaksi
- List transaksi yang terurut otomatis berdasarkan tanggal

###  **Kategori Default**
Aplikasi memiliki kategori awal seperti:
- Income: Gaji, Hadiah, Investasi  
- Expense: Makanan, Transportasi, Belanja, Tagihan, dll.

---

# 📋 Prerequisites

Pastikan komputer Anda telah menginstal software berikut:

- **Git** → https://git-scm.com/downloads  
- **VS Code** → https://code.visualstudio.com  
- **Flutter SDK** → https://docs.flutter.dev/get-started/install  
  (Pastikan `flutter doctor` centang hijau semua)
- **Android Studio** (untuk Emulator)

---

## 📋 Cara Instalasi

### 1️⃣ **Prasyarat (Prerequisites)**

Pastikan komputer Anda telah menginstal software berikut:

- **Git** → https://git-scm.com/downloads  
- **VS Code** → https://code.visualstudio.com  
- **Flutter SDK** → https://docs.flutter.dev/get-started/install  
  - Pastikan `flutter doctor` centang hijau semua
- **Android Studio** (untuk Emulator Android)
- **Xcode** (untuk iOS - hanya macOS)

### 2️⃣ **Clone Repository**

```bash
git clone https://github.com/aryabimasantoso21/spendsense.git
cd spendsense
```

### 3️⃣ **Install Flutter Dependencies**

```bash
flutter pub get
```

### 4️⃣ **Setup Backend (Supabase)**

## 1. Buat Project Supabase
1. Buka https://supabase.com  
2. Login / Sign Up  
3. Klik **New Project**  
4. Nama: **SpendSense**  
5. Buat password database  
6. Klik **Create Project**  
7. Tunggu hingga status menjadi hijau/aktif  

---

## 1.1 Buat Tabel Database

Masuk menu **SQL Editor**, lalu copy–paste query berikut → klik **Run**:

```sql
-- RESET TABEL
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
