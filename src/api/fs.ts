import { getElectronFile, getFilesFromDir } from '../services/fs';

export async function getAllFilesFromDir(dirPath: string) {
    const files = await getFilesFromDir(dirPath);
    const electronFiles = await Promise.all(files.map(getElectronFile));
    return electronFiles;
}
export { doesFolderExists } from '../services/fs';
