# App Lock Implementation - Ente Photos (Flutter Mobile)

> yo so you're a frontend dev tryna port the app lock to desktop and you've never touched Flutter? say less. i gotchu. this doc breaks down *exactly* how the mobile app lock works, no cap. every file, every flow, every crypto detail -- all here. think of Flutter widgets like React components and you'll be fine.

---

## Table of Contents

1. [Architecture Overview](#1-architecture-overview)
2. [Server Involvement](#2-server-involvement)
3. [Lock Types & Mutual Exclusivity](#3-lock-types--mutual-exclusivity)
4. [Key Files & Classes](#4-key-files--classes)
5. [Lifecycle & Flow](#5-lifecycle--flow)
   - [Cold Start](#51-cold-start)
   - [Background to Foreground (Auto-Lock)](#52-background--foreground-auto-lock)
   - [Unlock Flow](#53-unlock-flow)
6. [Cryptography & Hashing](#6-cryptography--hashing)
7. [On-Device Storage](#7-on-device-storage)
8. [Brute-Force Protection](#8-brute-force-protection)
9. [Settings UI & Configuration](#9-settings-ui--configuration)
10. [External Packages](#10-external-packages)
11. [Shared `lock_screen` Package (Newer Refactor)](#11-shared-lock_screen-package-newer-refactor)
12. [Desktop Considerations](#12-desktop-considerations)

---

## 1. Architecture Overview

okay so the whole app lock is **purely client-side**. zero server calls. nada. it's basically four layers stacked on top of each other, kinda like how you'd nest context providers in React but Flutter-style:

```
+-----------------------------------------------------+
|  AppLock Widget (lib/ui/tools/app_lock.dart)        |  <-- the big wrapper
|  wraps the ENTIRE app. watches app lifecycle.       |
|  starts a timer when you background the app.        |
+-----------------------------------------------------+
|  LockScreen Widget (lib/ui/tools/lock_screen.dart)  |  <-- the actual lock UI
|  lock icon, "Tap to Unlock", cooldown timer,        |
|  logout button -- the whole vibe                    |
+-----------------------------------------------------+
|  Auth Dispatch (lib/utils/auth_util.dart)           |  <-- the router
|  decides: show PIN screen? password screen?         |
|  or just use the phone's biometrics?                |
+-----------------------------------------------------+
|  LockScreenSettings (lib/utils/lock_screen_settings |  <-- the storage brain
|  .dart) - secure storage + shared prefs             |
+-----------------------------------------------------+
```

quick flutter 101 for the React folks:
- **StatefulWidget** = a component with its own `useState`-like internal state
- **Singleton** = basically a global instance, like a module-level export you import everywhere
- **SharedPreferences** = think `localStorage` but for mobile
- **FlutterSecureStorage** = like `localStorage` but encrypted (keychain on iOS, keystore on Android)
- **`build()` method** = literally the `render()` / return JSX of Flutter
- **`initState()`** = your `useEffect(() => {}, [])` -- runs once when the widget mounts
- **`dispose()`** = the cleanup function returned from `useEffect`
- **`setState()`** = yep, same concept as React's `setState`, triggers a re-render
- **`Navigator.push/pop`** = like `router.push()` / `router.back()` in Next.js
- **`context`** = kinda like React context but it's passed around everywhere in Flutter automatically

---

## 2. Server Involvement

**literally none.** the whole thing lives on the device. no fetch calls, no REST, no GraphQL, no nothing.

- PIN/password hashes, salt, and prefs? all on-device.
- locking and unlocking? local only.
- the **one** exception: if someone fails authentication **10 times in a row**, it calls `Configuration.instance.logout()` which does hit the server to kill the session. but that's a "you messed up too many times" security nuke, not part of the lock feature itself.

tldr: you don't need to touch any API routes for this. it's all local state management.

---

## 3. Lock Types & Mutual Exclusivity

there are three ways to lock the app. but here's the thing -- **you can only have ONE active at a time**. they're mutually exclusive. no mixing and matching. it's giving radio buttons, not checkboxes.

```dart
// lib/ui/settings/lock_screen/lock_screen_options.dart:24
enum LockType { device, pin, password }
```

| Lock Type | what it actually does | where it's stored |
|-----------|-----------|---------|
| `device` | uses your phone's own biometric/passcode (Face ID, fingerprint, device PIN) via the `local_auth` package | `SharedPreferences["should_show_lock_screen"] = true` |
| `pin` | custom in-app 4-digit PIN, hashed with Argon2id (fancy crypto stuff, more on that later) | `FlutterSecureStorage["ls_pin"]` (the hash) + `["ls_salt"]` |
| `password` | custom in-app password, also hashed with Argon2id | `FlutterSecureStorage["ls_password"]` (the hash) + `["ls_salt"]` |

**and when you set one, the other gets yeeted:**

```dart
// lock_screen_settings.dart:114 (inside setPin)
await _secureStorage.delete(key: password);  // bye bye password

// lock_screen_settings.dart:142 (inside setPassword)
await _secureStorage.delete(key: pin);       // bye bye PIN
```

so if a user switches from PIN to password, the old PIN hash is straight up deleted from secure storage. clean slate every time.

**the routing logic** (`auth_util.dart:21`) is basically a big if-else:
- got a PIN or password hash saved? -> show the custom in-app PIN/Password screen
- got nothing saved but lock is enabled? -> fall through to `LocalAuthentication().authenticate()` which pops up the OS biometric/passcode dialog (like when your banking app asks for Face ID)

---

## 4. Key Files & Classes

### Core Lock Mechanism (the important ones)

here's your file map. if you're used to a React project, think of these as your core hooks + providers + pages:

| File | Class/Function | what it does (fr fr) |
|------|----------------|------|
| `lib/ui/tools/app_lock.dart` | `AppLock` (StatefulWidget) | **the wrapper component.** imagine wrapping your entire `<App />` in a `<LockProvider>`. this thing listens for when the app goes to background/foreground (like `visibilitychange` event in web). starts a timer on background; shows lock screen when timer fires. also blocks the back button with `PopScope(canPop: false)` so users can't just swipe away the lock. |
| `lib/ui/tools/lock_screen.dart` | `LockScreen` (StatefulWidget) | **the lock screen page itself.** shows the lock icon, a circular progress indicator (for the cooldown timer), "Tap to Unlock" text, a countdown when you've failed too many times, and a logout button. handles the invalid attempt counting and the "ok you failed 10 times, you're logged out" logic. |
| `lib/utils/auth_util.dart` | `requestAuthentication()` | **the central dispatcher.** this is the function that decides which auth method to use. reads saved PIN/password from secure storage, then routes accordingly. also kills any stale biometric prompts before starting a new one (prevents ghost dialogs). think of it as your auth middleware. |
| `lib/services/local_authentication_service.dart` | `LocalAuthenticationService` | **service layer.** bridges the UI and auth logic. has three main methods: one for in-app sensitive actions (like "verify before showing recovery key"), one for the actual lock screen auth, and one for toggling system biometric on/off. singleton pattern (one global instance). |
| `lib/utils/lock_screen_settings.dart` | `LockScreenSettings` (Singleton) | **the data layer.** manages `FlutterSecureStorage` for the crypto stuff (hashed PIN, hashed password, salt) and `SharedPreferences` for everything else (attempt counters, auto-lock time, flags). also does the actual Argon2id hashing. this is where the real storage magic happens. |
| `lib/core/configuration.dart` | `Configuration` | **app-wide config.** has `shouldShowLockScreen()`, `shouldShowSystemLockScreen()`, and `setSystemLockScreen()`. the first one is the master check -- returns `true` if ANY lock method is enabled. |

### Settings UI Pages (the screens the user actually sees)

| File | Class | what the user sees |
|------|-------|------|
| `lib/ui/settings/lock_screen/lock_screen_options.dart` | `LockScreenOptions` | the main settings page. toggle app lock on/off, pick between Device/PIN/Password, set auto-lock time, toggle "hide content in app switcher". it's the settings dashboard. |
| `lib/ui/settings/lock_screen/lock_screen_pin.dart` | `LockScreenPin` | PIN entry screen. dual purpose -- used for both *setting* a new PIN and *verifying* an existing one. 4-digit input using the `Pinput` package (pretty nice looking tbh). |
| `lib/ui/settings/lock_screen/lock_screen_confirm_pin.dart` | `LockScreenConfirmPin` | "type your PIN again to confirm" screen. classic double-entry pattern. if it matches, hash it and store it. |
| `lib/ui/settings/lock_screen/lock_screen_password.dart` | `LockScreenPassword` | same thing but for passwords. uses a `TextInputWidget` instead of a PIN pad. has a "Next" FAB (floating action button -- those round buttons that float in the corner). |
| `lib/ui/settings/lock_screen/lock_screen_confirm_password.dart` | `LockScreenConfirmPassword` | password confirmation screen. "Confirm" FAB. match = hash and store, mismatch = haptic buzz + error. |
| `lib/ui/settings/lock_screen/lock_screen_auto_lock.dart` | `LockScreenAutoLock` | a picker screen for "how long after backgrounding should the lock kick in?" six options from instant to 30 min. |
| `lib/ui/settings/lock_screen/custom_pin_keypad.dart` | `CustomPinKeypad` | phone-style number pad (1-9, 0, backspace). looks like the dialer on your phone. only used on mobile -- desktop uses the regular keyboard. |

### Entry Points (where users get INTO the lock settings)

| File | Class | the vibe |
|------|-------|------|
| `lib/main.dart` | `main()` / `_runInForeground()` | the app's entry point. wraps the entire app in `AppLock`. decides `enabled` based on `shouldShowLockScreen() \|\| isOnGuestView()`. this is your `_app.tsx` equivalent. |
| `lib/ui/settings/security_section_widget.dart` | `SecuritySectionWidget` | older settings page entry. tapping "App Lock" first makes you authenticate (gotta prove you're you), THEN navigates to `LockScreenOptions`. |
| `lib/ui/settings/security/security_settings_page.dart` | `SecuritySettingsPage` | newer, redesigned version. same flow, better UI. |

---

## 5. Lifecycle & Flow

ok this is the juicy part. let's walk through what happens in different scenarios. if you understand component lifecycle in React, this will click.

### 5.1 Cold Start

this is what happens when you open the app from scratch (killed process, fresh launch):

```
main()
  -> _runInForeground()
    -> _init() (initializes LockScreenSettings, all the services, etc.)
    -> runApp(AppLock(
        builder: (args) => EnteApp(...),        // the actual app
        lockScreen: const LockScreen(),          // the lock screen widget
        enabled: await Configuration.instance.shouldShowLockScreen()
                 || localSettings.isOnGuestView(),
        ...
      ))
```

think of `runApp(AppLock(...))` like `ReactDOM.render(<LockProvider><App /></LockProvider>)`. the lock screen wraps everything.

**`AppLock.initState()`** (`app_lock.dart:67-75`) -- the "component did mount":
- if `enabled = true`: sets `_didUnlockForAppLaunch = false` (meaning "user hasn't proven they're legit yet")
- `build()` renders `MaterialApp(home: _lockScreen)` -- so the lock screen is literally the FIRST thing you see. the actual app isn't even rendered yet.
- lock screen is wrapped in `PopScope(canPop: false)` which is Flutter's way of saying "you CANNOT go back from this screen". no escape.

**`LockScreen.initState()`** (`lock_screen.dart:43-58`) -- the lock screen mounts:
- reads the persisted `invalidAttemptCount` from storage (in case the user was mid-lockout and killed the app)
- after the first frame renders, calls `_showLockScreen()` which triggers the authentication flow

**on successful auth** (`lock_screen.dart:344-352`):
- calls `AppLock.of(context)!.didUnlock()` -- this is how the lock screen tells the wrapper "we're good, let them in"
- `didUnlock()` -> `_didUnlockOnAppLaunch()` -> `pushReplacementNamed('/unlocked')` -- this **replaces** the lock screen route with the actual app. key word: *replaces*. the lock screen isn't sitting behind the app on the navigation stack. it's gone gone. user literally cannot navigate back to it.

### 5.2 Background -> Foreground (Auto-Lock)

this is the "user switches to Instagram for 30 seconds then comes back" flow. Flutter has lifecycle states kinda like the Page Visibility API in browsers.

**when the app goes to background** (`app_lock.dart:83-89`):
```dart
if (state == AppLifecycleState.paused &&
    (!this._isLocked && this._didUnlockForAppLaunch)) {
  this._backgroundLockLatencyTimer = Timer(
    Duration(milliseconds: LockScreenSettings.instance.getAutoLockTime()),
    () => this.showLockScreen(),
  );
}
```

in React terms, this is like:
```js
// pseudocode equivalent
useEffect(() => {
  const handleVisibilityChange = () => {
    if (document.hidden && !isLocked && hasUnlockedOnce) {
      timerRef.current = setTimeout(() => showLockScreen(), autoLockTime);
    }
    if (!document.hidden) {
      clearTimeout(timerRef.current);
    }
  };
  document.addEventListener('visibilitychange', handleVisibilityChange);
  return () => document.removeEventListener('visibilitychange', handleVisibilityChange);
}, []);
```

- a `Timer` starts with the configured auto-lock delay (default 5 seconds)
- two guard conditions: (a) lock screen isn't already showing, (b) user has already done the initial unlock (prevents the timer from starting during the very first lock screen)

**when the app returns to foreground** (`app_lock.dart:91-93`):
```dart
if (state == AppLifecycleState.resumed) {
  this._backgroundLockLatencyTimer?.cancel();
}
```

- came back fast enough? timer cancelled. no lock. you're good.
- timer already fired? lock screen is already there waiting. authenticate to get back in.

**the auto-lock duration options** (`lock_screen_settings.dart:25-32`):
```dart
static const List<Duration> autoLockDurations = [
  Duration(milliseconds: 650),   // "Immediately" (basically instant)
  Duration(seconds: 5),          // default
  Duration(seconds: 15),
  Duration(minutes: 1),
  Duration(minutes: 5),
  Duration(minutes: 30),
];
```

**on successful unlock after background** (`app_lock.dart:206-209`):
- `didUnlock()` -> `_didUnlockOnAppPaused()` -> `pop()`. this time it's a `pop()` (not `pushReplacement`) because the main app is still on the navigation stack underneath. just removes the lock screen overlay. like closing a modal.

### 5.3 Unlock Flow

here's the full step-by-step of what happens when someone taps "Tap to unlock":

```
User taps "Tap to unlock" on LockScreen
  |
  v
_showLockScreen() [lock_screen.dart:321]
  |
  +-- Check cooldown: if lastInvalidAttemptTime > now
  |   -> start countdown timer, skip auth entirely (you're in timeout bestie)
  |
  v
requestAuthentication() [auth_util.dart:10]
  |
  +-- LocalAuthentication().stopAuthentication()  <-- kill any zombie biometric dialogs
  |
  +-- Read savedPin & savedPassword from FlutterSecureStorage
  |
  +-- IF savedPassword OR savedPin exists:
  |    +-- LocalAuthenticationService.requestEnteAuthForLockScreen()
  |         +-- IF savedPassword != null -> Navigate to LockScreenPassword
  |         |    +-- User types password -> hash with Argon2id -> compare with stored hash
  |         +-- IF savedPin != null -> Navigate to LockScreenPin
  |              +-- User types 4-digit PIN -> hash with Argon2id -> compare with stored hash
  |
  +-- ELSE (device lock, no custom PIN/password):
       +-- LocalAuthentication().authenticate()  <-- OS biometric/passcode dialog
           (Face ID, fingerprint, device PIN -- whatever the phone supports)
```

**on success** (`lock_screen.dart:344-352`):
- records `lastAuthenticatingTime` (used for a 5-second debounce to prevent the lock from re-triggering during the unlock animation -- smart edge case handling)
- calls `AppLock.of(context)!.didUnlock()` -- we're in
- resets `invalidAttemptCount` to 0 -- clean slate

**on failure** (`lock_screen.dart:353-374`):
- see [Brute-Force Protection](#8-brute-force-protection) below. it gets spicy.

---

## 6. Cryptography & Hashing

alright this part is important. PINs and passwords are **never stored in plaintext**. they're hashed using **Argon2id v1.3** via libsodium's `crypto_pwhash`. if you've used bcrypt or scrypt in Node.js, Argon2id is the newer, fancier version that won a password hashing competition. it's the gold standard.

### Setting a PIN/Password

here's what happens when a user sets their PIN or password:

```
User enters PIN/password (String)
  -> utf8.encode(input)                      -> Uint8List (byte array, like a Buffer in Node)
  -> Generate 16-byte random salt             via Sodium.randombytesBuf(Sodium.cryptoPwhashSaltbytes)
  -> Argon2id v1.3:
      output length = 32 bytes               (Sodium.cryptoSecretboxKeybytes)
      opsLimit     = Interactive              (Sodium.cryptoPwhashOpslimitInteractive)
      memLimit     = Interactive              (Sodium.cryptoPwhashMemlimitInteractive)
  -> base64Encode(salt) -> FlutterSecureStorage["ls_salt"]
  -> base64Encode(hash) -> FlutterSecureStorage["ls_pin" or "ls_password"]
  -> Delete the opposite key (PIN <-> password are mutually exclusive)
```

for the web devs: this is similar to doing `await argon2.hash(password, { salt, type: argon2id })` and storing the result. except here it's using libsodium's C bindings through Flutter.

**actual code** (`lock_screen_settings.dart:98-117`):
```dart
Future<void> setPin(String userPin) async {
  await _secureStorage.delete(key: saltKey);
  final salt = _generateSalt();              // 16 random bytes
  final hash = cryptoPwHash({
    "password": utf8.encode(userPin),
    "salt": salt,
    "opsLimit": Sodium.cryptoPwhashOpslimitInteractive,
    "memLimit": Sodium.cryptoPwhashMemlimitInteractive,
  });
  await _secureStorage.write(key: saltKey, value: base64Encode(salt));
  await _secureStorage.write(key: pin, value: base64Encode(hash));
  await _secureStorage.delete(key: password); // mutual exclusivity
}
```

### Verifying a PIN/Password

when the user tries to unlock, this happens:

```
Retrieve stored salt from FlutterSecureStorage["ls_salt"]
  -> base64Decode -> Uint8List (16 bytes)
User enters PIN/password
  -> utf8.encode(input)
  -> Argon2id v1.3 (exact same parameters as when it was set)
  -> base64Encode(new_hash) == stored_hash ?
      +-- MATCH: reset invalid count, let them in
      +-- NO MATCH: phone vibrates, increment attempts, maybe start cooldown
```

it's the classic "hash the input, compare the hashes" pattern. same thing you'd do with bcrypt in a Node backend, except it's all happening locally on the device.

**actual code** (`lock_screen_pin.dart:63-72`):
```dart
final Uint8List? salt = await _lockscreenSetting.getSalt();
final hash = cryptoPwHash({
  "password": utf8.encode(code),
  "salt": salt,
  "opsLimit": Sodium.cryptoPwhashOpslimitInteractive,
  "memLimit": Sodium.cryptoPwhashMemlimitInteractive,
});
if (widget.authPin == base64Encode(hash)) { ... }  // hash comparison
```

### The `cryptoPwHash` Function

this is the actual wrapper around libsodium. lives in the internal `ente_crypto` plugin.

**location:** `plugins/ente_crypto/lib/src/crypto.dart:36-45`

```dart
Uint8List cryptoPwHash(Map<String, dynamic> args) {
  return Sodium.cryptoPwhash(
    Sodium.cryptoSecretboxKeybytes,    // 32 bytes output
    args["password"],                   // UTF-8 encoded input
    args["salt"],                       // 16-byte random salt
    args["opsLimit"],
    args["memLimit"],
    Sodium.cryptoPwhashAlgArgon2id13,  // Argon2id v1.3 algorithm
  );
}
```

---

## 7. On-Device Storage

two storage systems. think of it as having both a vault and a regular cabinet:

### FlutterSecureStorage (the vault -- encrypted, sensitive stuff)

this is the encrypted keychain/keystore. on iOS it's the actual Keychain, on Android it's the EncryptedSharedPreferences backed by the Keystore. your PIN hash, password hash, and salt live here because if someone gets access to the device filesystem, they shouldn't be able to read these.

| Key | Type | what's in there |
|-----|------|-------------|
| `"ls_pin"` | String | base64-encoded Argon2id hash of the user's PIN |
| `"ls_password"` | String | base64-encoded Argon2id hash of the user's password |
| `"ls_salt"` | String | base64-encoded 16-byte random salt (regenerated every time a new PIN/password is set) |

### SharedPreferences (the cabinet -- non-sensitive settings)

this is just key-value storage. like `localStorage` on the web. not encrypted, but it doesn't need to be -- none of this data is sensitive enough to require encryption.

| Key | Type | Default | what it's for |
|-----|------|---------|-------------|
| `"ls_invalid_attempts"` | int | 0 | how many times in a row the user failed to authenticate |
| `"ls_last_invalid_attempt_time"` | int | 0 | **this name is a lie.** it's actually the *lockout EXPIRY timestamp* (epoch ms). the time when the lockout ENDS, not when the last attempt happened. classic misleading variable name moment. |
| `"ls_hide_app_content"` | bool | false | whether to blur/hide app content in the app switcher (task manager) |
| `"ls_auto_lock_time"` | int | 5000 | auto-lock delay in milliseconds (how long after backgrounding before lock kicks in) |
| `"should_show_lock_screen"` | bool | false | whether the device/system lock is enabled (stored by `Configuration`, not `LockScreenSettings`) |

---

## 8. Brute-Force Protection

this is where the security gets real. you can't just guess PINs forever. the app fights back with **exponential backoff** -- each failure makes you wait longer, and eventually it just logs you out entirely.

### Invalid Attempt Escalation

cooldown kicks in **after the 4th failed attempt** (i.e., on your 5th L):

| attempt # | the math | how long you're locked out |
|-----------|---------|----------|
| 1-4 | -- | nothing, try again |
| 5 | 2^(5-5) x 30 = 30 | **30 seconds** |
| 6 | 2^(6-5) x 30 = 60 | **1 minute** |
| 7 | 2^(7-5) x 30 = 120 | **2 minutes** |
| 8 | 2^(8-5) x 30 = 240 | **4 minutes** |
| 9 | 2^(9-5) x 30 = 480 | **8 minutes** |
| 10+ | -- | **auto-logout. session nuked. start over.** |

the formula is `2^(attemptCount - 5) * 30` seconds. exponential growth go brrr.

### the code (`lock_screen.dart:353-374`)

```dart
// on failure:
if (invalidAttemptCount > 9) {
  _autoLogoutOnMaxInvalidAttempts(); // calls Configuration.instance.logout()
  return;                            // game over
}
lockedTimeInSeconds = pow(2, invalidAttemptCount - 5).toInt() * 30;
await _lockscreenSetting.setLastInvalidAttemptTime(
  DateTime.now().millisecondsSinceEpoch + lockedTimeInSeconds * 1000,
);
await startLockTimer(lockedTimeInSeconds);
```

### Cooldown Persistence

the lockout expiry timestamp gets saved to `SharedPreferences["ls_last_invalid_attempt_time"]`. this is clutch because it means:
- **cooldowns survive app kills.** you can't just force-quit and reopen to bypass the timer. it checks the stored timestamp on relaunch.
- on resume or relaunch, the remaining lockout time is recalculated from `storedExpiry - Date.now()`.

### Timer UI

while you're in the penalty box, the lock screen shows:
- a circular progress indicator that fills up as the cooldown elapses (looks clean ngl)
- a crossfade animation: "Too many incorrect attempts" text fades out, replaced by a countdown timer like "4m 30s"
- tapping during cooldown does **nothing** -- `result` is set to `false` directly without even attempting auth. you just gotta wait.

---

## 9. Settings UI & Configuration

### Lock Screen Options (`lock_screen_options.dart`)

the settings page has four sections. here's the layout:

#### 1. App Lock Toggle (always visible)
- big on/off switch at the top. the master control.
- **flipping ON:** enables device lock by default, calls `AppLock.of(context)!.setEnabled(true)` (tells the lifecycle wrapper to start watching)
- **flipping OFF:** deletes stored PIN/password from secure storage, disables system lock screen, calls `AppLock.of(context)!.setEnabled(false)`. full cleanup.

#### 2. Lock Type Selection (only shows when app lock is ON)
three options, radio-button style with a checkmark on the active one:
- **Device Lock:** yeets any saved PIN/password, turns on system lock screen. uses whatever your phone has (Face ID, fingerprint, device PIN).
- **PIN Lock:** navigates to `LockScreenPin` -> `LockScreenConfirmPin`. on success, turns OFF system lock screen (because your custom PIN is now the boss).
- **Password Lock:** navigates to `LockScreenPassword` -> `LockScreenConfirmPassword`. same deal, turns off system lock.

#### 3. Auto Lock (only shows when app lock is ON)
- shows the current auto-lock time with a chevron. tap to go to the duration picker.
- options: Immediately (650ms), 5s, 15s, 1m, 5m, 30m

#### 4. Hide Content in App Switcher (ALWAYS visible, independent of app lock)
- toggle switch. when ON, the app switcher (recent apps screen) won't show the app's actual content -- it'll be blurred or blanked out.
- uses the `privacy_screen` package under the hood
- **Android:** sets `FLAG_SECURE` window flag (same thing banking apps use)
- **iOS:** applies a blur effect triggered on `didEnterBackground`

### PIN Setup Flow

```
LockScreenOptions -> [Tap "PIN Lock"]
  -> LockScreenPin (set mode)
    -> User enters 4-digit PIN on the custom keypad
    -> LockScreenConfirmPin
      -> User re-enters same PIN
      -> IF match: hash with Argon2id, store in FlutterSecureStorage, pop x2 back to Options
      -> IF mismatch: phone vibrates, input clears, try again
```

### Password Setup Flow

```
LockScreenOptions -> [Tap "Password Lock"]
  -> LockScreenPassword (set mode)
    -> User types password, taps the "Next" floating button
    -> LockScreenConfirmPassword
      -> User re-types password, taps "Confirm" floating button
      -> IF match: hash with Argon2id, store in FlutterSecureStorage, pop x2 back to Options
      -> IF mismatch: phone vibrates, error shown, try again
```

### Accessing Settings (how users even GET to this page)

both `SecuritySectionWidget` (old) and `SecuritySettingsPage` (new) make you **authenticate BEFORE you can touch lock settings**. smart -- can't have someone changing your lock settings if they're not you.

1. check `LocalAuthentication().isDeviceSupported()` -- does this device even have biometrics/passcode?
2. if yes: call `requestAuthentication()` -> on success, navigate to `LockScreenOptions`
3. if no: show an error dialog telling the user to set up a device passcode first

---

## 10. External Packages

### the dependency lineup (directly used for app lock)

| Package | Version | what it does | where it's used |
|---------|---------|---------|---------|
| **`local_auth`** | `^2.1.5` | talks to the OS biometric system -- Face ID, fingerprint, device PIN. like the Web Authentication API but for mobile. | `auth_util.dart`, `local_authentication_service.dart` |
| **`local_auth_android`** | (comes with local_auth) | android-specific localized strings for the biometric dialog ("Touch the fingerprint sensor", etc.) | `auth_util.dart:33-51` |
| **`local_auth_ios`** | (comes with local_auth) | iOS-specific strings for Face ID / Touch ID prompts | `auth_util.dart:52-59` |
| **`flutter_secure_storage`** | `9.0.0` (PINNED - do not upgrade) | encrypted key-value store. iOS Keychain, Android EncryptedSharedPreferences. where the PIN/password hashes live. | `lock_screen_settings.dart` |
| **`flutter_sodium`** | git fork | dart bindings for libsodium (the crypto library). provides Argon2id hashing + random byte generation. | `lock_screen_settings.dart` |
| **`ente_crypto`** | internal plugin | thin wrapper around flutter_sodium. exports the `cryptoPwHash()` function that does the actual hashing. | `lock_screen_settings.dart`, `lock_screen_pin.dart`, `lock_screen_password.dart` |
| **`pinput`** | `^5.0.0` | slick 4-digit PIN input widget. supports custom theming, error states, obscured text. think of it as a fancy `<input type="password" maxlength="4">` but way prettier. | `lock_screen_pin.dart`, `lock_screen_confirm_pin.dart` |
| **`privacy_screen`** | git fork (`v2-only`) | hides app content in the app switcher / recent apps. prevents screenshots of the app content. | `lock_screen_settings.dart` |
| **`shared_preferences`** | `^2.0.5` | persistent key-value storage for non-sensitive stuff. literally `localStorage` for Flutter. | `lock_screen_settings.dart`, `configuration.dart` |
| **`flutter_animate`** | `^4.1.0` | animation library. used for the smooth crossfade between "Too many attempts" and the countdown timer on the lock screen. | `lock_screen.dart` |

### heads up about `flutter_secure_storage`

it's pinned at **exactly 9.0.0** on purpose. version 9.2.4 has a bug where iOS keychain items survive app reinstallation ([issue #870](https://github.com/juliansteenbakker/flutter_secure_storage/issues/870)). meaning if a user uninstalls and reinstalls the app, their old lock screen PIN hash would still be there in the keychain, but the app wouldn't know about it. bad vibes. so we stay on 9.0.0.

---

## 11. Shared `lock_screen` Package (Newer Refactor)

there's a **newer, refactored version** of all this code at `mobile/packages/lock_screen/`. it's designed to be shared across all Ente apps (Photos, Auth, Locker) instead of being photos-specific. same architecture, but decoupled and abstracted.

### how it's different from the photos app version

| what changed | Photos App (the OG) | Shared Package (the glow-up) |
|--------|-----------------|---------------------|
| crypto backend | `flutter_sodium` (FFI, C bindings) | `ente_crypto_api` (abstract interface -- plug in any backend) |
| Argon2 opsLimit | `Interactive` (faster) | **`Sensitive`** (slower, more secure, ~2x CPU time) |
| i18n / localization | `AppLocalizations.of(context)` (standard Flutter) | `context.strings` (custom `ente_strings` extension -- shared across apps) |
| configuration | `Configuration.instance` (photos-specific singleton) | `BaseConfiguration` (abstract class, injected -- any app can provide its own) |
| where lock state lives | split between `Configuration` + `LockScreenSettings` (messy) | **all in `LockScreenSettings`** (clean, single source of truth) |
| Linux support | nope | yes, via `flutter_local_authentication` + platform checks |
| desktop support | nope | yes -- `PlatformDetector.isDesktop()` guards, uses native keyboard instead of custom keypad, has `PlatformUtil.refocusWindows()` |
| manual lock | not a thing | `showManualLockScreen()` + `_suppressAutoPrompt` flag (user can manually lock the app) |
| default "hide content" | `false` | **`true`** (more privacy-first by default) |
| sign-out cleanup | manual (you gotta remember to clear stuff) | automatic via `Bus.instance.on<SignedOutEvent>()` (event-driven, just works) |
| fresh install cleanup | none | `_clearLsDataInKeychainIfFreshInstall()` for iOS/macOS (handles that keychain persistence issue) |
| migration logic | none | `runLockScreenChangesMigration()` (handles upgrading from old settings format) |
| debug mode shortcut | none | 60-second auth cooldown skip in debug mode (quality of life for devs) |

### the abstraction layer (how different apps plug in)

the shared package uses dependency injection so any Ente app can use it:

1. **`BaseConfiguration` injection** -- your app subclasses `BaseConfiguration` and passes it to `LockScreenSettings.init()` and `LockScreen()`. provides `isLoggedIn()` and `logout()`.
2. **`ente_crypto_api`** -- abstract crypto interface. register your `CryptoApi` implementation (flutter_sodium adapter, Rust adapter, WebCrypto adapter, whatever).
3. **`ente_strings`** -- shared localization. all text uses `context.strings.xxx` instead of app-specific localizations.
4. **`ente_ui`** -- shared component library (MenuItemWidget, ToggleSwitchWidget, DynamicFAB, TextInputWidget, etc.). like your design system package.
5. **`AppLock` builder pattern** -- wrap your app: `AppLock(builder: ..., lockScreen: ..., ...)`. clean composition.

### the deps

| Package | Version | why |
|---------|---------|---------|
| `ente_accounts` | path | `UserService` for logout |
| `ente_configuration` | path | `BaseConfiguration` interface |
| `ente_crypto_api` | path | `CryptoUtil` for hashing |
| `ente_events` | path | `Bus` + `SignedOutEvent` (event bus pattern) |
| `ente_pure_utils` | path | `PlatformDetector` (isMobile/isDesktop checks) |
| `ente_strings` | path | shared localization strings |
| `ente_ui` | path | shared UI components (the design system) |
| `ente_utils` | path | `PlatformUtil.refocusWindows()` |
| `flutter_local_authentication` | git ref `1ac346a` | Linux biometric auth |
| `flutter_secure_storage` | `9.0.0` (pinned) | encrypted storage |
| `local_auth` | `^2.3.0` | iOS/Android biometric |
| `pinput` | `^5.0.0` | PIN input widget |
| `privacy_screen` | `^0.0.8` | app switcher privacy |
| `shared_preferences` | `^2.5.3` | settings persistence |

> **important:** the photos app does **NOT** use the shared package yet. it still runs its own implementation in `lib/`. the shared package exists but hasn't been wired in.

---

## 12. Desktop Considerations

ok so you're building this for desktop. here's the real talk on what works out of the box and what needs work:

### what you can basically copy-paste (conceptually)
- the `AppLock` lifecycle wrapper pattern (though "background" means something different on desktop vs mobile -- more on that below)
- the `LockScreenSettings` storage layer (`FlutterSecureStorage` + `SharedPreferences` both work on desktop)
- Argon2id hashing via `ente_crypto_api` (already abstracted, doesn't care about platform)
- PIN/password entry and verification flow (same logic, different UI)
- brute-force protection (cooldown timers, auto-logout -- all platform-agnostic logic)

### what needs actual work
- **biometrics:** `local_auth` works on macOS (Touch ID) but not Linux/Windows. the shared package adds Linux support via `flutter_local_authentication`. Windows is... complicated. might need to skip biometrics on Windows or find a Windows Hello package.
- **privacy screen / hide content:** `PrivacyScreen` is mobile-only. the shared package already skips it on desktop via `PlatformDetector.isDesktop()`. for desktop you'd need native window management to hide content (minimize to tray? blur window on focus loss?). different beast.
- **auto-lock trigger:** on mobile it's `AppLifecycleState.paused` (app goes to background). on desktop, apps don't really "go to background" the same way. you'll want to listen for **window focus/blur events**, **screen lock/unlock**, or maybe an **idle timeout** (no mouse/keyboard activity for X minutes). totally different paradigm.
- **custom PIN keypad:** not needed on desktop. users have a real keyboard. the shared package already handles this -- it checks `isPlatformDesktop` and skips the `CustomPinKeypad`, using native keyboard input instead.
- **window refocus:** the shared package already has `PlatformUtil.refocusWindows()` for desktop. this is called after auth dialogs to bring the window back to focus (because system auth dialogs can steal focus on desktop).
- **macOS keychain weirdness:** macOS Keychain items can persist after app deletion (same issue as iOS). the shared package has `_clearLsDataInKeychainIfFreshInstall()` to handle this.

### the recommendation

use the **shared `lock_screen` package** (`mobile/packages/lock_screen/`) as your starting point, not the photos-app-specific code. it already has:
- desktop platform detection and guards
- abstract crypto API (no direct flutter_sodium dependency to wrestle with)
- consolidated settings (no confusing split between `Configuration` and `LockScreenSettings`)
- Linux biometric support scaffolding
- manual lock support (`showManualLockScreen()`)
- native keyboard support on desktop

you'll still need to adapt the lifecycle stuff (auto-lock triggers) and potentially the biometric layer for your target platforms, but the core logic -- storage, hashing, attempt counting, cooldowns -- is all ready to go. just wire it up.

good luck king, you got this.
