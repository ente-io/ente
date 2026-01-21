# Ente Auth Browser Extension

A browser extension for Ente Auth that provides secure 2FA code autofill.

## Features

- View and copy your 2FA codes from the browser toolbar
- Automatic detection of MFA input fields on websites
- Smart domain matching to suggest relevant codes
- One-click autofill with optional auto-submit
- Syncs with your Ente Auth account
- Works with Chrome and Firefox

## Building from source

From the `web` directory, install dependencies:

```sh
yarn install
```

Build the extension:

```sh
# Build for both browsers (outputs to dist-chrome/ and dist-firefox/)
yarn build:auth-extension

# Build for a specific browser
yarn build:auth-extension:chrome
yarn build:auth-extension:firefox
```

## Development

Start the development build with file watching:

```sh
yarn dev:auth-extension
```

This will rebuild the extension automatically when you make changes.

### Loading the extension in Chrome

1. Open `chrome://extensions`
2. Enable "Developer mode" (toggle in top right)
3. Click "Load unpacked"
4. Select the `web/apps/auth-extension/dist-chrome` directory

### Loading the extension in Firefox

1. Open `about:debugging#/runtime/this-firefox`
2. Click "Load Temporary Add-on"
3. Select the `manifest.json` file in `web/apps/auth-extension/dist-firefox`

> [!NOTE]
>
> Firefox temporary add-ons are removed when you close the browser. For
> persistent installation during development, you can use
> [web-ext](https://extensionworkshop.com/documentation/develop/getting-started-with-web-ext/).

## Directory structure

```
auth-extension/
├── assets/            # Extension icons
├── manifests/         # Browser-specific manifest files
├── src/
│   ├── background/    # Service worker (Chrome) / background script (Firefox)
│   ├── content/       # Content scripts for MFA detection and autofill
│   ├── options/       # Extension options page
│   ├── popup/         # Browser toolbar popup UI
│   └── shared/        # Shared utilities (crypto, OTP, API)
└── dist-*/            # Build outputs (gitignored)
```

## Authentication

The extension authenticates by opening `auth.ente.io` in a new tab. Once you
log in, your credentials are securely captured and stored in the extension.
Your 2FA codes are then synced and available from the toolbar popup.

## How autofill works

When you visit a website with an MFA input field:

1. The content script detects the field using common patterns
2. If matching codes are found, a popup appears offering to fill them
3. Clicking "Fill" inserts the code and optionally submits the form

The extension matches codes to websites using the issuer name and any domain
hints stored in your 2FA entries.
