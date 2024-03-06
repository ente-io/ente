# Deploying the web apps

## tl;dr;

```sh
yarn deploy:photos
```

## Details

The various web apps (Ente Photos, Ente Auth) are deployed on Cloudflare Pages.

The deployment is done using the GitHub app provided by Cloudflare Pages. The
Cloudflare integration watches for pushes to all branches named "deploy/*". In
all cases, it runs the same script, `scripts/deploy.sh`, using the
`CF_PAGES_BRANCH` environment variable to decide what exactly to build ([CF
docs](https://developers.cloudflare.com/pages/how-to/build-commands-branches/)).

For each of these branches, we have configured CNAME aliases (Cloudflare calls
them Custom Domains) to give a stable URL to the deployments.

- `deploy/photos` → _web.ente.io_
- `deploy/auth` → _auth.ente.io_
- `deploy/accounts` → _accounts.ente.io_
- `deploy/cast` → _cast.ente.io_

Thus to trigger a, say, production deployment of the photos app, we can open and
merge a PR into the `deploy/photos` branch. Cloudflare will then build and
deploy the code to _web.ente.io_.

The command `yarn deploy:photos` just does that - it'll open a new PR to fast
forward the current main onto `deploy/photos`. There are similar `yarn deploy:*`
commands for the other apps.

## Other subdomains

Apart from this, there are also some subdomains:

- `albums.ente.io` is a CNAME alias to the production deployment
  (`web.ente.io`). However, when the code detects that it is being served from
  `albums.ente.io`, it redirects to the `/shared-albums` page (Enhancement:
  serve it as a separate app with a smaller bundle size).

- `payments.ente.io` and `family.ente.io` are currently in a separate
  repositories (Enhancement: bring them in here).

## NODE_VERSION

In Cloudflare Pages setting the `NODE_VERSION` environment variables is defined.

This determines which version of Node is used when we do `yarn build:foo`.
Currently this is set to `20.11.1`. The major version here should match that of
`@types/node` in our dev dependencies.

It is a good idea to also use the same major version of node on your machine.
For example, for macOS you can install the the latest from the v20 series using
`brew install node@20`.

## Adding a new app

1. Add a mapping in `scripts/deploy.sh`.

2. Add a [Custom Domain in
   Cloudflare](https://developers.cloudflare.com/pages/how-to/custom-branch-aliases/)
   pointing to this branch's deployment.
