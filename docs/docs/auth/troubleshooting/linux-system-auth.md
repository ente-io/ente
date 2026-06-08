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
com.ente.auth.unlock
```

### Manual Policy Setup

Flatpak apps cannot install host Polkit policies by themselves, and AppImage or
manual builds may also need manual setup. Download the policy from GitHub and
verify its SHA-256 checksum before installing it:

```sh
policy_url="https://raw.githubusercontent.com/ente-io/ente/main/mobile/apps/auth/assets/polkit/com.ente.auth.policy"
policy_sha256="efba0409db9a0a53196fa8a7c9f4d4e874234b48287eb5242cf399f466e4c695"
policy="$(mktemp)"

if curl -fsSL "$policy_url" -o "$policy" &&
  printf "%s  %s\n" "$policy_sha256" "$policy" | sha256sum -c -; then
  sudo install -D -o root -g root -m 0644 \
    "$policy" \
    /usr/share/polkit-1/actions/com.ente.auth.policy

  if command -v chcon >/dev/null 2>&1; then
    sudo chcon system_u:object_r:usr_t:s0 \
      /usr/share/polkit-1/actions/com.ente.auth.policy || true
  fi

  pkaction --action-id com.ente.auth.unlock --verbose
else
  echo "Policy download or checksum verification failed. Not installing."
fi

rm -f "$policy"
```

### Remove the Policy

If you manually installed the Polkit policy and no longer want Ente Auth to use
Linux system authentication, remove it:

```sh
sudo rm -f /usr/share/polkit-1/actions/com.ente.auth.policy
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
