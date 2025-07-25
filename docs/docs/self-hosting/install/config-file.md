---
title: "Configuration File - Self-hosting"
description:
    "Information about all the configuration variables needed to run Ente with
    museum.yaml"
---

# Configuration File

Museum uses YAML-based configuration file that is used for handling database
connectivity, bucket configuration, internal configuration, etc.

If the `ENVIRONMENT` environment variable is set, a corresponding file from
`configurations/` is loaded, by default, `local.yaml` configuration is loaded.

If `credentials-file` is defined and found, it overrides the defaults.

Self-hosted clusters generally use `museum.yaml` file for reading configuration
specifications.

All configuration values can be overridden via environment variables using the
`ENTE_` prefix and replacing dots (`.`) or hyphens (`-`) with underscores (`_`).

The configuration variables declared in `museum.yaml` are read by Museum.
Additionally, environment variables prefixed by `ENTE_` are read by Museum and
used internally in same manner as configuration variables.

For example, `s3.b2-eu-cen` in `museum.yaml` and `ENTE_S3_B2_EU_CEN` declared as
environment variable are the same and `ENTE_S3_B2_EU_CEN` overrides
`s3.b2-eu-cen`.

## General Settings

| Variable           | Description                                               | Default            |
| ------------------ | --------------------------------------------------------- | ------------------ |
| `credentials-file` | Path to optional credentials override file                | `credentials.yaml` |
| `credentials-dir`  | Directory to look for credentials (TLS, service accounts) | `credentials/`     |
| `log-file`         | Log output path. Required in production.                  | `""`               |

## HTTP

| Variable       | Description                       | Default |
| -------------- | --------------------------------- | ------- |
| `http.use-tls` | Enables TLS and binds to port 443 | `false` |

## App Endpoints

| Variable             | Description                                             | Default                    |
| -------------------- | ------------------------------------------------------- | -------------------------- |
| `apps.public-albums` | Albums app base endpoint for public sharing             | `https://albums.ente.io`   |
| `apps.cast`          | Cast app base endpoint                                  | `https://cast.ente.io`     |
| `apps.accounts`      | Accounts app base endpoint (used for passkey-based 2FA) | `https://accounts.ente.io` |

## Database

| Variable      | Description                | Default     |
| ------------- | -------------------------- | ----------- |
| `db.host`     | DB hostname                | `localhost` |
| `db.port`     | DB port                    | `5432`      |
| `db.name`     | Database name              | `ente_db`   |
| `db.sslmode`  | SSL mode for DB connection | `disable`   |
| `db.user`     | Database username          |             |
| `db.password` | Database password          |             |
| `db.extra`    | Additional DSN parameters  |             |

## Object Storage

| Variable                               | Description                                  | Default |
| -------------------------------------- | -------------------------------------------- | ------- |
| `s3.b2-eu-cen`                         | Primary hot storage S3 config                |         |
| `s3.wasabi-eu-central-2-v3.compliance` | Whether to disable compliance lock on delete | `true`  |
| `s3.scw-eu-fr-v3`                      | Optional secondary S3 config                 |         |
| `s3.wasabi-eu-central-2-derived`       | Derived data storage                         |         |
| `s3.are_local_buckets`                 | Use local MinIO-compatible storage           | `false` |
| `s3.use_path_style_urls`               | Enable path-style URLs for MinIO             | `false` |

## Encryption Keys

| Variable         | Description                            | Default     |
| ---------------- | -------------------------------------- | ----------- |
| `key.encryption` | Key for encrypting user emails         | Pre-defined |
| `key.hash`       | Hash key for verifying email integrity | Pre-defined |

## JWT

| Variable     | Description             | Default    |
| ------------ | ----------------------- | ---------- |
| `jwt.secret` | Secret for signing JWTs | Predefined |

## Email

| Variable           | Description                  | Default |
| ------------------ | ---------------------------- | ------- |
| `smtp.host`        | SMTP server host             |         |
| `smtp.port`        | SMTP server port             |         |
| `smtp.username`    | SMTP auth username           |         |
| `smtp.password`    | SMTP auth password           |         |
| `smtp.email`       | Sender email address         |         |
| `smtp.sender-name` | Custom name for email sender |         |
| `transmail.key`    | Zeptomail API key            |         |

## WebAuthn Passkey Support

| Variable             | Description                  | Default                     |
| -------------------- | ---------------------------- | --------------------------- |
| `webauthn.rpid`      | Relying Party ID             | `localhost`                 |
| `webauthn.rporigins` | Allowed origins for WebAuthn | `["http://localhost:3001"]` |

## Internal

| Variable                        | Description                                   | Default |
| ------------------------------- | --------------------------------------------- | ------- |
| `internal.silent`               | Suppress external effects (e.g. email alerts) | `false` |
| `internal.health-check-url`     | External healthcheck URL                      |         |
| `internal.hardcoded-ott`        | Predefined OTPs for testing                   |         |
| `internal.admins`               | List of admin user IDs                        | `[]`    |
| `internal.admin`                | Single admin user ID                          |         |
| `internal.disable-registration` | Disable user registration                     | `false` |

## Replication

| Variable                   | Description                          | Default           |
| -------------------------- | ------------------------------------ | ----------------- |
| `replication.enabled`      | Enable cross-datacenter replication  | `false`           |
| `replication.worker-url`   | Cloudflare Worker for replication    |                   |
| `replication.worker-count` | Number of goroutines for replication | `6`               |
| `replication.tmp-storage`  | Temp directory for replication       | `tmp/replication` |

## Background Jobs

| Variable                                      | Description                             | Default |
| --------------------------------------------- | --------------------------------------- | ------- |
| `jobs.cron.skip`                              | Skip all cron jobs                      | `false` |
| `jobs.remove-unreported-objects.worker-count` | Workers for removing unreported objects | `1`     |
| `jobs.clear-orphan-objects.enabled`           | Enable orphan cleanup                   | `false` |
| `jobs.clear-orphan-objects.prefix`            | Prefix filter for orphaned objects      |         |
