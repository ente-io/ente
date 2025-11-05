# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commit Message Guidelines

When making commits, follow these rules:

- Keep messages CONCISE (no walls of text)
- Subject line under 72 chars as a single sentence (no body text, no bullets, no lists - only Co-Authored-By line)
- NO emojis
- NO promotional text or links (except Co-Authored-By line)
- Use ONLY "Co-Authored-By: Claude <noreply@anthropic.com>" for attribution

Example:

```
Format markdown files with Prettier for consistent styling

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Repository Overview

Documentation for Ente's products (Photos, Auth, self-hosting), published at [ente.io/help](https://ente.io/help). Built with VitePress.

## Development Commands

```bash
yarn install       # Install dependencies
yarn dev           # Start local dev server
yarn build         # Build for production
yarn pretty        # Format all files with Prettier
```

## Critical Architecture Notes

**Adding new pages**: New pages MUST be manually added to `docs/.vitepress/sidebar.ts` - VitePress does not auto-generate the sidebar.

## Style Guide

Full style guide: `docs/photos/STYLE_GUIDE.md`. Key requirements:

**Voice and terminology:**

- Use imperative voice: "Open Settings" not "You can open Settings"
- Use **Open** for navigation (NOT "Go to" or "Navigate to")
- **Tap** for mobile, **Click** for desktop/web
- Settings paths: `` `Settings > Backup > Folders` `` (code-formatted with `>`)

**Platform instructions** - always use bold headers:

- `**On mobile:**`, `**On desktop:**`, `**On web:**`, `**On iOS:**`, etc.

**FAQ requirements** - ALL questions MUST have unique anchor IDs:

- Format: `### Question? {#unique-anchor-id}`
- Descriptive IDs: `{#enable-face-recognition-ml}` NOT `{#faq1}`
- Must be unique across ALL FAQ files

Check for duplicates:

```bash
grep -rh "{#[a-z0-9-]*}" docs/photos/faq/*.md | sed 's/.*{#\([^}]*\)}.*/\1/' | sort | uniq -d
```

**Links:** Use "Learn more" (NOT "See more", "For more details", "Read more")
