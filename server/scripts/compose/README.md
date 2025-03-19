A variant docker compose file that does not require cloning the repository, and
instead uses pre-built images.

**TODO: Not done yet, a future standalone compose file will live here.**

### Details

This folder contains a `compose.yaml` file that is a variant of the top level
`server/compose.yaml`. The difference between the two are:

- `server/compose.yaml` builds Ente images from source, assuming that the
  `ente-io/ente` repository has been checked out.

- `server/scripts/compose/compose.yaml` (the `compose.yaml` in this directory)
  uses the pre-build Ente images, and does not require the `ente-io/ente`
  repository to be cloned. That is, it can be run standalone by just curl-ing
  it, and a few required files, to any folder on your machine.

For more details about how to use it, see [docker.md](../../docs/docker.md).

This folder also contains a credentials file that is required by (both) these
docker compose files.
