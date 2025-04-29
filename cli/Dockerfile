# syntax=docker/dockerfile:1
FROM golang:1.23-alpine3.21 AS builder
RUN apk add --no-cache gcc musl-dev git build-base pkgconfig libsodium-dev

ENV GOOS=linux

WORKDIR /etc/ente/

COPY --link go.mod .
COPY --link go.sum .
RUN go mod download

COPY --link . .
# the --mount option requires BuildKit. Refer to https://docs.docker.com/go/buildkit/ to learn how to build images with BuildKit enabled
RUN --mount=type=cache,target=/root/.cache/go-build \
  go build -o ente-cli main.go

FROM alpine:3.21
RUN apk add libsodium-dev
COPY --link --from=builder /etc/ente/ente-cli .

ARG GIT_COMMIT
ENV GIT_COMMIT=$GIT_COMMIT

CMD ["./ente-cli"]
