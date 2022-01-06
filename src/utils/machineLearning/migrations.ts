import { MlFileData, Face } from 'types/machineLearning';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import { mlFilesStore } from 'utils/storage/mlStorage';
import { getFaceId } from '.';
import { getStoredFaceCropForBlob } from './faceCrop';

// TODO: for migrating existing data, to be removed
export async function migrateExistingFiles() {
    const existingFiles: Array<MlFileData> = [];
    await mlFilesStore.iterate((mlFileData: MlFileData) => {
        if (!mlFileData.errorCount) {
            mlFileData.errorCount = 0;
            existingFiles.push(mlFileData);
        }
    });
    console.log('existing files: ', existingFiles.length);

    try {
        for (const file of existingFiles) {
            await mlIDbStorage.putFile(file);
        }
        await mlIDbStorage.setIndexVersion('files', 1);
        console.log('migrateExistingFiles done');
    } catch (e) {
        console.error(e);
    }
}

export async function migrateFaceCropsToCache() {
    console.time('migrateFaceCropsToCache');
    console.log('migrateFaceCropsToCache started');
    const allFiles = await mlIDbStorage.getAllFiles();
    const allFilesWithFaces = allFiles.filter(
        (f) => f.faces && f.faces.length > 0
    );
    const updatedFacesMap = new Map<number, Array<Face>>();

    for (const file of allFilesWithFaces) {
        let updated = false;
        for (const face of file.faces) {
            if (!face['id']) {
                const faceCropBlob = face.crop['image'];
                const faceId = getFaceId(face, file.imageDimentions);
                face.crop = await getStoredFaceCropForBlob(
                    faceId,
                    face.crop.imageBox,
                    faceCropBlob
                );
                face['id'] = faceId;
                updated = true;
            }
        }
        if (updated) {
            updatedFacesMap.set(file.fileId, file.faces);
        }
    }

    if (updatedFacesMap.size > 0) {
        console.log('updating face crops: ', updatedFacesMap.size);
        await mlIDbStorage.updateFaces(updatedFacesMap);
    } else {
        console.log('not updating face crops: ', updatedFacesMap.size);
    }
    console.timeEnd('migrateFaceCropsToCache');
}
