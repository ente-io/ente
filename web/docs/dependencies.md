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

-   [eslint-plugin-react](https://github.com/jsx-eslint/eslint-plugin-react),
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

## Cryptography

We use [libsodium](https://libsodium.gitbook.io/doc/) for our cryptography
primitives. We use its WebAssembly target, accessible via JavaScript wrappers
maintained by the original authors of libsodium themselves -
[libsodium-wrappers](https://github.com/jedisct1/libsodium.js).

More precisely, we use the sumo variant, "libsodium-wrappers-sumo", since the
standard variant does not provide the `crypto_pwhash_*` functions.

## Meta frameworks

### Next.js

[Next.js](https://nextjs.org) (package:
[next](https://github.com/vercel/next.js)) provides the meta framework for both
the photos and the auth app, and also for some of the sidecar apps like accounts
and cast.

We use a limited subset of Next.js. The main thing we get out of it is a
reasonable set of defaults for bundling our app into a static export which we
can then deploy to our webserver. In addition, the Next.js page router is
convenient. Overall our apps can be described as regular React SPAs, and are not
particularly tied to Next.js.

### Vite

For some of our newer code, we have started to use [Vite](https://vitejs.dev).
It is likely the future (both generally, and for our code) since Next.js is
becoming less suitable for SPAs and static SSR with their push towards RSC and
dynamic SSR.

## UI

### React

[React](https://react.dev) (package: [react](https://github.com/facebook/react))
is our core framework. We also import its a sibling
[react-dom](https://github.com/facebook/react) package that renders JSX to the
DOM.

### MUI and Material Icons

We use [MUI](https://mui.com)'s
[@mui/material](https://mui.com/material-ui/getting-started/installation/) as
our base React component library.

MUI uses [Emotion](https://emotion.sh/) as its preferred CSS-in-JS library, for
which we need to install install two Emotion packages (`@emotion/react` and
`@emotion/styled`) as peer dependencies.

We need to pin the emotion version (using the "resolutions" field in
`package.json`) to those used by MUI since react-select (another package we use)
specify a different emotion version directly instead of as a peer dependency,
and we end up with two emotions at runtime otherwise.

We also use MUI's
[@mui/material-icons](https://mui.com/material-ui/material-icons/) package,
which provides Material icons exported as React components (a `SvgIcon`).

### Date pickers

[@mui/x-date-pickers](https://mui.com/x/react-date-pickers/getting-started/) is
used to get a date/time picker component. This is the community version of the
DateTimePicker component provided by MUI.

[dayjs](https://github.com/iamkun/dayjs) is used as the date library that that
`@mui/x-date-pickers` will internally use to manipulate dates.

### Translations

For showing the app's UI in multiple languages, we use the
[i18next](https://www.i18next.com), specifically its three components

-   [i18next](https://github.com/i18next/i18next): The core `i18next` library.
-   [react-i18next](https://github.com/i18next/react-i18next): React specific
    support in `i18next`.
-   [i18next-http-backend](https://github.com/i18next/i18next-http-backend):
    Adds support for initializing `i18next` with JSON file containing the
    translation in a particular language, fetched at runtime.

Note that inspite of the "next" in the name of the library, it has nothing to do
with Next.js.

For more details, see [translations.md](translations.md).

### Other UI components

-   [formik](https://github.com/jaredpalmer/formik) provides an easier to use
    abstraction for dealing with form state, validation and submission states
    when using React.

-   [react-select](https://react-select.com/) is used for search dropdowns.

-   [react-otp-input](https://github.com/devfolioco/react-otp-input) is used to
    render a segmented OTP input field for 2FA authentication.

## Utilities

-   [comlink](https://github.com/GoogleChromeLabs/comlink) provides a minimal
    layer on top of web workers to make them more easier to use.

-   [idb](https://github.com/jakearchibald/idb) provides a promise API over the
    browser-native IndexedDB APIs.

    > For more details about IDB and its role, see [storage.md](storage.md).

-   [zod](https://github.com/colinhacks/zod) is used for runtime typechecking
    (e.g. verifying that API responses match the expected TypeScript shape).

-   [nanoid](https://github.com/ai/nanoid) is used for generating unique
    identifiers. For one particular use case, we also need
    [uuid](https://github.com/uuidjs/uuid) for UUID v4 generation.

-   [debounce](https://github.com/sindresorhus/debounce) and its
    promise-supporting sibling
    [pDebounce](https://github.com/sindresorhus/p-debounce) are used for
    debouncing operations (See also: `[Note: Throttle and debounce]`).

-   [zxcvbn](https://github.com/dropbox/zxcvbn) is used for password strength
    estimation.

## Media

-   [ffmpeg.wasm](https://github.com/ffmpegwasm/ffmpeg.wasm) is used to run
    FFmpeg in the browser using WASM. Note that this is substantially slower
    than native ffmpeg (the desktop app can, and does, bundle the faster native
    ffmpeg implementation too).

-   [ExifReader](https://github.com/mattiasw/ExifReader) is used for Exif
    parsing.

-   [jszip](https://github.com/Stuk/jszip) is used for reading zip files in the
    web code (Live photos are zip files under the hood). Note that the desktop
    app uses also has a ZIP parser (that one supports streaming).

-   [file-type](https://github.com/sindresorhus/file-type) is used for MIME type
    detection. We are at an old version 16.5.4 because v17 onwards the package
    became ESM only - for our limited use case, the custom Webpack configuration
    that it'd entail is not worth the upgrade.

-   [heic-convert](https://github.com/catdad-experiments/heic-convert) is used
    for converting HEIC files (which browsers don't natively support) into JPEG.

## Photos app specific

-   [react-dropzone](https://github.com/react-dropzone/react-dropzone/) is a
    React hook to create a drag-and-drop input zone.

-   [sanitize-filename](https://github.com/parshap/node-sanitize-filename) is
    for converting arbitrary strings into strings that are suitable for being
    used as filenames.

-   [chrono-node](https://github.com/wanasit/chrono) is used for parsing natural
    language queries into dates for showing search results.

-   [matrix](https://github.com/mljs/matrix) is mathematical matrix abstraction
    by the machine learning code. It is used alongwith
    [similarity-transformation](https://github.com/shaileshpandit/similarity-transformation-js)
    during face alignment.

### UI

-   [react-top-loading-bar](https://github.com/klendi/react-top-loading-bar) is
    used for showing a progress indicator for global actions (This shouldn't be
    used always, it is only meant as a fallback when there isn't an otherwise
    suitable place for showing a local activity indicator).

-   [pure-react-carousel](https://github.com/express-labs/pure-react-carousel)
    is used for the feature carousel on the welcome (login / signup) screen.

## Auth app specific

-   [otpauth](https://github.com/hectorm/otpauth) is used for the generation of
    the actual OTP from the user's TOTP/HOTP secret.

-   However, otpauth doesn't support steam OTPs. For these, we need to compute
    the SHA-1, and we use the same library, `jssha` that `otpauth` uses since it
    is already part of our bundle (transitively).
