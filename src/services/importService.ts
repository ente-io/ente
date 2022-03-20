import { Collection } from 'types/collection';
import { ElectronFile, FileWithCollection } from 'types/upload';
import { runningInBrowser } from 'utils/common';
import { getElectronFiles } from 'utils/upload';

class ImportService {
    ElectronAPIs: any;
    private allElectronAPIsExist: boolean = false;

    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.ElectronAPIs?.exists;
    }

    async setDoneUploadingFiles() {
        if (this.allElectronAPIsExist) {
            this.ElectronAPIs.setToUploadFiles(null, null, null, true);
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

    async getToUploadFiles() {
        if (this.allElectronAPIsExist) {
            const { filesPaths, collectionName, collectionIDs } =
                this.ElectronAPIs.getToUploadFiles();
            const files = await getElectronFiles(filesPaths);
            return {
                files,
                collectionName,
                collectionIDs,
            };
        }
    }

    async setToUploadFiles(
        files: FileWithCollection[],
        collections?: Collection[]
    ) {
        if (this.allElectronAPIsExist) {
            let collectionName;
            if (collections?.length > 0) {
                collectionName = collections[0].name;
            }
            const filePaths = files.map(
                (file) => (file.file as ElectronFile).path
            );
            const collectionIDs = files.map((file) => file.collectionID);
            this.ElectronAPIs.setToUploadFiles(
                filePaths,
                collectionName,
                collectionIDs,
                false
            );
        }
    }
}
export default new ImportService();
