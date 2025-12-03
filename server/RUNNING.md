# Running Museum

You can run a Docker compose cluster containing museum, the web app, and the
essential auxiliary services it requires (database and object storage). This is
the easiest and simplest way to get started, and also provides an isolated
environment that doesn't clutter your machine.

You can also run museum directly on your machine if you wish - it is a single
static go binary.

This document describes these different approaches (you can choose any one), and
also outlines configuration.

-   [Run using pre-built Docker images](quickstart/README.md)
-   [Run using Docker, building image from source](#build-and-run-using-docker)
-   [Run with Docker, à la carte](#pre-built-images)
-   [Run without Docker](#running-without-docker)
-   [Configuration](#configuration)

## Run using pre-built Docker images

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ente-io/ente/main/server/quickstart.sh)"
```

For more details, see [docs/quickstart.md](docs/quickstart.md).

## Build and run using Docker

Start the cluster (in the `ente/server` directory)

    docker compose up --build

Once the cluster has started, you should be able to do call museum

    curl http://localhost:8080/ping

Or connect from the [web app](../web)

    NEXT_PUBLIC_ENTE_ENDPOINT=http://localhost:8080 yarn dev

Or connect from the [mobile app](../mobile)

    flutter run --dart-define=endpoint=http://localhost:8080

Or interact with the other services in the cluster, e.g. connect to the DB

    docker compose exec postgres env PGPASSWORD=pgpass psql -U pguser -d ente_db

Or interact with the MinIO S3 API

    AWS_ACCESS_KEY_ID=changeme AWS_SECRET_ACCESS_KEY=changeme1234 \
        aws s3 --endpoint-url http://localhost:3200 ls s3://b2-eu-cen

Or open the MinIO dashboard at http://localhost:3201

> [!NOTE]
>
> To avoid exposing unnecessary services, this port is not exposed by default.
> You'll need to uncomment the corresponding port in your `compose.yaml` first.

> [!WARNING]
>
> The default credentials are user changeme / password changeme1234. Goes
> without saying, but remember to change them!

> [!NOTE]
>
> While we've provided a MinIO based Docker compose file to make it easy for
> people to get started, if you're running it in production we recommend using
> an external S3.

### Cleanup

Persistent data is stored in Docker volumes and will persist across container
restarts. The volume can be saved / inspected using the `docker volumes`
command.

To remove stopped containers, use `docker compose rm`. To also remove volumes,
use `docker compose down -v`.

### Multiple clusters

You can spin up independent clusters, each with its own volumes, by using the
`-p` Docker Compose flag to specify different project names for each one.

### Pruning images

Each time museum gets rebuilt from source, a new image gets created but the old
one is retained as a dangling image. You can use `docker image prune --force`,
or `docker system prune` if that's fine with you, to remove these.

## Pre-built images

## server

If you have setup the database and object storage externally and only want to
run Ente's server, you can just pull and run the image from
**`ghcr.io/ente-io/server`**.

```sh
docker pull ghcr.io/ente-io/server
```

## web

Similarly, there is a pre-built Docker image containing all the web apps which
you can just pull and run the from **`ghcr.io/ente-io/web`**.

```sh
docker pull ghcr.io/ente-io/web
```

For details about configuring the web image, see
[web/docs/docker.md](../web/docs/docker.md).

## Running without Docker

The museum binary can be run by using `go run cmd/museum/main.go`. But first,
you'll need to prepare your machine for development. Here we give the steps,
with examples that work for macOS (please adapt to your OS).

### Install [Go](https://golang.org/dl/)

```sh
brew tap homebrew/core
brew upgrade
brew install go
```

### Install other packages

```sh
brew install postgresql@15
brew install libsodium
brew install pkg-config
```

> [!NOTE]
>
> Here we install same major version of Postgres as our production database to
> avoid surprises, but if you're using a newer Postgres that should work fine
> too.

On M1 macs, we additionally need to link the postgres keg.

```
brew link postgresql@15
```

### Init Postgres database

Homebrew already creates a default database cluster for us, but if needed, it
can also be done with the following commands:

```sh
sudo mkdir -p /usr/local/var/postgres
sudo chmod 775 /usr/local/var/postgres
sudo chown $(whoami)  /usr/local/var/postgres
initdb /usr/local/var/postgres
```

On M1 macs, the path to the database cluster is
`/opt/homebrew/var/postgresql@15` (instead of `/usr/local/var/postgres`).

### Start Postgres

```sh
pg_ctl -D /usr/local/var/postgres -l logfile start
```

### Create user

```sh
createuser -s postgres
```

### Start museum

```sh
export ENTE_DB_USER=postgres
go run cmd/museum/main.go
```

For live reloads, install [air](https://github.com/cosmtrek/air#installation).
Then you can just call `air` after declaring the required environment variables.
For example,

```sh
ENTE_DB_USER=ente_user
air
```

### Testing

Set up a local database for testing. This is not required for running the server.
Create a test database with the following name and credentials:

```sql
$ psql -U postgres
CREATE DATABASE ente_test_db;
CREATE USER test_user WITH PASSWORD 'test_pass';
GRANT ALL PRIVILEGES ON DATABASE ente_test_db TO test_user;
```

For running the tests, you can use the following command:

```sh
ENV="test" go test -v ./pkg/...
go clean -testcache  && ENV="test" go test -v ./pkg/...
```

## Configuration

Now that you have museum running (either inside Docker or standalone), we can
talk about configuring it.

By default, museum runs in the "local" configuration using values specified in
`local.yaml`.

To override these values, you can create a file named `museum.yaml` in the
current directory. This path is git-ignored for convenience. Note that if you
run the Docker compose cluster without creating this file, Docker will create an
empty directory named `museum.yaml` which you can `rmdir` if you need to provide
a config file later on.

The keys and values supported by this configuration file are documented in
[configurations/local.yaml](configurations/local.yaml).

> [!TIP]
>
> If your mobile app is able to connect to your self hosted instance but is not
able to view or upload images, see
[ente.io/help/self-hosting/guides/configuring-s3](https://ente.io/help/self-hosting/guides/configuring-s3).
