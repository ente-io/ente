---
title: CLI (Command Line Interface)
description: Ente's command-line tool for advanced users
---

# CLI (Command Line Interface)

The Ente CLI is a command-line tool for advanced users that provides programmatic access to Ente Photos. It's particularly useful for automation, server environments, and power users who prefer terminal-based tools.

This guide uses the new CLI introduced with `ente-cli-v0.4.0`. If you use the previous Go CLI, read the [migration guide](/cli/migration) before switching. The new CLI does not reuse its settings or credentials.

## What is the CLI?

The Ente CLI allows you to:

- Export your entire library or specific albums to local storage
- Set up automated exports with cron jobs
- Sync data to NAS or other storage systems
- Perform bulk operations programmatically

## Why use the CLI?

The CLI is particularly useful for:

- **Regular automated backups** to local/NAS storage
- **Server-to-server transfers** without a GUI
- **Power users** who prefer command-line tools
- **Scheduled tasks** using cron or similar schedulers
- **Scripting and automation** workflows

## Installation

Ente's CLI is distributed directly over [GitHub](https://github.com/ente/ente/releases?q=tag%3Aente-cli-v).

**Steps:**

1. Go to the [CLI releases page](https://github.com/ente/ente/releases?q=tag%3Aente-cli-v)
2. Download the appropriate version for your platform:
    - Linux (x64, ARM64)
    - macOS (Intel, Apple Silicon)
    - Windows (x64)
3. Follow the installation instructions in the [CLI guides](/cli/)

## Basic usage

### Authentication

Before using the CLI, you need to authenticate:

```sh
ente account login --account personal --app photos
```

This will prompt for your email and password, then store your session securely.

### Exporting photos

The CLI supports **incremental exports**, reusing unchanged files. Pass the destination on each run:

```sh
# Export all photos
ente photos export /path/to/backup --account personal

# Export specific albums (exact, case-sensitive names or album IDs)
ente photos export /path/to/backup --album "Album Name" --album "Another Album" --account personal
```

To take over an export made by the previous CLI or desktop app, stop its export job first, preserve a copy if you want a way back, then run the new export command with `--adopt`. See [reconnect or adopt an export](/cli/photos#reconnect-or-adopt-an-export).

**Key features:**

- Incremental exports (only new/changed files)
- Gracefully handles interruptions
- Safe to stop and restart without re-downloading
- Preserves album structure and metadata

For complete command documentation, see the [CLI guides](/cli/).

## Automated exports

### Setting up cron jobs

You can automate exports using cron (Linux/macOS) or Task Scheduler (Windows).

Log in once, then schedule the export command with its destination. For headless jobs, configure the CLI home and vault key using the [automation guide](/cli/automation).

```sh
# Daily export at 2 AM; use the same CLI home and vault key as the initial login
0 2 * * * /usr/local/bin/ente photos export /nas/ente-backup --account personal --no-input
```

**Steps to set up:**

1. Open crontab editor: `crontab -e`
2. Add the cron job line
3. Save and exit
4. Verify with: `crontab -l`

### NAS sync setup

The recommended approach for keeping NAS and Ente synced is to use the CLI to **pull data from Ente to your NAS**:

**Setup:**

1. Install the CLI on your NAS or a machine that can access it
2. Authenticate the CLI with your Ente account
3. Set up a cron job to run periodic exports
4. Use the CLI's incremental export feature to keep data synced

**Example for daily NAS sync:**

```sh
0 2 * * * /usr/local/bin/ente photos export /nas/ente-backup --account personal --no-input
```

> [!IMPORTANT]
>
> Two-way sync is not currently supported. The CLI only pulls data from Ente to local storage - changes to local files won't sync back to Ente.

## Export details

### Album structure preservation

Each album becomes a separate folder. Characters that are not portable across filesystems are replaced with `_`, and name collisions receive numeric suffixes.

### Metadata handling

Metadata is exported as JSON sidecars alongside album records. See the [CLI export layout](/cli/photos#export-layout) for fields and Live Photo handling.

**Format:**

```
Album/photo.jpg
Album/metadata/photo.jpg.json
```

Learn more in the [Export feature guide](/photos/features/backup-and-sync/export).

## CLI vs Desktop export

| Feature         | CLI                      | Desktop App          |
| --------------- | ------------------------ | -------------------- |
| Platform        | All platforms (terminal) | Desktop GUI          |
| Automation      | ✅ Cron jobs, scripts    | ✅ Continuous export |
| Server use      | ✅ Headless servers      | ❌ Requires GUI      |
| Album selection | Command line flags       | GUI settings         |
| Incremental     | ✅                       | ✅                   |
| Metadata        | ✅                       | ✅                   |

**When to use CLI:**

- Server environments without GUI
- Scheduled automated backups
- Custom scripting workflows
- Power users who prefer terminal

**When to use Desktop:**

- Visual interface preferred
- Continuous background export
- One-time setup without scripting

## Source code and development

The CLI is open source and part of the Ente project:

- **Source code**: [GitHub](https://github.com/ente/ente/tree/main/rust/cli)
- **Documentation**: [CLI guides](/cli/)
- **Report issues**: [GitHub Issues](https://github.com/ente/ente/issues)

You can review, contribute to, or extend the CLI for your specific needs.

## Related FAQs

- [What is the Ente CLI?](/photos/faq/advanced-features#what-is-cli)
- [How do I install the CLI?](/photos/faq/advanced-features#install-cli)
- [How do I export photos with CLI?](/photos/faq/advanced-features#cli-export-photos)
- [How do I sync NAS and Ente?](/photos/faq/advanced-features#nas-sync)
- [CLI not found after installation](/photos/faq/advanced-features#cli-not-found)
- [CLI authentication issues](/photos/faq/advanced-features#cli-auth-issues)
- [CLI export interruptions](/photos/faq/advanced-features#cli-export-interruptions)
- [NAS export issues with CLI](/photos/faq/advanced-features#cli-nas-export)

## Related topics

- [Export](/photos/features/backup-and-sync/export) - Desktop export feature
- [Watch folders](/photos/features/backup-and-sync/watch-folders) - Automatic uploads
