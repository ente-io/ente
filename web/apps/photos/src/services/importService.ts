import { ensureElectron } from "@/next/electron";
import { Collection } from "types/collection";
import { ElectronFile, FileWithCollection } from "types/upload";

class ImportService {
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
        await ensureElectron().setPendingUploadCollection(collectionName);
    }

    async updatePendingUploads(files: FileWithCollection[]) {
        const filePaths = [];
        for (const fileWithCollection of files) {
            if (fileWithCollection.isLivePhoto) {
                filePaths.push(
                    (fileWithCollection.livePhotoAssets.image as ElectronFile)
                        .path,
                    (fileWithCollection.livePhotoAssets.video as ElectronFile)
                        .path,
                );
            } else {
                filePaths.push((fileWithCollection.file as ElectronFile).path);
            }
        }
        await ensureElectron().setPendingUploadFiles("files", filePaths);
    }

    async cancelRemainingUploads() {
        const electron = ensureElectron();
        await electron.setPendingUploadCollection(undefined);
        await electron.setPendingUploadFiles("zips", []);
        await electron.setPendingUploadFiles("files", []);
    }
}

export default new ImportService();
