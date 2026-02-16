# App Lock Architecture - Ente Photos (Web/Desktop)

> Architecture document for implementing the app lock feature in `web/apps/photos/`, ported from the Flutter mobile implementation. Covers browser and Electron desktop targets.

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Platform Feasibility](#2-platform-feasibility)
3. [Component Hierarchy](#3-component-hierarchy)
4. [State Management](#4-state-management)
5. [Storage Strategy](#5-storage-strategy)
6. [Cryptography](#6-cryptography)
7. [Lock Trigger Mechanism](#7-lock-trigger-mechanism)
8. [Lock Screen UI](#8-lock-screen-ui)
9. [Settings UI](#9-settings-ui)
10. [Data Flow Diagrams](#10-data-flow-diagrams)
11. [Multi-Tab Synchronization](#11-multi-tab-synchronization)
12. [Brute-Force Protection](#12-brute-force-protection)
13. [Integration Points](#13-integration-points)
14. [Security Model](#14-security-model)
15. [Accessibility](#15-accessibility)
16. [New & Modified Files](#16-new--modified-files)
17. [MVP Implementation Order](#17-mvp-implementation-order)
18. [Deferred Features](#18-deferred-features)

---

## 1. Executive Summary

The app lock is a **purely client-side** feature that prevents unauthorized access to the app after it has been authenticated. It supports two lock types (PIN and password), is independent of the user's master key, and reuses the existing Argon2id crypto infrastructure already in the codebase.

- **Browser:** Lock is a UX convenience feature (prevents casual shoulder-surfing). A determined user with DevTools access can bypass it. This is an acceptable trade-off.
- **Electron desktop:** Lock provides meaningful security. Production builds don't expose DevTools, and credentials can be stored in OS-level secure storage (Keychain/DPAPI/libsecret).

---

## 2. Platform Feasibility

### Feature Matrix

| Feature | Chrome/Firefox/Safari | Electron macOS | Electron Windows | Electron Linux |
|---------|----------------------|----------------|------------------|----------------|
| PIN/Password lock | YES | YES | YES | YES |
| Argon2id hashing | YES (WASM) | YES (WASM) | YES (WASM) | YES (WASM) |
| Biometric unlock | NO | YES (Touch ID) | YES (Windows Hello) | NO |
| Auto-lock on tab/window switch | PARTIAL (visibilitychange) | YES (window blur + focus) | YES (window blur + focus) | YES (window blur + focus) |
| Auto-lock on system idle | NO | YES (powerMonitor) | YES (powerMonitor) | YES (powerMonitor) |
| Auto-lock on screen lock | NO | YES (powerMonitor) | YES (powerMonitor) | YES (powerMonitor) |
| Secure PIN storage | NO (IndexedDB only) | YES (Keychain) | YES (DPAPI) | PARTIAL (libsecret) |
| Tamper-resistant lock state | NO | YES (main process) | YES (main process) | YES (main process) |

### Existing Infrastructure

The codebase already provides the key building blocks:

| Need | Existing Solution | Location |
|------|-------------------|----------|
| Argon2id hashing | `deriveInteractiveKey` via libsodium WASM | `web/packages/base/crypto/libsodium.ts:848-857` |
| Web Worker crypto | Comlink-based worker delegation | `web/packages/base/crypto/worker.ts` |
| Visibility detection | Page Visibility API | Already used in `useJoinAlbum.ts:80` |
| Window focus events | `electron.onMainWindowFocus` IPC | `web/packages/base/types/ipc.ts:104-113` |
| Electron safe storage | `safeStorage.encryptString/decryptString` | `desktop/src/main/services/store.ts:27-38` |
| KV storage (IndexedDB) | `getKV/setKV/getKVS` | `web/packages/base/kv.ts` |
| Re-auth pattern | `AuthenticateUser` component | `web/packages/new/photos/components/AuthenticateUser.tsx` |
| Settings drawer pattern | `TitledNestedSidebarDrawer` | Used by `TwoFactorSettings`, `MLSettings`, etc. |

### Mobile vs Web Threat Model

| Aspect | Mobile (Flutter) | Browser | Electron Desktop |
|--------|-----------------|---------|-------------------|
| App sandbox | YES (OS-enforced) | NO | PARTIAL (process-level) |
| Secure storage | FlutterSecureStorage (Keychain/Keystore) | None | safeStorage (Keychain/DPAPI/libsecret) |
| DevTools access | NO (release builds) | YES (always) | NO (production) |
| Biometric auth | Native APIs | WebAuthn only (needs server) | Touch ID / Windows Hello |
| Background detection | App lifecycle events | Page Visibility only | Window focus + powerMonitor |
| Lock state tamper | Very difficult | Trivial via DevTools | Difficult (main process) |

---

## 3. Component Hierarchy

The lock overlay renders as a **sibling** alongside the page `Component` in `_app.tsx`, not as a wrapper. This avoids unnecessary re-renders of the entire component tree.

```
ThemeProvider
  CustomHead, CssBaseline, LoadingBar
  BaseContext
    PhotosAppContext
      Component (pages/*)           <-- existing
      AppLockOverlay                <-- NEW (conditional, sibling)
```

**Why an overlay, not route-based?** The app uses Next.js file-based routing. A route-based lock (`/lock`) would require guarding every page with redirects and would break browser history. A fixed-position overlay covers everything without modifying the route stack -- the same pattern the mobile app uses with its `AppLock` widget.

**Why not a React portal?** The existing `TranslucentLoadingOverlay` in `_app.tsx` renders directly as a sibling and works fine. No portal needed.

**Insertion point in `_app.tsx` (~line 192):**

```tsx
<ThemeProvider theme={photosTheme}>
    ...
    <BaseContext value={baseContext}>
        <PhotosAppContext value={appContext}>
            {!isI18nReady ? (
                <LoadingIndicator />
            ) : (
                <>
                    {isChangingRoute && <TranslucentLoadingOverlay />}
                    <Component {...pageProps} />
                    <AppLockOverlay />      {/* NEW */}
                </>
            )}
        </PhotosAppContext>
    </BaseContext>
</ThemeProvider>
```

**Cold-start flash prevention:** The lock enabled check reads from `localStorage` (synchronous), so the overlay renders immediately on mount without a flash of unlocked content. The async IndexedDB read (for hash/salt) only happens when the user submits their PIN/password.

---

## 4. State Management

Follows the existing `useSyncExternalStore` / snapshot pattern used by `settings.ts` (`web/packages/new/photos/services/settings.ts:232-252`). This avoids React context re-render issues.

### State Shape

```typescript
export interface AppLockState {
    /** Whether app lock is enabled */
    enabled: boolean;
    /** Active lock type: "pin" | "password" | "none" */
    lockType: "pin" | "password" | "none";
    /** Whether the app is currently locked */
    isLocked: boolean;
    /** Consecutive failed attempts in current lockout cycle */
    invalidAttemptCount: number;
    /** Epoch ms when cooldown expires (0 = no cooldown) */
    cooldownExpiresAt: number;
    /** Auto-lock delay in milliseconds */
    autoLockTimeMs: number;
}
```

### Access Pattern

```typescript
// Module-level state (in app-lock.ts)
let _state: AppLockState = { ... };
const _listeners = new Set<() => void>();

export const appLockSubscribe = (listener: () => void) => { ... };
export const appLockSnapshot = () => _state;

// React hook (in use-snapshot.ts or app-lock.ts)
export const useAppLockSnapshot = () =>
    useSyncExternalStore(appLockSubscribe, appLockSnapshot);
```

### Imperative API

```typescript
export function lock(): void;
export function attemptUnlock(input: string): Promise<boolean>;
export function setAppLockEnabled(enabled: boolean): void;
export function setLockType(type: "pin" | "password"): void;
export function setAutoLockTime(ms: number): void;
export function setupPin(pin: string): Promise<void>;
export function setupPassword(password: string): Promise<void>;
export function logoutAppLock(): void;
```

---

## 5. Storage Strategy

Three categories, each using the appropriate existing storage mechanism:

| Data | Storage | Why | Key |
|------|---------|-----|-----|
| Hashed PIN/password (base64) | IndexedDB via `setKV`/`getKV` | Async, survives refresh, matches auth token pattern | `"appLock.hash"` |
| Salt (base64) | IndexedDB via `setKV`/`getKV` | Must pair with hash | `"appLock.salt"` |
| Lock type | `localStorage` | Synchronous read needed on cold start | `"appLock.lockType"` |
| Enabled flag | `localStorage` | Synchronous read needed on cold start | `"appLock.enabled"` |
| Auto-lock time (ms) | `localStorage` | Non-sensitive preference | `"appLock.autoLockTimeMs"` |
| Invalid attempt count | IndexedDB via `setKV` | Harder to tamper than localStorage | `"appLock.invalidAttempts"` |
| Cooldown expiry timestamp | IndexedDB via `setKV` | Harder to tamper than localStorage | `"appLock.cooldownExpiresAt"` |

### Electron Enhancement (Post-MVP)

On desktop, the hash and salt should additionally be stored in OS safe storage via a new IPC method, following the existing `saveMasterKeyInSafeStorage` pattern in `desktop/src/main/services/store.ts`. This prevents bypass by clearing IndexedDB.

### Logout Cleanup

Add `logoutAppLock()` call to `photosLogout()` in `web/apps/photos/src/services/logout.ts`. This clears all app lock keys from both localStorage and KV DB, following the existing pattern of `logoutSettings()`, `logoutUserDetails()`, etc.

---

## 6. Cryptography

Reuse the existing libsodium infrastructure. No new crypto dependencies needed.

### Setting a PIN/Password

```typescript
import { generateDeriveKeySalt } from "ente-base/crypto";
import { deriveInteractiveKey } from "ente-base/crypto/libsodium";

async function setupPin(pin: string): Promise<void> {
    const salt = await generateDeriveKeySalt(); // 16-byte random salt
    // Argon2id with INTERACTIVE limits: opsLimit=2, memLimit=64MB
    // Runs in Web Worker via comlink -- zero UI jank, ~200ms
    const derivedKey = await deriveInteractiveKey(pin, salt);
    await setKV("appLock.salt", salt);
    await setKV("appLock.hash", derivedKey.key);
    localStorage.setItem("appLock.lockType", "pin");
    localStorage.setItem("appLock.enabled", "true");
}
```

### Verifying a PIN/Password

```typescript
async function verifyInput(input: string): Promise<boolean> {
    const salt = await getKVS("appLock.salt");
    const storedHash = await getKVS("appLock.hash");
    if (!salt || !storedHash) return false;
    const derivedKey = await deriveInteractiveKey(input, salt);
    return derivedKey.key === storedHash;
}
```

### Why INTERACTIVE Limits?

Same rationale as the mobile app: lock screen auth is interactive and must be responsive. `OPSLIMIT_INTERACTIVE` / `MEMLIMIT_INTERACTIVE` (64MB) completes in ~100-500ms. The mobile app uses these same parameters.

### Why Independent from Master Key?

The app lock is a local-only feature. Using a separate Argon2id hash keeps security domains cleanly separated. A compromised app lock PIN should not expose the user's master key.

---

## 7. Lock Trigger Mechanism

### Browser (Tab-Based)

```typescript
// In _app.tsx useEffect:
const handleVisibilityChange = () => {
    if (document.hidden && !isLocked && hasUnlockedOnce) {
        autoLockTimerRef.current = window.setTimeout(() => {
            lock();
        }, autoLockTimeMs);
    }
    if (!document.hidden) {
        if (autoLockTimerRef.current) {
            clearTimeout(autoLockTimerRef.current);
            autoLockTimerRef.current = null;
        }
    }
};
document.addEventListener("visibilitychange", handleVisibilityChange);
```

### Electron (Desktop)

Uses the existing `electron.onMainWindowFocus` callback. Requires adding a new `onMainWindowBlur` IPC method:

```typescript
if (electron) {
    electron.onMainWindowBlur(() => {
        // Filter: don't trigger if focus moved to another Electron window
        autoLockTimerRef.current = window.setTimeout(lock, autoLockTimeMs);
    });
    electron.onMainWindowFocus(() => {
        if (autoLockTimerRef.current) {
            clearTimeout(autoLockTimerRef.current);
        }
    });
}
```

**Important:** The blur listener must check if focus moved to another Electron window in the same process (e.g., image viewer, export dialog). If so, the lock timer should NOT trigger.

### Auto-Lock Durations (Matching Mobile)

```typescript
export const autoLockDurations = [
    { label: "immediately", ms: 0 },
    { label: "5_seconds", ms: 5000 },
    { label: "15_seconds", ms: 15000 },
    { label: "1_minute", ms: 60000 },
    { label: "5_minutes", ms: 300000 },
    { label: "30_minutes", ms: 1800000 },
];
```

---

## 8. Lock Screen UI

### Layout

Full-viewport fixed-position overlay. Uses MUI z-index convention: `calc(var(--mui-zIndex-tooltip) + 1)`.

```
+----------------------------------------------------+
|                                                    |
|              [Ente Logo, small]                     |
|                                                    |
|              [Lock Icon, large]                     |
|                                                    |
|    +------------------------------------------+    |
|    |  PIN: 4 individual TextField inputs       |    |
|    |    OR                                     |    |
|    |  Password: TextField with show/hide       |    |
|    +------------------------------------------+    |
|                                                    |
|    [Error message / cooldown timer]                |
|                                                    |
|    [Unlock button]                                 |
|                                                    |
|    [Logout link, small, at bottom]                 |
|                                                    |
+----------------------------------------------------+
```

### Key Design Decisions

1. **Full viewport overlay:** `position: fixed; inset: 0;` with `zIndex: calc(var(--mui-zIndex-tooltip) + 1)`. Above all MUI dialogs.

2. **Reuses existing MUI components:**
   - `TextField` for password input (same as `VerifyMasterPasswordForm`)
   - `FocusVisibleButton` for the unlock button
   - `ShowHidePasswordInputAdornment` for password visibility toggle
   - PIN input: 4 individual `TextField` components with `maxLength: 1`, auto-advancing focus on input

3. **Cooldown timer:** Shows "Too many attempts. Try again in Xm Ys" with a `setInterval` countdown.

4. **No dismiss:** Cannot be closed except through authentication or logout. No Escape key handling. No click-outside dismiss.

5. **Logout link:** Calls the existing `logout()` from `BaseContext`. Shows a confirmation dialog before proceeding (matching the existing `handleLogout` pattern in `Sidebar.tsx:266-278`).

---

## 9. Settings UI

Located in the **Account section** of the Sidebar, alongside "Recovery Key", "Two Factor", "Change Password". This is where security-related settings live.

### Sidebar Entry Point

Add to `Sidebar.tsx` Account section:

```tsx
<RowButtonGroup>
    <RowButton
        label={t("app_lock")}
        endIcon={<ChevronRightIcon />}
        onClick={showAppLockSettings}
    />
</RowButtonGroup>
```

**Requires re-authentication** before opening (same pattern as "Active Sessions" at `Sidebar.tsx:977-980`).

### Settings Drawer Layout

Uses `TitledNestedSidebarDrawer` (same as `TwoFactorSettings`, `MLSettings`, `SessionsSettings`):

```
+----------------------------------------------------+
|  <- App Lock                                       |
+----------------------------------------------------+
|                                                    |
|  [Toggle: Enable App Lock]         [RowSwitch]     |
|                                                    |
|  --- (shown only when enabled) ---                 |
|                                                    |
|  Lock Type:                                        |
|  +--------------------------------------------+   |
|  | PIN                          [checkmark]    |   |
|  |-------------------------------------------- |   |
|  | Password                                    |   |
|  +--------------------------------------------+   |
|                                                    |
|  Auto-Lock:                                        |
|  +--------------------------------------------+   |
|  | [Selection: Immediately / 5s / 15s / ...]   |   |
|  +--------------------------------------------+   |
|                                                    |
|  --- (always shown, independent of lock) ---       |
|                                                    |
|  +--------------------------------------------+   |
|  | Hide content when switching tabs [RowSwitch]|   |
|  +--------------------------------------------+   |
|  Hint: Blurs app content in tab previews           |
|                                                    |
+----------------------------------------------------+
```

### PIN/Password Setup Flow

When user selects a lock type, show a dialog (using existing `TitledMiniDialog` pattern):

```
Select "PIN" -> Enter 4-digit PIN -> Confirm PIN -> Hash & store
Select "Password" -> Enter password -> Confirm password -> Hash & store
```

Switching lock type generates a new salt and overwrites the old hash (mutual exclusivity, matching mobile).

---

## 10. Data Flow Diagrams

### 10.1 Cold Start (Page Load)

```
User opens app / refreshes page
    |
    v
_app.tsx renders
    |
    +-- Read localStorage("appLock.enabled") [SYNC]
    |   Read localStorage("appLock.lockType") [SYNC]
    |
    +-- IF enabled AND haveMasterKeyInSession():
    |       Set isLocked = true (in-memory)
    |       AppLockOverlay renders immediately (full-screen)
    |       |
    |       +-- Read KV("appLock.cooldownExpiresAt") [ASYNC]
    |       |   IF now < expiresAt: show cooldown timer
    |       |
    |       +-- User enters PIN/password
    |       |   -> Read salt from KV DB [ASYNC]
    |       |   -> deriveInteractiveKey(input, salt) [Web Worker]
    |       |   -> Compare with hash from KV DB
    |       |   -> Match: set isLocked = false, reset attempts
    |       |   -> No match: increment attempts, maybe start cooldown
    |       |
    |       v
    |   Overlay removed, app content interactive
    |
    +-- IF NOT enabled OR not logged in:
            App renders normally (no overlay)
```

### 10.2 Tab Hidden -> Visible (Browser)

```
User switches to another tab
    |
    v
document.visibilitychange fires (hidden)
    |
    v
Start auto-lock timer (setTimeout with autoLockTimeMs)
    |
    +-- User returns BEFORE timer fires:
    |       clearTimeout, no lock
    |
    +-- Timer fires WHILE tab is hidden:
    |       Set isLocked = true
    |       Broadcast "lock" via BroadcastChannel
    |
    v
document.visibilitychange fires (visible)
    |
    v
IF isLocked:
    AppLockOverlay showing, user must authenticate
ELSE:
    Normal operation resumes
```

### 10.3 Unlock Flow

```
AppLockOverlay is showing
    |
    v
User enters PIN (4 digits) or password
    |
    v
attemptUnlock(input) called
    |
    +-- Check cooldown: IF Date.now() < cooldownExpiresAt
    |       Reject immediately, show remaining time
    |       RETURN
    |
    +-- Check session: IF !haveMasterKeyInSession()
    |       Session expired while locked, call logout()
    |       RETURN
    |
    +-- salt = await getKVS("appLock.salt")
    +-- storedHash = await getKVS("appLock.hash")
    |
    +-- inputHash = await deriveInteractiveKey(input, salt)
    |
    +-- IF inputHash.key === storedHash:
    |       Set isLocked = false
    |       Set invalidAttemptCount = 0
    |       Clear cooldownExpiresAt
    |       Save to KV DB
    |       Broadcast "unlock" via BroadcastChannel
    |       Overlay unmounts
    |
    +-- IF inputHash.key !== storedHash:
            invalidAttemptCount++
            IF count >= 10:
                Call logout() (security auto-logout)
            ELSE IF count >= 5:
                cooldownSeconds = 2^(count-5) * 30
                cooldownExpiresAt = Date.now() + cooldownSeconds*1000
                Save to KV DB
                Start countdown timer UI
            Show error: "Incorrect PIN/password"
```

### 10.4 Settings Change Flow

```
User opens Sidebar -> Account -> "App Lock"
    |
    v
onAuthenticateUser() triggers master password re-auth
    |
    +-- Auth succeeds: AppLockSettings drawer opens
    +-- Auth cancelled: nothing happens
    |
    v
Toggle "Enable App Lock" ON
    |
    +-- Default lockType = "pin"
    +-- Show PIN setup dialog (enter + confirm)
    +-- On confirm:
    |       salt = generateDeriveKeySalt()
    |       hash = deriveInteractiveKey(pin, salt)
    |       Store hash + salt in KV DB
    |       Store lockType + enabled in localStorage
    |       Update in-memory state, notify subscribers
    |
    v
Change lock type (e.g., PIN -> Password)
    |
    +-- Show password setup dialog (enter + confirm)
    +-- On confirm:
    |       Generate NEW salt (overwrites old)
    |       Hash password, store in KV DB (overwrites old hash)
    |       Update lockType in localStorage
    |
    v
Toggle "Enable App Lock" OFF
    |
    +-- Clear hash + salt from KV DB
    +-- Clear lockType + enabled from localStorage
    +-- Clear attempt counters from KV DB
    +-- Set isLocked = false
    +-- Notify subscribers
```

---

## 11. Multi-Tab Synchronization

Use the `BroadcastChannel` API to synchronize lock/unlock events across browser tabs.

```typescript
const channel = new BroadcastChannel("ente-app-lock");

// When locking:
channel.postMessage({ type: "lock" });

// When unlocking:
channel.postMessage({ type: "unlock" });

// Listen for events from other tabs:
channel.onmessage = (event) => {
    if (event.data.type === "lock") lock();
    if (event.data.type === "unlock") unlockWithoutAuth(); // other tab already verified
};
```

**Behavior:**
- Tab A locks -> Tab B also locks (both show overlay)
- Tab A unlocks -> Tab B also unlocks (both hide overlay)
- Opening a new tab while locked: new tab reads `enabled` from localStorage on mount, starts locked

---

## 12. Brute-Force Protection

Matches the mobile implementation:

| Attempt # | Cooldown | Action |
|-----------|----------|--------|
| 1-4 | None | Try again |
| 5 | 30 seconds | `2^(5-5) * 30 = 30s` |
| 6 | 1 minute | `2^(6-5) * 30 = 60s` |
| 7 | 2 minutes | `2^(7-5) * 30 = 120s` |
| 8 | 4 minutes | `2^(8-5) * 30 = 240s` |
| 9 | 8 minutes | `2^(9-5) * 30 = 480s` |
| 10+ | -- | **Auto-logout. Session terminated.** |

Formula: `2^(attemptCount - 5) * 30` seconds.

**Persistence:** Attempt count and cooldown expiry stored in IndexedDB KV store (not localStorage). This makes them slightly harder to tamper with than localStorage, though still clearable by a determined browser user.

**Cooldowns survive refresh:** On page load/lock screen mount, read `cooldownExpiresAt` from KV DB. If `Date.now() < expiresAt`, show the remaining cooldown timer immediately.

---

## 13. Integration Points

### Independent from Master Key

The app lock uses a **separate** Argon2id hash with its own salt. It does NOT interact with:
- `AuthenticateUser` (which verifies the master password via SRP)
- The master key in `sessionStorage`
- Any server API

### Session Management

- On cold start, the lock overlay checks `haveMasterKeyInSession()`. If no master key (user not logged in), the overlay doesn't render.
- On unlock attempt, verify the session is still valid. If the auth token expired during lock, redirect to login via `logout()`.

### Logout Flow

The lock screen includes a "Logout" link. Clicking it:
1. Shows a confirmation dialog (matching existing `handleLogout` pattern)
2. Calls `logout()` from `BaseContext`
3. `photosLogout()` calls `logoutAppLock()`, which clears all app lock storage

---

## 14. Security Model

### Browser (Known Limitations)

The browser app lock is a **UX convenience feature**, not a security boundary:
- localStorage and IndexedDB are readable/clearable via DevTools
- Lock state in memory can be manipulated via console
- The master key in sessionStorage is accessible to anyone with DevTools

This is acceptable. The lock prevents:
- Casual shoulder-surfing when stepping away from a shared computer
- Accidental access by someone opening your browser tabs

### Electron Desktop

The Electron app lock provides **meaningful security against casual physical access**:
- Production builds don't expose DevTools
- PIN hash can be stored in OS safe storage (Keychain/DPAPI/libsecret)
- Lock state can be enforced in the main process

### PIN Entropy

4-digit PIN = 10,000 combinations. With Argon2id interactive limits (~200ms per hash), exhaustive brute force takes ~33 minutes. Combined with exponential backoff (locked out after 4 failures) and auto-logout after 10 attempts, this is adequate for a local lock.

### Session Isolation

- Each browser tab has its own in-memory lock state
- localStorage and IndexedDB are shared across tabs (same origin)
- BroadcastChannel syncs lock/unlock events across tabs
- Opening a new tab while locked: the new tab starts locked

---

## 15. Accessibility

The lock screen overlay must be fully accessible:

- **Focus trapping:** Use `aria-modal="true"` and `role="dialog"` on the overlay. Tab key cycles within the overlay only.
- **Keyboard navigation:** Tab to PIN/password input, Enter to submit. Escape does nothing (locked).
- **Screen reader:** Announce "App is locked. Enter your PIN to unlock." via `aria-label` on the dialog.
- **Error announcements:** Failed attempts announced via `aria-live="polite"` region.
- **Cooldown timer:** Timer updates announced to screen readers.

Use MUI's `<Backdrop>` or `<Dialog>` with `disableEscapeKeyDown` for built-in focus trapping.

---

## 16. New & Modified Files

### New Files

| File | Purpose |
|------|---------|
| `web/packages/new/photos/services/app-lock.ts` | State management (subscribe/snapshot), storage ops, hashing, brute-force logic, BroadcastChannel sync |
| `web/packages/new/photos/components/AppLockOverlay.tsx` | Lock screen UI (overlay, PIN/password input, cooldown timer, logout, accessibility) |
| `web/packages/new/photos/components/sidebar/AppLockSettings.tsx` | Settings drawer (enable/disable, lock type, auto-lock time, privacy toggle) |

### Modified Files

| File | Change |
|------|--------|
| `web/apps/photos/src/pages/_app.tsx` | Render `AppLockOverlay` as sibling, add visibility/timer event listeners via `useEffect` |
| `web/apps/photos/src/components/Sidebar.tsx` | Add "App Lock" entry in Account section |
| `web/apps/photos/src/services/logout.ts` | Add `logoutAppLock()` call in `photosLogout()` |
| `web/packages/base/types/ipc.ts` | Add `onMainWindowBlur` callback (Electron, post-MVP) |
| `desktop/src/main.ts` | Wire up `onMainWindowBlur` IPC event (Electron, post-MVP) |
| `desktop/src/preload.ts` | Bridge `onMainWindowBlur` (Electron, post-MVP) |

---

## 17. MVP Implementation Order

| Priority | Component | Complexity | Description |
|----------|-----------|------------|-------------|
| 1 | `app-lock.ts` service | Medium | Core state machine, hash/verify, lock/unlock, timer management, BroadcastChannel |
| 2 | `AppLockOverlay.tsx` | Medium | PIN/password input, cooldown display, logout link, focus trapping, accessibility |
| 3 | `AppLockSettings.tsx` | Low | Enable/disable toggle, lock type selection, PIN/password setup dialogs, auto-lock picker |
| 4 | `_app.tsx` + `Sidebar.tsx` integration | Low | Wire up overlay rendering, visibility event listeners, sidebar entry |
| 5 | Multi-tab sync | Low | BroadcastChannel lock/unlock synchronization |

---

## 18. Deferred Features

These are not part of the MVP but should be considered for future iterations:

| Feature | Complexity | Notes |
|---------|------------|-------|
| Electron `onMainWindowBlur` IPC | Medium | Cross-package change (web + desktop). Must filter blur events from other Electron windows. |
| Electron safeStorage-backed hash | Medium | Store hash/salt in OS secure storage in addition to IndexedDB. Prevents DevTools bypass on desktop. |
| Biometric unlock (Touch ID / Windows Hello) | High | Requires new IPC methods + platform-specific APIs. Touch ID via `systemPreferences.promptTouchID()`. |
| System idle auto-lock | Medium | Electron `powerMonitor.getSystemIdleTime()`. Not available in browser. |
| Screen lock detection | Low | Electron `powerMonitor.on('lock-screen')`. Auto-lock when OS screen locks. |
| Storage key versioning | Low | Version keys (e.g., `appLock_v1_hash`) for future migration paths. |
