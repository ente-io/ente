## Setting up a remote desktop

This is handy, e.g., when creating test environments with large disks, where we
still need a graphical session to run the desktop app.

Create a normal Ubuntu instance (tweak the exact commands if using a different
distro).

Install

-   **Xfce4** - The desktop environment
-   **xorg** - An X server
-   **xrdp** - A remote desktop protocol (RDP) server.

```sh
sudo apt install xfce4 xorg xrdp
```

Configure xrdp to use Xfce

```sh
echo xfce4-session > ~/.xsession
```

Start the xrdp service, and also enable it so that it starts on boot

```sh
sudo systemctl enable xrdp
sudo systemctl start xrdp
```

On macOS, install a RDP client, e.g. [Microsoft Remote Desktop](https://apps.apple.com/us/app/microsoft-remote-desktop/id1295203466).
