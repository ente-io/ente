# Dependencies

## Dev

These are some global dev dependencies in the root `package.json`. These set the
baseline for how our code be in all the workspaces in this (yarn) monorepo.

-   "prettier" - Formatter
-   "eslint" - Linter
-   "typescript" - Type checker

They also need some support packages, which come from the leaf `@/build-config`
package:

-   "@typescript-eslint/parser" - Tells ESLint how to read TypeScript syntax
-   "@typescript-eslint/eslint-plugin" - Provides TypeScript rules and presets
-   "eslint-plugin-react-hooks", "eslint-plugin-react-namespace-import" - Some
    React specific ESLint rules and configurations that are used by the
    workspaces that have React code.
-   "prettier-plugin-organize-imports" - A Prettier plugin to sort imports.
-   "prettier-plugin-packagejson" - A Prettier plugin to also prettify
    `package.json`.

## Utils

### Crypto

We use [libsodium](https://libsodium.gitbook.io/doc/) for encryption, key
generation etc. Specifically, we use its WebAssembly and JS wrappers made using
Emscripten, maintained by the original authors of libsodium themselves -
[libsodium-wrappers](https://github.com/jedisct1/libsodium.js).

Currently, we've pinned the version to 0.7.9 since later versions remove the
`crypto_pwhash_*` functionality that we use (they've not been deprecated,
they've just been moved to a different NPM package). From the (upstream)
[release notes](https://github.com/jedisct1/libsodium/releases/tag/1.0.19-RELEASE):

> Emscripten: the `crypto_pwhash_*()` functions have been removed from Sumo
> builds, as they reserve a substantial amount of JavaScript memory, even when
> not used.

This wording is a bit incorrect, they've actually been _added_ to the sumo
builds (See this [issue](https://github.com/jedisct1/libsodium.js/issues/326)).

Updating it is not a big problem, it is just a pending chore - we want to test a
bit more exhaustively when changing the crypto layer.

## UI

### React

[React](https://react.dev) ("react") is our core framework. It also has a
sibling "react-dom" package that renders JSX to the DOM.

### MUI and Emotion

We use [MUI](https://mui.com) ("@mui/material"), which is a React component
library, to get a base set of components.

MUI uses [Emotion](https://emotion.sh/) (a styled-component variant) as its
preferred CSS-in-JS library.

Emotion itself comes in many parts, of which we need the following:

-   "@emotion/react" - React interface to Emotion. In particular, we set this as
    the package that handles the transformation of JSX into JS (via the
    `jsxImportSource` property in `tsconfig.json`).

-   "@emotion/styled" - Provides the `styled` utility, a la styled-components.
    We don't use it directly, instead we import it from `@mui/material`.
    However, MUI docs
    [mention](https://mui.com/material-ui/integrations/interoperability/#styled-components)
    that

    > Keep `@emotion/styled` as a dependency of your project. Even if you never
    > use it explicitly, it's a peer dependency of `@mui/material`.

#### Component selectors

Note that currently the SWC plugin doesn't allow the use of the component
selectors API (i.e using `styled.div` instead of `styled("div")`).

> I think the transform for component selectors is not implemented in the swc
> plugin.
>
> https://github.com/vercel/next.js/issues/46973

There is a way of enabling it by installing the `@emotion/babel-plugin` and
specifying the import map as mentioned
[here](https://mui.com/system/styled/#how-to-use-components-selector-api)
([full example](https://github.com/mui/material-ui/issues/27380#issuecomment-928973157)),
but that disables the SWC integration altogether, so we live with this
infelicity for now.

### Translations

For showing the app's UI in multiple languages, we use the i18next library,
specifically its three components

-   "i18next": The core `i18next` library.
-   "i18next-http-backend": Adds support for initializing `i18next` with JSON
    file containing the translation in a particular language, fetched at
    runtime.
-   "react-i18next": React specific support in `i18next`.

Note that inspite of the "next" in the name of the library, it has nothing to do
with Next.js.

For more details, see [translations.md](translations.md).

## Meta Frameworks

### Next.js

[Next.js](https://nextjs.org) ("next") provides the meta framework for both the
Photos and the Auth app, and also for some of the sidecar apps like accounts and
cast.

We use a limited subset of Next. The main thing we get out of it is a reasonable
set of defaults for bundling our app into a static export which we can then
deploy to our webserver. In addition, the Next.js page router is convenient.
Apart from this, while we use a few tidbits from Next.js here and there, overall
our apps are regular React SPAs, and are not particularly tied to Next.
