# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ente is a fully open-source, end-to-end encrypted platform for storing data in the cloud. This monorepo contains:
- **Ente Photos**: End-to-end encrypted photo storage app (iOS/Android/Web/Desktop)
- **Ente Auth**: 2FA authenticator app with cloud backup
- Multiple client applications across platforms
- Museum: The Go backend server powering all services

## Repository Structure

- `/mobile/` - Flutter apps (Photos, Auth, Locker)
- `/web/` - Web applications (Next.js/React)
- `/desktop/` - Electron desktop app
- `/server/` - Museum backend (Go + PostgreSQL)
- `/cli/` - Command-line tools
- `/architecture/` - Technical documentation on E2E encryption

## Common Development Commands

### Web Development
```bash
cd web
yarn install           # Install dependencies
yarn dev:photos       # Run photos app on port 3000
yarn dev:auth         # Run auth app on port 3003
yarn build:photos     # Build photos for production
yarn lint             # Run prettier, eslint, and tsc checks
yarn lint-fix         # Auto-fix linting issues
```

### Mobile Development (Flutter)
```bash
cd mobile
melos bootstrap       # Link packages and install dependencies
melos run:photos:apk  # Run photos app on Android
melos build:photos:apk # Build release APK
melos clean:all       # Clean all projects
flutter test          # Run tests for current project
```

### Server Development (Museum)
```bash
cd server
docker compose up --build  # Start local development cluster
go mod download           # Download dependencies
go build -o museum ./cmd/museum  # Build binary
docker compose down       # Stop cluster
```

### Desktop Development
```bash
cd desktop
yarn install         # Install dependencies
yarn dev             # Start development server
yarn build           # Build for production
yarn lint            # Run linting checks
```

## Architecture

### End-to-End Encryption
All user data is encrypted client-side using:
- **Master Key**: Generated on signup, never leaves device unencrypted
- **Key Encryption Key**: Derived from user password
- **Collection Keys**: For folders/albums
- **File Keys**: Unique for each file
- Encryption uses libsodium (XSalsa20 + Poly1305 MAC)

### Technology Stack
- **Backend**: Go with Gin framework, PostgreSQL, Docker
- **Web**: Next.js, React, TypeScript, Yarn workspaces
- **Mobile**: Flutter 3.32.8, Dart, Melos for monorepo management
- **Desktop**: Electron, TypeScript
- **Infrastructure**: Docker, S3-compatible storage, multi-cloud replication

### API Communication
- Museum server at `localhost:8080` for local development
- Authentication via JWT tokens encrypted with user's public key
- All data transmitted is end-to-end encrypted

## Testing & Quality Checks

### Before Committing
- Run appropriate lint commands for the module you're working on
- Ensure TypeScript compilation succeeds (`yarn tsc` or `tsc`)
- For Flutter: Run `flutter analyze` and `flutter test`
- For Go: Run `go fmt ./...` and `go vet ./...`

### Code Style
- Follow existing patterns in neighboring files
- Use existing libraries rather than adding new dependencies
- Match the indentation and formatting style of existing code
- TypeScript/JavaScript: Prettier + ESLint configuration
- Flutter: Standard Dart formatting
- Go: Standard Go formatting

### Localization (Flutter)
- Add new strings to `/mobile/apps/photos/lib/l10n/intl_en.arb`
- Use `AppLocalizations` to access localized strings in code
- Example: `AppLocalizations.of(context).yourStringKey`

## Important Notes

- All sensitive operations happen client-side due to E2E encryption
- Never log or expose encryption keys, passwords, or auth tokens
- The server (Museum) cannot decrypt user data
- Follow security best practices for handling encrypted data
- When modifying encryption-related code, ensure backward compatibility
- **No analytics or tracking**: Never add any analytics, telemetry, or user tracking code