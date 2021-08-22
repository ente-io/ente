# bhari-frame (heavy-frame)

Desktop app for [ente.io](https://ente.io) build with [electron](https://electronjs.org) and loads of ❤️.

## Disclaimer

We are aware that electron is a sub-optimal choice for building desktop applications.

The goal of this app was to
1. provide a stable environment for customers to back up large amounts of data reliably
2. export uploaded data from our servers to their local hard drives.
 
Electron was the best way to reuse our battle tested code from [bada-frame](https://github.com/ente-io/bada-frame) that powers [web.ente.io](https://web.ente.io).

As an archival solution built by a small team, we are hopeful that this project will help us keep our stack lean, while ensuring a painfree life for our customers.

If you are running into issues with this app, please drop a mail to [support@ente.io](mailto:support@ente.io) and we'll be very happy to help.

## Download
- [Latest Release](https://github.com/ente-io/bhari-frame/releases/latest)

## Develop

To clone and run this repository you'll need [Git](https://git-scm.com) and [Node.js](https://nodejs.org/en/download/) (which comes with [npm](http://npmjs.com)) installed on your computer. From your command line:

```bash
# Clone this repository
git clone https://github.com/ente-io/bhari-frame
# Go into the repository
cd bhari-frame
# Install dependencies
npm install
# Run the app
npm start
```

Note: If you're using Linux Bash for Windows, [see this guide](https://www.howtogeek.com/261575/how-to-run-graphical-linux-desktop-applications-from-windows-10s-bash-shell/) or use `node` from the command prompt.

### Re-compile automatically

To recompile automatically and to allow using [electron-reload](https://github.com/yan-foto/electron-reload), run this in a separate terminal:

```bash
npm run watch
```
