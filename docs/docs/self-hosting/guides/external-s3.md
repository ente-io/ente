---
title: External S3 buckets
description:
    Self hosting Ente's server and photos web app when using an external S3
    bucket
---

# Hosting server and web app using external S3

> [!NOTE]
>
> This is a community contributed guide, and some of these steps ~~might be~~
> ARE out of sync with the upstream changes. This document is retained for
> reference purposes, but if something is not working correctly, please see the
> latest [READMEs](https://github.com/ente-io/ente/blob/main/server/README.md)
> in the repository and/or other guides in [self-hosting](/self-hosting/).

This guide is for self hosting the server and the web application of Ente Photos
using docker compose and an external S3 bucket. So we assume that you already
have the keys and secrets for the S3 bucket. The plan is as follows:

1. Create a `compose.yaml` file
2. Set up the `.credentials.env` file
3. Run `docker-compose up`
4. Create an account and increase storage quota
5. Fix potential CORS issue with your bucket

## 1. Create a `compose.yaml` file

After cloning the main repository with

```bash
git clone https://github.com/ente-io/ente.git
# Or git clone git@github.com:ente-io/ente.git
cd ente
```

Create a `compose.yaml` file at the root of the project with the following
content (there is nothing to change here):

```yaml
services:
    museum:
        build:
            context: server
            args:
                GIT_COMMIT: local
        ports:
            - 8080:8080 # API
            - 2112:2112 # Prometheus metrics
        depends_on:
            postgres:
                condition: service_healthy

        # Wait for museum to ping pong before starting the webapp.
        healthcheck:
            test: [
                    "CMD",
                    "echo",
                    "1", # I don't know what to put here
                ]
        environment:
            # no need to touch these
            ENTE_DB_HOST: postgres
            ENTE_DB_PORT: 5432
            ENTE_DB_NAME: ente_db
            ENTE_DB_USER: pguser
            ENTE_DB_PASSWORD: pgpass
        env_file:
            - ./.credentials.env
        volumes:
            - custom-logs:/var/logs
            - museum.yaml:/museum.yaml:ro
        networks:
            - internal

    web:
        build:
            context: web
        ports:
            - 8081:80
            - 8082:80
        depends_on:
            museum:
                condition: service_healthy
        env_file:
            - ./.credentials.env

    postgres:
        image: postgres:12
        ports:
            - 5432:5432
        environment:
            POSTGRES_USER: pguser
            POSTGRES_PASSWORD: pgpass
            POSTGRES_DB: ente_db
        # Wait for postgres to be accept connections before starting museum.
        healthcheck:
            test: ["CMD", "pg_isready", "-q", "-d", "ente_db", "-U", "pguser"]
            interval: 1s
            timeout: 5s
            retries: 20
        volumes:
            - postgres-data:/var/lib/postgresql/data
        networks:
            - internal
volumes:
    custom-logs:
    postgres-data:
networks:
    internal:
```

It maybe be added in the future, but if it does not exist, create a `Dockerfile`
in the `web` directory with the following content:

```Dockerfile
# syntax=docker/dockerfile:1
FROM node:21-bookworm-slim as ente-builder
WORKDIR /app
RUN apt update && apt install -y ca-certificates && rm -rf /var/lib/apt/lists/*
COPY . .
RUN yarn install
ENV NEXT_PUBLIC_ENTE_ENDPOINT=DOCKER_RUNTIME_REPLACE_ENDPOINT
ENV NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT=DOCKER_RUNTIME_REPLACE_ALBUMS_ENDPOINT
RUN yarn build


FROM nginx:1.25-alpine-slim
COPY --from=ente-builder /app/apps/photos/out /usr/share/nginx/html
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
  listen 80 default_server;
  root /usr/share/nginx/html;
  location / {
      try_files \$uri \$uri.html \$uri/ =404;
  }
  error_page 404 /404.html;
  location = /404.html {
      internal;
  }
}
EOF
ARG ENDPOINT="http://localhost:8080"
ENV ENDPOINT "$ENDPOINT"
ARG ALBUMS_ENDPOINT="http://localhost:8082"
ENV ALBUMS_ENDPOINT "$ALBUMS_ENDPOINT"
COPY <<EOF /docker-entrypoint.d/replace_ente_endpoints.sh
echo "Replacing endpoints"
echo "  Endpoint: \$ENDPOINT"
echo "  Albums Endpoint: \$ALBUMS_ENDPOINT"

replace_enpoints() {
  sed -i -e 's,DOCKER_RUNTIME_REPLACE_ENDPOINT,'"\$ENDPOINT"',g' \$1
  sed -i -e 's,DOCKER_RUNTIME_REPLACE_ALBUMS_ENDPOINT,'"\$ALBUMS_ENDPOINT"',g' \$1
}
for jsfile in `find '/usr/share/nginx/html' -type f -name '*.js'`
do
    replace_enpoints "\$jsfile"
done
EOF

RUN chmod +x /docker-entrypoint.d/replace_ente_endpoints.sh
```

This runs nginx inside to handle both the web & album URLs so we don't have to
make two web images with different port.

- `DOCKER_RUNTIME_REPLACE_ENDPOINT` this is your public museum API URL.
- `DOCKER_RUNTIME_REPLACE_ALBUMS_ENDPOINT` this is the shared albums URL (for
  more details about configuring shared albums, see
  [faq/sharing](/self-hosting/faq/sharing)).

Note how above we had updated the `compose.yaml` file for the server with

```yaml
web:
    build:
        context: web
    ports:
        - 8081:80
        - 8082:80
```

so that web and album both point to the same container and nginx will handle it.

## 2. Set up the `.credentials.env` file

Create a `.credentials.env` file at the root of the project with the following
content (here you need to set the correct value of each variable):

<!-- The following code block should have language env, but vitepress currently
doesn't support that language, so use sh as a reasonable fallback instead. -->

```sh
# run  `go run tools/gen-random-keys/main.go` in the server directory to generate the keys
ENTE_KEY_ENCRYPTION=
ENTE_KEY_HASH=
ENTE_JWT_SECRET=

# if you deploy it on a server under a domain, you need to set the correct value of the following variables
# it can be changed later

# The backend server URL (Museum) to be used by the webapp
ENDPOINT=http://localhost:8080
# The URL of the public albums webapp (also need to be updated in museum.yml so the correct links are generated)
ALBUMS_ENDPOINT=http://localhost:8082
```

Create the `museum.yaml` with additional configuration, this will be mounted
(read-only) into the container:

```yaml
s3:
    are_local_buckets: false
    # For some self-hosted S3 deployments you (e.g. Minio) you might need to disable bucket subdomains
    use_path_style_urls: true
    # The key must be named like so
    b2-eu-cen:
        key: $YOUR_S3_KEY
        secret: $YOUR_S3_SECRET
        endpoint: $YOUR_S3_ENDPOINT
        region: $YOUR_S3_REGION
        bucket: $YOUR_S3_BUCKET_NAME
# The same value as the one specified in ALBUMS_ENDPOINT
apps:
    public-albums: http://localhost:8082
```

## 3. Run `docker-compose up`

Run `docker-compose up` at the root of the project (add `-d` to run it in the
background).

## 4. Create an account and increase storage quota

Open `http://localhost:8080` or whatever Endpoint you mentioned for the web app
and create an account. If your SMTP related configurations are all set and
right, you will receive an email with your OTT in it. There are two work arounds
to retrieve the OTP, checkout
[this document](https://help.ente.io/self-hosting/faq/otp) for getting your
OTT's..

If you successfully log in, select any plan and increase the storage quota with
the following command:

```bash
docker compose exec -i postgres psql -U pguser -d ente_db -c "INSERT INTO storage_bonus (bonus_id, user_id, storage, type, valid_till) VALUES ('self-hosted-myself', (SELECT user_id FROM users), 1099511627776, 'ADD_ON_SUPPORT', 0)"
```

After few reloads, you should see 1 To of quota.

## Related

Some other users have also shared their setups.

- [Using Traefik](https://github.com/ente-io/ente/pull/3663)

- [Building custom images from source (Linux)](https://github.com/ente-io/ente/discussions/3778)

- [Troubleshooting Bucket CORS](/self-hosting/troubleshooting/bucket-cors)
