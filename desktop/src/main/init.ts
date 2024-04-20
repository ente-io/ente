import { BrowserWindow, app, shell } from "electron";
import { existsSync } from "node:fs";
import path from "node:path";
import { rendererURL } from "../main";

export function handleDownloads(mainWindow: BrowserWindow) {
    mainWindow.webContents.session.on("will-download", (_, item) => {
        item.setSavePath(
            getUniqueSavePath(item.getFilename(), app.getPath("downloads")),
        );
    });
}

export function handleExternalLinks(mainWindow: BrowserWindow) {
    mainWindow.webContents.setWindowOpenHandler(({ url }) => {
        if (!url.startsWith(rendererURL)) {
            shell.openExternal(url);
            return { action: "deny" };
        } else {
            return { action: "allow" };
        }
    });
}

export function getUniqueSavePath(filename: string, directory: string): string {
    let uniqueFileSavePath = path.join(directory, filename);
    const { name: filenameWithoutExtension, ext: extension } =
        path.parse(filename);
    let n = 0;
    while (existsSync(uniqueFileSavePath)) {
        n++;
        // filter need to remove undefined extension from the array
        // else [`${fileName}`, undefined].join(".") will lead to `${fileName}.` as joined string
        const fileNameWithNumberedSuffix = [
            `${filenameWithoutExtension}(${n})`,
            extension,
        ]
            .filter((x) => x) // filters out undefined/null values
            .join("");
        uniqueFileSavePath = path.join(directory, fileNameWithNumberedSuffix);
    }
    return uniqueFileSavePath;
}

function lowerCaseHeaders(responseHeaders: Record<string, string[]>) {
    const headers: Record<string, string[]> = {};
    for (const key of Object.keys(responseHeaders)) {
        headers[key.toLowerCase()] = responseHeaders[key];
    }
    return headers;
}

export function addAllowOriginHeader(mainWindow: BrowserWindow) {
    mainWindow.webContents.session.webRequest.onHeadersReceived(
        (details, callback) => {
            details.responseHeaders = lowerCaseHeaders(details.responseHeaders);
            details.responseHeaders["access-control-allow-origin"] = ["*"];
            callback({
                responseHeaders: details.responseHeaders,
            });
        },
    );
}
