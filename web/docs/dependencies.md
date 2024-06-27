# Dependencies

## Dev

These are some global dev dependencies in the root `package.json`. These set the
baseline for how our code be in all the workspaces in this (yarn) monorepo.

-   [prettier](https://prettier.io) - Formatter

-   [eslint](https://eslint.org) - Linter

-   [typescript](https://www.typescriptlang.org/) - Type checker

They also need some support packages, which come from the leaf `@/build-config`
package:

-   [@eslint/js](https://eslint.org/) provides JavaScript ESLint functionality,
    and provides the configuration recommended the by ESLint team.

-   [typescript-eslint](https://typescript-eslint.io/packages/typescript-eslint/)
    \- provides TypeScript ESLint functionality and provides a set of
    recommended configurations (`typescript-eslint` is the new entry point, our
    yet-unmigrated packages use the older method of separately including
    [@typescript-eslint/parser](https://typescript-eslint.io/packages/eslint-plugin/)
    \- which tells ESLint how to read TypeScript syntax - and
    [@typescript-eslint/eslint-plugin](https://typescript-eslint.io/packages/eslint-plugin/)
    \- which provides the TypeScript rules and presets).

-   [eslint-plugin-react-hooks](https://github.com/jsx-eslint/eslint-plugin-react),
    [eslint-plugin-react-hooks](https://reactjs.org/) \- Some React specific
    ESLint rules and configurations that are used by the workspaces that have
    React code.

-   [eslint-plugin-react-refresh](https://github.com/ArnaudBarre/eslint-plugin-react-refresh)
    \- A plugin to ensure that React components are exported in a way that they
    can be HMR-ed.

-   [prettier-plugin-organize-imports](https://github.com/simonhaenisch/prettier-plugin-organize-imports)
    \- A Prettier plugin to sort imports.

-   [prettier-plugin-packagejson](https://github.com/matzkoh/prettier-plugin-packagejson)
    \- A Prettier plugin to also prettify `package.json`.

The root `package.json` also has a convenience dev dependency:

-   [concurrently](https://github.com/open-cli-tools/concurrently) for spawning
    parallel tasks when we invoke various yarn scripts.

## Crypto

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

## Meta frameworks

### Next.js

[Next.js](https://nextjs.org) ("next") provides the meta framework for both the
Photos and the Auth app, and also for some of the sidecar apps like accounts and
cast.

We use a limited subset of Next. The main thing we get out of it is a reasonable
set of defaults for bundling our app into a static export which we can then
deploy to our webserver. In addition, the Next.js page router is convenient.
Apart from this, while we use a few tidbits from Next.js here and there, overall
our apps are regular React SPAs, and are not particularly tied to Next.

### Vite

For some of our newer code, we have started to use [Vite](https://vitejs.dev).
It is more lower level than Next, but the bells and whistles it doesn't have are
the bells and whistles (and the accompanying complexity) that we don't need in
some cases.

## UI

### React

[React](https://react.dev) ("react") is our core framework. It also has a
sibling "react-dom" package that renders JSX to the DOM.

### MUI and Material Icons

We use [MUI](https://mui.com)'s

-   [@mui/material](https://mui.com/material-ui/getting-started/installation/),
    which is a React component library, to get a base set of components; and

-   [@mui/material-icons](https://mui.com/material-ui/material-icons/). which
    provides Material icons exported as React components (a `SvgIcon`).

### Emotion

MUI uses [Emotion](https://emotion.sh/) (a styled-component variant) as its
preferred CSS-in-JS library, and we use the same in our code too to reduce
moving parts.

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

### Others

-   [formik](https://github.com/jaredpalmer/formik) provides an easier to use
    abstraction for dealing with form state, validation and submission states
    when using React.

## Infrastructure

-   [comlink](https://github.com/GoogleChromeLabs/comlink) provides a minimal
    layer on top of web workers to make them more easier to use.

-   [idb](https://github.com/jakearchibald/idb) provides a promise API over the
    browser-native IndexedDB APIs.

    > For more details about IDB and its role, see [storage.md](storage.md).

-   [zod](https://github.com/colinhacks/zod) is used for runtime typechecking
    (e.g. verifying that API responses match the expected TypeScript shape).

## Media

-   [jszip](https://github.com/Stuk/jszip) is used for reading zip files in
    JavaScript (Live photos are zip files under the hood).

-   [file-type](https://github.com/sindresorhus/file-type) is used for MIME type
    detection. We are at an old version 16.5.4 because v17 onwards the package
    became ESM only - for our limited use case, the custom Webpack configuration
    that entails is not worth the upgrade.

-   [heic-convert](https://github.com/catdad-experiments/heic-convert) is used
    for converting HEIC files (which browsers don't natively support) into JPEG.

## Photos app specific

### General

-   [react-dropzone](https://github.com/react-dropzone/react-dropzone/) is a
    React hook to create a drag-and-drop input zone.

-   [sanitize-filename](https://github.com/parshap/node-sanitize-filename) is
    for converting arbitrary strings into strings that are suitable for being
    used as filenames.

### Face search

-   [transformation-matrix](https://github.com/chrvadala/transformation-matrix)
    is used for performing 2D affine transformations using transformation
    matrices. It is used during face detection.

-   [matrix](https://github.com/mljs/matrix) is mathematical matrix abstraction.
    It is used alongwith
    [similarity-transformation](https://github.com/shaileshpandit/similarity-transformation-js)
    during face alignment.

    > Note that while both `transformation-matrix` and `matrix` are "matrix"
    > libraries, they have different foci and purposes: `transformation-matrix`
    > provides affine transforms, while `matrix` is for performing computations
    > on matrices, say inverting them or performing their decomposition.

-   [hdbscan](https://github.com/shaileshpandit/hdbscan-js) is used for face
    clustering.

## Auth app specific

-   [otpauth](https://github.com/hectorm/otpauth) is used for the generation of
    the actual OTP from the user's TOTP/HOTP secret.

-   However, otpauth doesn't support steam OTPs. For these, we need to compute
    the SHA-1, and we use the same library, `jssha` that `otpauth` uses (since
    it is already part of our bundle).
