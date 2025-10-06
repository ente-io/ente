# CLAUDE.md

## Commit Message Guidelines

When making commits, follow these rules:

- Keep messages CONCISE (no walls of text)
- Subject line under 72 chars as a single sentence (no body text, no bullets, no lists - only Co-Authored-By line)
- NO emojis
- NO promotional text or links (except Co-Authored-By line)
- Use ONLY "Co-Authored-By: Claude <noreply@anthropic.com>" for attribution
- ONLY run pre-commit checks (format, lint, typecheck, build) when explicitly creating a commit

## Commands

### Development

```bash
# Install dependencies (uses Yarn classic 1.22.22)
yarn install

# Run development servers
yarn dev              # Photos app (port 3000)
yarn dev:auth         # Auth app (port 3003)
yarn dev:embed        # Embed app (port 3006)
yarn dev:accounts     # Accounts app (port 3001)
yarn dev:cast         # Cast app (port 3004)
yarn dev:locker       # Locker app (port 3005)

# Production builds
yarn build            # Photos app
yarn build:auth       # Auth app
yarn build:embed      # Embed app
yarn build:accounts   # Accounts app
yarn build:cast       # Cast app

# Code quality - ONLY run when:
# 1. Explicitly requested by user
# 2. Before creating a commit (pre-commit)
# DO NOT run automatically after file modifications
yarn lint             # Check formatting, linting, and TypeScript types
yarn lint-fix         # Auto-fix linting and formatting issues
```

## Architecture

This is a **monorepo** containing multiple Ente web applications using **Yarn workspaces**.

### Technology Stack

- **Next.js** for static site generation (all apps except payments)
- **React** with TypeScript
- **Material-UI (MUI)** with Emotion for styling

### Repository Structure

```
web/
├── apps/              # Individual applications
│   ├── photos/        # Main photo management app + shared albums
│   ├── auth/          # 2FA authentication app
│   ├── embed/         # Embeddable photo viewer (iframe-friendly)
│   ├── accounts/      # Passkey support
│   ├── cast/          # Chromecast/browser casting
│   ├── locker/        # Document storage
│   └── payments/      # Subscription management
│
├── packages/          # Shared code between apps
│   ├── base/          # Core UI components, crypto, i18n
│   ├── gallery/       # Photo gallery components
│   ├── accounts/      # Account management
│   ├── media/         # Media processing (FFmpeg, image conversion)
│   ├── utils/         # General utilities
│   ├── new/           # A temporary place for code shared by photos and albums
│   └── build-config/  # Shared build configuration
│
└── docs/          # Development documentation
```

## Important Notes

- Always run `yarn lint` when explicitly requested or before committing (but not after file modifications)
- Use Yarn (not npm) for package management
- Respect the monorepo structure - shared code goes in packages/
- Follow existing Material-UI theming patterns
- Maintain TypeScript strict mode compliance
