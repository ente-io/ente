# syntax=docker/dockerfile:1

FROM node:21-bookworm-slim as ente-builder

WORKDIR /app

RUN apt update && apt install -y ca-certificates && rm -rf /var/lib/apt/lists/*

COPY . .
RUN yarn install

ARG GIT_SHA=local
ENV GIT_SHA=$GIT_SHA

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