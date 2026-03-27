# Docker

Automated Docker images for the self-hosting web apps are created every
Wednesday. You can fetch them from `ghcr.io/ente-io/web`.

These images expose the following apps:

- `3000` - Photos
- `3001` - Accounts
- `3002` - Albums
- `3003` - Auth
- `3004` - Cast
- `3005` - Share
- `3006` - Embed

For example, for selectively exposing only the photos web app on your port 8000,
you could:

```sh
docker run -it --rm -p 8000:3000 ghcr.io/ente-io/web
```

These images accept three environment variables to allow you to customize them:

- `ENTE_API_ORIGIN` - The API origin (scheme://host:port) for your API server.
  Default: "http://localhost:8080".

- `ENTE_ALBUMS_ORIGIN` - The externally visible origin where the albums app is
  hosted. This is used for public album links and handoffs between the photos
  and albums apps. Default: "http://localhost:3002".

- `ENTE_PHOTOS_ORIGIN` - The externally visible origin where the photos app is
  hosted. This is used for features like join album links. Default:
  "http://localhost:3000".

For example, if your API server is running at `https://api.example.org`, you can
configure your Docker image to connect to it:

```sh
docker run -it --rm -e ENTE_API_ORIGIN=https://api.example.org ghcr.io/ente-io/web
```

### Dockerfile

If you're manually building the Docker image using `web/Dockerfile` instead of using prebuilt `ghcr.io/ente-io/web` image, remember to run the build from the repo root since the context requires both the `web` and `rust` folders.

```sh
docker build -f web/Dockerfile .
```
