
### Service logs

```bash
tail -f -n 100  /root/var/logs/copycat-db.log
```

### Backup timeout
If you are seeing time-out from scw while waiting for backup, usually just stopping the [service](.copycat-db.service) and letting the [daily timer](./copycat-db.timer) restart it later works

```bash
 sudo systemctl stop copycat-db.service
```
