# Development

## npm commands

### npm run dev

Launch the app in development mode:

- Transpiles the files in `src/` and starts the main process.

- Runs a development server for the renderer, with hot module reload.

### npm run build

Build a binary for your current platform.

Note that our actual releases use a [GitHub workflow](../.github/workflows/desktop-release.yml) that is similar to this, except it builds binaries for all the supported OSes and uses production signing credentials.

During development, you might find `npm run build:quick` helpful. It is a variant of `npm run build` that omits some steps to build a binary quicker, something that can be useful during development.

### postinstall

When using native node modules (those written in C/C++), we need to ensure they are built against `electron`'s packaged `node` version. We use [electron-builder](https://www.electron.build/cli)'s `install-app-deps` command to rebuild those modules automatically after each dependency install by invoking it in as the `postinstall` step in our package.json.

### lint, lint:fix

Use `npm run lint` to check that your code formatting is as expected, and that there are no linter errors. Use `npm run lint:fix` to try and automatically fix the issues.
