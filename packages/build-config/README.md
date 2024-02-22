## @/build-config

Build time configuration files. This can be thought of as a `devDependency` that
exports various config files that our packages use at build time.

### Packaging

This is _not_ a TypeScript package, nor is it linted. It is not meant to be
transpiled, it just exports static files that can be included verbatim.
