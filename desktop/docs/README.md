# Developer docs

If you just want to run the Ente Photos desktop app locally or develop it, you can do:

```sh
npm ci
npm run dev
```

The docs in this directory provide more details that some developers might find useful. You might also find the developer docs for [web](../../web/docs/README.md) useful.

## npm install

Use `npm ci` when installing dependencies since it uses the lockfile. Use plain `npm install` only when you are intentionally updating dependencies and reviewing the resulting `package-lock.json` changes.
