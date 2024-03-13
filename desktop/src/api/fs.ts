import { getDirFilePaths, getElectronFile } from "../services/fs";

export async function getDirFiles(dirPath: string) {
    const files = await getDirFilePaths(dirPath);
    const electronFiles = await Promise.all(files.map(getElectronFile));
    return electronFiles;
}
export {
    deleteFile,
    deleteFolder,
    isFolder,
    moveFile,
    readTextFile,
    rename,
} from "../services/fs";
