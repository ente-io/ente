export function isPlatform(platform: "mac" | "windows" | "linux") {
    return getPlatform() === platform;
}

export function getPlatform(): "mac" | "windows" | "linux" {
    switch (process.platform) {
        case "aix":
        case "freebsd":
        case "linux":
        case "openbsd":
        case "android":
            return "linux";
        case "darwin":
        case "sunos":
            return "mac";
        case "win32":
            return "windows";
    }
}
