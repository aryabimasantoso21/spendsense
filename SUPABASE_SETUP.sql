-- ============================================================
-- Supabase SQL Setup untuk SpendSense
-- Jalankan semua queries ini di Supabase SQL Editor
-- ============================================================

-- ==================== USERS TABLE ====================
-- (Supabase auth.users sudah ada, kita hanya reference)

-- ==================== ACCOUNTS TABLE ====================
CREATE TABLE IF NOT EXISTS accounts (
  account_id BIGSERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'cash', 'bank', 'card', 'savings'
  balance DECIMAL(12, 2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== CATEGORIES TABLE ====================
CREATE TABLE IF NOT EXISTS categories (
  category_id BIGSERIAL PRIMARY KEY,
  type VARCHAR(50) NOT NULL, -- 'expense' or 'income'
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== TRANSACTIONS TABLE ====================
CREATE TABLE IF NOT EXISTS transactions (
  id BIGSERIAL PRIMARY KEY,
  account_id BIGINT NOT NULL REFERENCES accounts(account_id) ON DELETE CASCADE,
  category_id BIGINT NOT NULL REFERENCES categories(category_id) ON DELETE CASCADE,
  description VARCHAR(255),
  amount DECIMAL(12, 2) NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'income' or 'expense'
  date TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ==================== INSERT DEFAULT CATEGORIES ====================
-- Expense Categories
INSERT INTO categories (type, name) VALUES
('expense', 'Food & Dining'),
('expense', 'Transportation'),
('expense', 'Shopping'),
('expense', 'Entertainment'),
('expense', 'Bills & Utilities'),
('expense', 'Healthcare'),
('expense', 'Education'),
('expense', 'Other Expenses');

-- Income Categories
INSERT INTO categories (type, name) VALUES
('income', 'Salary'),
('income', 'Freelance'),
('income', 'Investment'),
('income', 'Bonus'),
('income', 'Other Income');
