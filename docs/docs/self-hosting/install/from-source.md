---
title: Ente from Source
description: Getting started self hosting Ente Photos and/or Ente Auth
---

# Ente from Source

> [!WARNING] NOTE The below documentation will cover instructions about
> self-hosting the web app manually. If you want to deploy Ente hassle free, use
> the [one line](https://ente.io/blog/self-hosting-quickstart/) command to setup
> Ente. This guide might be deprecated in the near future.

## Installing Docker

Refer to
[How to install Docker from the APT repository](https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository)
for detailed instructions.

## Start the server

```sh
git clone https://github.com/ente-io/ente
cd ente/server
docker compose up --build
```

> [!TIP]
>
> You can also use a pre-built Docker image from `ghcr.io/ente-io/server`
> ([More info](https://github.com/ente-io/ente/blob/main/server/docs/docker.md))

Install the necessary dependencies for running the web client

```sh
# installing npm and yarn

sudo apt update
sudo apt install nodejs npm
sudo npm install -g yarn // to install yarn globally
```

Then in a separate terminal, you can run (e.g) the web client

```sh
cd ente/web
git submodule update --init --recursive
yarn install
NEXT_PUBLIC_ENTE_ENDPOINT=http://localhost:8080 yarn dev
```

That's about it. If you open http://localhost:3000, you will be able to create
an account on a Ente Photos web app running on your machine, and this web app
will be connecting to the server running on your local machine at
`localhost:8080`.

For the mobile apps, you don't even need to build, and can install normal Ente
apps and configure them to use your
[custom self-hosted server](/self-hosting/guides/custom-server/).

> If you want to build the mobile apps from source, see the instructions
> [here](/self-hosting/guides/mobile-build).

## Web app with Docker and Compose

The instructoins in previous section were just a temporary way to run the web
app locally. To run the web apps as services, the user has to build a docker
image manually.

> [!IMPORTANT]
>
> Recurring changes might be made by the team or from community if more
> improvements can be made so that we are able to build a full-fledged docker
> image.

```dockerfile
FROM node:20-bookworm-slim as builder

WORKDIR ./ente

COPY . .
COPY apps/ .

# Will help default to yarn versoin 1.22.22
RUN corepack enable

# Endpoint for Ente Server
ENV NEXT_PUBLIC_ENTE_ENDPOINT=https://your-ente-endpoint.com
ENV NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT=https://your-albums-endpoint.com

RUN yarn cache clean
RUN yarn install --network-timeout 1000000000
RUN yarn build:photos && yarn build:accounts && yarn build:auth && yarn build:cast

FROM node:20-bookworm-slim

WORKDIR /app

COPY --from=builder /ente/apps/photos/out /app/photos
COPY --from=builder /ente/apps/accounts/out /app/accounts
COPY --from=builder /ente/apps/auth/out /app/auth
COPY --from=builder /ente/apps/cast/out /app/cast

RUN npm install -g serve

ENV PHOTOS=3000
EXPOSE ${PHOTOS}

ENV ACCOUNTS=3001
EXPOSE ${ACCOUNTS}

ENV AUTH=3002
EXPOSE ${AUTH}

ENV CAST=3003
EXPOSE ${CAST}

# The albums app does not have navigable pages on it, but the
# port will be exposed in-order to self up the albums endpoint
# `apps.public-albums` in museum.yaml configuration file.
ENV ALBUMS=3004
EXPOSE ${ALBUMS}

CMD ["sh", "-c", "serve /app/photos -l tcp://0.0.0.0:${PHOTOS} & serve /app/accounts -l tcp://0.0.0.0:${ACCOUNTS} & serve /app/auth -l tcp://0.0.0.0:${AUTH} & serve /app/cast -l tcp://0.0.0.0:${CAST}"]
```

The above is a multi-stage Dockerfile which creates a production ready static
output of the 4 apps (Photos, Accounts, Auth and Cast) and serves the static
content with Caddy.

Looking at 2 different node base-images doing different tasks in the same
Dockerfile would not make sense, but the Dockerfile is divided into two just to
improve the build efficiency as building this Dockerfile will arguably take more
time.

Lets build a Docker image from the above Dockerfile. Copy and paste the above
Dockerfile contents in the root of your web directory which is inside
`ente/web`. Execute the below command to create an image from this Dockerfile.

```sh
# Build the image
docker build -t <image-name>:<tag> --no-cache --progress plain .
```

You can always edit the Dockerfile and remove the steps for apps which you do
not intend to install on your system (like auth or cast) and opt out of those.

Regarding Albums App, take a note that they are not apps with navigable pages,
if accessed on the web-browser they will simply redirect to ente.web.io.

## compose.yaml

Moving ahead, we need to paste the below contents into the compose.yaml inside
`ente/server/compose.yaml` under the services section.

```yaml
ente-web:
    image: <image-name> # name of the image you used while building
    ports:
        - 3000:3000
        - 3001:3001
        - 3002:3002
        - 3003:3003
        - 3004:3004
    environment:
        - NODE_ENV=development
    restart: always
```

Now, we're good to go. All we are left to do now is start the containers.

```sh
docker compose up -d # --build

# Accessing the logs
docker compose logs <container-name>
```

## Configure App Endpoints

> [!NOTE] Previously, this was dependent on the env variables
> `NEXT_ENTE_PUBLIC_ACCOUNTS_ENDPOINT` and etc. Please check the below
> documentation to update your setup configurations

You can configure the web endpoints for the other apps including Accounts,
Albums Family and Cast in your `museum.yaml` configuration file. Checkout
[`local.yaml`](https://github.com/ente-io/ente/blob/543411254b2bb55bd00a0e515dcafa12d12d3b35/server/configurations/local.yaml#L76-L89)
to configure the endpoints. Make sure to setup up your DNS Records accordingly
to the similar URL's you set up in `museum.yaml`.

Next part is to configure the web server.

# Web server configuration

The last step ahead is configuring reverse_proxy for the ports on which the apps
are being served (you will have to make changes, if you have cusotmized the
ports). The web server of choice in this guide is
[Caddy](https://caddyserver.com) because with caddy you don't have to manually
configure/setup SSL ceritifcates as caddy will take care of that.

```groovy
photos.yourdomain.com {
	reverse_proxy http://localhost:3001
    # for logging
    log {
        level error
    }
}

auth.yourdomain.com {
    reverse_proxy http://localhost:3002
}
# and so on ...
```

Next, start the caddy server :).

```sh
# If caddy service is not enabled
sudo systemctl enable caddy

sudo systemctl daemon-reload

sudo systemctl start caddy
```

## Contributing

Please start a discussion on the Github Repo if you have any suggestions for the
Dockerfile, You can also share your setups on Github Discussions.
