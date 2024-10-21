# Running Museum

You can run a Docker compose cluster containing museum and the essential
auxiliary services it requires (database and object storage). This is the
easiest and simplest way to get started, and also provides an isolated
environment that doesn't clutter your machine.

You can also run museum directly on your machine if you wish - it is a single
static go binary.

This document describes these approaches, and also outlines configuration.

-   [Run using Docker using a pre-built Docker image](docs/docker.md)
-   [Run using Docker but build an image from source](#build-and-run-using-docker)
-   [Running without Docker](#run-without-docker)
-   [Configuration](#configuration)

If your mobile app is able to connect to your self hosted instance but is not
able to view or upload images, see
[help.ente.io/self-hosting/guides/configuring-s3](https://help.ente.io/self-hosting/guides/configuring-s3).

## Build and run using Docker

Start the cluster

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

    AWS_ACCESS_KEY_ID=test AWS_SECRET_ACCESS_KEY=testtest \
        aws s3 --endpoint-url http://localhost:3200 ls s3://test

Or open the MinIO dashboard at <http://localhost:3201> (user: test/password: testtest).

> [!NOTE]
>
> While we've provided a MinIO based Docker compose file to make it easy for
> people to get started, if you're running it in production we recommend using
> an external S3.

> [!NOTE]
>
> If something seems amiss, ensure that Docker has read access to the parent
> folder so that it can access credentials.yaml and other local files. On macOS,
> you can do this by going to System Settings > Security & Privacy > Files and
> Folders > Docker.

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
