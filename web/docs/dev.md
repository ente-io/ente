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

> Tip: `yarn dev` is a shorcut for `yarn dev:photos`

Note that yarn does not automatically update `node_modules` if you switch to a
branch that has added or modified dependencies. So if you encounter unexpected
errors on switching branches, make sure that your `node_modules` is up to date
by running `yarn install` first.

> `yarn` is a shortcut for `yarn install`

To add a local package as a dependency, use `<package-name>@*`. The "*" here
denotes any version.

```sh
yarn workspace photos add '@/utils@*'
```

> Note: The yarn (classic) command above causes harmless but noisy diffs in
> `yarn.lock` when adding or removing dependencies to the workspaces. To fix
> them, run `yarn` again once to reset these unnecessary changes.

To see what packages depend on each other locally, use

```sh
yarn workspaces info
```
