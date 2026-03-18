# Docs - https://github.com/ente-io/ente/blob/main/web/docs/docker.md

FROM node:22 AS builder

# Install Rust for building ente-wasm
RUN apt-get update && apt-get install -y curl build-essential && rm -rf /var/lib/apt/lists/* && \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --target wasm32-unknown-unknown
ENV PATH="/root/.cargo/bin:${PATH}"

WORKDIR /build
COPY web/ ./web
COPY rust/core ./rust/core

WORKDIR /build/web

ENV NEXT_PUBLIC_ENTE_ENDPOINT=ENTE_API_ORIGIN_PLACEHOLDER
ENV NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT=ENTE_ALBUMS_ORIGIN_PLACEHOLDER
ENV NEXT_PUBLIC_ENTE_PHOTOS_ENDPOINT=ENTE_PHOTOS_ORIGIN_PLACEHOLDER

# `yarn install` is flaky on the GitHub arm64 runners otherwise.
RUN yarn config set network-timeout 900000 -g

RUN yarn install
RUN yarn build:photos
RUN yarn build:accounts
RUN yarn build:auth
RUN yarn build:cast
RUN yarn build:share
RUN yarn build:embed

FROM nginxinc/nginx-unprivileged:1.29-alpine-otel

USER root

COPY --chmod=755 <<EOF /docker-entrypoint.d/90-replace-ente-env.sh
sed -i'' "s#ENTE_API_ORIGIN_PLACEHOLDER#\$ENTE_API_ORIGIN#g" /etc/nginx/conf.d/default.conf
find /usr/share/nginx/html -name '*.js' |
    xargs sed -i'' "s#ENTE_API_ORIGIN_PLACEHOLDER#\$ENTE_API_ORIGIN#g"
find /usr/share/nginx/html/photos -name '*.js' |
    xargs sed -i'' "s#ENTE_ALBUMS_ORIGIN_PLACEHOLDER#\$ENTE_ALBUMS_ORIGIN#g"
find /usr/share/nginx/html/photos -name '*.js' |
    xargs sed -i'' "s#ENTE_PHOTOS_ORIGIN_PLACEHOLDER#\$ENTE_PHOTOS_ORIGIN#g"
EOF

USER nginx

COPY --from=builder --chown=nginx:nginx /build/web/apps/photos/out /usr/share/nginx/html/photos
COPY --from=builder --chown=nginx:nginx /build/web/apps/accounts/out /usr/share/nginx/html/accounts
COPY --from=builder --chown=nginx:nginx /build/web/apps/auth/out /usr/share/nginx/html/auth
COPY --from=builder --chown=nginx:nginx /build/web/apps/cast/out /usr/share/nginx/html/cast
COPY --from=builder --chown=nginx:nginx /build/web/apps/share/out /usr/share/nginx/html/share
COPY --from=builder --chown=nginx:nginx /build/web/apps/embed/out /usr/share/nginx/html/embed

COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 3000; root /usr/share/nginx/html/photos;
    location / { try_files \$uri \$uri.html /index.html; }
    add_header 'Access-Control-Allow-Origin' 'ENTE_API_ORIGIN_PLACEHOLDER';
}
server {
    listen 3001; root /usr/share/nginx/html/accounts;
    location / { try_files \$uri \$uri.html /index.html; }
    add_header 'Access-Control-Allow-Origin' 'ENTE_API_ORIGIN_PLACEHOLDER';
}
server {
    listen 3002; root /usr/share/nginx/html/photos;
    location / { try_files \$uri \$uri.html /index.html; }
    add_header 'Access-Control-Allow-Origin' 'ENTE_API_ORIGIN_PLACEHOLDER';
}
server {
    listen 3003; root /usr/share/nginx/html/auth;
    location / { try_files \$uri \$uri.html /index.html; }
    add_header 'Access-Control-Allow-Origin' 'ENTE_API_ORIGIN_PLACEHOLDER';
}
server {
    listen 3004; root /usr/share/nginx/html/cast;
    location / { try_files \$uri \$uri.html /index.html; }
    add_header 'Access-Control-Allow-Origin' 'ENTE_API_ORIGIN_PLACEHOLDER';
}
server {
    listen 3005; root /usr/share/nginx/html/share;
    location / { try_files \$uri \$uri.html /index.html; }
    add_header 'Access-Control-Allow-Origin' 'ENTE_API_ORIGIN_PLACEHOLDER';
}
server {
    listen 3006; root /usr/share/nginx/html/embed;
    location / { try_files \$uri \$uri.html /index.html; }
    add_header 'Access-Control-Allow-Origin' 'ENTE_API_ORIGIN_PLACEHOLDER';
}
EOF

EXPOSE 3000
EXPOSE 3001
EXPOSE 3002
EXPOSE 3003
EXPOSE 3004
EXPOSE 3005
EXPOSE 3006

ENV ENTE_API_ORIGIN=http://localhost:8080
ENV ENTE_ALBUMS_ORIGIN=https://localhost:3002
ENV ENTE_PHOTOS_ORIGIN=https://localhost:3000
