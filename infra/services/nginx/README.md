# Nginx

This is a base Nginx service that terminates TLS, and can be used as a reverse
proxy for arbitrary services by adding new entries in `/root/nginx/conf.d` and
`sudo systemctl restart nginx`.

## Installation

Copy the service definition

```sh
scp services/nginx/nginx.service <instance>:

sudo mv nginx.service /etc/systemd/system/nginx.service
```

Create a directory to house service specific configuration

    sudo mkdir -p /root/nginx/conf.d

Add the SSL certificate provided by Cloudflare

    sudo tee /root/nginx/cert.pem
    sudo tee /root/nginx/key.pem

Tell systemd to pick up new service definition, enable it (so that it
automatically starts on boot going forward), and start it.

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now nginx
```

## Adding a service

When adding new services that sit behind Nginx,

1. Add its nginx conf file to `/root/nginx/conf.d`

2. Restart nginx (`sudo systemctl restart nginx`)
