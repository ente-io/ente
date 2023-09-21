import { ElectronAPIs } from 'types/electron';
import { logError } from 'utils/sentry';

class ElectronFSService {
    private electronAPIs: ElectronAPIs;

    constructor() {
        this.electronAPIs = globalThis['ElectronAPIs'];
    }

    getDirFiles(dirPath: string) {
        if (this.electronAPIs.getDirFiles) {
            return this.electronAPIs.getDirFiles(dirPath);
        }
    }

    async isFolder(folderPath: string) {
        try {
            const isFolder = await this.electronAPIs.isFolder(folderPath);
            return isFolder;
        } catch (e) {
            logError(e, 'error while checking if is Folder');
        }
    }

    async saveMediaFile(
        filePath: string,
        fileStream: ReadableStream<Uint8Array>
    ) {
        try {
            await this.electronAPIs.saveStreamToDisk(filePath, fileStream);
        } catch (e) {
            logError(e, 'error while saving media file');
            throw e;
        }
    }

    deleteFile(filePath: string) {
        try {
            this.electronAPIs.deleteFile(filePath);
        } catch (e) {
            logError(e, 'error while deleting file');
            throw e;
        }
    }
}

export default new ElectronFSService();
