---
title: Migrating from most providers
description:
    Guide for importing your existing 2FA tokens into Ente Auth from most providers
---

# Migrating from most providers

---

Ente Auth natively supports imports from many 2FA providers. In addition to the 
providers specifically listed in the documentation, the supported providers are:

-   2FAS Authenticator
-   Aegis Authenticator
-   Bitwarden
-   Google Authenticator
-   Ravio OTP
-   LastPass

Details as to how codes may be imported from these providers may be found within
the app.

Ente Auth also supports imports from Auth's own encrypted exports and plain 
text files. Plain text files must be in the following format:

```otpauth://totp/provider.com:you@email.com?secret=YOUR_SECRET```

The codes can be seperated by a comma or a new line.