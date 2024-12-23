---
title: Hosting the web apps
description:
    Building and hosting Ente's web apps, connecting it to your self-hosted
    server
---

# Web app

The getting started instructions mention using `yarn dev` (which is an alias of
`yarn dev:photos`) to serve your web app.

```sh
cd ente/web
git submodule update --init --recursive
yarn install
NEXT_PUBLIC_ENTE_ENDPOINT=http://localhost:8080 yarn dev:photos
```

This is fine for trying the web app and verifying that your self-hosted server is 
working as expected etc. But if you would like to use the web app for a longer term, 
then it is recommended to follow the Docker approach. 

## With Docker/Docker Compose (Recommended)

> [!IMPORTANT]
>
> This docker image is still in testing stage and it might show up with some
> unknown variables in different scenarios. But this image has been tested on a production 
> ente site. 
> 
> Recurring changes might be made by the team or from community if more
> improvements can be made so that we are able to build a full-fledged docker image.

```dockerfile
FROM node:20-bookworm-slim as builder

WORKDIR ./ente

COPY . .
COPY apps/ .

# Will help default to yarn versoin 1.22.22
RUN corepack enable

# Configure Albums and Accounts Endpoints
ENV NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT=https://your-domain.com 
ENV NEXT_PUBLIC_ENTE_ACCOUNTS_ENDPOINT=https://your-domain.com

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

The above is a multi-stage Dockerfile which creates a production ready static output
of the 4 apps (Photos, Accounts, Auth and Cast) and serves the static content with 
Caddy. 

Looking at 2 different node base-images doing different tasks in the same Dockerfile 
would not make sense, but the Dockerfile is divided into two just to improve the build 
efficiency as building this Dockerfile will arguably take more time.

Lets build a Docker image from the above Dockerfile. Copy and paste the above Dockerfile 
contents in the root of your web directory which is inside `ente/web`. Execute the 
below command to create an image from this Dockerfile.


```sh
# Build the image
docker build -t <image-name>:<tag> --no-cache --progress plain . 
```

You can always edit the Dockerfile and remove the steps for apps which you do not 
intend to install on your system (like auth or cast) and opt out of those. 

Regarding Albums App, please take a note that they are not web pages with 
navigable pages, if accessed on the web-browser they will simply redirect to 
ente.web.io. 

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
      - NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT=https://your-domain.com 
      - NEXT_PUBLIC_ENTE_ACCOUNTS_ENDPOINT=https://your-domain.com
      - NODE_ENV=development
    restart: always
```

Now, we're good to go. All we are left to do now is start the containers. 

```sh 
docker compose up -d # --build 

# Accessing the logs
docker compose logs <container-name>
```

Next part is to configure a [web server](#web-server-configuration).

## Without Docker / Docker compose

One way to run all the apps together without Docker is by using [PM2](https://pm2.keymetrics.io/) 
in this setup. The configuration and usage is very simple and just needs one 
configuration file for it. You can run the apps both in dev server mode as 
well as static files. 

The below configuration will run the apps in dev server mode.

### Install PM2

```sh 
npm install pm2@latest 
```

Copy the below contents to a file called `ecosystem.config.js` inside the `ente/web`
directory. 

```js 
module.exports = {
  apps: [
    {
      name: "photos",
      script: "yarn workspace photos next dev",
      env: {
        NODE_ENV: "development",
        PORT: "3000"
      }
    },
    {
      name: "accounts",
      script: "yarn workspace accounts next dev",
      env: {
        NODE_ENV: "development",
        PORT: "3001"
      },
    {
      name: "auth",
      script: "yarn workspace auth next dev",
      env: {
        NODE_ENV: "development",
        PORT: "3002"
      }
    },
    {
      name: "cast",
      script: "yarn workspace cast next dev",
      env: {
        NODE_ENV: "development",
        PORT: "3003"
      }
    }
  ]
};

```

Finally, start pm2. 

```sh 
pm2 start 

# for logs
pm2 logs all
```

# Web server configuration 

The last step ahead is configuring reverse_proxy for the ports on which the 
apps are being served (you will have to make changes, if you have cusotmized the ports).
The web server of choice in this guide is [Caddy](https://caddyserver.com) because
with caddy you don't have to manually configure/setup SSL ceritifcates as caddy 
will take care of that.

```sh
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

Please start a discussion on the Github Repo if you have any suggestions for the Dockerfile,
You can also share your setups on Github Discussions. 
