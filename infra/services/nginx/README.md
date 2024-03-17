# Nginx

This is a base nginx service that terminates TLS, and can be used as a reverse
proxy for arbitrary services by adding new entries in `/root/nginx/conf.d` and
`sudo systemctl restart nginx`.

## Installation

Create a directory to house service specific configuration

    sudo mkdir -p /root/nginx/conf.d

Add the SSL certificate provided by Cloudflare

    sudo tee /root/nginx/cert.pem
    sudo tee /root/nginx/key.pem

## Adding a service

When adding new services that sit behind nginx, add their nginx conf file to
`/root/nginx/conf.d` and and restart the nginx service.
