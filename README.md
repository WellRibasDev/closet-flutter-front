# Closet App (Flutter)

App de guarda-roupa pessoal consumindo a API `closet-back`.

## Setup

```bash
cp .env.example .env
# Emulador Android local:
# API_URL=http://10.0.2.2:3000/api
# Dispositivo físico / iOS simulator: use o IP da máquina
# Produção: URL da Vercel + /api

flutter pub get
flutter run
```

## Conta seed

- `teste@closet.app` / `senha123`

## Estrutura

- `lib/src/core` — env, Dio, storage, router
- `lib/src/features/auth` — login/registro/splash
- `lib/src/features/wardrobe` — CRUD + foto
- `lib/src/features/wishlist` — desejos + mover para closet
# closet-flutter-front
