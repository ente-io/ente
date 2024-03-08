# Deploying

The various web apps and static sites in this repository are deployed on
Cloudflare Pages. This document describes details of how things were setup, and
how deployments happen on changes.

The summary of what happens is:

* `docs/` get deployed to [help.ente.io](https://help.ente.io) whenever
  something that changes `docs/` gets merged to main.

You likely don't need to know the rest of the details (until you do, but you can
read this then).

## First time preparation

Create a new Pages project in Cloudflare, setting it up to use [Direct
Upload](https://developers.cloudflare.com/pages/get-started/direct-upload/).

> [!NOTE]
>
> Direct upload doesn't work for existing projects tied to your repository using
> the [Git
> integration](https://developers.cloudflare.com/pages/get-started/git-integration/).
>
> If you want to keep the pages.dev domain from an existing project, you should
> be able to delete your existing project and recreate it (assuming no one
> claims the domain in the middle). I've not seen this documented anywhere, but
> it worked when I tried, and it seems to have worked for [other people
> too](https://community.cloudflare.com/t/linking-git-repo-to-existing-cf-pages-project/530888).


There are two ways to create a new project, using Wrangler
[[1](https://github.com/cloudflare/pages-action/issues/51)] or using the
Cloudflare dashboard
[[2](https://github.com/cloudflare/pages-action/issues/115)]. Since this is one
time thing, the second option might be easier.

The remaining steps are documented in [Cloudflare's guide for using Direct
Upload with
CI](https://developers.cloudflare.com/pages/how-to/use-direct-upload-with-continuous-integration/).
As a checklist,

- Generate `CLOUDFLARE_API_TOKEN`
- Add `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_API_TOKEN` to the GitHub secrets
- Add your workflow. e.g. see `docs-deploy.yml`.

This is the basic setup, and should already work.

## Deploying multiple sites

However, we wish to deploy multiple sites from this same repository, so the
standard Cloudflare conception of a single "production" branch doesn't work for
us.

Instead, we use tie each deployment to a branch names. Note that we don't have
to actually create the branch or push to it, this branch name is just used as
the the `branch` parameter that gets passed to `cloudflare/pages-action`.

Since our root pages project is `ente.pages.dev`, so a branch named `foo` would
be available at `foo.ente.pages.dev`.

Finally, we create CNAME aliases using a [Custom Domain in
Cloudflare](https://developers.cloudflare.com/pages/how-to/custom-branch-aliases/)
to point to these deployments from our user facing DNS names.

As a concrete example, the GitHub workflow that deploys `docs/` passes "help" as
the branch name. The resulting deployment is available at "help.ente.pages.dev".
Finally, we add a custom domain to point to it from
[help.ente.io](https://help.ente.io).
