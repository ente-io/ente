---
title: Configuration - Self-hosting
description:
    "Information about all the configuration variables needed to run Ente with
    museum.yaml"
---

# Configuration

Museum is designed to be configured either via environment variables or via
YAML. We recommend using YAML for maintaining your configuration as it can be
backed up easily, helping in restoration.

## Configuration File

Museum's configuration file (`museum.yaml`) is responsible for making database
configuration, bucket configuration, internal configuration, etc. accessible for
other internal services.

By default, Museum runs in local environment, thus `local.yaml` configuration is
loaded.

If `ENVIRONMENT` environment variable is set (say, to `production`), Museum will
attempt to load `configurations/production.yaml`.

If `credentials-file` is defined and found, it overrides the defaults.

Self-hosted clusters generally use `museum.yaml` file for declaring
configuration over directly editing `local.yaml`.

All configuration values can be overridden via environment variables using the
`ENTE_` prefix and replacing dots (`.`) or hyphens (`-`) with underscores (`_`).

Museum reads configuration from `museum.yaml`. Any environment variables
prefixed with `ENTE_` takes precedence.

For example,

```yaml
s3:
    b2-eu-cen:
        endpoint:
```

in `museum.yaml` is read as `s3.b2-eu-cen.endpoint` by Museum.

`ENTE_S3_B2_EU_CEN_ENDPOINT` declared as environment variable is same as the
above and `ENTE_S3_B2_EU_CEN_ENDPOINT` overrides `s3.b2-eu-cen.endpoint`.

### General Settings

| Variable           | Description                                               | Default            |
| ------------------ | --------------------------------------------------------- | ------------------ |
| `credentials-file` | Path to optional credentials override file                | `credentials.yaml` |
| `credentials-dir`  | Directory to look for credentials (TLS, service accounts) | `credentials/`     |
| `log-file`         | Log output path. Required in production.                  | `""`               |

### HTTP

| Variable       | Description                       | Default |
| -------------- | --------------------------------- | ------- |
| `http.use-tls` | Enables TLS and binds to port 443 | `false` |

### App Endpoints

The web apps for Ente (Auth, Cast, Albums) use different endpoints.

These endpoints are configurable in `museum.yaml` under the apps.\* section.

Upon configuration, the application will start utilizing the specified endpoints
instead of Ente's production instances or local endpoints (overridden values
used for Compose and quickstart for ease of use.)

| Variable             | Description                                             | Default                    |
| -------------------- | ------------------------------------------------------- | -------------------------- |
| `apps.public-albums` | Albums app base endpoint for public sharing             | `https://albums.ente.io`   |
| `apps.cast`          | Cast app base endpoint                                  | `https://cast.ente.io`     |
| `apps.accounts`      | Accounts app base endpoint (used for passkey-based 2FA) | `https://accounts.ente.io` |

### Database

| Variable      | Description                | Default     |
| ------------- | -------------------------- | ----------- |
| `db.host`     | DB hostname                | `localhost` |
| `db.port`     | DB port                    | `5432`      |
| `db.name`     | Database name              | `ente_db`   |
| `db.sslmode`  | SSL mode for DB connection | `disable`   |
| `db.user`     | Database username          |             |
| `db.password` | Database password          |             |
| `db.extra`    | Additional DSN parameters  |             |

### Object Storage

The `s3` section within `museum.yaml` is by default configured to use local
MinIO buckets when using `quickstart.sh` or Docker Compose.

If you wish to use an external S3 provider, you can edit the configuration with
your provider's credentials, and set `are_local_buckets` to `false`.

MinIO uses the port `3200` for API Endpoints. Web Console can be accessed at
http://localhost:3201 by enabling port `3201` in the Compose file.

If you face any issues related to uploads then checkout [Troubleshooting bucket
CORS] and [Frequently encountered S3 errors].

| Variable                               | Description                                  | Default |
| -------------------------------------- | -------------------------------------------- | ------- |
| `s3.b2-eu-cen`                         | Primary hot storage S3 config                |         |
| `s3.wasabi-eu-central-2-v3.compliance` | Whether to disable compliance lock on delete | `true`  |
| `s3.scw-eu-fr-v3`                      | Optional secondary S3 config                 |         |
| `s3.wasabi-eu-central-2-derived`       | Derived data storage                         |         |
| `s3.are_local_buckets`                 | Use local MinIO-compatible storage           | `false` |
| `s3.use_path_style_urls`               | Enable path-style URLs for MinIO             | `false` |

