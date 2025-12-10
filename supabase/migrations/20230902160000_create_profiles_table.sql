-- Cria a tabela de perfis se não existir
CREATE TABLE IF NOT EXISTS public.profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE,
  email TEXT,
  full_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (id)
);

-- Habilita RLS (Row Level Security)
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Políticas de segurança
CREATE POLICY "Permitir leitura para todos"
  ON public.profiles FOR SELECT
  USING (true);

CREATE POLICY "Permitir inserção para usuários autenticados"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Permitir atualização apenas para o dono do perfil"
  ON public.profiles FOR UPDATE
  USING (auth.uid() = id);

-- Função para atualizar o campo updated_at automaticamente
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Cria o trigger para atualizar o updated_at
DROP TRIGGER IF EXISTS on_profiles_updated ON public.profiles;
CREATE TRIGGER on_profiles_updated
  BEFORE UPDATE ON public.profiles
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();
