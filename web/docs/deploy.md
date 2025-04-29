# Deploying

The various web apps and static sites in this repository are deployed on
Cloudflare Pages using GitHub workflows.

- Automated production deployments of `main` daily 8:00 AM IST.

- Automated staging deployments `*.ente.sh` of `main` daily 3:00 PM IST.

- [help.ente.io](https://help.ente.io) gets deployed whenever a PR that changes
  anything inside `docs/` gets merged to `main`.

- Production or staging deployments can made manually by triggering the
  corresponding workflow. There is variant to deploy a single app to production
  using the `web-deploy-one.yml` workflow, and a variant to deploy any one of
  the apps to `preview.ente.sh` (see below).

These GitHub workflows use the various `yarn deploy:*` commands. For example,
`yarn deploy:photos` will open a PR to merge the current `main` onto
`deploy/photos`, which'll trigger the deployment workflow, which'll build and
publish to [web.ente.io](https://web.ente.io).

## Deployments

Here is a list of all the deployments, whether or not they are production
deployments, and the action that triggers them:

| URL                                          | Type       | Deployment action                           |
| -------------------------------------------- | ---------- | ------------------------------------------- |
| [web.ente.io](https://web.ente.io)           | Production | Daily deploy of `main`                      |
| [photos.ente.io](https://photos.ente.io)     | Production | Alias of [web.ente.io](https://web.ente.io) |
| [auth.ente.io](https://auth.ente.io)         | Production | Daily deploy of `main`                      |
| [accounts.ente.io](https://accounts.ente.io) | Production | Daily deploy of `main`                      |
| [cast.ente.io](https://cast.ente.io)         | Production | Daily deploy of `main`                      |
| [payments.ente.io](https://payments.ente.io) | Production | Daily deploy of `main`                      |
| [help.ente.io](https://help.ente.io)         | Production | Changes in `docs/` on push to `main`        |
| [staff.ente.sh](https://staff.ente.sh)       | Production | Changes in `infra/staff` on push to `main`  |
| [accounts.ente.sh](https://accounts.ente.sh) | Preview    | Daily deploy of `main`                      |
| [auth.ente.sh](https://auth.ente.sh)         | Preview    | Daily deploy of `main`                      |
| [cast.ente.sh](https://cast.ente.sh)         | Preview    | Daily deploy of `main`                      |
| [payments.ente.sh](https://payments.ente.sh) | Preview    | Daily deploy of `main`                      |
| [photos.ente.sh](https://photos.ente.sh)     | Preview    | Daily deploy of `main`                      |
| [preview.ente.sh](https://preview.ente.sh)   | Preview    | Manually triggered                          |

### Other subdomains

Apart from this, there are also some other deployments:

- `albums.ente.io` is a CNAME alias to the production deployment
  (`web.ente.io`). However, when the code detects that it is being served from
  `albums.ente.io`, it redirects to the `/shared-albums` page (Enhancement:
  serve it as a separate app with a smaller bundle size).

- `family.ente.io` is currently in a separate repository (Enhancement: bring it
  in here).

### Preview deployments

To trigger a preview deployment, manually trigger the "Deploy preview (web)"
workflow from the Actions tab on GitHub. You'll need to select the app to build,
and the branch to use. This'll then build the specified app (e.g. "photos") from
that branch, and deploy it to [preview.ente.sh](https://preview.ente.sh).

The workflow can also be triggered using GitHub's CLI, gh. e.g.

```sh
gh workflow run web-preview -F app=cast --ref my-branch
```

---

## Details

The rest of the document describes details about how things were setup. You
likely don't need to know them to be able to deploy.

## First time preparation

Create a new Pages project in Cloudflare, setting it up to use
[Direct Upload](https://developers.cloudflare.com/pages/get-started/direct-upload/).

> [!NOTE]
>
> Direct upload doesn't work for existing projects tied to your repository using
> the
> [Git integration](https://developers.cloudflare.com/pages/get-started/git-integration/).
>
> If you want to keep the pages.dev domain from an existing project, you should
> be able to delete your existing project and recreate it (assuming no one
> claims the domain in the middle). I've not seen this documented anywhere, but
> it worked when I tried, and it seems to have worked for
> [other people too](https://community.cloudflare.com/t/linking-git-repo-to-existing-cf-pages-project/530888).

There are two ways to create a new project, using Wrangler
[[1](https://github.com/cloudflare/pages-action/issues/51)] or using the
Cloudflare dashboard
[[2](https://github.com/cloudflare/pages-action/issues/115)]. Since this is one
time thing, the second option might be easier.

The remaining steps are documented in
[Cloudflare's guide for using Direct Upload with CI](https://developers.cloudflare.com/pages/how-to/use-direct-upload-with-continuous-integration/).
As a checklist,

- Generate `CLOUDFLARE_API_TOKEN`
- Add `CLOUDFLARE_ACCOUNT_ID` and `CLOUDFLARE_API_TOKEN` to the GitHub secrets
- Add your workflow. e.g. see `docs-deploy.yml`.

This is the basic setup, and should already work.

## Deploying multiple sites

However, we wish to deploy multiple sites from this same repository, so the
standard Cloudflare conception of a single "production" branch doesn't work for
us.

Instead, we tie each deployment to a branch name. Note that we don't have to
actually create the branch or push to it, this branch name is just used as the
the `branch` parameter that gets passed to `cloudflare/pages-action`.

Since our root pages project is `ente.pages.dev`, so a branch named `foo` would
be available at `foo.ente.pages.dev`.

Finally, we create CNAME aliases using a
[Custom Domain in Cloudflare](https://developers.cloudflare.com/pages/how-to/custom-branch-aliases/)
to point to these deployments from our user facing DNS names.

As a concrete example, the GitHub workflow that deploys `docs/` passes "help" as
the branch name. The resulting deployment is available at "help.ente.pages.dev".
Finally, we add a custom domain to point to it from
[help.ente.io](https://help.ente.io).
