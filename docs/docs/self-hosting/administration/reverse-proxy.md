---
Title: Configuring Reverse Proxy
Description: Configuring reverse proxy for Museum and other services
---

# Reverse proxy

Configuring reverse proxy is a way to make the service accessible via the public
Internet without exposing multiple ports for various services.

It also allows configuration of HTTPS through SSL certificate management.

We highly recommend using HTTPS for Museum (Ente's server). For security reasons, Museum
will not accept incoming HTTP traffic.

## Pre-requisites

1. **Reverse Proxy:** We recommend using Caddy for simplicity of
configuration and automatic certificate generation and management,
although you can use other alternatives such as NGINX, Traefik, etc.
    
    Install Caddy using the following command on Debian/Ubuntu-based systems:
    ``` shell
    sudo apt install caddy
    ```

    Start the service, enable it to start upon system boot and reload when configuration
    has changed.

    ``` shell
    sudo systemctl start caddy

    sudo systemctl enable caddy

    sudo systemctl reload caddy
    ```

## Step 1: Configure A or AAAA records

Set up the appropriate records for the endpoints in your DNS
management dashboard (usually associated with your domain registrar).

`A` or `AAAA` records pointing to your server's IP address are sufficient.

DNS propagation can take a few minutes to take effect.

![cloudflare](/cloudflare.png)

## Step 2: Configure reverse proxy

After installing Caddy, a `Caddyfile` is created on the path
`/etc/caddy/`. Edit `/etc/caddy/Caddyfile` to configure reverse proxies.

Here is a ready-to-use configuration that can be used with your own domain.

> yourdomain.tld is an example. Replace it with your own domain

```groovy
# For Museum
api.ente.yourdomain.tld {
    reverse_proxy http://localhost:8080
}

# For Ente Photos web app
web.ente.yourdomain.tld {
    reverse_proxy http://localhost:3000
}

# For Ente Accounts web app
accounts.ente.yourdomain.tld {
    reverse_proxy http://localhost:3001
}

# For Ente Albums web app
albums.ente.yourdomain.tld {
    reverse_proxy http://localhost:3002
}

# For Ente Auth web app
auth.ente.yourdomain.tld {
    reverse_proxy http://localhost:3003
}

# For Ente Cast web app
cast.ente.yourdomain.tld {
    reverse_proxy http://localhost:3004
}
```

## Step 3: Reload reverse proxy

Reload Caddy for changes to take effect

``` shell
sudo systemctl caddy reload
```

## Step 4: Verify the setup

Ente Photos web app should be up on https://web.ente.yourdomain.tld.

Museum should be accessible at https://api.ente.yourdomain.tld.

> [!TIP]
> If you are using other reverse proxy servers such as NGINX,
> Traefik, etc., please check out their documentation.
