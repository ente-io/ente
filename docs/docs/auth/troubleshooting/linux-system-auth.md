---
title: Linux system authentication
description: Set up Linux system authentication for Ente Auth desktop
---

# Linux System Authentication

> [!NOTE]
>
> Linux system authentication was added after the public `auth-v4.4.22` release
> from May 6, 2026. Use a newer Ente Auth desktop release before following this
> guide.

Ente Auth uses Polkit to ask your Linux desktop to authenticate the current
user. Polkit then uses your host PAM configuration, so the prompt may accept
your account password, fingerprint, or another method configured by your
distribution.

## Register the Polkit Policy

Deb, RPM, and pacman packages install the policy automatically. If Ente Auth
shows **Linux setup required**, install the policy manually.

The policy action is:

```text
io.ente.auth.unlock
```

### Flatpak

Flatpak apps cannot install host Polkit policies by themselves. Install the
policy from the installed Flatpak bundle:

```sh
app_id="io.ente.auth"
install_dir="$(flatpak info --show-location "$app_id")"
policy="$install_dir/files/share/enteauth/data/flutter_assets/assets/polkit/io.ente.auth.policy"

sudo install -D -o root -g root -m 0644 \
  "$policy" \
  /usr/share/polkit-1/actions/io.ente.auth.policy

if command -v chcon >/dev/null 2>&1; then
  sudo chcon system_u:object_r:usr_t:s0 \
    /usr/share/polkit-1/actions/io.ente.auth.policy || true
fi

pkaction --action-id io.ente.auth.unlock --verbose
```

### AppImage or Manual Builds

If Ente Auth shows **Linux setup required**, click **Copy setup command** in the
dialog and run the copied command in a terminal.

For AppImage builds, you can also extract the AppImage and install the bundled
policy:

```sh
./ente-auth.AppImage --appimage-extract

sudo install -D -o root -g root -m 0644 \
  squashfs-root/data/flutter_assets/assets/polkit/io.ente.auth.policy \
  /usr/share/polkit-1/actions/io.ente.auth.policy

if command -v chcon >/dev/null 2>&1; then
  sudo chcon system_u:object_r:usr_t:s0 \
    /usr/share/polkit-1/actions/io.ente.auth.policy || true
fi

pkaction --action-id io.ente.auth.unlock --verbose
```

## Fingerprint Prompts

The Polkit policy only registers Ente Auth as an application that can request
system authentication. Password versus fingerprint is controlled by your Linux
PAM and fprintd setup.

On Ubuntu, if password authentication works but fingerprint is not offered:

```sh
fprintd-list "$USER"
sudo apt install fprintd libpam-fprintd
sudo pam-auth-update
grep -n "pam_fprintd" /etc/pam.d/common-auth
cat /etc/pam.d/polkit-1
```

Enable **Fingerprint authentication** in `pam-auth-update`. Polkit should route
through `common-auth`; otherwise `/etc/pam.d/polkit-1` may remain password-only.

## Expected Linux Behavior

- `canCheckBiometrics=false` is expected for this backend.
- Ente Auth does not enumerate fingerprints directly.
- System authentication is ready when Polkit is available and
  `io.ente.auth.unlock` is registered.
- Fingerprint availability depends on your host PAM/fprintd configuration.
