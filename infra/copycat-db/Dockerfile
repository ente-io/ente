FROM ubuntu:latest

RUN apt-get update && apt-get install -y curl gnupg
RUN apt-get install -y tini

# Install pg_dump (via Postgres client)
# https://www.postgresql.org/download/linux/ubuntu/
#
# We don't need it for production backups, but this is useful for local testing.
RUN \
    apt-get install -y lsb-release && \
    sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list' && \
    curl https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get -y install postgresql-client-12

# Install SCW CLI
# Latest release: https://github.com/scaleway/scaleway-cli/releases/latest
RUN \
    export VERSION="2.26.0" && \
    curl -o /usr/local/bin/scw -L "https://github.com/scaleway/scaleway-cli/releases/download/v${VERSION}/scaleway-cli_${VERSION}_linux_amd64" && \
    chmod +x /usr/local/bin/scw

RUN apt-get install -y jq

# Install rclone
RUN apt-get install -y unzip
RUN curl https://rclone.org/install.sh | bash

COPY src /

ENTRYPOINT ["tini", "--"]

CMD [ "/backup.sh" ]
