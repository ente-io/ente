---
title: FAQ - Auth
description: Frequently asked questions about Ente Auth
---

# Frequently Asked Questions

### How secure is Ente Auth?

All codes you backup via Ente is stored with end-to-end encryption. This means
only you can access your codes. Our apps are open source and our cryptography
has been externally audited.

### How can I delete or edit codes?

You can delete or edit a code by long pressing (or right clicking on desktop) on
that item.

### How can I support this project?

You can support the development of this project by subscribing to our Photos app
at [ente.io](https://ente.io).

### How can I enable FaceID lock in Ente Auth?

You can enable FaceID lock under Settings → Security → Lockscreen.

### How secure is the lock screen provided by Ente Auth?

Auth's lock screen acts as a barrier to prevent an attacker from accessing the
contents of the app. It does not introduce a layer of cryptographic security.

### Why do the desktop and mobile apps display different codes?

Please verify that the time on both your mobile and desktop is the same.

The codes depend on time. If the time is the same on both your browser and
mobile, the codes you see will be the same.

Usually, this discrepancy occurs because the time in your browser might be
incorrect. In particular, multiple users have reported that Firefox provides
incorrect time when certain privacy settings are enabled.

> [!TIP]
>
> Newer Ente Auth clients (upcoming 4.4.0+) will automatically try to correct
> for incorrect system time, so you should be seeing correct codes even if your
> system time is out of sync. However, this automatic correction will not work
> if you're using Ente Auth in offline mode.
>
> If you've recently changed your system time and the codes are still incorrect,
> try to refresh / restart the app if needed.

### Can I access my codes on web?

You can access your codes on the web at [auth.ente.io](https://auth.ente.io).

### Does Ente Auth require an account?

No, Ente Auth does not require an account. You can choose to use the app without
backups if you prefer.

### Can I use Ente Auth on multiple devices and sync them?

Yes, you can download Ente Auth on multiple devices and sync the codes with
end-to-end encryption.

### What information about my codes is stored on Ente server?

Due to E2EE, the server doesn't know anything about your codes. Everything is
encrypted, including the tags, type, account, issuer, notes, pinned or trash
status, etc.

### What does it mean when I receive a message saying that my current device isn't powerful enough to verify my password?

This means that the parameters that were used to derive your master-key on your
original device, are incompatible with your current device (likely because it's
less powerful).

If you recover your account using your current device and reset the password, a
new key will be generated with different parameters. This new key will be
equally strong and compatible with both devices.
