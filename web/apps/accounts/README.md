# Ente Accounts

Code that runs on `accounts.ente.io`.

Primarily, this serves a common domain where our clients (mobile and web / auth
and photos) can create and authenticate using shared passkeys tied to the user's
Ente account. Passkeys can be shared by multiple domains, so we didn't strictly
need a separate web origin for sharing passkeys across our web clients, but we
do need a web origin to handle the passkey flow for the mobile clients.

For more details about the Passkey flows,
[docs/webauthn-passkeys.md](../../docs/webauthn-passkeys.md).
