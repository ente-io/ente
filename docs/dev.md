## Monorepo

The monorepo uses Yarn (classic) workspaces.

To run a command for a workspace `<ws>`, invoke `yarn workspace <ws> <cmd>` from
the root folder instead the the `yarn <cmd>` you’d have done otherwise. For
example, to start a development server for the `photos` app, we can do

```sh
yarn workspace photos next dev
```

There is also a convenience alias, `yarn dev:photos`. See `package.json` for the
full list of such aliases. The two common patterns are `dev:<app-name>` for
running a local development server, and `build:<app-name>` for creating a
production build.

Note that yarn does not automatically update `node_modules` if you switch to a
branch that has added or modified dependencies. So if you encounter unexpected
errors or switching branches, make sure that your node_modules is up to date by
running `yarn install` first (tip: `yarn` is a shortcut for `yarn install`).

To add a local package as a dependency, use `<package-name>@*`. The "*" here
denotes any version.

```sh
yarn workspace photos add '@/utils@*'
```

To see what packages depend on each other locally, use

```sh
yarn workspaces info
```
