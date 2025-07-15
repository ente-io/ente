---
Title: Configuring Reverse Proxy
Description: configuring reverse proxy for Museum and other endpoints
---

# Reverse proxy

Ente's server (museum) runs on port `:8080`, web app on `:3000` and the other
apps from ports `3001-3004`.

We highly recommend using HTTPS for Museum (`8080`). For security reasons museum
will not accept incoming HTTP traffic.

Head over to your DNS management dashboard and setup the appropriate records for
the endpoints. Mostly, `A` or `AAAA` records targeting towards your server's IP
address should be sufficient. The rest of the work will be done by the web
server on your machine.

![cloudflare](/cloudflare.png)

### Caddy

Setting up a reverse proxy with Caddy is easy and straightforward.

Firstly, install Caddy on your server.

```sh
sudo apt install caddy
```

After the installation is complete, a `Caddyfile` is created on the path
`/etc/caddy/`. This file is used to configure reverse proxies among other
things.

```groovy
# Caddyfile - myente.xyz is just an example.

api.myente.xyz {
    reverse_proxy http://localhost:8080
}

ente.myente.xyz {
    reverse_proxy http://localhost:3000
}

#...and so on for other endpoints
```

After a hard-reload, the Ente Photos web app should be up on
https://ente.myente.xyz.

If you are using a different tool for reverse proxy (like nginx), please check
out their documentation.
