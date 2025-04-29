FROM ubuntu:latest

RUN apt-get update && apt-get install -y curl gnupg
RUN apt-get install -y tini

# Install Postgres client (needed for restores, and for local testing)
# https://www.postgresql.org/download/linux/ubuntu/
#
# We don't have specific dependencies on Postgres, so just use the latest.
RUN apt-get update && apt-get -y install postgresql-client

# Install SCW CLI
# Latest release: https://github.com/scaleway/scaleway-cli/releases/latest
RUN \
    export VERSION="2.34.0" && \
    curl -o /usr/local/bin/scw -L "https://github.com/scaleway/scaleway-cli/releases/download/v${VERSION}/scaleway-cli_${VERSION}_linux_amd64" && \
    chmod +x /usr/local/bin/scw

RUN apt-get install -y jq

# Install rclone
RUN apt-get install -y unzip
RUN curl https://rclone.org/install.sh | bash

COPY src /

ENTRYPOINT ["tini", "--"]

CMD [ "/backup.sh" ]
