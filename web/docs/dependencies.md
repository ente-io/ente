# Dependencies

## Dev

These are some global dev dependencies in the root `package.json`. These set the
baseline for how our code be in all the workspaces in this (yarn) monorepo.

* "prettier" - Formatter
* "eslint" - Linter
* "typescript" - Type checker

They also need some support packages, which come from the leaf `@/build-config`
package:

* "@typescript-eslint/parser" - Tells ESLint how to read TypeScript syntax
* "@typescript-eslint/eslint-plugin" - Provides TypeScript rules and presets
* "eslint-plugin-react-hooks", "eslint-plugin-react-namespace-import" - Some
  React specific ESLint rules and configurations that are used by the workspaces
  that have React code.
* "prettier-plugin-organize-imports" - A Prettier plugin to sort imports.
* "prettier-plugin-packagejson" - A Prettier plugin to also prettify
  `package.json`.

## Utils

### Crypto

We use [libsodium](https://libsodium.gitbook.io/doc/) for encryption, key
generation etc. Specifically, we use its WebAssembly and JS wrappers made using
Emscripten, maintained by the original authors of libsodium themselves -
[libsodium-wrappers](https://github.com/jedisct1/libsodium.js).

Currently, we've pinned the version to 0.7.9 since later versions remove the
crypto_pwhash_* functionality that we use (they've not been deprecated, they've
just been moved to a different NPM package). From the (upstream) [release
notes](https://github.com/jedisct1/libsodium/releases/tag/1.0.19-RELEASE):

> Emscripten: the crypto_pwhash_*() functions have been removed from Sumo
> builds, as they reserve a substantial amount of JavaScript memory, even when
> not used.

This wording is a bit incorrect, they've actually been _added_ to the sumo
builds (See this [issue](https://github.com/jedisct1/libsodium.js/issues/326)).

Updating it is not a big problem, it is just a pending chore - we want to test a
bit more exhaustively when changing the crypto layer.

## UI

The UI package uses "react". This is our core framework. We do use layers on top
of React, but those are contingent and can be replaced, or even removed. But the
usage of React is deep rooted. React also has a sibling "react-dom" package that
renders "React" interfaces to the DOM.

### MUI and Emotion

Currently, we use MUI ("@mui/material"), which is a React component library, to
get a base set of components. MUI uses Emotion (a styled-component variant) as
its preferred CSS-in-JS library and to keep things simple, that's also what we
use to write CSS in our own JS (TS).

Emotion itself comes in many parts, of which we need the following three:

* "@emotion/react" - React interface to Emotion. In particular, we set this as
  the package that handles the transformation of JSX into JS (via the
  `jsxImportSource` property in `tsconfig.json`).

* "@emotion/styled" - Provides the `styled` utility, a la styled-components. We
  don't use it directly, instead we import it from `@mui/material`. However, MUI
  docs
  [mention](https://mui.com/material-ui/integrations/interoperability/#styled-components)
  that

  > Keep `@emotion/styled` as a dependency of your project. Even if you never
  > use it explicitly, it's a peer dependency of `@mui/material`.

* "@emotion/server"

### Translations

For showing the app's UI in multiple languages, we use the i18next library,
specifically its three components

* "i18next": The core `i18next` library.
* "i18next-http-backend": Adds support for initializing `i18next` with JSON file
  containing the translation in a particular language, fetched at runtime.
* "react-i18next": React specific support in `i18next`.

Note that inspite of the "next" in the name of the library, it has nothing to do
with Next.js.

For more details, see [translations.md](translations.md).
