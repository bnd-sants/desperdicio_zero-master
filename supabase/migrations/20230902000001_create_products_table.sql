-- Create products table
CREATE TABLE IF NOT EXISTS public.products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  quantity NUMERIC NOT NULL DEFAULT 1,
  unit TEXT NOT NULL,
  expiration_date TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_products_user_id ON public.products(user_id);
CREATE INDEX IF NOT EXISTS idx_products_expiration_date ON public.products(expiration_date);
CREATE INDEX IF NOT EXISTS idx_products_created_at ON public.products(created_at);

-- Security policies
-- Users can only see their own products
CREATE POLICY "Users can view their products"
  ON public.products
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own products
CREATE POLICY "Users can insert their products"
  ON public.products
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own products
CREATE POLICY "Users can update their products"
  ON public.products
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own products
CREATE POLICY "Users can delete their products"
  ON public.products
  FOR DELETE
  USING (auth.uid() = user_id);

-- Trigger to update updated_at column
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_products_updated_at
BEFORE UPDATE ON public.products
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