### Encryption Keys

These values are used for encryption of user e-mails. Default values are
provided by Museum.

They are generated by random in quickstart script, so no intervention is
necessary if using quickstart.

However, if you are using Ente for long-term needs and you have not installed
Ente via quickstart, consider generating values for these along with [JWT](#jwt)
by following the steps described below:

```shell
# If you have not cloned already
git clone https://github.com/ente-io/ente

# Generate the values
cd ente/server
go run tools/gen-random-keys/main.go
```

| Variable         | Description                    | Default     |
| ---------------- | ------------------------------ | ----------- |
| `key.encryption` | Key for encrypting user emails | Pre-defined |
| `key.hash`       | Hash key                       | Pre-defined |

### JWT

| Variable     | Description             | Default    |
| ------------ | ----------------------- | ---------- |
| `jwt.secret` | Secret for signing JWTs | Predefined |

### Email

| Variable           | Description                  | Default |
| ------------------ | ---------------------------- | ------- |
| `smtp.host`        | SMTP server host             |         |
| `smtp.port`        | SMTP server port             |         |
| `smtp.username`    | SMTP auth username           |         |
| `smtp.password`    | SMTP auth password           |         |
| `smtp.email`       | Sender email address         |         |
| `smtp.sender-name` | Custom name for email sender |         |
| `transmail.key`    | Zeptomail API key            |         |

### WebAuthn Passkey Support

| Variable             | Description                  | Default                     |
| -------------------- | ---------------------------- | --------------------------- |
| `webauthn.rpid`      | Relying Party ID             | `localhost`                 |
| `webauthn.rporigins` | Allowed origins for WebAuthn | `["http://localhost:3001"]` |

### Internal

| Variable                                     | Description                                   | Default |
| -------------------------------------------- | --------------------------------------------- | ------- |
| `internal.silent`                            | Suppress external effects (e.g. email alerts) | `false` |
| `internal.health-check-url`                  | External healthcheck URL                      |         |
| `internal.hardcoded-ott`                     | Predefined OTPs for testing                   |         |
| `internal.hardcoded-ott.emails`              | E-mail addresses with hardcoded OTTs          |  `[]`   |
| `internal.hardcoded-ott.local-domain-suffix` | Suffix for which hardcoded OTT is to be used  |         |
| `internal.hardcoded-ott.local-domain-value`  | Hardcoded OTT value for the above suffix      |         |
| `internal.admins`                            | List of admin user IDs                        | `[]`    |
| `internal.admin`                             | Single admin user ID                          |         |
| `internal.disable-registration`              | Disable user registration                     | `false` |

### Replication

By default, replication of objects (photos, thumbnails, videos) is disabled and
only one bucket is used.

To enable replication, set `replication.enabled` to `true`. For this to work, 3
buckets have to be configured in total.

| Variable                   | Description                          | Default           |
| -------------------------- | ------------------------------------ | ----------------- |
| `replication.enabled`      | Enable replication across buckets    | `false`           |
| `replication.worker-url`   | Cloudflare Worker for replication    |                   |
| `replication.worker-count` | Number of goroutines for replication | `6`               |
| `replication.tmp-storage`  | Temp directory for replication       | `tmp/replication` |

### Background Jobs

This configuration is for enabling background cron jobs for tasks such as
sending mails, removing unused objects (clean up) and worker configuration for
the same.

| Variable                                      | Description                             | Default |
| --------------------------------------------- | --------------------------------------- | ------- |
| `jobs.cron.skip`                              | Skip all cron jobs                      | `false` |
| `jobs.remove-unreported-objects.worker-count` | Workers for removing unreported objects | `1`     |
| `jobs.clear-orphan-objects.enabled`           | Enable orphan cleanup                   | `false` |
| `jobs.clear-orphan-objects.prefix`            | Prefix filter for orphaned objects      |         |
