FROM ubuntu:latest

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    jq \
    postgresql-common \
    tini \
    unzip \
    zstd

# Install Postgres client 15 (needed for restores, and for local testing)
# https://www.postgresql.org/download/linux/ubuntu/
RUN /usr/share/postgresql-common/pgdg/apt.postgresql.org.sh -y
RUN apt-get update && apt-get install -y postgresql-client-15

# Install SCW CLI
# Latest release: https://github.com/scaleway/scaleway-cli/releases/latest
RUN \
    export VERSION="2.55.0" && \
    curl -o /usr/local/bin/scw -L "https://github.com/scaleway/scaleway-cli/releases/download/v${VERSION}/scaleway-cli_${VERSION}_linux_amd64" && \
    chmod +x /usr/local/bin/scw

# Install rclone
RUN curl https://rclone.org/install.sh | bash

COPY src /

ENTRYPOINT ["tini", "--"]

CMD [ "/backup.sh" ]
