# Development

## Editor setup

We recommend VS Code, with the following extensions:

- Prettier - reformats your code automatically (enable format on save),
- ESLint - warns you about issues

Optionally, if you're going to make many changes to the CSS in JS, you might
also find it useful to install the _vscode-styled-components_ extension.

## Yarn commands

Make sure you're on yarn 1.x series (aka yarn "classic").

### yarn install

Installs dependencies. This needs to be done once, and thereafter wherever there
is a change in `yarn.lock` (e.g. when pulling the latest upstream).

### yarn dev:\*

Launch the app in development mode. There is one `yarn dev:foo` for each app,
e.g. `yarn dev:auth`. `yarn dev` is a shortcut for `yarn dev:photos`.

The ports are different for the main apps (3000), various sidecars (3001, 3002).

### yarn build:\*

Build a production export for the app. This is a bunch of static HTML/JS/CSS
that can be then deployed to any web server.

There is one `yarn build:foo` for each app, e.g. `yarn build:auth`. The output
will be placed in `apps/<foo>/out`, e.g. `apps/auth/out`.

### lint, lint-fix

Use `yarn lint` to check that your code formatting is as expected, and that
there are no linter errors. Use `yarn lint-fix` to try and automatically fix the
issues.

## Monorepo

The monorepo uses Yarn (classic) workspaces.

To run a command for a workspace `<ws>`, invoke `yarn workspace <ws> <cmd>` from
the root folder instead the `yarn <cmd>` you’d have done otherwise. For example,
to start a development server for the `photos` app, we can do

```sh
yarn workspace photos next dev
```

There is also a convenience alias, `yarn dev:photos`. See `package.json` for the
full list of such aliases. The two common patterns are `dev:<app-name>` for
running a local development server, and `build:<app-name>` for creating a
production build.

> Tip: `yarn dev` is a shortcut for `yarn dev:photos`

Note that yarn does not automatically update `node_modules` if you switch to a
branch that has added or modified dependencies. So if you encounter unexpected
errors on switching branches, make sure that your `node_modules` is up to date
by running `yarn install` first.

> `yarn` is a shortcut for `yarn install`

To add a local package as a dependency, use `<package-name>@*`. The "\*" here
denotes any version.

```sh
yarn workspace photos add 'ente-utils@*'
```

> Note: The yarn (classic) command above causes harmless but noisy diffs in
> `yarn.lock` when adding or removing dependencies to the workspaces. To fix
> them, run `yarn` again once to reset these unnecessary changes.

To see what packages depend on each other locally, use

```sh
yarn workspaces info
```
