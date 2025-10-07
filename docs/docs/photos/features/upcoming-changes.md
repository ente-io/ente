---
title: Upcoming changes
description: Documentation updates pending release
unlisted: true
---

# Upcoming changes

This page tracks documentation updates that are pending release. Each entry includes sufficient detail for implementation without requiring additional context.

---

## Embed albums - Mobile app support

**Status:** Pending release
**Affects files:**
- `/docs/photos/features/sharing-and-collaboration/embed.md`
- `/docs/photos/faq/sharing-and-collaboration.md`

**Change description:**

The mobile app now supports the "Copy embed HTML" feature, similar to the web app. Users can copy embed code directly from their mobile device.

**Updates required:**

### 1. Update `/docs/photos/features/sharing-and-collaboration/embed.md`

**Location:** Under section "### Easy method - Using the web app" (lines 18-28)

**Current text:**
```markdown
### Easy method - Using the web app

The simplest way to get the embed code is directly from Ente's web app:

1. Open the album in [web.ente.io](https://web.ente.io)
2. Open the album's sharing settings
3. Create a public link (if you haven't already)
4. Open the link settings ("Manage link")
5. Click the "Copy embed HTML" button

This copies ready-to-use iframe code that you can paste directly into your website's HTML.
```

**Replace with:**
```markdown
### Easy method - Using the app

The simplest way to get the embed code is directly from Ente (web or mobile):

**On web:**
1. Open the album in [web.ente.io](https://web.ente.io)
2. Open the album's sharing settings
3. Create a public link (if you haven't already)
4. Open the link settings ("Manage link")
5. Click the "Copy embed HTML" button

**On mobile:**
1. Open the album in the Ente app
2. Tap the share icon
3. Create a public link (if you haven't already)
4. Tap "Manage link"
5. Tap "Copy embed HTML"

This copies ready-to-use iframe code that you can paste directly into your website's HTML.
```

### 2. Update `/docs/photos/faq/sharing-and-collaboration.md`

**Location:** Under question "### How do I embed an album on my website?" (around line 430-455)

**Current text:**
```markdown
**Easy method:**

Open the album in Ente's web app, create a public link, open link settings, and click "Copy embed HTML".
```

**Replace with:**
```markdown
**Easy method:**

Open the album in Ente (web or mobile app), create a public link, open link settings, and tap/click "Copy embed HTML".
```

**Implementation notes:**
- The mobile app implementation follows the same flow as web
- The button label is "Copy embed HTML" on both platforms
- The copied HTML format is identical across platforms
- No code changes needed, only documentation updates
