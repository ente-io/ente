import { Collection } from 'types/collection';
import { ElectronFile, FileWithCollection } from 'types/upload';
import { runningInBrowser } from 'utils/common';

interface FilesAndCollections {
    files: FileWithCollection[];
    collections: Collection[];
}

class ImportService {
    ElectronAPIs: any;
    private allElectronAPIsExist: boolean = false;

    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.ElectronAPIs?.exists;
    }

    async setToUploadFiles(
        filesWithCollectionToUpload: FileWithCollection[],
        collections?: Collection[]
    ) {
        if (this.allElectronAPIsExist) {
            this.ElectronAPIs.setToUploadFiles(
                filesWithCollectionToUpload,
                collections,
                false
            );
        }
    }

    async setDoneUploadingFiles() {
        if (this.allElectronAPIsExist) {
            this.ElectronAPIs.setToUploadFiles([], [], true);
        }
    }

    async getToUploadFiles(): Promise<FilesAndCollections> {
        if (this.allElectronAPIsExist) {
            return this.ElectronAPIs.getToUploadFiles();
        }
    }

    async getIfToUploadFilesExists(): Promise<boolean> {
        if (this.allElectronAPIsExist) {
            return this.ElectronAPIs.getIfToUploadFilesExists();
        }
    }

    async getElectronFile(filePath: string): Promise<ElectronFile> {
        if (this.allElectronAPIsExist) {
            return this.ElectronAPIs.getElectronFile(filePath);
        }
    }

    async showUploadFilesDialog(): Promise<string[]> {
        if (this.allElectronAPIsExist) {
            return this.ElectronAPIs.showUploadFilesDialog();
        }
    }

    async showUploadDirsDialog(): Promise<string[]> {
        if (this.allElectronAPIsExist) {
            return this.ElectronAPIs.showUploadDirsDialog();
        }
    }
}
export default new ImportService();
