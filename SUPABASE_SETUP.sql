-- ============================================================
-- Supabase SQL Setup untuk SpendSense
-- Jalankan semua queries ini di Supabase SQL Editor
-- ============================================================

-- ==================== USERS TABLE ====================
-- (Supabase auth.users sudah ada, kita hanya reference)

-- ==================== ACCOUNTS TABLE ====================
CREATE TABLE IF NOT EXISTS accounts (
  id INT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'cash', 'bank', 'card', 'savings'
  balance DECIMAL(12, 2) DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, name)
);

-- Enable RLS for accounts
ALTER TABLE accounts ENABLE ROW LEVEL SECURITY;

-- Create policy: Users can only see their own accounts
CREATE POLICY "Users can view their own accounts"
  ON accounts FOR SELECT
  USING (auth.uid() = user_id);

-- Create policy: Users can insert their own accounts
CREATE POLICY "Users can insert their own accounts"
  ON accounts FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Create policy: Users can update their own accounts
CREATE POLICY "Users can update their own accounts"
  ON accounts FOR UPDATE
  USING (auth.uid() = user_id);

-- Create policy: Users can delete their own accounts
CREATE POLICY "Users can delete their own accounts"
  ON accounts FOR DELETE
  USING (auth.uid() = user_id);

-- ==================== CATEGORIES TABLE ====================
CREATE TABLE IF NOT EXISTS categories (
  id INT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'expense' or 'income'
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(user_id, name, type)
);

-- Enable RLS for categories
ALTER TABLE categories ENABLE ROW LEVEL SECURITY;

-- Create policies for categories
CREATE POLICY "Users can view their own categories"
  ON categories FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own categories"
  ON categories FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own categories"
  ON categories FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own categories"
  ON categories FOR DELETE
  USING (auth.uid() = user_id);

-- ==================== TRANSACTIONS TABLE ====================
CREATE TABLE IF NOT EXISTS transactions (
  id INT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  description VARCHAR(255),
  amount DECIMAL(12, 2) NOT NULL,
  type VARCHAR(50) NOT NULL, -- 'income' or 'expense'
  category_name VARCHAR(255),
  date TIMESTAMP NOT NULL,
  account_id INT NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Enable RLS for transactions
ALTER TABLE transactions ENABLE ROW LEVEL SECURITY;

-- Create policies for transactions
CREATE POLICY "Users can view their own transactions"
  ON transactions FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own transactions"
  ON transactions FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own transactions"
  ON transactions FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own transactions"
  ON transactions FOR DELETE
  USING (auth.uid() = user_id);

-- ==================== CREATE INDEXES ====================
CREATE INDEX idx_accounts_user_id ON accounts(user_id);
CREATE INDEX idx_categories_user_id ON categories(user_id);
CREATE INDEX idx_transactions_user_id ON transactions(user_id);
CREATE INDEX idx_transactions_date ON transactions(date);
CREATE INDEX idx_transactions_type ON transactions(type);
