---
title: Album sharing
description: Getting album sharing to work using an self-hosted Ente
---

# Is public sharing available for self-hosted instances?

Yes.

You'll need to run two instances of the web app, one is regular web app, but
another one is the same code but running on a different origin (i.e. on a
different hostname or different port).

Then, you need to tell the regular web app to use your second instance to
service public links. You can do this by setting the
`NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT` to point to your second instance when running
or building the regular web app.

For more details, see
[.env](https://github.com/ente-io/ente/blob/main/web/apps/photos/.env) and
[.env.development](https://github.com/ente-io/ente/blob/main/web/apps/photos/.env.development).

As a concrete example, assuming we have a Ente server running on
`localhost:8080`, we can start two instances of the web app, passing them
`NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT` that points to the origin
("scheme://host[:port]") of the second "albums" instance.

The first one, the normal web app

```sh
NEXT_PUBLIC_ENTE_ENDPOINT=http://localhost:8080 \
    NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT=http://localhost:3002 \
    yarn dev:photos
```

The second one, the same code but acting as the "albums" app (the only
difference is the port it is running on):

```sh
NEXT_PUBLIC_ENTE_ENDPOINT=http://localhost:8080 \
    NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT=http://localhost:3002 \
    yarn dev:albums
```

If you also want to change the prefix (the origin) in the generated public
links, to use your custom albums endpoint in the generated public link instead
of albums.ente.io, set `apps.public-albums` property in museum's configuration

For example, when running using the starter docker compose file, you can do this
by creating a `museum.yaml` and defining the following configuration there:

```yaml
apps:
    public-albums: http://localhost:3002
```

(For more details, see
[local.yaml](https://github.com/ente-io/ente/blob/main/server/configurations/local.yaml)
in the server's source code).

## Dockerfile example

Here is an example of a Dockerfile by @Dylanger on our community Discord. This
runs a standalone self-hosted version of the public albums app in production
mode.

```Dockerfile
FROM node:20-alpine as builder

WORKDIR /app
COPY . .

ARG NEXT_PUBLIC_ENTE_ENDPOINT=https://your.ente.example.org
ARG NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT=https://your.albums.example.org

RUN yarn install && yarn build

FROM node:20-alpine

WORKDIR /app
COPY --from=builder /app/apps/photos/out .

RUN npm install -g serve

ENV PORT=3000
EXPOSE ${PORT}

CMD serve -s . -l tcp://0.0.0.0:${PORT}
```

Note that this only runs the public albums app, but the same principle can be
used to run both the normal Ente photos app and the public albums app. There is
a slightly more involved example showing how to do this also provided by in a
community contributed guide about
[configuring external S3](/self-hosting/guides/external-s3).

You will also want to tell museum about your custom shared albums endpoint so
that it uses that instead of the default URL when creating share links. You can
configure that in museum's `config.yaml`:

```
apps:
    public-albums: https://your.albums.example.org
```
