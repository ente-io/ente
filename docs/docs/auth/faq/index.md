---
title: FAQ - Auth
description: Frequently asked questions about Ente Auth
---

# Frequently Asked Questions

### How secure is Ente Auth?

All codes you backup via Ente is stored end-to-end encrypted. This means only
you can access your codes. Our apps are open source and our cryptography has
been externally audited.

### Can I access my codes on desktop?

You can access your codes on the web at [auth.ente.io](https://auth.ente.io).

### How can I delete or edit codes?

You can delete or edit a code by swiping left on that item.

### How can I support this project?

You can support the development of this project by subscribing to our Photos app
at [ente.io](https://ente.io).

### How can I enable FaceID lock in Ente Auth?

You can enable FaceID lock under Settings → Security → Lockscreen.

### Why does the desktop and mobile app displays different code?

Please verify that the time on both your mobile and desktop is same.

The codes depend on time. If the time is the same on both browser and mobile,
the codes you see will be the same.

Usually this discrepancy occurs because the time in your browser might be
incorrect. In particular, multiple users who have reported that Firefox provides
incorrect time when various privacy settings are enabled.

### Does Ente Authenticator require an account?

Answer: No, Ente Authenticator does not require an account. You can choose to
use the app without backups if you prefer.

### Can I use the Ente 2FA app on multiple devices and sync them?

Yes, you can download the Ente app on multiple devices and sync the codes,
end-to-end encrypted.

### What does it mean when I receive a message saying my current device is not powerful enough to verify my password?

This means that the parameters that were used to derive your master-key on your
original device, are incompatible with your current device (likely because it's
less powerful).

If you recover your account via your current device and reset the password, it
will re-generate a key that will be compatible on both devices.
