# CLAUDE.md

## Commit Message Guidelines

When making commits, follow these rules:

- Keep messages CONCISE (no walls of text)
- Subject line under 72 chars as a single sentence (no body text, no bullets, no lists)
- NO emojis
- NO promotional text or links
- NO Co-Authored-By lines
- ONLY run pre-commit checks (format, lint, typecheck, build) when explicitly creating a commit

Example:

```
Format markdown files with Prettier for consistent styling
```

## Commands

```bash
# Install dependencies from the committed lockfile (uses Yarn classic 1.22.22)
yarn install --frozen-lockfile

# Run development servers
yarn dev              # Photos app (port 3000)
yarn dev:auth         # Auth app (port 3003)
yarn dev:embed        # Embed app (port 3006)
yarn dev:accounts     # Accounts app (port 3001)
yarn dev:cast         # Cast app (port 3004)
yarn dev:share       # Public Locker app (port 3005)

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

Use plain `yarn install` only when intentionally updating dependencies and
reviewing the resulting `yarn.lock` changes.

## Structure

This is a monorepo containing multiple Ente web applications using Yarn workspaces.

Shared code goes in `packages/`. All apps use Next.js for static export except `payments`. Run `ls apps/` and `ls packages/` to see the full list.

## Important Notes

- Always run `yarn lint` when explicitly requested or before committing (but not after file modifications)
- Use Yarn (not npm) for package management
- Follow existing Material-UI theming patterns
- Maintain TypeScript strict mode compliance
