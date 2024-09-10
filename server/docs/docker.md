# Running using published Docker images

Here we describe a way to run an Ente instance using a starter Docker compose
file and using the pre-built Docker images that we publish. This method does not
require you to clone the repository or build any images.

1. Create a directory where you'll run Ente

    ```sh
    mkdir ente && cd ente
    ```

2. Copy the starter compose.yaml and two of its support files from the
   repository onto your directory. You can do it by hand, or use (e.g.) curl

    ```sh
    # compose.yaml
    curl -LO https://raw.githubusercontent.com/ente-io/ente/main/server/compose.yaml

    mkdir -p scripts/compose
    cd scripts/compose

    # scripts/compose/credentials.yaml
    curl -LO https://raw.githubusercontent.com/ente-io/ente/main/server/scripts/compose/credentials.yaml

    # scripts/compose/minio-provision.sh
    curl -LO https://raw.githubusercontent.com/ente-io/ente/main/server/scripts/compose/minio-provision.sh

    cd ../..
    ```

3. Modify `compose.yaml`. Instead of building from source, we want directly use
   the published Docker image from `ghcr.io/ente-io/server`

    ```diff
    --- a/server/compose.yaml
    +++ b/server/compose.yaml
    @@ -1,9 +1,6 @@
     services:
       museum:
    -    build:
    -      context: .
    -      args:
    -        GIT_COMMIT: development-cluster
    +    image: ghcr.io/ente-io/server
    ```

4. Create an (empty) configuration file. You can later put your custom
   configuration in this if needed.

    ```sh
    touch museum.yaml
    ```

5. That is all. You can now start everything.

    ```sh
    docker compose up
    ```

This will start a cluster containing:

-   Ente's own server
-   PostgresQL (DB)
-   MinIO (the S3 layer)

For each of these, it'll use the latest published Docker image.

You can do a quick smoke test by pinging the API:

```sh
curl localhost:8080/ping
```

## Only the server

Alternatively, if you have setup the database and object storage externally and
only want to run Ente's server, you can skip the steps above and directly pull
and run the image from **`ghcr.io/ente-io/server`**.

```sh
docker pull ghcr.io/ente-io/server
```

> [!TIP]
>
> For more documentation around self-hosting, see
> **[help.ente.io/self-hosting](https://help.ente.io/self-hosting)**.
