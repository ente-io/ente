---
title: Manual setup (without Docker) - Self-hosting
description: Installing and setting up Ente without Docker
---

# Manual setup (without Docker)

If you wish to run Ente from source without using Docker, follow the steps
described below:

## Requirements

1. **Go:** Install Go on your system. This is needed for building Museum (Ente's
   server)

    ```shell
    sudo apt update && sudo apt upgrade
    sudo apt install golang-go
    ```

    Alternatively, you can also download the latest binaries from the
    [official website](https://go.dev/dl/).

2. **PostgreSQL and `libsodium`:** Install PostgreSQL (database) and `libsodium`
   (high level API for encryption) via package manager.

    ```shell
    sudo apt install postgresql
    sudo apt install libsodium23 libsodium-dev
    ```

    Start the database using `systemd` automatically when the system starts.

    ```shell
    sudo systemctl enable postgresql
    sudo systemctl start postgresql
    ```

    Ensure the database is running using

    ```shell
    sudo systemctl status postgresql
    ```

3. **`pkg-config`:** Install `pkg-config` for dependency handling.

    ```shell
    sudo apt install pkg-config
    ```

4. **yarn, npm and Node.js:** Needed for building the web application.

    Install npm and Node using your package manager.

    ```shell
    sudo apt install npm nodejs
    ```

    Install yarn by following the
    [official documentation](https://yarnpkg.com/getting-started/install)

5. **Git:** Needed for cloning the repository and pulling in latest changes

6. **Caddy:** Used for setting reverse proxy and file servers

7. **Object Storage:** Ensure you have an object storage configured for usage,
   needed for storing files. You can choose to run MinIO or Garage locally
   without Docker, however, an external bucket will be reliable and suited for
   long-term storage.

## Step 1: Clone the repository

Start by cloning Ente's repository from GitHub to your local machine.

```shell
git clone https://github.com/ente-io/ente
```

## Step 2: Configure Museum (Ente's server)

1.  Install all the needed dependencies for the server.

    ```shell
    # Change into server directory, where the source code for Museum is
    # present inside the repo
    cd ente/server

    # Install the needed dependencies
    go mod tidy
    ```

2.  Build the server. The server binary should be available as `./main` relative
    to `server` directory

    ```shell
    go build cmd/museum/main.go
    ```

3.  Create `museum.yaml` file inside `server` for configuring the needed
    variables. You can copy the templated configuration file for editing with
    ease.

    ```shell
    cp config/example.yaml ./museum.yaml
    ```

    ::: tip

    Make sure to enter the correct values for the database and object storage.

    You should consider generating values for JWT and encryption keys for emails
    if you intend to use for long-term needs.

    You can do by running the following command inside `ente/server`, assuming
    you cloned the repository to `ente`:

    ```shell
    # Change into the ente/server
    cd ente/server
    # Generate secrets
    go run tools/gen-random-keys/main.go
    ```

    :::

4.  Run the server

    ```shell
    ./main
    ```

    Museum should be accessible at `http://localhost:8080`

## Step 3: Configure Web Application

1. Install the dependencies for web application. Enable corepack if prompted.

    ```shell
    # Change into web directory, this is where all the applications
    # will be managed and built
    cd web

    # Install dependencies
    yarn install
    ```

2. Configure the environment variables in your corresponding shell's
   configuration file (`.bashrc`, `.zshrc`)
    ```shell
    # Replace this with actual endpoint for Museum
    export NEXT_PUBLIC_ENTE_ENDPOINT=http://localhost:8080
    # Replace this with actual endpoint for Albums
    export NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT=http://localhost:3002
    ```
3. Build the needed applications (Photos, Accounts, Auth, Cast, Public Locker, Embed) as per
   your needs:

    ```shell
    # These commands are executed inside web directory
    # Build photos. Build output to be served is present at apps/photos/out
    yarn build

    # Build accounts. Build output to be served is present at apps/accounts/out
    yarn build:accounts

    # Build auth. Build output to be served is present at apps/auth/out
    yarn build:auth

    # Build cast. Build output to be served is present at apps/cast/out
    yarn build:cast

    # Build public locker. Build output to be served is present at apps/share/out
    yarn build:share

    # Build embed. Build output to be served is present at apps/embed/out
    yarn build:embed
    ```

4. Copy the output files to `/var/www/ente/apps` for easier management.

    ```shell
    mkdir -p /var/www/ente/apps

    # Photos
    sudo cp -r apps/photos/out /var/www/ente/apps/photos
    # Accounts
    sudo cp -r apps/accounts/out /var/www/ente/apps/accounts
    # Auth
    sudo cp -r apps/auth/out /var/www/ente/apps/auth
    # Cast
    sudo cp -r apps/cast/out /var/www/ente/apps/cast
    # Public Locker
    sudo cp -r apps/share/out /var/www/ente/apps/share
    # Embed
    sudo cp -r apps/embed/out /var/www/ente/apps/embed
    ```

5. Set up file server using Caddy by editing `Caddyfile`, present at
   `/etc/caddy/Caddyfile`.

    ```groovy
    # Replace the ports with domain names if you have subdomains configured and need HTTPS
    :3000 {
        root * /var/www/ente/apps/out/photos
        file_server
        try_files {path} {path}.html /index.html
    }

    :3001 {
        root * /var/www/ente/apps/out/accounts
        file_server
        try_files {path} {path}.html /index.html
    }

    :3002 {
        root * /var/www/ente/apps/out/photos
        file_server
        try_files {path} {path}.html /index.html
    }

    :3003 {
        root * /var/www/ente/apps/out/auth
        file_server
        try_files {path} {path}.html /index.html
    }

    :3004 {
        root * /var/www/ente/apps/out/cast
        file_server
        try_files {path} {path}.html /index.html
    }

    :3005 {
        root * /var/www/ente/apps/out/share
        file_server
        try_files {path} {path}.html /index.html
    }

    :3006 {
        root * /var/www/ente/apps/out/embed
        file_server
        try_files {path} {path}.html /index.html
    }
    ```

    ::: tip Important for Share App

    The share web app (Public Locker) specifically requires all routes to be served through `/index.html` as it uses client-side routing with a single entry point. The `try_files` directive with `/index.html` as the fallback is essential for proper functionality. Without this configuration, direct links to shared albums and routes will result in 404 errors.

    :::

    The web application for Ente Photos should be accessible at
    http://localhost:3000, check out the
    [default ports](/self-hosting/installation/env-var#ports) for more
    information.

::: tip

Check out [post-installations steps](/self-hosting/installation/post-install/)
for further usage.

:::
