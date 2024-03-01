Notes on how to upload electron symbols directly to sentry instance (bypassing the CF limits) cc @abhi just for future reference

To upload electron symbols

1. Create a tunnel
```
ssh -p 7426 -N -L 8080:localhost:9000 sentry
```

2. Add the following env file
```
NEXT_PUBLIC_IS_SENTRY_ENABLED = yes
SENTRY_ORG = ente
SENTRY_PROJECT = bhari-frame
SENTRY_URL2 = https://sentry.ente.io/
SENTRY_URL = http://localhost:8080/
SENTRY_AUTH_TOKEN = xxx
SENTRY_LOG_LEVEL = debug
```

3. Run

```
node sentry-symbols.js
```