FROM golang:1.20-alpine3.17 as builder
RUN apk add --no-cache gcc musl-dev git build-base pkgconfig libsodium-dev

ENV GOOS=linux

WORKDIR /etc/ente/

COPY go.mod .
COPY go.sum .
RUN go mod download

COPY . .
RUN --mount=type=cache,target=/root/.cache/go-build \
  go build -o ente-cli main.go

FROM alpine:3.17
RUN apk add libsodium-dev
COPY --from=builder /etc/ente/ente-cli .

ARG GIT_COMMIT
ENV GIT_COMMIT=$GIT_COMMIT

CMD ["./ente-cli"]
