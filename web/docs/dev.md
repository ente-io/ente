# Development

## Editor setup

We recommend VS Code, with the following extensions:

- Prettier - reformats your code automatically (enable format on save),
- ESLint - warns you about issues

Optionally, if you're going to make many changes to the CSS in JS, you might also find it useful to install the _vscode-styled-components_ extension.

## npm commands

Use the npm version from `package.json`.

### npm ci

Installs dependencies using the committed lockfile. This should be the default for local setup, and whenever there is a change in `package-lock.json` (e.g. when pulling the latest upstream).

Use plain `npm install` only when intentionally updating dependencies and reviewing the resulting `package.json` and `package-lock.json` changes.

### npm run dev:\*

Launch the app in development mode. There is one `npm run dev:foo` for each app, e.g. `npm run dev:auth`. `npm run dev` is a shortcut for `npm run dev:photos`.

Common ports are `3000` for photos, `3002` for albums, `3003` for auth, `3005` for share, and `3006` for embed. See `package.json` for the full list.

### npm run build:\*

Build a production export for the app. This is a bunch of static HTML/JS/CSS that can be then deployed to any web server.

There is one `npm run build:foo` for each app, e.g. `npm run build:auth`. The output will be placed in `apps/<foo>/out`, e.g. `apps/auth/out`.

### lint, lint:fix

Use `npm run lint` to check that your code formatting is as expected, and that there are no linter errors. Use `npm run lint:fix` to try and automatically fix the issues.

## Monorepo

The monorepo uses npm workspaces.

To run a command for a workspace `<ws>`, invoke `npm exec --workspace <ws> -- <cmd>` from the root folder. For example, to start a development server for the `photos` app, we can do

```sh
npm exec --workspace photos -- next dev
```

There is also a convenience alias, `npm run dev:photos`. See `package.json` for the full list of such aliases. The two common patterns are `dev:<app-name>` for running a local development server, and `build:<app-name>` for creating a production build.

> Tip: `npm run dev` is a shortcut for `npm run dev:photos`

Note that npm does not automatically update `node_modules` if you switch to a branch that has added or modified dependencies. So if you encounter unexpected errors on switching branches, make sure that your `node_modules` is up to date by running `npm ci` first.

> Normal development should prefer `npm ci`.

To add a local package as a dependency, use `<package-name>@*`. The "\*" here denotes any version.

```sh
npm install 'ente-utils@*' --workspace photos
```

To see the workspace package metadata, use

```sh
npm query .workspace
```
