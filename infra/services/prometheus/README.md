# Prometheus

Install `prometheus.service` on an instance if it is running something that
exports custom Prometheus metrics. In particular, museum does.

Also install `node-exporter.service` (after installing
[node-exporter](https://prometheus.io/docs/guides/node-exporter/) itself) if it
is a production instance whose metrics (CPU, disk, RAM etc) we want to monitor.

## Installing

Prometheus doesn't currently support environment variables in config file, so
remember to change the hardcoded `XX-HOSTNAME` too in addition to adding the
`remote_write` configuration.

```sh
scp -P 7426 services/prometheus/* <instance>:

nano prometheus.yml
sudo mv prometheus.yml /root/prometheus.yml
sudo mv prometheus.service /etc/systemd/system/prometheus.service
sudo mv node-exporter.service /etc/systemd/system/node-exporter.service
```

Tell systemd to pick up new service definitions, enable the units (so that they
automatically start on boot going forward), and start them.

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now node-exporter
sudo systemctl enable --now prometheus
```
