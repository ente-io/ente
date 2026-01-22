# Ente Auth Browser Extension - Code Management Features

## Overview

Add code management features to the browser extension matching iOS/Android app capabilities:
- Edit codes
- Share codes (time-limited)
- Pin/unpin codes
- Tag management
- Trash/restore/delete
- Add new entries
- QR code scanning from page

**All changes are contained within `web/apps/auth-extension/`** - no modifications to shared packages.

## Phase 1: API Layer & Types

### 1.1 Extend `src/shared/types.ts`

Add to `CodeDisplay`:
```typescript
tags?: string[];
```

Add new message types:
```typescript
| { type: "CREATE_CODE"; input: CodeInput }
| { type: "UPDATE_CODE"; id: string; input: CodeInput }
| { type: "DELETE_CODE"; id: string }
| { type: "TOGGLE_PIN"; id: string }
| { type: "TRASH_CODE"; id: string }
| { type: "RESTORE_CODE"; id: string }
| { type: "UPDATE_TAGS"; id: string; tags: string[] }
| { type: "GET_ALL_TAGS" }
| { type: "GENERATE_SHARE_URL"; id: string; durationMinutes: number }
| { type: "SCAN_PAGE_FOR_QR" }
```

Add `CodeInput` interface for create/edit forms.

### 1.2 Add mutations to `src/shared/api.ts` (~30 lines)

Add 3 functions following mobile patterns (from `mobile/apps/auth/lib/gateway/authenticator.dart:39-74`):

```typescript
// POST /authenticator/entity { encryptedData, header } → { id }
export const createAuthenticatorEntity = async (
    token: string,
    encryptedData: string,
    header: string,
    customEndpoint?: string
): Promise<{ id: string }> => {
    const url = buildApiUrl("/authenticator/entity", undefined, customEndpoint);
    const response = await authenticatedFetch(url, token, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ encryptedData, header }),
    });
    return response.json();
};

// PUT /authenticator/entity { id, encryptedData, header }
export const updateAuthenticatorEntity = async (
    token: string,
    id: string,
    encryptedData: string,
    header: string,
    customEndpoint?: string
): Promise<void> => {
    const url = buildApiUrl("/authenticator/entity", undefined, customEndpoint);
    await authenticatedFetch(url, token, {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ id, encryptedData, header }),
    });
};

// DELETE /authenticator/entity?id={id}
export const deleteAuthenticatorEntity = async (
    token: string,
    id: string,
    customEndpoint?: string
): Promise<void> => {
    const url = buildApiUrl("/authenticator/entity", { id }, customEndpoint);
    await authenticatedFetch(url, token, { method: "DELETE" });
};
```

### 1.3 Add encryption to `src/shared/crypto.ts` (~25 lines)

Add `encryptBlobBytes` (inverse of existing `decryptBlobBytes` at line 58) and `encryptMetadataJSON`:

```typescript
export const encryptBlobBytes = async (
    data: BytesOrB64,
    key: BytesOrB64
): Promise<EncryptedBlob> => {
    await sodium.ready;
    const keyBytes = await bytes(key);
    const initResult = sodium.crypto_secretstream_xchacha20poly1305_init_push(keyBytes);
    const encryptedData = sodium.crypto_secretstream_xchacha20poly1305_push(
        initResult.state,
        await bytes(data),
        null,
        sodium.crypto_secretstream_xchacha20poly1305_TAG_FINAL
    );
    return {
        encryptedData: await toB64(encryptedData),
        decryptionHeader: await toB64(initResult.header),
    };
};

export const encryptMetadataJSON = async (
    jsonValue: unknown,
    key: BytesOrB64
): Promise<EncryptedBlob> =>
    encryptBlobBytes(new TextEncoder().encode(JSON.stringify(jsonValue)), key);
```

## Phase 2: Background Code Manager

### 2.1 Create `src/background/code-manager.ts`

Central service for all code operations:

- `createCode(input: CodeInput)` - Build URI, encrypt, POST to API
- `updateCode(id, input)` - Modify existing code, PUT to API
- `togglePin(id)` - Toggle `codeDisplay.pinned`
- `trashCode(id)` - Set `codeDisplay.trashed = true`
- `restoreCode(id)` - Set `codeDisplay.trashed = false`
- `deleteCode(id)` - Permanent DELETE from API
- `updateTags(id, tags)` - Update `codeDisplay.tags`
- `getAllTags()` - Collect unique tags from all codes

Key implementation: Build `otpauth://` URI with `codeDisplay` JSON in query param, encrypt with authenticator key, send to API.

### 2.2 Create `src/background/share-service.ts`

