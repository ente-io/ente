---
title: Troubleshooting FAQ
description: Solutions to common issues with Ente Locker
---

# Troubleshooting FAQ

Solutions to common problems and issues with Ente Locker.

## Sync Issues

### Why aren't my changes syncing? {#locker-sync-issues}

If changes aren't appearing on your other devices:

1. **Check internet connection**: Ensure both devices are connected
2. **Pull to refresh**: Pull down on the main screen to force sync
3. **Check account**: Verify you're logged into the same account on both
   devices
4. **Restart the app**: Close and reopen Locker
5. **Check for errors**: Open Settings to see if any sync errors are shown

### Why is sync slow? {#locker-sync-slow}

Slow sync can be caused by:

- Poor internet connection
- Large number of documents during initial sync
- Server maintenance (rare)

Try:

1. Connect to a faster network (WiFi instead of mobile data)
2. Wait for initial sync to complete
3. Check [status.ente.io](https://status.ente.io) for service status

### Documents are showing on one device but not another {#locker-missing-documents}

1. Verify both devices are logged into the same Ente account
2. Pull down to force a sync on the device missing documents
3. Wait a few moments for sync to complete
4. If still missing, try logging out and back in

## App Issues

### The app is crashing. What should I do? {#locker-app-crash}

Try these steps:

1. **Update the app**: Install the latest version from your app store
2. **Restart your device**: A fresh start can resolve many issues
3. **Clear app cache** (Android): Settings > Apps > Ente Locker > Clear Cache
4. **Reinstall the app**: Uninstall and reinstall (your data is safe in the
   cloud)
5. **Contact support**: If crashes continue, email
   [support@ente.io](mailto:support@ente.io) with details

### The app is running slowly {#locker-app-slow}

To improve performance:

1. Close other apps to free memory
2. Ensure adequate storage space on your device
3. Update to the latest app version
4. Restart the app

### Why isn't my document appearing in search? {#locker-search-missing}

Documents may not appear in search because:

- **Search scope**: Search matches document titles and names, not the full
  content within documents
- **Recently created**: Wait a moment for indexing
- **In Trash**: Search doesn't include trashed items
- **Spelling**: Check your search query for typos
- **Not synced**: Pull to refresh to ensure latest sync

Try searching for the document's title or name. Use descriptive titles to make
documents easier to find.

## Login Issues

### I can't log in to my account {#locker-login-issues}

1. **Check credentials**: Verify your email and password are correct
2. **Check email**: Ensure you're using the email registered with Ente
3. **Reset password**: Use your recovery key if you forgot your password
4. **Check 2FA**: If enabled, enter your 2FA code correctly
5. **Try another device**: Test if you can log in elsewhere

### I'm locked out and don't have my recovery key {#locker-locked-out}

Unfortunately, without your recovery key and password, your account cannot
be recovered. This is an intentional security feature of end-to-end
encryption.

To prevent this in the future, always save your recovery key in multiple
secure locations when creating an account.

### 2FA is not accepting my code {#locker-2fa-issues}

1. **Check time sync**: Ensure your device's time is accurate
2. **Use correct app**: Use the authenticator app where you set up 2FA
3. **Try backup codes**: Use a backup code if available
4. **Wait for new code**: TOTP codes change every 30 seconds

## Lock Screen Issues

### Lock screen isn't working {#locker-lock-screen-not-working}

1. Check that lock screen is enabled in `Settings > Security`
2. Verify your device has biometric authentication configured
3. Try setting up a PIN as an alternative
4. Restart the app

### I forgot my Locker PIN {#locker-forgot-pin}

If you configured biometric authentication, use that to access the app,
then change your PIN in `Settings > Security`.

If you only have a PIN and forgot it, you may need to reinstall the app
and log in again with your Ente credentials.

## Getting Help

### How do I report a bug? {#locker-report-bug}

Report bugs on GitHub:
[github.com/ente-io/ente/issues](https://github.com/ente-io/ente/issues)

Include:

- Device model and OS version
- App version
- Steps to reproduce the issue
- Screenshots if helpful

### How do I contact support? {#locker-contact-support}

Email [support@ente.io](mailto:support@ente.io) for personalized help.

Include:

- Your Ente email (for account-related issues)
- Description of the problem
- Steps you've already tried

### How do I share debug logs with support? {#locker-share-logs}

1. Open `Settings > Support`
2. Tap **Export logs**
3. Share the exported file with [support@ente.io](mailto:support@ente.io)

Logs help us diagnose issues but contain no personal data.

## Related Features

- [Sync](/locker/features/security/sync)
- [Lock screen](/locker/features/security/lock-screen)
- [Security FAQ](/locker/faq/security)
