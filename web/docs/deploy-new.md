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

