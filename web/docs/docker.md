# Docker

Automated docker images that allow you to run any (or all) of the web apps are
created every Wednesday. You can use fetch them from `ghcr.io/ente-io/web`.

These images expose web apps on 5 ports:

- `3000` - Photos
- `3001` - Account
- `3002` - Albums
- `3003` - Auth
- `3004` - Cast

For example, for selectively exposing only the photos web app on your port 8000,
you could:

```sh
docker run -it --rm -p 8000:3000 ghcr.io/ente-io/web
```

These images accept two environment variables to allow you to customize them:

- `ENTE_API_ORIGIN` - The API origin (scheme://host:port) for your API server.
  Default: "http://localhost:8080".

- `ENTE_ALBUMS_ORIGIN` - If you're running the album app, then set this to the
  externally visible origin where the albums app is hosted. Default:
  "https://localhost:3002".

For example, if your API server is running at `https://api.example.org`, you can
configure your Docker image to connect to it:

```sh
docker run -it --rm -e ENTE_API_ORIGIN=https://api.example.org ghcr.io/ente-io/web
```
