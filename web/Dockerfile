# Docs - https://github.com/ente-io/ente/blob/main/web/docs/docker.md

FROM node:22-alpine AS builder

WORKDIR /build
COPY . .

ENV NEXT_PUBLIC_ENTE_ENDPOINT=ENTE_API_ORIGIN_PLACEHOLDER
ENV NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT=ENTE_ALBUMS_ORIGIN_PLACEHOLDER

# `yarn install` is flaky on the GitHub arm64 runners otherwise.
RUN yarn config set network-timeout 900000 -g

RUN yarn install
RUN yarn build:photos
RUN yarn build:accounts
RUN yarn build:auth
RUN yarn build:cast
RUN yarn build:share

FROM nginx

WORKDIR /out

COPY --from=builder /build/apps/photos/out /out/photos
COPY --from=builder /build/apps/accounts/out /out/accounts
COPY --from=builder /build/apps/auth/out /out/auth
COPY --from=builder /build/apps/cast/out /out/cast
COPY --from=builder /build/apps/share/out /out/share

COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 3000; root /out/photos;
    location / { try_files \$uri \$uri.html /index.html; }
}
server {
    listen 3001; root /out/accounts;
    location / { try_files \$uri \$uri.html /index.html; }
}
server {
    listen 3002; root /out/photos;
    location / { try_files \$uri \$uri.html /index.html; }
}
server {
    listen 3003; root /out/auth;
    location / { try_files \$uri \$uri.html /index.html; }
}
server {
    listen 3004; root /out/cast;
    location / { try_files \$uri \$uri.html /index.html; }
}
server {
    listen 3005; root /out/share;
    location = / { try_files /index.html =404; }
    location / { try_files \$uri \$uri.html /404.html; }
}
EOF

EXPOSE 3000
EXPOSE 3001
EXPOSE 3002
EXPOSE 3003
EXPOSE 3004
EXPOSE 3005

ENV ENTE_API_ORIGIN=http://localhost:8080
ENV ENTE_ALBUMS_ORIGIN=https://localhost:3002

COPY <<EOF /docker-entrypoint.d/90-replace-ente-env.sh
find /out -name '*.js' |
    xargs sed -i'' "s#ENTE_API_ORIGIN_PLACEHOLDER#\$ENTE_API_ORIGIN#g"
find /out/photos -name '*.js' |
    xargs sed -i'' "s#ENTE_ALBUMS_ORIGIN_PLACEHOLDER#\$ENTE_ALBUMS_ORIGIN#g"
EOF

RUN chmod +x /docker-entrypoint.d/90-replace-ente-env.sh
