import { PICKED_UPLOAD_TYPE } from 'constants/upload';
import { Collection } from 'types/collection';
import { ElectronFile, FileWithCollection } from 'types/upload';
import { logError } from '@ente/shared/sentry';
import ElectronAPIs from '@ente/shared/electron';

interface PendingUploads {
    files: ElectronFile[];
    collectionName: string;
    type: PICKED_UPLOAD_TYPE;
}

class ImportService {
    async getPendingUploads(): Promise<PendingUploads> {
        try {
            const pendingUploads =
                (await ElectronAPIs.getPendingUploads()) as PendingUploads;
            return pendingUploads;
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
        ElectronAPIs.setToUploadCollection(collectionName);
    }

    updatePendingUploads(files: FileWithCollection[]) {
        const filePaths = [];
        for (const fileWithCollection of files) {
            if (fileWithCollection.isLivePhoto) {
                filePaths.push(
                    (fileWithCollection.livePhotoAssets.image as ElectronFile)
                        .path,
                    (fileWithCollection.livePhotoAssets.video as ElectronFile)
                        .path
                );
            } else {
                filePaths.push((fileWithCollection.file as ElectronFile).path);
            }
        }
        ElectronAPIs.setToUploadFiles(PICKED_UPLOAD_TYPE.FILES, filePaths);
    }

    cancelRemainingUploads() {
        ElectronAPIs.setToUploadCollection(null);
        ElectronAPIs.setToUploadFiles(PICKED_UPLOAD_TYPE.ZIPS, []);
        ElectronAPIs.setToUploadFiles(PICKED_UPLOAD_TYPE.FILES, []);
    }
}

export default new ImportService();
