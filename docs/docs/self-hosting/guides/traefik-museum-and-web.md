# Selfhosting Ente backend + web server behind traefik on one single server

This is a documentation of how I self-host Ente [Photos] on my server behind a traefik port. It does not need an external S3 storage. If you would like to host Ente Auth, you have to use the official Dockerfile (or modify mine slighly if you are familiar with it) and comment out the traefik part in the `compose.yaml` for `auth.YOURDOMAIN`

1. Clone the repo and initialize submodules:
  
  ```bash
  git clone https://github.com/ente-io/ente.git
  cd ente
  git submodule update --init --recursive
  ```
  
2. Place a Dockerfile insinde the `web` Folder to build the web app. Either use the [official one provided here](https://help.ente.io/self-hosting/guides/web-app) or my modified version attached below. I modified it TO ONLY RUN ENTE PHOTOS! (and updated the base image version from 20 to 23). Also insert your domain names 
3. Create a `compose.yaml` file in the main directory (yeit is supposed to be inside the server directory if you follow the official guide. But if I come back to update stuff later I will not remember where it was...). LOOK FOR STUFF IN CAPS FOR IMPORTANT NOTES. The code for the file is attached below and I explain there the modification I made to the original file. Your traefik config will probably be different from mine so you might need to change parts! 
4. Create a `museum.yaml` file based on the one provided bellow. To generate new secrets use this oneline provided from [this kind github](https://github.com/EdyTheCow/ente-selfhost) repo
  
  ```bash
  docker run --rm ghcr.io/edythecow/ente-server-tools go run tools/gen-random-keys/main.go
  ```
  
5. Be careful to change the following variables for production:
  
  | Variable name | Location | New value |
  | --- | --- | --- |
  | `POSTGRES_PASSWORD` | `compose.yaml` &  `server/scripts/compose/credentials.yaml` | secure random value |
  | `MINIO_ROOT_PASSWORD` | `compose.yaml` & `server/scripts/compose/minio-provision.sh` & `server/scripts/compose/credentials.yaml` | secure random value |
  | (OPTIONAL) `MINIO_ROOT_USER` | `compose.yaml` & `server/scripts/compose/minio-provision.sh` & `server/scripts/compose/credentials.yaml` | secure random value |
  | YOURDOMAIN | `compose.yaml` & `museum.yaml` & `web/Dockerfile` | your actual domain |
  
  ### Now you should be able to reach your ente server under photos.YOURDOMAIN (you can also try api.YOURDOMAIN/ping )
  
  ## Create account
  
  You can create an account and obtain the OTP from the docker logs if you did not configure an email server
  
  ## Adjust storage
  
  I created an account via the web interface but maybe the account can also be created via CLI.
  I downloaded and extracted the CLI from the releasas page of the ente github repo. In the same directory as the executable ([alternative/details](https://help.ente.io/self-hosting/guides/selfhost-cli)) create a `config.yaml`:
  
  ```yaml
  endpoint:
   api: "https://api.example"
  ```
  
  Now run
```bash
./ente account add
./ente account list
```
This will need to be added to the admins in the `museum.yaml`. Restart your server.
```
./ente admin update-subscription -a ADMINEMAIL --no-limit True -u USEREMAIL
```
  # `compose.yaml`
  
1. I do not like docker volumes and modified the file to only use local directories
2. Change all containers to be in the same network as traefik:
  
  ```yaml
  networks:
  default:
   external:
     name: web
  ```
  
3. Change the museum part to be also included in that network and add labels. With this change you do not need to publicly expose port 8080
  
  ```yaml
  #ports:
   #  - 8080:8080 # API
   #  - 2112:2112 # Prometheus metrics - I THINK can be commented out if you do not use promotheus
   [...]
   networks:
     - internal
     - default
   labels:
     - traefik.http.routers.enteapi.rule=Host(`api.example.com`)
     - traefik.http.routers.enteapi.tls.certresolver=YOURDEFAULTCERTRESOLVER
     - traefik.http.services.enteapi.loadbalancer.server.port=8080
  ```
  
4. I commented out Port `5432` of the PostgreSQL container since the museum container accesses it locally and after 5 minutes I got approx 10 requests/second from someone trying to bruteforce their way into the database
5. adjust relative pathsChange the minio part to be also included in that network and add labels. With this change you do not need to publicly expose port 3200
  
  ## Finished part
  
  ```yaml
  services:
    museum:
      build:
        context: server
        args:
          GIT_COMMIT: development-cluster
      #image: ghcr.io/ente-io/server
      #ports:
      #  - 8080:8080 # API
      #  - 2112:2112 # Prometheus metrics
      depends_on:
        postgres:
          condition: service_healthy
      environment:
        # Pass-in the config to connect to the DB and MinIO
        ENTE_CREDENTIALS_FILE: /credentials.yaml
      volumes:
        - ./custom-logs:/var/logs
        - ./museum.yaml:/museum.yaml:ro
        - ./server/scripts/compose/credentials.yaml:/credentials.yaml:ro
        - ./data:/data:ro
      networks:
        - default
      labels:
        - traefik.http.routers.enteapi.rule=Host(`api.YOURDOMAIN`)
        - traefik.http.routers.enteapi.tls.certresolver=YOURCERTRESOLVER
        - traefik.http.services.enteapi.loadbalancer.server.port=8080
  
    # Resolve "localhost:3200" in the museum container to the minio container.
    socat:
      image: alpine/socat
      network_mode: service:museum
      depends_on:
        - museum
      command: "TCP-LISTEN:3200,fork,reuseaddr TCP:minio:3200"
  
    postgres:
      #CHANGE BASE IMAGE TO VERSION 17
      image: postgres:17
      # COMMENTED OUT BECAUSE I THINK DATABASE DOES NOT NEED TO PUBLICLY EXPOSED
      #ports:
      #  - 5432:5432
      environment:
        POSTGRES_USER: pguser
        POSTGRES_PASSWORD: CHANGEME
        POSTGRES_DB: ente_db
      # Wait for postgres to accept connections before starting museum.
      healthcheck:
        test:
          [
            "CMD",
            "pg_isready",
            "-q",
            "-d",
            "ente_db",
            "-U",
            "pguser"
          ]
        start_period: 40s
      volumes:
        - ./postgres-data:/var/lib/postgresql/data
      networks:
        - default
  
    minio:
      image: minio/minio
      # Use different ports than the minio defaults to avoid conflicting
      # with the ports used by Prometheus.
      ports:
      #  - 3200:3200 # API --> AVAILABLE VIA minio.YOURDOMAIN
        - 3201:3201 # Console
      environment:
        MINIO_ROOT_USER: CHANGEME
        MINIO_ROOT_PASSWORD: CHANGEME
      command: server /data --address ":3200" --console-address ":3201"
      volumes:
        - ./minio-data:/data
      networks:
        - default
      labels:
        - traefik.http.routers.minio.rule=Host(`minio.YOURDOMAIN`)
        - traefik.http.routers.minio.tls.certresolver=YOURCERTRESOLVER
        - traefik.http.services.minio.loadbalancer.server.port=3200
  
    minio-provision:
      image: minio/mc
      depends_on:
        - minio
      volumes:
        - ./server/scripts/compose/minio-provision.sh:/provision.sh:ro
        - ./minio-data:/data # WHEN MOUNTING THIS AS A DIRECTORY YOU WILL NEED TO CHOWN THE DIRECTROY AFTER CREATION. chown -R 1001 minio-data
      networks:
        - default
      entrypoint: sh /provision.sh
  
  
  
  
  
    ente-web:
      build:
        context: web
      #image: <image-name> # name of the image you used while building
      #ports:
      #  - 3000:3000
      #  - 3001:3001
      #  - 3002:3002
      #  - 3003:3003
      #  - 3004:3004
      environment:
        - NODE_ENV=development
        - ENDPOINT=https://api.welsch.pro
        - ALBUMS_ENDPOINT=https://albums.welsch.pro
      restart: always
      labels:
        - traefik.http.routers.photos.rule=Host(`photos.YOURDOMAIN`)
        - traefik.http.routers.photos.tls.certresolver=YOURCERTRESOLVER
        - traefik.http.routers.photos.service=svc_photos
        - traefik.http.services.svc_photos.loadbalancer.server.port=3000
        - traefik.http.routers.albums.rule=Host(`albums.YOURDOMAIN`)
        - traefik.http.routers.albums.tls.certresolver=YOURCERTRESOLVER
        - traefik.http.routers.albums.service=svc_albums
        - traefik.http.services.svc_albums.loadbalancer.server.port=3004
        #IF YOU WANT TO USE ENTE AUTH
        #- traefik.http.routers.auth.rule=Host(`auth.YOURDOMAIN`)
        #- traefik.http.routers.auth.tls.certresolver=YOURCERTRESOLVER
        #- traefik.http.routers.auth.service=svc_auth
        #- traefik.http.services.svc_auth.loadbalancer.server.port=3002
      networks:
        - default
  
  
  
  networks:
    default:
      external:
        name: web
  
  ```
  
  # `museum.yaml`
  
  ```yaml
  # HTTP connection parameters
  http:
      # If true, bind to 443 and use TLS.
      # By default, this is false, and museum will bind to 8080 without TLS.
      # use-tls: true
  
  # Specify the base endpoints for various apps
  apps:
      # Default is https://albums.ente.io
      #
      # If you're running a self hosted instance and wish to serve public links,
      # set this to the URL where your albums web app is running.
      public-albums: https://albums.YOURDOMAIN #CHANGE
  
  
  # Passkey support (optional)
  # Use case: MFA
  #webauthn:
  #    # Our "Relying Party" ID. This scopes the generated credentials.
  #    # See: https://www.w3.org/TR/webauthn-3/#rp-id
  #    rpid: accounts.example.com
  #    # Whitelist of origins from where we will accept WebAuthn requests.
  #    # See: https://github.com/go-webauthn/webauthn
  #    rporigins:
  #        - "https://accounts.example.com"
  
  s3:
      are_local_buckets: true
      b2-eu-cen:
          key: MINIO_ROOT_USER #CHANGE
          secret: MINIO_ROOT_PASSWORD #CHANGE
          endpoint: https://minio.YOURDOMAIN #CHANGE
          region: eu-central-2
          bucket: b2-eu-cen
  key:
      encryption: YOURGENERATEDENCRYPTIONSECRETS #CHANGE
      hash: YOURGENERATEDENCRYPTIONSECRETS #CHANGE
  jwt:
      secret: YOURGENERATEDENCRYPTIONSECRETS #CHANGE
  
  
  
  # Add this once you have done the CLI part
  #internal:
  #    admins:
  #        - 1580559962386438
  
  
  # SMTP configuration (optional)
  #
  # Configure credentials here for sending mails from museum (e.g. OTP emails).
  #
  # The smtp credentials will be used if the host is specified. Otherwise it will
  # try to use the transmail credentials. Ideally, one of smtp or transmail should
  # be configured for a production instance.
  #
  # username and password are optional (e.g. if you're using a local relay server
  # and don't need authentication).
  #smtp:
  #    host: 
  #    port: 
  #    username: 
  #    password: 
  #    # The email address from which to send the email. Set this to an email
  #    # address whose credentials you're providing.
  #    email: 
  
  ```
  
  # `Dockerfile` for building ONLY PHOTOS web app
  
  ```dockerfile
  FROM node:23-bookworm-slim as builder
  WORKDIR ./ente
  COPY . .
  COPY apps/ .
  # Will help default to yarn versoin 1.22.22
  RUN corepack enable
  # Endpoint for Ente Server
  ENV NEXT_PUBLIC_ENTE_ENDPOINT=https://api.YOURDOMAIN
  ENV NEXT_PUBLIC_ENTE_ALBUMS_ENDPOINT=https://albums.YOURDOMAIN
  RUN yarn cache clean
  RUN yarn install --network-timeout 1000000000
  RUN yarn build:photos #&& yarn build:accounts && yarn build:auth && yarn build:cast
  FROM node:23-bookworm-slim
  WORKDIR /app
  COPY --from=builder /ente/apps/photos/out /app/photos
  #COPY --from=builder /ente/apps/accounts/out /app/accounts
  #COPY --from=builder /ente/apps/auth/out /app/auth
  #COPY --from=builder /ente/apps/cast/out /app/cast
  RUN npm install -g serve
  ENV PHOTOS=3000
  EXPOSE ${PHOTOS}
  #ENV ACCOUNTS=3001
  #EXPOSE ${ACCOUNTS}
  #ENV AUTH=3002
  #EXPOSE ${AUTH}
  #ENV CAST=3003
  #EXPOSE ${CAST}
  # The albums app does not have navigable pages on it, but the
  # port will be exposed in-order to self up the albums endpoint
  # `apps.public-albums` in museum.yaml configuration file.
  ENV ALBUMS=3004
  EXPOSE ${ALBUMS}
  CMD ["sh", "-c", "serve /app/photos -l tcp://0.0.0.0:${PHOTOS}"]
  # & serve /app/accounts -l tcp://0.0.0.0:${ACCOUNTS} & serve /app/auth -l tcp://0.0.0.0:${AUTH} & serve /app/cast -l tcp://0.0.0.0:${CAST}"]
  ```
