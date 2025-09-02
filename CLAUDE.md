# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

Ente is a monorepo containing end-to-end encrypted cloud storage applications (Photos and Auth), with clients for multiple platforms and a self-hostable backend server. The codebase uses end-to-end encryption for all user data, ensuring privacy and security.

## Common Development Commands

### Web Development
- **Run Photos app**: `cd web && yarn dev:photos` (port 3000)
- **Run Auth app**: `cd web && yarn dev:auth` (port 3003)
- **Build Photos**: `cd web && yarn build:photos`
- **Lint and typecheck**: `cd web && yarn lint`
- **Fix linting issues**: `cd web && yarn lint-fix`

### Mobile Development (Flutter)
- **Bootstrap monorepo**: `cd mobile && melos bootstrap`
- **Run Photos app**: `cd mobile && melos run:photos:apk`
- **Run Auth app**: `cd mobile && melos run:auth:apk`
- **Build Photos APK**: `cd mobile && melos build:photos:apk`
- **Clean all projects**: `cd mobile && melos clean:all`

### Desktop Development (Electron)
- **Run development**: `cd desktop && yarn dev`
- **Build quickly**: `cd desktop && yarn build:quick`
- **Full build**: `cd desktop && yarn build`
- **Lint**: `cd desktop && yarn lint`

### Server Development (Go)
- **Run locally**: `cd server && docker compose up --build`
- **API endpoint**: `http://localhost:8080`
- **Health check**: `curl http://localhost:8080/ping`

## Architecture

### Encryption Architecture
The system implements end-to-end encryption using:
- **Master Key**: Generated client-side, never leaves device unencrypted
- **Key Encryption Key**: Derived from user password using Argon2
- **Collection Keys**: Per-folder/album encryption keys
- **File Keys**: Individual encryption for each file
- Uses libsodium for all cryptographic operations

### Project Structure
- `web/apps/` - Next.js web applications (photos, auth, accounts, etc.)
- `mobile/apps/` - Flutter applications for iOS/Android
- `desktop/` - Electron desktop application
- `server/` - Go backend API (Museum)
- `cli/` - Command-line interface
- `docs/` - Documentation
- `infra/` - Infrastructure and deployment configs

### Key Technologies
- **Frontend**: Next.js, React, TypeScript
- **Mobile**: Flutter, Dart
- **Desktop**: Electron, TypeScript
- **Backend**: Go, PostgreSQL, Docker
- **Cryptography**: libsodium, end-to-end encryption

## Testing Approach
- Check for test scripts in package.json files
- Mobile tests can be run with Flutter's test command
- Server tests use Go's built-in testing framework