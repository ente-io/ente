# Development tips

-   `yarn build:quick` is a variant of `yarn build` that uses the
    `--config.compression=store` flag to (slightly) speed up electron-builder.

## Notes

-   When using native node modules (those written in C/C++), we need to ensure
    they are built against `electron`'s packaged `node` version. We use
    [electron-builder](https://www.electron.build/cli)'s `install-app-deps`
    command to rebuild those modules automatically after each `yarn install` by
    invoking it in as the `preinstall` step in our package.json.
