---
Title: Configuring Reverse Proxy
Description: configuring reverse proxy for Museum and other endpoints
---

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
#...and so on for other endpoints
```

After a few hard-reloads, Ente Photos web app should be up on https://ente.myente.xyz. You can check out
the documentation for any other reverse proxy tool (like nginx) you want to use. 