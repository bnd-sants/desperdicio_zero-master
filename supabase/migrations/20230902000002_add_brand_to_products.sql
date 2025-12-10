-- Add brand column to products table
ALTER TABLE public.products
ADD COLUMN IF NOT EXISTS brand TEXT;

-- Update RLS policies to include the new column
-- No need to update existing policies as they are column-agnostic

-- Update the function to handle the new column
-- (The existing update_updated_at_column function will work as is)
