-- Create saved_meals table
CREATE TABLE IF NOT EXISTS public.saved_meals (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  meal_data JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.saved_meals ENABLE ROW LEVEL SECURITY;

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_saved_meals_user_id ON public.saved_meals(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_meals_created_at ON public.saved_meals(created_at);

-- Security policies
-- Users can only see their own saved meals
CREATE POLICY "Users can view their saved meals"
  ON public.saved_meals
  FOR SELECT
  USING (auth.uid() = user_id);

-- Users can insert their own saved meals
CREATE POLICY "Users can insert their saved meals"
  ON public.saved_meals
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

-- Users can update their own saved meals
CREATE POLICY "Users can update their saved meals"
  ON public.saved_meals
  FOR UPDATE
  USING (auth.uid() = user_id);

-- Users can delete their own saved meals
CREATE POLICY "Users can delete their saved meals"
  ON public.saved_meals
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

CREATE TRIGGER update_saved_meals_updated_at
BEFORE UPDATE ON public.saved_meals
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();
