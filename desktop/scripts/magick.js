/**
 * [Note: ImageMagick]
 *
 * We need static builds for Linux and Windows for both x64 and ARM. For this,
 * we need a custom workflow because (as of writing):
 *
 * 1. Upstream doesn't publish ARM64 binaries for Linux
 *
 * 2. The Windows portable releases are not part of the artifacts attached to
 *    the upstream GitHub release.
 *
 * Our custom workflow is an adaption of the upstream release.yml - its goal is
 * to have 4 standalone binaries - Linux x64, Linux ARM, Win x64, Win ARM -
 * attached to a GitHub release from which we can pull them when building the
 * desktop app.
 *
 * This is our custom workflow, which runs on a fork of upstream:
 * https://github.com/ente-io/ImageMagick/commit/df895cce13d6a3f874a716c05ff2babeb33351b9
 * (For reference, we also include a copy of it in this repo - `magick.yml`).
 *
 * The binaries it creates are available at
 * https://github.com/ente-io/ImageMagick/releases/tag/2025-01-21.
 *
 * To integrate this ImageMagick binary, we need to modify two places:
 *
 * 1. This script, `magick.js`, runs during "yarn install" (it is set as the
 *    "prepare" step in our `package.json`). It downloads the relevant binary
 *    for the current OS/arch combination and places it in the `build` folder,
 *    allowing it to be used during development.
 *
 * 2. The sibling script, `beforeBuild.js`, runs during "yarn build" (it is set
 *    as the beforeBuild script in `electrons-builder.yml`). It downloads the
 *    relevant binary for the OS/arch combination being built.
 *
 * Note that `magick.js` would've already run once `beforeBuild.js` is run, but
 * on our CI we prepare builds for multiple architectures in one go, so we need
 * to unconditonally replace the binary with the relevant one for the current
 * architecture being built (which might be different from the one we're running
 * on). `beforeBuild.js` runs for each architecture being built.
 *
 * On macOS, we don't need ImageMagick since there we use the native `sips`.
 */

const fs = require("fs");
const fsp = require("fs/promises");

const main = () => {
    switch (`${process.platform}-${process.arch}`) {
        case "linux-x64":
            return downloadIfNeeded("magick-x86_64", "magick");
        case "linux-arm64":
            return downloadIfNeeded("magick-aarch64", "magick");
        case "win32-x64":
            return downloadIfNeeded("magick-x64.exe", "magick.exe");
        case "linux-arm64":
            return downloadIfNeeded("magick-arm64.exe", "magick.exe");
    }
};

const downloadIfNeeded = (downloadName, outputName) => {
    const out = `build/${outputName}`;

    try {
        // Making the file executable is the last step, so if the file exists at
        // this path and is executable, we assume it is the correct one.
        fs.accessSync(out, fs.constants.X_OK);
        return;
    } catch {}

    console.log(`Downloading ${downloadName}`);
    const downloadPath = `https://github.com/ente-io/ImageMagick/releases/download/2025-01-21/${downloadName}`;
    return fetch(downloadPath)
        .then((res) => res.blob())
        .then((blob) => fsp.writeFile(out, blob.stream()))
        .then(() => fsp.chmod(out, "744"));
};

main();