Time-limited share URL generation (matching mobile):
1. Generate future OTPs for selected duration (2/5/10 min)
2. Create payload: `{ startTime, step, codes: "123456,654321,..." }`
3. Generate random 256-bit key
4. Encrypt payload with key
5. Return: `https://auth.ente.io/share?data={encrypted}&header={header}#{key}`

### 2.3 Update `src/background/index.ts`

Add message handlers for all new message types, calling CodeManager methods.

## Phase 3: UI Components

### 3.1 Create `src/popup/components/Modal.tsx`

Base modal component for forms (overlay within 360px popup).

### 3.2 Create `src/popup/components/CodeContextMenu.tsx`

Dropdown menu triggered by right-click or menu button on CodeCard:
- Edit
- Share
- Pin/Unpin
- Manage Tags
- Move to Trash / Restore
- Delete Permanently (only in trash)

### 3.3 Create `src/popup/components/EditCodeForm.tsx`

Form fields:
- Issuer (required)
- Account
- Secret (required, base32 validated)
- Type dropdown (TOTP/HOTP/Steam)
- Algorithm dropdown (SHA1/SHA256/SHA512)
- Digits (6/8)
- Period (seconds)
- Note (textarea)
- Tags (multi-select)

Used for both create and edit flows.

### 3.4 Create `src/popup/components/ShareDialog.tsx`

Duration selection (2/5/10 min), generates URL, copy button.

### 3.5 Create `src/popup/components/TagSelector.tsx`

Checkbox list of existing tags + create new tag input.

### 3.6 Create `src/popup/components/TrashView.tsx`

List of trashed codes with restore/delete options.

### 3.7 Update `src/popup/CodeCard.tsx`

Add menu button (three dots) to trigger context menu.

### 3.8 Update `src/popup/App.tsx`

- Add "+" button in header to add new code
- Add trash icon to view trashed codes
- Wire up modals and context menus

## Phase 4: QR Code Scanning

### 4.1 Add dependency

Add `jsqr` to `package.json`.

### 4.2 Create `src/content/qr-scanner.ts`

Content script function to:
1. Find all `<img>` and `<canvas>` elements
2. Draw to canvas
3. Use jsQR to detect QR codes
4. Filter for `otpauth://` URIs
5. Return found codes

### 4.3 Add message handler

`SCAN_PAGE_FOR_QR` sends message to active tab's content script, returns found URIs.

### 4.4 UI integration

"Scan QR from page" button in add code flow opens selection of found codes.

## Files to Create (all within `web/apps/auth-extension/`)

```
src/
├── background/
│   ├── code-manager.ts      # Code CRUD operations
│   └── share-service.ts     # Share URL generation
├── content/
│   └── qr-scanner.ts        # QR code detection from page images
└── popup/
    └── components/
        ├── Modal.tsx           # Base modal overlay
        ├── CodeContextMenu.tsx # Right-click/menu button actions
        ├── EditCodeForm.tsx    # Create/edit code form
        ├── ShareDialog.tsx     # Time-limited share URL generator
        ├── TagSelector.tsx     # Tag assignment UI
        ├── ConfirmDialog.tsx   # Confirmation for destructive actions
        └── TrashView.tsx       # View and manage trashed codes
```

## Files to Modify (all within `web/apps/auth-extension/`)

```
src/shared/types.ts          - Add CodeInput, message types, extend CodeDisplay
src/shared/api.ts            - Add mutation functions (POST/PUT/DELETE)
src/shared/crypto.ts         - Add encryptBlobBytes, encryptMetadataJSON
src/background/index.ts      - Add new message handlers
src/popup/App.tsx            - Add buttons, modals, trash view
src/popup/CodeCard.tsx       - Add context menu trigger
src/popup/styles.css         - New component styles
package.json                 - Add jsqr dependency
```

## Verification

1. **Create code**: Add via manual form, verify appears in list and syncs
2. **Edit code**: Modify each field, verify changes persist after sync
3. **Pin/unpin**: Toggle pin, verify ordering (pinned first)
4. **Tags**: Add/remove tags, verify filtering works
5. **Trash**: Move to trash, verify hidden from main list
6. **Restore**: Restore from trash, verify back in main list
7. **Delete**: Permanently delete from trash, verify removed from API
8. **Share**: Generate URL, open in browser, verify codes display correctly
9. **QR scan**: Visit site with TOTP QR, scan, verify correct code parsed
10. **Sync**: Verify all changes sync to mobile apps

## Reference Files

- Mobile API patterns: `mobile/apps/auth/lib/gateway/authenticator.dart`
- Mobile code model: `mobile/apps/auth/lib/models/code.dart`
- Mobile code display: `mobile/apps/auth/lib/models/code_display.dart`
- Mobile share implementation: `mobile/apps/auth/lib/ui/share/code_share.dart`
- Existing extension crypto: `src/shared/crypto.ts`
- Existing extension API: `src/shared/api.ts`
