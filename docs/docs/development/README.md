---
title: Development Guide
description: Guide for developing Ente locally
---

# Development Guide

This guide covers how to set up and run Ente components locally for development.

## Repository Structure

Ente is a monorepo containing multiple components:

| Directory | Description |
|-----------|-------------|
| `mobile/` | Flutter apps (Ente Photos, Ente Auth, Ente Locker) |
| `web/` | Next.js web applications |
| `desktop/` | Desktop Electron apps |
| `server/` | Go server (Museum) |
| `cli/` | Go CLI tool for data export |
| `docs/` | Documentation (VitePress) |
| `architecture/` | Architecture documentation |

## Prerequisites

### Common requirements

- [Git](https://git-scm.com/)
- [Docker](https://www.docker.com/) (for server development)

### Per-component requirements

**Web development**

```sh
Node.js 24 (with corepack)
Yarn 1.22.22
```

**Mobile development**

```sh
Flutter SDK (latest stable)
Dart 3.x
Android SDK / Xcode (for respective platforms)
```

**Server development**

```sh
Go 1.21+
Docker Compose
PostgreSQL 15+
```

**CLI development**

```sh
Go 1.21+
```

## Setting Up

### 1. Clone the repository

```sh
git clone https://github.com/ente-io/ente.git
cd ente
```

### 2. Web apps

```sh
cd web
yarn install --frozen-lockfile

# Run development servers
yarn dev              # Photos app (port 3000)
yarn dev:auth         # Auth app (port 3003)
yarn dev:embed        # Embed app (port 3006)
yarn dev:accounts     # Accounts app (port 3001)
yarn dev:cast         # Cast app (port 3004)
yarn dev:share        # Public Locker app (port 3005)
```

### 3. Mobile apps

```sh
cd mobile

# Install Flutter dependencies
flutter pub get

# Run on Android
flutter run --dart-define=endpoint=http://localhost:8080 --flavor independent -t lib/main.dart

# Run on iOS
flutter run --dart-define=endpoint=http://localhost:8080
```

### 4. Server (Museum)

```sh
cd server

# Start local cluster
docker compose up --build

# Verify it's running
curl http://localhost:8080/ping
```

### 5. CLI

```sh
cd cli

# Build from source
go build -o "bin/ente" main.go

# Or run directly
go run main.go --help
```

## Running with custom endpoint

When building or running mobile apps, you can point them to a custom server:

```sh
--dart-define=endpoint=http://localhost:8080
```

For the web apps, set the endpoint environment variable:

```sh
NEXT_PUBLIC_ENTE_ENDPOINT=http://localhost:8080 yarn dev
```

## Code Quality

### Web

```sh
cd web
yarn lint             # Check formatting, linting, and TypeScript types
yarn lint:fix         # Auto-fix issues
```

### Commit messages

- Keep subject lines under 72 characters
- Use imperative mood ("Add feature" not "Added feature")
- No emojis or promotional text
- No Co-Authored-By lines

Example:

```
Fix authentication token refresh race condition
```

## Architecture

For details on how Ente's end-to-end encryption works, see the [Architecture](../architecture/) documentation.

## Contributing

See [CONTRIBUTING.md](../CONTRIBUTING.md) for contribution guidelines, and the [main docs index](../) for product-specific documentation.