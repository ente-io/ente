import { dialog } from "electron/main";
import { posixPath } from "../utils-path";

export const selectDirectory = async () => {
    const result = await dialog.showOpenDialog({
        properties: ["openDirectory"],
    });
    const dirPath = result.filePaths[0];
    return dirPath ? posixPath(dirPath) : undefined;
};
