# Contributing

Thank you for showing interest in contributing to ente Authenticator. There are a couple of ways to help
out. This document contains some general guidelines for each type of
contribution.


## Translations
[![Crowdin](https://badges.crowdin.net/ente-authenticator-app/localized.svg)](https://crowdin.com/project/ente-authenticator-app)

We use [Crowdin](https://crowdin.com/project/ente-authenticator-app) to crowdsource
translations of ente Authenticator. 
If your language is not listed for translation, feel free to [create a GitHub issue](https://github.com/ente-io/auth/issues/new?title=Request+for+New+Language+Translation&body=Language+name%3A) to have it added.

## Icons

ente Auth supports the icon pack provided by
[simple-icons](https://github.com/simple-icons/simple-icons).

If you would like to add your own custom icon, please open a pull-request
with the relevant SVG and color
code ([example PR](https://github.com/ente-io/auth/pull/213/files)).


## Developement

If you're planning on adding a new feature or making other changes, please
discuss it with us by creating [an
issue](https://github.com/ente-io/auth/issues/new)
on GitHub. Discussing your idea with us first ensures that everyone is on the
same page before you start working on your change.

### 💻  Setup

1. [Install Flutter v3.10.6](https://flutter.dev/docs/get-started/install)
2. Clone this repository with `git clone git@github.com:ente-io/auth.git` 
3. Pull in all submodules with `git submodule update --init --recursive`
4. For Android, run 
    ```bash
    flutter run -t lib/main.dart --flavor independent
    ```
5. For iOS, run `flutter run` 


#### Localization
If the feature works require adding new strings, you can do that by following these steps.

1. Add a new entry inside [app_en.arb](https://github.com/ente-io/auth/blob/main/lib/l10n/arb/app_en.arb) (Remember to save)
2.  In your dart file, add follwing import
    ```dart
    import "package:ente_auth/l10n/l10n.dart";
    ```
3. Refer to the string using `context.l10n.<keyName>`. For example 
    ```dart
    context.l10n.account
    ```
