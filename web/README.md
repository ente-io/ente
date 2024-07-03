# Ente's web apps

Source code for Ente's various web apps and supporting websites.

Live versions are at:

-   Ente Photos: [web.ente.io](https://web.ente.io)
-   Ente Auth: [auth.ente.io](https://auth.ente.io)

To know more about Ente, see [our main README](../README.md) or visit
[ente.io](https://ente.io).

## Building from source

Fetch submodules

```sh
git submodule update --init --recursive
```

Install dependencies

```sh
yarn install
```

Start a local development server

```sh
yarn dev
```

That's it. The web app will automatically hot reload when you make changes.

> [!TIP]
>
> If you're new to web development and unsure about how to get started, or are
> facing some problems when running the above steps, see
> [docs/new](docs/new.md).

## Other apps

By default, `yarn dev` builds the Photos app. You can build the auth app by
doing `yarn dev:auth`.

To see the full list of apps you can run (and other scripts that you can use),
use `yarn run`.

For more details about development workflows, see [docs/dev](docs/dev.md).

## Directory structure

As a brief overview, this directory contains the following apps:

-   `apps/photos`: A fully functional web client for Ente Photos.
-   `apps/auth`: A view only client for Ente Auth. Currently you can only view
    your 2FA codes using this web app. For adding and editing your 2FA codes,
    please use the Ente Auth [mobile/desktop app](../auth/README.md) instead.

These are the public facing apps. There are other part of the code which are
accessed as features within the main apps, but in terms of code are
independently maintained and deployed:

-   `apps/accounts`: Passkey support (Coming soon)
-   `apps/cast`: Browser and Chromecast casting support.
-   `apps/payments`: Handle subscription payments.

> Apart from these, we also have the manage family portal whose code is
> currently in a separate repository (https://github.com/ente-io/families) and
> still needs to be brought here.

The apps take use various `packages/` to share code amongst themselves.

You might also find this [overview of dependencies](docs/dependencies.md)
useful.

## Attributions

City coordinates from [Simple Maps](https://simplemaps.com/data/world-cities)

## 🌍 Translate

[![Crowdin](https://badges.crowdin.net/ente-photos-web/localized.svg)](https://crowdin.com/project/ente-photos-web)

If you're interested in helping out with translation, please visit our
[Crowdin project](https://crowdin.com/project/ente-photos-web) to get started.
Thank you for your support.

If your language is not listed for translation, please
[create a GitHub issue](https://github.com/ente-io/ente/issues/new?title=Request+for+New+Language+Translation&body=Language+name%3A)
to have it added.

## Contribute

For more ways to contribute, see [../CONTRIBUTING.md](../CONTRIBUTING.md).
