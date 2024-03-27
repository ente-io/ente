# Publishing images

There are two different images we publish - internal and external.

## Internal

The internal images can be built and run by triggering the "Server (release)"
workflow. You can trigger it either from GitHub's UI on the Actions tab, or use
the following command:

    gh workflow run server-release.yml

This will take the latest main, package it into a Docker image, and publish it
to our Scaleway registry. From there, we can update our production instances to
use this new image (see [deploy/README](../scripts/deploy/README.md)).

## External

Periodically, we can republish a new image from an existing known-to-be-good
commit to the GitHub Container Registry (GHCR) so that it can be used by folks
without needing to clone our repository just for building an image. For more
details about the use case, see [docker.md](docker.md).

To publish such an external image, firstly find the commit of the currently
running production instance.

    curl -s https://api.ente.io/ping | jq -r '.id'

> We can publish from any arbitrary commit really, but by using the commit
> that's already seen production for a few days, we avoid externally publishing
> images with issues.

Then, trigger the "Publish (server)" workflow, providing it the commit. You can
trigger it either from GitHub's UI or using the `gh cli`. With the CLI, we can
combine both these steps too.

    gh workflow run server-publish.yml -F commit=`curl -s https://api.ente.io/ping | jq -r '.id'`

Once the workflow completes, the resultant image will be available at
`ghcr.io/ente-io/server`. The image will be tagged by the commit SHA. The latest
image will also be tagged, well, "latest".
