---
title: Self Hosting
description: Getting started self hosting Ente Photos and/or Ente Auth
---

# Self Hosting

The entire source code for Ente is open source, including the servers. This is
the same code we use for our own cloud service.

> [!TIP]
>
> To get some context, you might find our
> [blog post](https://ente.io/blog/open-sourcing-our-server/) announcing the
> open sourcing of our server useful.


## System Requirements 

The server has minimal resource requirements, running as a lightweight Go binary 
with no server-side ML. It performs well on small cloud instances, old laptops,
and even [low-end embedded devices](https://github.com/ente-io/ente/discussions/594) 
reported by community members. Virtually any reasonable hardware should be sufficient.

## Getting started

Execute the below one-liner command in your terminal to setup Ente on your system. 

```sh
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ente-io/ente/main/server/quickstart.sh)"
```

The above `curl` command is a simple shell-script, which pulls the docker images, 
creates a directory `my-ente` in the current working directory and starts all the 
containers required to run Ente on your system.

![quickstart](/quickstart.png)

The docker containers will be up and listening on their desired ports. The Ente Photos 
web app will be accessible on `http://localhost:3000`. Open the URL in your browser 
and proceed with creating an account. By default, the API Endpoint will be `localhost:8080`
as Museum (our server endpoint) will listen on `:8080`.

![endpoint](/endpoint.png)

To complete your account registration you need to enter a 6-digit verification code. 
This can be found in the server logs, which should already be shown in your quickstart
terminal. Alternatively, you can open the server logs with the following command from 
inside the `my-ente` folder:

```sh 
sudo docker compose logs
```

## Reverse Proxy

This step isn't really the direct next step after creating an account. It is
one of the most essential steps to avoid certain CORS errors and will help you through 
the configuration coming ahead. 

Museum runs on port `:8080`, Ente Photos web app runs on `:3000` and so on the other apps
are lined up after each other from ports `3001-3004`.

We highly recommend using HTTPS for Museum (`8080`). Primarily, because for security reasons Museum
won't accept any incoming HTTP traffic. Hence, all the requests will fail.

Head over to your DNS Management Dashboard and setup the appropriate records for the endpoints.
Mostly, `A` or `AAAA` records targeting towards your server's IP address should be sufficient. The rest of the work
will be done by the web server sitting on your server machine.

![cloudflare](/cloudflare.png)

### With Caddy

Setting up a reverse proxy with Caddy is pretty easy and straightforward. Firstly, install Caddy
on your server machine. 

```sh
sudo apt install caddy
``` 

After the installation is complete, a `Caddyfile` is created on the path `/etc/caddy/`. This file is
used to configure reverse proxies and a whole lot of different things. 

```yaml 
# Caddyfile - myente.xyz is just an example.
api.myente.xyz {
    reverse_proxy http://localhost:8080
}
ente.myente.xyz {
    reverse_proxy http://localhost:3000
}
```

After a few hard-reloads, Ente Photos web app should be working on https://ente.myente.xyz. You can check out
the documentation for any other reverse proxy tool (like nginx) you want to use. 

## Configuring `museum.yaml`

`Museum.yaml` is a YAML configuration file used to configure various things for museum. 
By default, [`local.yaml`](https://github.com/ente-io/ente/tree/main/server/configurations/local.yaml) 
is also available, but  it is overridden if `museum.yaml` file is found. We highly 
recommend creating and building your own `museum.yaml` instead of editing `configurations/local.yaml`. 
The `my-ente` directory will include a `museum.yaml` file with some configurations around encryption 
keys and secrets, postgres DB, and MinIO.

> [!TIP]
> Always do `docker compose down` inside `my-ente` directory, if you've made any changes to `museum.yaml`
> and then restart the containers with `docker compose up -d ` to see the changes in action.

### S3 Buckets

By default, the `s3` section is configured to use local minIO buckets and for the same reason 
`are_local_buckets`  is set to `true`.  If you wish to bring any external S3 provider, 
you just have to edit the configuration with appropriate credentails and details given by the provider. 
And set `are_local_buckets` to false.  Check out [Configuring S3](/self-hosting/guides/configuring-s3.md) 
to understand more on how to configure S3 buckets and how the communication happens.

MinIO makes use of the port `3200` for API Endpoints and the Client Web App is run over `:3201` 
(both on localhost). You can login to MinIO Console Web UI by accessing `localhost:3201` in your web-browser
and setting up all the things related to regions there itself.

If you face any issues related to uploads then checkout 
[Troubleshooting Bucket CORS](/self-hosting/troubleshooting/bucket-cors) and 
[Frequently Answered Error related to S3](/self-hosting/guides/configuring-s3#fae-frequently-answered-errors)

### App Endpoints

Ente Photos Web app is divided into multiple sub-apps like albums, cast, auth, etc.
These endpoints are configurable in the museum.yaml under the `apps.*` section.

For example, 

```yaml
apps:
    public-albums: albums.myente.xyz
    cast: cast.myente.xyz
    accounts: accounts.myente.xyz
    family: family.myente.xyz
```

By default, all the values redirect to our publicly hosted production services. 
After you are done with filling the values, restart museum and the App will start utilizing
those endpoints for everything instead of the Ente's prod instances.

Once you configure all the necessary endpoints, `cd` into `my-ente` and  stop all the docker 
containers with `docker compose down` to completely stop all the containers and restart them 
with `docker compose up -d`. 

Similarly, you can read the default [`local.yaml`](https://github.com/ente-io/ente/tree/main/server/configurations/local.yaml) 
and build a functioning `museum.yaml` for many other functionalities like SMTP, Discord
Notifications, Hardcoded-OTT's, etc.

## Queries?

If you need any help or support, do not hesitate to drop your queries on our community
[discord channel](https://discord.gg/z2YVKkycX3) or create a 
[Github Discussion](https://github.com/ente-io/ente/discussions) where 100s of self-hosters help each other :p.