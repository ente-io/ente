# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commit Message Guidelines

When making commits, follow these rules:

- Keep messages CONCISE (no walls of text)
- Subject line under 72 chars as a single sentence (no body text, no bullets, no lists - only Co-Authored-By line)
- NO emojis
- NO promotional text or links (except Co-Authored-By line)
- Use ONLY "Co-Authored-By: Claude <noreply@anthropic.com>" for attribution

## Repository Overview

This is the documentation repository for Ente's products (Photos, Auth, and self-hosting guides), published at [help.ente.io](https://help.ente.io). It contains 137+ markdown files built with VitePress.

## Development Commands

### Local development
```bash
yarn install       # Install dependencies
yarn dev           # Start local dev server (runs vitepress dev docs)
yarn build         # Build for production
yarn preview       # Preview production build
```

### Code formatting
```bash
yarn pretty        # Format all files with Prettier
yarn pretty:check  # Check formatting without modifying files
```

## Architecture

### VitePress Configuration

- **Main config**: `docs/.vitepress/config.ts` - Site-level configuration (title, description, theme settings)
- **Sidebar**: `docs/.vitepress/sidebar.ts` - Navigation structure for all documentation (manually maintained)
- **Theme**: `docs/.vitepress/theme/` - Custom theme extends VitePress default theme with Ente branding colors

### Content Structure

Documentation is organized by product:
- `docs/photos/` - Ente Photos documentation (features, FAQ, migration guides)
- `docs/auth/` - Ente Auth 2FA app documentation
- `docs/self-hosting/` - Self-hosting installation and administration guides
- `docs/cli/` - CLI tool documentation

Each product section typically contains:
- `index.md` - Product introduction
- `features/` - Feature documentation organized by category
- `faq/` - Frequently asked questions
- `migration/` - Migration guides from other platforms
- `troubleshooting/` - Problem-solving guides

### Navigation and Sidebar

**CRITICAL**: When adding new pages, they MUST be manually added to `docs/.vitepress/sidebar.ts`. VitePress does not auto-generate the sidebar. The sidebar is a TypeScript array that defines the entire navigation structure.

## Writing Documentation

### Style Guide

The repository includes a comprehensive style guide at `docs/photos/STYLE_GUIDE.md`. Key requirements:

#### Voice and Terminology
- Use imperative voice: "Open Settings" not "You can open Settings"
- Use "Ente" or "Ente Photos" in documentation (not "we" unless offering support/commitments)
- Capitalize UI elements: Settings, Preferences, Albums, Trash, Hidden, Archive
- Platform names: iOS, Android, macOS, Windows, Linux

#### Actions and Navigation
- **Tap** for mobile, **Click** for desktop/web
- **Open** for UI elements, menus, settings (NOT "Go to" or "Navigate to")
- **Select** for choosing options
- **Enable/Disable** for toggles
- Settings paths: `` `Settings > Backup > Folders` `` (code-formatted with `>` separator)

#### Platform-Specific Instructions
Always use bold headers:
```markdown
**On mobile:**
1. Open `Settings > Backup`

**On desktop:**
1. Open `Preferences > Backup`

**On web:**
1. Click the menu icon
```

Variations: `**On iOS:**`, `**On Android:**`, `**On web/desktop:**`, etc.

#### FAQ Requirements
ALL FAQ questions MUST:
1. Be H3 headings with unique anchor IDs: `### Question? {#unique-anchor-id}`
2. Have descriptive anchor IDs (lowercase, hyphens only): `{#enable-face-recognition-ml}` NOT `{#faq1}`
3. Be unique across ALL FAQ files (not just within one file)

Check for duplicate anchors:
```bash
grep -rh "{#[a-z0-9-]*}" docs/photos/faq/*.md | sed 's/.*{#\([^}]*\)}.*/\1/' | sort | uniq -d
```

#### Links and Cross-References
- Use "Learn more" consistently (NOT "See more", "For more details", "Read more")
- Link text should be descriptive and use title case
- Always cross-link related features from FAQ and vice versa

#### Formatting
- H1: Page title only
- H2: Major sections
- H3: Subsections / FAQ questions (auto-spaced via CSS)
- **Bold**: UI elements, platform headers, important warnings
- `Code`: File paths, commands, technical values
- Notes: `> **Note**: Text here` (use blockquotes with bold labels)

### Content Review Checklist
Before submitting documentation changes:
- [ ] Follow style guide terminology and voice
- [ ] Use imperative voice for instructions
- [ ] Platform headers are bold
- [ ] Settings paths use code format
- [ ] FAQ questions have unique anchor IDs
- [ ] Cross-links use "Learn more" phrasing
- [ ] Run `yarn pretty` to format

## Key Files

- `package.json` - NPM scripts and dependencies (VitePress, Prettier)
- `.prettierrc.json` - Prettier configuration for code formatting
- `docs/index.md` - Homepage with product introductions
- `docs/.vitepress/theme/custom.css` - Ente brand colors (green: #1db954)

## Important Notes

- Changes merged to main are automatically deployed to help.ente.io
- This is a documentation-only repository (part of larger ente-io/ente monorepo)
- Use VSCode with Prettier extension, set to format on save for best experience
- H3 headings have 48px top margin for better spacing (especially in FAQ pages)
