# Desperdício Zero 🍎

Aplicativo para combate ao desperdício de alimentos, permitindo o gerenciamento de produtos, receitas e notificações de validade. Desenvolvido em Flutter com integração ao Supabase e Spoonacular API.

> **Últimas Atualizações (10/09/2024)**
> - 🎨 Nova interface de usuário com tema inspirado no WhatsApp
> 👤 Tela de perfil com upload de foto e edição de dados
> 🔄 Melhorias na navegação entre telas
> 🛠️ Otimizações de build para Android

## 🚀 Funcionalidades

- **Autenticação de Usuários**
  - Cadastro e login com e-mail/senha
  - Recuperação de senha
  - Gerenciamento de perfil completo
  - Upload e edição de foto de perfil

- **Gerenciamento de Produtos**
  - Cadastro de produtos com data de validade
  - Notificações de vencimento
  - Leitura de código de barras

- **Receitas Inteligentes**
  - Sugestões de receitas baseadas nos produtos próximos do vencimento
  - Integração com a API Spoonacular
  - Favoritar receitas

- **Notificações**
  - Alertas de produtos próximos do vencimento
  - Lembretes personalizáveis

## 🛠️ Tecnologias Utilizadas

- **Frontend**: Flutter
- **Backend**: Supabase (Auth, Database, Storage)
- **API Externa**: Spoonacular (receitas)
- **Outras Bibliotecas**:
  - flutter_riverpod: Gerenciamento de estado
  - intl: Formatação de datas
  - barcode_scan2: Leitura de códigos de barras
  - flutter_local_notifications: Notificações locais
  - url_launcher: Abertura de links externos
  - shared_preferences: Armazenamento local de preferências
  - http: Requisições HTTP
  - flutter_dotenv: Gerenciamento de variáveis de ambiente

## 📋 Pré-requisitos

- Flutter SDK (versão ^3.9.0)
- Dart SDK (versão ^3.9.0)
- Conta no [Supabase](https://supabase.com/)
- Chave de API do [Spoonacular](https://spoonacular.com/food-api)
- Android Studio / Xcode (para desenvolvimento nativo)
- Git (para controle de versão)

## 🚀 Como Executar

1. Clone o repositório:
   ```bash
   git clone https://github.com/bnd-sants/desperdicio_zero-master.git
   cd desperdicio_zero-master
   ```

2. Instale as dependências:
   ```bash
   flutter pub get
   ```

3. Configure as variáveis de ambiente:
   ```bash
   cp .env.example .env
   ```
   
   Edite o arquivo `.env` com suas credenciais. Não publique esse arquivo nem chaves privadas no repositório:
   ```
   SUPABASE_URL=https://seu-projeto.supabase.co
   SUPABASE_ANON_KEY=sua_chave_publica
   SPOONACULAR_API_KEY=sua_chave_privada
   ```

4. Execute o aplicativo:
   ```bash
   flutter run
   ```

## 🏗️ Estrutura do Projeto

```
lib/
├── config/           # Configurações do aplicativo
├── models/           # Modelos de dados
├── providers/        # Gerenciamento de estado
├── screens/          # Telas do aplicativo
│   ├── auth/         # Autenticação
│   └── ...
├── services/         # Serviços e APIs
└── widgets/          # Componentes reutilizáveis
```

## 🛠️ Configuração de Ambiente

1. Crie um projeto no [Supabase](https://supabase.com/)
2. Configure o esquema do banco de dados (ver `supabase/migrations`)
3. Obtenha uma chave de API do [Spoonacular](https://spoonacular.com/food-api)
4. Configure as URLs de redirecionamento no painel do Supabase
5. Configure as permissões de armazenamento para upload de imagens de perfil

## 📱 Build para Produção

Para gerar APKs otimizados:

```bash
# Build para todas as ABIs
flutter build apk --split-per-abi

# Build apenas para arm64-v8a (dispositivos modernos)
flutter build apk --target-platform=android-arm64 --release
```

Os APKs serão gerados em:
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

##  Testes

Para executar os testes:
```bash
flutter test
```

##  Build

Para gerar APK de release:
```bash
flutter build apk --split-per-abi
```

##  Contribuição

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/nova-feature`)
3. Faça commit das alterações (`git commit -m 'Adiciona nova feature'`)
4. Faça push para a branch (`git push origin feature/nova-feature`)
5. Abra um Pull Request

##  Licença

Este projeto está sob a licença MIT. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.

##  Agradecimentos

- [Flutter](https://flutter.dev/)
- [Supabase](https://supabase.com/)
- [Spoonacular](https://spoonacular.com/food-api)
- E todos os mantenedores das bibliotecas utilizadas

## 📧 Contato

[bnd-sants no GitHub](https://github.com/bnd-sants)

Link do Projeto: [Desperdício Zero](https://github.com/bnd-sants/desperdicio_zero-master)
