## @/new

This package only exists so that we can write code that works with TypeScript
strict mode. This provides a gradual way of migrating the existing code in the
old packages to strict mode. Once there is sufficient gravity here, we can flip
the switch on the original packages and move these back to where they came from.

### Packaging

This (internal) package exports a vanilla TypeScript library. We rely on the
importing project to transpile and bundle it.
