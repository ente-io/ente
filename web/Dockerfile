FROM node:20-alpine AS builder

ARG ENTE_API_ORIGIN=http://localhost:8080
ARG ENTE_ALBUMS_APP_ORIGIN=https://localhost:3002

ENV NEXT_PUBLIC_ENTE_ENDPOINT="$ENTE_API_ORIGIN"
ENV NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT="$ENTE_ALBUMS_APP_ORIGIN"

WORKDIR /build
COPY . .

RUN yarn install
RUN yarn build:photos
RUN yarn build:accounts
RUN yarn build:auth
RUN yarn build:cast

FROM nginx

WORKDIR /out

COPY --from=builder /build/apps/photos/out /out/photos
COPY --from=builder /build/apps/photos/out /out/albums
COPY --from=builder /build/apps/accounts/out /out/accounts
COPY --from=builder /build/apps/auth/out /out/auth
COPY --from=builder /build/apps/cast/out /out/cast

COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 3000; root /out/photos;
    location / { try_files \$uri \$uri/ \$uri.html /index.html; }
}
server {
    listen 3001; root /out/accounts;
    location / { try_files \$uri \$uri/ \$uri.html /index.html; }
}
server {
    listen 3002; root /out/albums;
    location / { try_files \$uri \$uri/ \$uri.html /index.html; }
}
server {
    listen 3003; root /out/auth;
    location / { try_files \$uri \$uri/ \$uri.html /index.html; }
}
server {
    listen 3004; root /out/cast;
    location / { try_files \$uri \$uri/ \$uri.html /index.html; }
}
EOF

EXPOSE 3000
EXPOSE 3001
EXPOSE 3002
EXPOSE 3003
EXPOSE 3004
