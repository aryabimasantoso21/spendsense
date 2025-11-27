-- ============================================================
-- SUPABASE DATABASE UPDATE - SpendSense v2
-- Run this in your Supabase SQL Editor
-- ============================================================

-- 1. Add transfer support to transactions table
-- Add optional destination_account_id for transfers
ALTER TABLE public.transactions 
ADD COLUMN IF NOT EXISTS destination_account_id integer REFERENCES public.accounts(account_id);

-- 2. Update type constraint to include 'transfer'
-- First drop any existing check constraint on type
ALTER TABLE public.transactions 
DROP CONSTRAINT IF EXISTS transactions_type_check;

-- Add new constraint with transfer type
ALTER TABLE public.transactions 
ADD CONSTRAINT transactions_type_check 
CHECK (type IN ('expense', 'income', 'transfer'));

-- 3. Create function to update account balance when transaction is added
CREATE OR REPLACE FUNCTION update_account_balance_on_transaction()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    -- Handle new transaction
    IF NEW.type = 'income' THEN
      -- Income: add to account balance
      UPDATE public.accounts 
      SET balance = balance + NEW.amount 
      WHERE account_id = NEW.account_id;
    ELSIF NEW.type = 'expense' THEN
      -- Expense: subtract from account balance
      UPDATE public.accounts 
      SET balance = balance - NEW.amount 
      WHERE account_id = NEW.account_id;
    ELSIF NEW.type = 'transfer' THEN
      -- Transfer: subtract from source, add to destination
      UPDATE public.accounts 
      SET balance = balance - NEW.amount 
      WHERE account_id = NEW.account_id;
      
      UPDATE public.accounts 
      SET balance = balance + NEW.amount 
      WHERE account_id = NEW.destination_account_id;
    END IF;
    RETURN NEW;
    
  ELSIF TG_OP = 'DELETE' THEN
    -- Handle transaction deletion (reverse the original operation)
    IF OLD.type = 'income' THEN
      UPDATE public.accounts 
      SET balance = balance - OLD.amount 
      WHERE account_id = OLD.account_id;
    ELSIF OLD.type = 'expense' THEN
      UPDATE public.accounts 
      SET balance = balance + OLD.amount 
      WHERE account_id = OLD.account_id;
    ELSIF OLD.type = 'transfer' THEN
      UPDATE public.accounts 
      SET balance = balance + OLD.amount 
      WHERE account_id = OLD.account_id;
      
      UPDATE public.accounts 
      SET balance = balance - OLD.amount 
      WHERE account_id = OLD.destination_account_id;
    END IF;
    RETURN OLD;
    
  ELSIF TG_OP = 'UPDATE' THEN
    -- Handle transaction update
    -- First reverse old transaction effect
    IF OLD.type = 'income' THEN
      UPDATE public.accounts 
      SET balance = balance - OLD.amount 
      WHERE account_id = OLD.account_id;
    ELSIF OLD.type = 'expense' THEN
      UPDATE public.accounts 
      SET balance = balance + OLD.amount 
      WHERE account_id = OLD.account_id;
    ELSIF OLD.type = 'transfer' THEN
      UPDATE public.accounts 
      SET balance = balance + OLD.amount 
      WHERE account_id = OLD.account_id;
      
      UPDATE public.accounts 
      SET balance = balance - OLD.amount 
      WHERE account_id = OLD.destination_account_id;
    END IF;
    
    -- Then apply new transaction effect
    IF NEW.type = 'income' THEN
      UPDATE public.accounts 
      SET balance = balance + NEW.amount 
      WHERE account_id = NEW.account_id;
    ELSIF NEW.type = 'expense' THEN
      UPDATE public.accounts 
      SET balance = balance - NEW.amount 
      WHERE account_id = NEW.account_id;
    ELSIF NEW.type = 'transfer' THEN
      UPDATE public.accounts 
      SET balance = balance - NEW.amount 
      WHERE account_id = NEW.account_id;
      
      UPDATE public.accounts 
      SET balance = balance + NEW.amount 
      WHERE account_id = NEW.destination_account_id;
    END IF;
    RETURN NEW;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- 4. Create trigger to auto-update account balance
DROP TRIGGER IF EXISTS trigger_update_account_balance ON public.transactions;

CREATE TRIGGER trigger_update_account_balance
AFTER INSERT OR UPDATE OR DELETE ON public.transactions
FOR EACH ROW
EXECUTE FUNCTION update_account_balance_on_transaction();

-- 5. Add a "Transfer" category if not exists
INSERT INTO public.categories (type, name)
SELECT 'transfer', 'Transfer'
WHERE NOT EXISTS (SELECT 1 FROM public.categories WHERE type = 'transfer');

-- 6. Verify setup
SELECT 'Database updated successfully!' as status;
