import { Collection } from 'types/collection';
import { ElectronFile, FileWithCollection } from 'types/upload';
import { runningInBrowser } from 'utils/common';

class ImportService {
    ElectronAPIs: any;

    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
    }

    async showUploadFilesDialog(): Promise<ElectronFile[]> {
        return this.ElectronAPIs.showUploadFilesDialog();
    }

    async showUploadDirsDialog(): Promise<ElectronFile[]> {
        return this.ElectronAPIs.showUploadDirsDialog();
    }

    async getPendingUploads() {
        const { files, collectionName } =
            (await this.ElectronAPIs.getPendingUploads()) as {
                files: ElectronFile[];
                collectionName: string;
            };
        return {
            files,
            collectionName,
        };
    }

    async setToUploadFiles(
        files: FileWithCollection[],
        collections: Collection[]
    ) {
        let collectionName: string;
        /* collection being one suggest one of two things
                1. Either the user has upload to a single existing collection
                2. Created a new single collection to upload to 
                    may have had multiple folder, but chose to upload
                    to one album
                hence saving the collection name when upload collection count is 1
                helps the info of user choosing this options
                and on next upload we can directly start uploading to this collection 
        */
        if (collections.length === 1) {
            collectionName = collections[0].name;
        }
        const filePaths = files.map((file) => (file.file as ElectronFile).path);
        this.ElectronAPIs.setToUploadFiles(filePaths, collectionName);
    }

    updatePendingUploads(files: FileWithCollection[]) {
        const filePaths = files.map((file) => (file.file as ElectronFile).path);
        this.ElectronAPIs.updatePendingUploadsFilePaths(filePaths);
    }
}
export default new ImportService();
