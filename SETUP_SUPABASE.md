# SETUP INSTRUCTIONS - SUPABASE DATABASE

## STEPS TO SET UP SUPABASE DATABASE

### Step 1: Open Supabase Dashboard
- Go to https://app.supabase.com
- Sign in with your Supabase account
- Select the **SpendSense** project

### Step 2: Navigate to SQL Editor
- Click on **SQL Editor** in the left sidebar
- This will open the SQL query editor

### Step 3: Create New Query
- Click the **"New Query"** button (top right area)
- Or click **"New"** → **"SQL Query"**

### Step 4: Copy and Paste SQL Script
- Open the file `SUPABASE_SETUP.sql` from the project root folder
- Select ALL the content (Ctrl+A)
- Copy it (Ctrl+C)
- Go back to Supabase SQL Editor
- Click in the query area and paste (Ctrl+V)

### Step 5: Execute the SQL Script
- Click the **"Run"** button (usually green button at top right)
- Wait for execution to complete
- You should see a success message

### Step 6: Verify Tables Created
- Go to **"Tables"** section in Supabase (left sidebar)
- You should see 3 new tables:
  1. **accounts** - untuk menyimpan data akun/dompet user
  2. **categories** - untuk menyimpan kategori pengeluaran/pemasukan
  3. **transactions** - untuk menyimpan catatan transaksi

## WHAT THE SQL SCRIPT DOES

The SUPABASE_SETUP.sql script creates:

1. **accounts** table with columns:
   - id (primary key)
   - user_id (foreign key to auth.users)
   - name (nama akun)
   - type (cash, bank, card, savings)
   - balance (saldo akun)
   - created_at (waktu pembuatan)

2. **categories** table with columns:
   - id (primary key)
   - user_id (foreign key)
   - name (nama kategori)
   - type (expense, income)
   - created_at

3. **transactions** table with columns:
   - id (primary key)
   - user_id (foreign key)
   - description (deskripsi transaksi)
   - amount (jumlah uang)
   - type (expense, income)
   - category_name (nama kategori)
   - date (tanggal transaksi)
   - account_id (akun yang digunakan)
   - created_at

4. **Row Level Security (RLS) Policies**:
   - Users dapat hanya melihat data mereka sendiri
   - Users dapat hanya edit/delete data mereka
   - Keamanan data terjamin

## TESTING THE APP AFTER SETUP

After SQL setup is complete:

1. Run the app: `flutter run`
2. You will see the Splash Screen (2 seconds)
3. Since you're not logged in, you'll be redirected to **Login Page**
4. Click **"Daftar di sini"** to create a new account
5. Fill in email and password (min 6 chars)
6. Click **"Daftar"** button
7. If successful, you'll see a success message
8. Click back to go to Login page
9. Login with the account you just created
10. You should now see the **Home Page** with your account data

## TROUBLESHOOTING

### "LateInitializationError" when running app
- This is fixed! We updated LocalStorageService to be properly async-initialized

### SQL Script Errors
- Make sure you copied the ENTIRE script (all tables and policies)
- Check that you selected the correct Supabase project
- Make sure RLS policies are enabled (they should be in the script)

### Login fails with "Invalid login credentials"
- Double-check your email and password
- Make sure account was created successfully (check Users tab in Supabase Auth)

### Email not confirmed error
- Supabase may require email verification
- Check your email inbox for verification link
- Click the link to confirm your email

## NEXT STEPS

After Supabase setup is complete:

1. ✅ Auth pages are ready (Login/Register)
2. ✅ Splash screen checks auth status
3. ⏳ Next: Update data models to match Supabase schema
4. ⏳ Next: Connect Pages (Home, Accounts, Transactions) to Supabase
5. ⏳ Next: Implement offline sync (LocalStorage ↔ Supabase)

The app is ready to test! Just make sure you execute the SQL script first.
