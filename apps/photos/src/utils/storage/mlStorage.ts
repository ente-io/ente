import { EnteFile } from 'types/file';
import {
    Face,
    MlFileData,
    MLIndex,
    MLSyncContext,
} from 'types/machineLearning';
import localForage from './localForage';

export const mlFilesStore = localForage.createInstance({
    driver: localForage.INDEXEDDB,
    name: 'ml-data',
    version: 1.0,
    storeName: 'files',
});

export const mlPeopleStore = localForage.createInstance({
    driver: localForage.INDEXEDDB,
    name: 'ml-data',
    version: 1.0,
    storeName: 'people',
});

export const mlLibraryStore = localForage.createInstance({
    driver: localForage.INDEXEDDB,
    name: 'ml-data',
    version: 1.0,
    storeName: 'library',
});

export const mlVersionStore = localForage.createInstance({
    driver: localForage.INDEXEDDB,
    name: 'ml-data',
    version: 1.0,
    storeName: 'versions',
});

export async function clearMLStorage() {
    await mlFilesStore.clear();
    await mlPeopleStore.clear();
    await mlLibraryStore.clear();
    await mlVersionStore.clear();
}

export async function getIndexVersion(index: MLIndex): Promise<number> {
    return ((await mlVersionStore.getItem(`${index}`)) as number) || 0;
}

export async function setIndexVersion(
    index: MLIndex,
    version: number
): Promise<number> {
    await mlVersionStore.setItem(`${index}`, version);

    return version;
}

export async function incrementIndexVersion(index: MLIndex): Promise<number> {
    let currentVersion = await getIndexVersion(index);
    currentVersion = currentVersion + 1;
    await setIndexVersion(index, currentVersion);

    return currentVersion;
}

export async function isVersionOutdated(index: MLIndex, thanIndex: MLIndex) {
    const indexVersion = await getIndexVersion(index);
    const thanIndexVersion = await getIndexVersion(thanIndex);

    return indexVersion < thanIndexVersion;
}

export function newMlData(
    syncContext: MLSyncContext,
    enteFile: EnteFile
): MlFileData {
    return {
        fileId: enteFile.id,
        imageSource: syncContext.config.imageSource,
        faceDetectionMethod: syncContext.faceDetectionService.method,
        faceCropMethod: syncContext.faceCropService.method,
        faceAlignmentMethod: syncContext.faceAlignmentService.method,
        faceEmbeddingMethod: syncContext.faceEmbeddingService.method,
        errorCount: 0,
        mlVersion: 0,
    };
}

export async function getAllFacesMap() {
    const allSyncedFacesMap = new Map<number, Array<Face>>();
    await mlFilesStore.iterate((mlFileData: MlFileData) => {
        mlFileData.faces &&
            allSyncedFacesMap.set(mlFileData.fileId, mlFileData.faces);
    });

    return allSyncedFacesMap;
}
