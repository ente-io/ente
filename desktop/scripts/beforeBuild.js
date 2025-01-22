const fsp = require("fs/promises");

/**
 * This hook is invoked during the initial build (e.g. when triggered by "yarn
 * build"), and importantly, on each rebuild for a different architecture during
 * the build. We use it to ensure that the magick binary is for the current
 * architecture being built. See "[Note: ImageMagick]" for more details.
 *
 * The documentation for this hook is at:
 * https://www.electron.build/app-builder-lib.interface.configuration#beforebuild
 *
 * > The function to be run before dependencies are installed or rebuilt.
 *
 * Here is an example of the context that it gets
 * https://www.electron.build/app-builder-lib.interface.beforebuildcontext
 *
 *     appDir: '/path/to/ente/desktop',
 *     platform: Platform {
 *         name: 'mac',
 *         buildConfigurationKey: 'mac',
 *         nodeName: 'darwin'
 *     },
 *     arch: 'arm64'
 *
 */
module.exports = async (context) => {
    const { appDir, platform, arch } = context;

    // The arch used by Electron Builder is not the same as the arch used by
    // Node's process, but for the two cases that we care about, "x64" and
    // "arm64", both of them use the string constant and thus can be compared.
    //
    // https://github.com/electron-userland/electron-builder/blob/master/packages/builder-util/src/arch.ts#L9
    // https://nodejs.org/api/process.html#processarch
    if (arch == process.arch) {
        // `magick.js` would've already downloaded the file, nothing to do.
        //
        // We must not return false, because
        // > Resolving to false will skip dependencies install or rebuild.
        return true;
    }

    const download = async (downloadName, outputName) => {
        const out = `${appDir}/build/${outputName}`;
        console.log(`Downloading ${downloadName}`);
        const downloadPath = `https://github.com/ente-io/ImageMagick/releases/download/2025-01-21/${downloadName}`;
        return fetch(downloadPath)
            .then((res) => res.blob())
            .then((blob) => fsp.writeFile(out, blob.stream()))
            .then(() => fsp.chmod(out, "744"));
    };

    switch (`${platform.nodeName}-${arch}`) {
        case "linux-x64":
            return download("magick-x86_64", "magick");
        case "linux-arm64":
            return download("magick-aarch64", "magick");
        case "win32-x64":
            return download("magick-x64.exe", "magick.exe");
        case "linux-arm64":
            return download("magick-arm64.exe", "magick.exe");
    }
};
