import { Collection } from 'types/collection';
import { ElectronAPIs } from 'types/electron';
import { ElectronFile, FileWithCollection, UPLOAD_TYPE } from 'types/upload';
import { runningInBrowser } from 'utils/common';
import { logError } from 'utils/sentry';

interface PendingUploads {
    files: ElectronFile[];
    collectionName: string;
    type: UPLOAD_TYPE;
}

interface selectZipResult {
    files: ElectronFile[];
    zipPaths: string[];
}
class ImportService {
    ElectronAPIs: ElectronAPIs;
    private allElectronAPIsExist: boolean = false;

    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.ElectronAPIs?.getPendingUploads;
    }

    async getElectronFilesFromGoogleZip(
        zipPath: string
    ): Promise<ElectronFile[]> {
        if (this.allElectronAPIsExist) {
            return this.ElectronAPIs.getElectronFilesFromGoogleZip(zipPath);
        }
    }

    checkAllElectronAPIsExists = () => this.allElectronAPIsExist;

    async showUploadFilesDialog(): Promise<ElectronFile[]> {
        if (this.allElectronAPIsExist) {
            return this.ElectronAPIs.showUploadFilesDialog();
        }
    }

    async showUploadDirsDialog(): Promise<ElectronFile[]> {
        if (this.allElectronAPIsExist) {
            return this.ElectronAPIs.showUploadDirsDialog();
        }
    }

    async showUploadZipDialog(): Promise<selectZipResult> {
        if (this.allElectronAPIsExist) {
            return this.ElectronAPIs.showUploadZipDialog();
        }
    }
    async getPendingUploads(): Promise<PendingUploads> {
        try {
            if (this.allElectronAPIsExist) {
                const pendingUploads =
                    (await this.ElectronAPIs.getPendingUploads()) as PendingUploads;
                return pendingUploads;
            }
        } catch (e) {
            if (e?.message?.includes('ENOENT: no such file or directory')) {
                // ignore
            } else {
                logError(e, 'failed to getPendingUploads ');
            }
            return { files: [], collectionName: null, type: null };
        }
    }

    async setToUploadCollection(collections: Collection[]) {
        if (this.allElectronAPIsExist) {
            let collectionName: string = null;
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
            this.ElectronAPIs.setToUploadCollection(collectionName);
        }
    }

    async setToUploadFiles(
        type: UPLOAD_TYPE.FILES | UPLOAD_TYPE.ZIPS,
        filePaths: string[]
    ) {
        if (this.allElectronAPIsExist) {
            this.ElectronAPIs.setToUploadFiles(type, filePaths);
        }
    }

    updatePendingUploads(files: FileWithCollection[]) {
        if (this.allElectronAPIsExist) {
            const filePaths = [];
            for (const fileWithCollection of files) {
                if (fileWithCollection.isLivePhoto) {
                    filePaths.push(
                        (
                            fileWithCollection.livePhotoAssets
                                .image as ElectronFile
                        ).path,
                        (
                            fileWithCollection.livePhotoAssets
                                .video as ElectronFile
                        ).path
                    );
                } else {
                    filePaths.push(
                        (fileWithCollection.file as ElectronFile).path
                    );
                }
            }
            this.setToUploadFiles(UPLOAD_TYPE.FILES, filePaths);
        }
    }
    cancelRemainingUploads() {
        if (this.allElectronAPIsExist) {
            this.ElectronAPIs.setToUploadCollection(null);
            this.ElectronAPIs.setToUploadFiles(UPLOAD_TYPE.ZIPS, []);
            this.ElectronAPIs.setToUploadFiles(UPLOAD_TYPE.FILES, []);
        }
    }
}

export default new ImportService();
