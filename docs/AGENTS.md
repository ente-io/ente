# Ente Documentation Agent Guidelines

This file provides guidance for AI coding agents working on Ente documentation. Documentation for Ente's products (Photos, Auth, self-hosting), published at [ente.com/help](https://ente.com/help). Built with VitePress.

## Project Overview

Ente is a monorepo containing multiple interconnected components. Documentation covers:
- **Web apps**: Next.js applications for photos, auth, accounts, etc.
- **Mobile apps**: Flutter applications for iOS/Android
- **Infrastructure**: Cloud workers and backend services

## Build, Lint & Test Commands

### Documentation (VitePress)

```bash
# Install dependencies
yarn install

# Development server
yarn dev           # Start local dev server

# Production build
yarn build         # Build for production

# Code quality
yarn pretty        # Format all files with Prettier
```

## Code Style Guidelines

### Markdown/Documentation

- **Voice and terminology:**
  - Use imperative voice: "Open Settings" not "You can open Settings"
  - Use **Open** for navigation (NOT "Go to" or "Navigate to")
  - **Tap** for mobile, **Click** for desktop/web
  - Settings paths: `` `Settings > Backup > Folders` `` (code-formatted with `>`)

- **Platform instructions** - always use bold headers:
  - `**On mobile:**`, `**On desktop:**`, `**On web:**`, `**On iOS:**`, etc.

- **FAQ requirements** - ALL questions MUST have unique anchor IDs:
  - Format: `### Question? {#unique-anchor-id}`
  - Descriptive IDs: `{#enable-face-recognition-ml}` NOT `{#faq1}`
  - Must be unique across ALL FAQ files

- **Links:** Use "Learn more" (NOT "See more", "For more details", "Read more")

- **Formatting**: Follow Prettier configuration, 4-space indentation

## Commit Guidelines

- Keep messages concise (< 72 chars)
- Subject line only (no body text)
- No emojis, no promotional text
- Format: `Add feature X to component Y`
- Use ONLY "Co-Authored-By: Claude <noreply@anthropic.com>" for attribution

Example:
```
Format markdown files with Prettier for consistent styling

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Testing Philosophy

- Validate all links and cross-references
- Check FAQ anchor ID uniqueness
- Ensure consistent terminology across documentation
- Verify platform-specific instructions are complete

## Architecture Principles

### Documentation Structure
- **Adding new pages**: New pages MUST be manually added to `docs/.vitepress/sidebar.ts` - VitePress does not auto-generate the sidebar
- **Organization**: Separate directories for each product/component
- **Consistency**: Maintain unified voice and terminology across all docs

### Quality Assurance
- **Zero issues**: Code must pass all linting checks
- **Link validation**: All links must be functional
- **Style compliance**: Follow style guide in `docs/photos/STYLE_GUIDE.md`
- **Anchor uniqueness**: Run duplicate check command before commits

## Development Workflow

1. **Before starting**: Understand the component you're documenting
2. **During development**: Run `yarn pretty` frequently
3. **Before commit**: Run full quality checks and anchor uniqueness validation
4. **Testing**: Ensure all links work and terminology is consistent

## Critical Notes

- Full style guide: `docs/photos/STYLE_GUIDE.md`
- Check for duplicate FAQ anchor IDs:
  ```bash
  grep -rh "{#[a-z0-9-]*}" docs/photos/faq/*.md | sed 's/.*{#\([^}]*\)}.*/\1/' | sort | uniq -d
  ```
- Always use platform-specific headers for instructions
- Maintain imperative voice throughout documentation
