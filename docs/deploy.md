# Deploying the web apps

The various web apps (Ente Photos, Ente Auth) are deployed on Cloudflare Pages.
They also use Cloudflare Workers for some tasks.

This repository deploys multiple different apps (the Photos app, the Auth app).
Some of them get deployed to multiple different endpoints (e.g. the main branch
of photos app gets deployed to testing.ente.io, the while the photos-release
branch is the production deployment).

The apps are under the app directory:

- photos - The Ente Photos app
- auth - The Ente Auth app
- cast - The cast app, which can be thought of as an independent subset of
  Photos app functionality
- ... and more

For deploying, we've added the GitHub integration provided by Cloudflare Pages
app to this repository. This integration watches for pushes to all branches. In
all cases, it runs the same script, `scripts/deploy.sh`.

Internally it uses the `CF_PAGES_BRANCH` environment variable to decide what
exactly to build ([CF
docs](https://developers.cloudflare.com/pages/how-to/build-commands-branches/)).

Then, for some special branches, we have configured CNAME aliases (Cloudflare
calls them Custom Domains) to give a stable URL to some of these deployments
Here is a potentially out of date list of CNAMEs and the corresponding branch;
see the Cloudflare dashboard for the latest:

- _testing.ente.io_: `main`
- _web.ente.io_: `photos-release`
- _auth.ente.io_: `auth-release`

Thus to trigger a, say, production deployment of the photos app, we can open and
merge a PR into the `photos-release` branch. Cloudflare will then build and
deploy the code to _web.ente.io_.

## Adding a new app

1. Add a mapping in `scripts/deploy.sh`.

2. Add a [Custom Domain in
   Cloudflare](https://developers.cloudflare.com/pages/how-to/custom-branch-aliases/)
   pointing to this branch's deployment.
