# Cloudflare Workers

Source code for our [Cloudflare
Workers](https://developers.cloudflare.com/workers/).

Each worker is a self contained directory with its each `package.json`.

## Deploying

* Switch to a worker directory, e.g. `cd github-discord-notifier`.

* Install dependencies (if needed) with `yarn`

* Login into wrangler (if needed) using `yarn wrangler login`

* Deploy! `yarn wrangler deploy`

Wrangler is the CLI provided by Cloudflare to manage workers. Apart from
deploying, it also allows us to stream logs from running workers by using `yarn
wrangler tail`.

## Creating a new worker

Copy paste an existing one. Unironically this is a good option because
Cloudflare's template has a lot of unnecessary noise, but if really do want to
create one from scratch, use `npm create cloudflare@latest`.

To import an existing worker from the Cloudflare dashboard, use

```sh
npm create cloudflare@2 existing-worker-name -- --type pre-existing --existing-script existing-worker-name
```
