## Monorepo

The monorepo uses Yarn (classic) workspaces.

To run a command for a workspace `<ws>`, invoke `yarn workspace <ws> <cmd>` from
the root folder instead the the `yarn <cmd>` you’d have done otherwise.

To add a local package as a dependency, use `<package-name>@*`. The "*" here
denotes any version.

```sh
yarn workspace photos add '@/utils@*'
```

To see what packages depend on each other locally, use

```sh
yarn workspaces info
```
