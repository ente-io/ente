# Services

"Services" are Docker images we run on our instances and manage using systemd.

All our services (including museum itself) follow the same pattern:

-   They're run on vanilla Ubuntu instances. The only expectation they have is
    for Docker to be installed.

-   They log to fixed, known, locations - `/root/var/log/foo.log` - so that
    these logs can get ingested by Promtail if needed.

-   Each service should consist of a Docker image (or a Docker compose file),
    and a systemd unit file.

-   To start / stop / schedule the service, we use systemd.

-   Each time the service runs it should pull the latest Docker image, so there
    is no separate installation/upgrade step needed. We can just restart the
    service, and it'll use the latest code.

-   Any credentials and/or configuration should be read by mounting the
    appropriate file from `/root/service-name` into the running Docker
    container.

## Systemd cheatsheet

```sh
sudo systemctl status my-service
sudo systemctl start my-service
sudo systemctl stop my-service
sudo systemctl restart my-service
sudo journalctl --unit my-service
```

## Adding a service

Create a systemd unit file (See the various `*.service` files in this repository
for examples).

If we want the service to start on boot, add an `[Install]` section to its
service file (_note_: starting on boot requires one more step later):

```
[Install]
WantedBy=multi-user.target
```

Copy the service file to the instance where we want to run the service. Services
might also have some additional configuration or env files, also copy those to
the instance.

```sh
scp services/example.service example.env <instance>:
```

SSH into the instance.

```sh
ssh <instance>
```

Move the service `/etc/systemd/service`, and any config files to their expected
place. env and other config files that contain credentials are kept in `/root`.

```sh
sudo mv example.service /etc/systemd/system
sudo mv example.env /root
```

If you want to start the service on boot (as spoken of in the `[Install]`
section above), then enable it (this only needs to be done once):

```sh
sudo systemctl enable service
```

Restarts systemd so that it gets to know of the service.

```sh
sudo systemctl daemon-reload
```

Now you can manage the service using standard systemd commands.

```sh
sudo systemctl start example
```

To view stdout/err, use:

```sh
sudo journalctl --follow --unit example
```

## Logging

Services should log to files in `/var/logs` within the container. This should be
mounted to `/root/var/logs` on the instance (using the `-v` flag in the service
file which launches the Docker container or the Docker compose cluster).

If these logs need to be sent to Grafana, then ensure that there is an entry for
this log file in the `promtail/promtail.yaml` on that instance. The logs will
then get scraped by Promtail and sent over to Grafana.
