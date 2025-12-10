-- Add is_consumed column to products table
ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS is_consumed BOOLEAN DEFAULT FALSE;

-- Update existing rows to set default value
UPDATE public.products 
SET is_consumed = FALSE 
WHERE is_consumed IS NULL;
