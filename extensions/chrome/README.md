# Ente Auth Browser Extension

Auto-fill TOTP codes from Ente Auth directly in your browser.

## Features

- **Secure Login**: Same email OTT + password authentication as the Ente Auth app
- **End-to-End Encryption**: All codes are encrypted with your master key
- **Auto-fill**: Automatically detects OTP input fields and offers to fill them
- **Site Matching**: Intelligently matches your codes to the current website
- **Search**: Quickly find codes by issuer or account name
- **Auto-lock**: Automatically locks after a configurable timeout

## Development

### Prerequisites

- Node.js 18+
- npm or yarn

### Setup

```bash
# Install dependencies
npm install

# Start development server (Chrome)
npm run dev

# Start development server (Firefox)
npm run dev:firefox
```

### Building

```bash
# Build for Chrome
npm run build

# Build for Firefox
npm run build:firefox

# Create zip for distribution
npm run zip
npm run zip:firefox
```

### Project Structure

```
src/
├── entrypoints/
│   ├── popup/           # Popup UI (React)
│   ├── background.ts    # Service worker
│   └── content.ts       # Content script for autofill
├── lib/
│   ├── api/             # API client
│   ├── crypto/          # Encryption/decryption
│   ├── services/        # Business logic
│   ├── storage/         # Chrome storage abstraction
│   └── types/           # TypeScript types
└── assets/              # Icons and other assets
```

## Security

- All sensitive data is stored encrypted using Chrome's secure storage APIs
- Session data (decrypted codes) is cleared when the browser closes
- Master key is never stored in plaintext
- Uses the same end-to-end encryption as the Ente Auth mobile and web apps

## License

AGPL-3.0 - Same as the main Ente repository
