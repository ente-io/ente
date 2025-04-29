# syntax=docker/dockerfile:1
FROM golang:1.23.4-alpine3.21 AS builder
RUN apk add --no-cache gcc musl-dev git build-base pkgconfig libsodium-dev

ENV GOOS=linux

WORKDIR /etc/ente/

COPY --link go.mod .
COPY --link go.sum .
RUN go mod download

COPY --link . .
RUN --mount=type=cache,target=/root/.cache/go-build \
  go build -o museum cmd/museum/main.go

FROM alpine:3.21
COPY --link --from=builder /usr/lib/libsodium.so* /usr/lib
COPY --link --from=builder /etc/ente/museum .
COPY --link configurations configurations
COPY --link migrations migrations
COPY --link mail-templates mail-templates

ARG GIT_COMMIT
ENV GIT_COMMIT=$GIT_COMMIT

CMD ["./museum"]
