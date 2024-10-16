---
title: Hosting the web app
description:
    Building and hosting Ente's web app, connecting it to your self-hosted
    server
---

# Web app

The getting started instructions mention using `yarn dev` (which is an alias of
`yarn dev:photos`) to serve your web app.

```sh
cd ente/web
git submodule update --init --recursive
yarn install
NEXT_PUBLIC_ENTE_ENDPOINT=http://localhost:8080 yarn dev:photos
```

This is fine for trying this out and verifying that your self-hosted server is
working correctly etc. But if you would like to use the web app for a longer
term, then it is recommended that you use a production build.

To create a production build, you can run the same process, but instead do a
`yarn build` (which is an alias for `yarn build:photos`). For example,

```sh
NEXT_PUBLIC_ENTE_ENDPOINT=http://localhost:8080 yarn build:photos
```

This creates a production build, which is a static site consisting of a folder
of HTML/CSS/JS files that can then be deployed on any standard web server.

Nginx is a common choice for a web server, and you can then put the generated
static site (from the `web/apps/photos/out` folder) to where nginx would serve
them. Note that there is nothing specific to nginx here - you can use any web
server - the basic gist is that yarn build will produce a web/apps/photos/out
folder that you can then serve with any web server of your choice.

If you're new to web development, you might find the [web app's README], and
some of the documentation it its source code -
[docs/new.md](https://github.com/ente-io/ente/blob/main/web/docs/new.md),
[docs/dev.md](https://github.com/ente-io/ente/blob/main/web/docs/dev.md) -
useful. We've also documented the process we use for our own production
deploypments in
[docs/deploy.md](https://github.com/ente-io/ente/blob/main/web/docs/deploy.md),
though be aware that that is probably overkill for simple cases.

## Using Docker

We currently don't offer pre-built Docker images for the web app, however it is
quite easy to build and deploy the web app in a Docker container without
installing anything extra on your machine. For example, you can use the
dockerfile from this
[discussion](https://github.com/ente-io/ente/discussions/1183), or use the
Dockerfile mentioned in the
[notes](https://help.ente.io/self-hosting/guides/external-s3) created by a
community member.

## Running the Web App as a Systemd Service  
You can also run the web app as a systemd service and reverse proxy 
it with a webserver like Nginx or caddy. 

Below is a [battle tested](https://github.com/ente-io/ente/discussions/1183#discussioncomment-10948025) 
systemd service example: 

```ini 
[Unit]
Description=Run Ente Web as a service

[Service]
Type=simple
Restart=always
WorkingDirectory=/path/to/ente/web-app
Environment=NEXT_PUBLIC_ENTE_ENDPOINT=http://localhost:8000
ExecStart=/usr/bin/yarn dev

# If the above doesn't work, try this as an alternative:
# ExecStart=yarn dev  

# You can add this to verify if yarn is installed
# ExecStartPre=yarn --version

[Install]
WantedBy=multi-user.target
```

Note: Please do not forget to set the right path for `WorkingDirectory` in the above. 

To debug in case of any issues, you could use `journalctl` utility or enable logging 
in systemd by adding 2 more lines to the ente.service file. 

```ini 
# The log file paths can be customised
StandardOutput=/var/log/ente-out.log 
StandardError=/var/log/ente-err.log 
```

Follow the below steps to configure and enable the service. 

```sh 
sudo touch /etc/systemd/system/ente-web.service 
sudo systemctl enable ente-web.service 
sudo systemctl daemon-reload && sudo systemctl start ente-web.service  
```


## Public sharing

If you'd also like to enable public sharing on the web app you're running,
please follow the [step here](https://help.ente.io/self-hosting/faq/sharing).
