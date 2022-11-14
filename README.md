# ente Authenticator

ente's Authenticator app helps you generate and store 2 step verification (2FA)
tokens on your mobile devices.

## ✨ Features

### Secure Backups

ente provides end-to-end encrypted cloud backups so that you don't have to worry
about losing your tokens. We use the same protocols [ente
Photos](https://ente.io/photos) uses to encrypt and preserve your data.


### Multi Device Synchronization

ente will automatically sync the 2FA tokens you add to your account, across all
your devices. Every new device you sign into will have access to these tokens.


### Offline Mode

ente generates 2FA tokens offline, so your network connectivity will not get in
the way of your workflow.

### Import and Export Tokens

You can add tokens to ente by one of the following methods:
1. Scanning a QR code
2. Manually entering (copy-pasting) a 2FA secret
3. Bulk importing from a file that contains a list of codes in the following
   format:
```
otpauth://totp/ACCOUNT?secret=SUPERSECRET&issuer=SERVICE
```
The codes maybe separated by new lines or commas.

You can also export the codes you have added to ente, to an **unencrypted** text
file, that adheres to the above format.


## 🔩 Architecture

The architecture that powers end-to-end encrypted storage and sync of your
tokens has been documented [here](architecture/index.md).


## 🧑‍💻 Building from source

1. [Install Flutter](https://flutter.dev/docs/get-started/install)
2. Clone this repository with `git clone git@github.com:ente-io/auth.git` 
3. Pull in all submodules with `git submodule update --init --recursive`
4. For Android, run `flutter build apk --release --flavor independent`
5. For iOS, run `flutter build ios` 


## 🙋‍♂️ Support

If you need help, please reach out to support@ente.io, and a human will get in
touch with you.

On the other hand, if you wish to support us, please
[star](https://github.com/ente-io/auth/stargazers) this project.


## 💜 Community
- Follow us on [Twitter](https://twitter.com/enteio)
- Join us on [Discord](https://ente.io/discord)
