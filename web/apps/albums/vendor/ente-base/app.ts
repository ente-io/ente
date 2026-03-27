export const appNames = [
    "accounts",
    "albums",
    "auth",
    "cast",
    "embed",
    "share",
    "photos",
    "ensu",
    "locker",
] as const;

export type AppName = (typeof appNames)[number];

// This vendored copy only serves the public albums web app.
export const appName: AppName = "albums";
export const isDesktop = false;
export const desktopAppVersion: string | undefined = undefined;
export const staticAppTitle = "Ente Photos";
export const clientPackageName = "io.ente.albums.web";
export const clientIdentifier = clientPackageName;
