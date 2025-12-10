-- Create recipes table
CREATE TABLE IF NOT EXISTS public.recipes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  instructions TEXT,
  image_url TEXT,
  prep_time INTEGER,
  cook_time INTEGER,
  servings INTEGER,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Create recipe_products join table
CREATE TABLE IF NOT EXISTS public.recipe_products (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipe_id UUID NOT NULL REFERENCES public.recipes(id) ON DELETE CASCADE,
  product_id UUID NOT NULL REFERENCES public.products(id) ON DELETE CASCADE,
  quantity NUMERIC NOT NULL,
  unit TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(recipe_id, product_id)
);

-- Enable RLS on both tables
ALTER TABLE public.recipes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.recipe_products ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_recipes_user_id ON public.recipes(user_id);
CREATE INDEX IF NOT EXISTS idx_recipe_products_recipe_id ON public.recipe_products(recipe_id);
CREATE INDEX IF NOT EXISTS idx_recipe_products_product_id ON public.recipe_products(product_id);

-- Security policies for recipes
CREATE POLICY "Users can view their recipes"
  ON public.recipes
  FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their recipes"
  ON public.recipes
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their recipes"
  ON public.recipes
  FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their recipes"
  ON public.recipes
  FOR DELETE
  USING (auth.uid() = user_id);

-- Security policies for recipe_products
CREATE POLICY "Users can view their recipe products"
  ON public.recipe_products
  FOR SELECT
  USING (EXISTS (
    SELECT 1 FROM public.recipes r 
    WHERE r.id = recipe_products.recipe_id 
    AND r.user_id = auth.uid()
  ));

CREATE POLICY "Users can insert their recipe products"
  ON public.recipe_products
  FOR INSERT
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.recipes r 
    WHERE r.id = recipe_products.recipe_id 
    AND r.user_id = auth.uid()
  ));

CREATE POLICY "Users can update their recipe products"
  ON public.recipe_products
  FOR UPDATE
  USING (EXISTS (
    SELECT 1 FROM public.recipes r 
    WHERE r.id = recipe_products.recipe_id 
    AND r.user_id = auth.uid()
  ));

CREATE POLICY "Users can delete their recipe products"
  ON public.recipe_products
  FOR DELETE
  USING (EXISTS (
    SELECT 1 FROM public.recipes r 
    WHERE r.id = recipe_products.recipe_id 
    AND r.user_id = auth.uid()
  ));

-- Trigger to update updated_at column for recipes
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_recipes_updated_at
BEFORE UPDATE ON public.recipes
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_recipe_products_updated_at
BEFORE UPDATE ON public.recipe_products
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- Function to create a recipe with products in a transaction
CREATE OR REPLACE FUNCTION public.create_recipe_with_products(
  p_recipe JSONB,
  p_products JSONB[]
) 
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_recipe_id UUID;
  v_product JSONB;
BEGIN
  -- Insert the recipe
  INSERT INTO public.recipes (
    user_id,
    title,
    description,
    instructions,
    image_url,
    prep_time,
    cook_time,
    servings
  ) VALUES (
    auth.uid(),
    p_recipe->>'title',
    p_recipe->>'description',
    p_recipe->>'instructions',
    p_recipe->>'image_url',
    (p_recipe->>'prep_time')::INTEGER,
    (p_recipe->>'cook_time')::INTEGER,
    (p_recipe->>'servings')::INTEGER
  )
  RETURNING id INTO v_recipe_id;

  -- Insert recipe products
  FOREACH v_product IN ARRAY p_products
  LOOP
    INSERT INTO public.recipe_products (
      recipe_id,
      product_id,
      quantity,
      unit
    ) VALUES (
      v_recipe_id,
      (v_product->>'product_id')::UUID,
      (v_product->>'quantity')::NUMERIC,
      v_product->>'unit'
    );
  END LOOP;

  RETURN v_recipe_id;
END;
$$;
