import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import { ElectronFile, FileWithCollection } from 'types/upload';
import { runningInBrowser } from 'utils/common';
import { removeFromCollection, syncCollections } from './collectionService';
import { syncFiles } from './fileService';
import debounce from 'debounce-promise';

export interface WatchMapping {
    collectionName: string;
    folderPath: string;
    files: {
        path: string;
        id: number;
    }[];
}

interface UploadQueueType {
    collectionName: string;
    paths: string[];
}

class WatchService {
    ElectronAPIs: any;
    allElectronAPIsExist: boolean = false;
    uploadQueue: UploadQueueType[] = [];
    isUploadRunning: boolean = false;
    pathToIDMap = new Map<string, number>();
    setElectronFiles: (files: ElectronFile[]) => void;
    setCollectionName: (collectionName: string) => void;
    syncWithRemote: () => void;

    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.ElectronAPIs?.getWatchMappings;
    }

    async init() {
        if (this.allElectronAPIsExist) {
            const mappings = this.getWatchMappings();

            console.log('mappings', mappings);

            if (!mappings) {
                return;
            }

            for (const mapping of mappings) {
                const filePathsOnDisk: string[] =
                    await this.ElectronAPIs.getPosixFilePathsFromDir(
                        mapping.folderPath
                    );

                const filesToUpload = filePathsOnDisk.filter((filePath) => {
                    return !mapping.files.find(
                        (file) => file.path === filePath
                    );
                });

                const filesToRemove = mapping.files.filter((file) => {
                    return !filePathsOnDisk.find(
                        (filePath) => filePath === file.path
                    );
                });

                if (filesToUpload.length > 0) {
                    const event: UploadQueueType = {
                        collectionName: mapping.collectionName,
                        paths: filesToUpload,
                    };
                    this.uploadQueue.push(event);
                }

                if (filesToRemove.length > 0) {
                    await this.trashByIDs(
                        filesToRemove,
                        mapping.collectionName
                    );
                    mapping.files = mapping.files.filter(
                        (file) =>
                            !filesToRemove.find(
                                (fileToRemove) =>
                                    file.path === fileToRemove.path
                            )
                    );
                }

                this.runNextUpload();
            }

            this.ElectronAPIs.setWatchMappings(mappings);
            this.setWatchFunctions();
            this.syncWithRemote();
        }
    }

    setWatchFunctions() {
        if (this.allElectronAPIsExist) {
            this.ElectronAPIs.registerWatcherFunctions(
                this,
                diskFileAddedCallback,
                diskFileRemovedCallback
            );
        }
    }

    async addWatchMapping(collectionName: string, folderPath: string) {
        await this.ElectronAPIs.addWatchMapping(collectionName, folderPath);
    }

    async removeWatchMapping(collectionName: string) {
        await this.ElectronAPIs.removeWatchMapping(collectionName);
    }

    getWatchMappings(): WatchMapping[] {
        if (this.allElectronAPIsExist) {
            return this.ElectronAPIs.getWatchMappings() ?? [];
        }
    }

    async runNextUpload() {
        if (this.uploadQueue.length === 0 || this.isUploadRunning) {
            return;
        }

        this.isUploadRunning = true;

        const newUploadQueue = [this.uploadQueue[0]];
        const len = this.uploadQueue.length;
        for (let i = 1; i < len; i++) {
            if (
                this.uploadQueue[i].collectionName ===
                newUploadQueue[0].collectionName
            ) {
                newUploadQueue[0].paths.push(...this.uploadQueue[i].paths);
            } else {
                newUploadQueue.push(this.uploadQueue[i]);
            }
        }
        newUploadQueue.push(...this.uploadQueue.slice(len));
        this.uploadQueue = newUploadQueue;

        this.setCollectionName(this.uploadQueue[0].collectionName);
        this.setElectronFiles(
            await Promise.all(
                this.uploadQueue[0].paths.map(async (path) => {
                    return await this.ElectronAPIs.getElectronFile(path);
                })
            )
        );
    }

    async fileUploadDone(
        fileWithCollection: FileWithCollection,
        file: EnteFile
    ) {
        if (fileWithCollection.isLivePhoto) {
            this.pathToIDMap.set(
                (fileWithCollection.livePhotoAssets.image as ElectronFile).path,
                file.id
            );
            this.pathToIDMap.set(
                (fileWithCollection.livePhotoAssets.video as ElectronFile).path,
                file.id
            );
        } else {
            this.pathToIDMap.set(
                (fileWithCollection.file as ElectronFile).path,
                file.id
            );
        }
    }

    async allUploadsDone(
        filesWithCollection: FileWithCollection[],
        collections: Collection[]
    ) {
        if (this.allElectronAPIsExist) {
            const collection = collections.find(
                (collection) =>
                    collection.id === filesWithCollection[0].collectionID
            );
            if (
                !this.isUploadRunning ||
                this.uploadQueue.length === 0 ||
                this.uploadQueue[0].collectionName !== collection?.name
            ) {
                return;
            }

            const uploadedFiles: WatchMapping['files'] = [];

            for (const fileWithCollection of filesWithCollection) {
                if (fileWithCollection.isLivePhoto) {
                    const imagePath = (
                        fileWithCollection.livePhotoAssets.image as ElectronFile
                    ).path;
                    const videoPath = (
                        fileWithCollection.livePhotoAssets.video as ElectronFile
                    ).path;
                    if (
                        this.pathToIDMap.has(imagePath) &&
                        this.pathToIDMap.has(videoPath)
                    ) {
                        uploadedFiles.push({
                            path: imagePath,
                            id: this.pathToIDMap.get(imagePath),
                        });
                        uploadedFiles.push({
                            path: videoPath,
                            id: this.pathToIDMap.get(videoPath),
                        });

                        this.pathToIDMap.delete(imagePath);
                        this.pathToIDMap.delete(videoPath);
                    }
                } else {
                    const filePath = (fileWithCollection.file as ElectronFile)
                        .path;
                    if (this.pathToIDMap.has(filePath)) {
                        uploadedFiles.push({
                            path: filePath,
                            id: this.pathToIDMap.get(filePath),
                        });

                        this.pathToIDMap.delete(filePath);
                    }
                }
            }

            console.log('uploadedFiles', uploadedFiles);

            if (uploadedFiles.length > 0) {
                const mappings = this.getWatchMappings();
                const mapping = mappings.find(
                    (mapping) =>
                        mapping.collectionName ===
                        this.uploadQueue[0].collectionName
                );
                mapping.files = [...mapping.files, ...uploadedFiles];

                console.log('new mappings', mappings);

                this.ElectronAPIs.setWatchMappings(mappings);
                this.syncWithRemote();

                console.log(
                    'now mappings',
                    await this.ElectronAPIs.getWatchMappings()
                );
            }

            this.uploadQueue.shift();
            this.isUploadRunning = false;
            this.runNextUpload();
        }
    }

    async trashByIDs(
        toTrashFiles: WatchMapping['files'],
        collectionName: string
    ) {
        if (this.allElectronAPIsExist) {
            const collections = await syncCollections();
            const collection = collections.find(
                (collection) => collection.name === collectionName
            );
            if (!collection) {
                return;
            }
            const files = await syncFiles(collections, () => {});

            const idSet = new Set<number>();
            for (const file of toTrashFiles) {
                idSet.add(file.id);
            }

            const filesToTrash = files.filter((file) => {
                return (
                    idSet.has(file.id) && file.collectionID === collection.id
                );
            });

            await removeFromCollection(collection, filesToTrash);
        }
    }

    async getCollectionName(filePath: string) {
        const mappings = this.getWatchMappings();

        console.log('mappings', mappings, filePath);

        const collectionName = mappings.find((mapping) =>
            filePath.startsWith(mapping.folderPath)
        )?.collectionName;

        if (!collectionName) {
            return null;
        }

        return collectionName;
    }

    async selectFolder(): Promise<string> {
        const folderPath = await this.ElectronAPIs.selectFolder();
        return folderPath;
    }
}

async function diskFileAddedCallback(instance: WatchService, filePath: string) {
    const collectionName = await instance.getCollectionName(filePath);

    if (!collectionName) {
        return;
    }

    console.log('adding', collectionName, filePath);

    const event: UploadQueueType = {
        collectionName,
        paths: [filePath],
    };
    instance.uploadQueue.push(event);
    await debounce(runNextUploadByInstance, 300)(instance);
}

async function diskFileRemovedCallback(
    instance: WatchService,
    filePath: string
) {
    const collectionName = await instance.getCollectionName(filePath);

    console.log('removing', collectionName, filePath);

    if (!collectionName) {
        return;
    }

    const mappings = instance.getWatchMappings();

    const mappingIdx = mappings.findIndex(
        (mapping) => mapping.collectionName === collectionName
    );
    if (mappingIdx === -1) {
        return;
    }

    const file = mappings[mappingIdx].files.find(
        (file) => file.path === filePath
    );
    if (!file) {
        return;
    }

    await instance.trashByIDs([file], collectionName);

    mappings[mappingIdx].files = mappings[mappingIdx].files.filter(
        (file) => file.path !== filePath
    );
    instance.ElectronAPIs.setWatchMappings(mappings);
    instance.syncWithRemote();

    console.log('after trash', instance.getWatchMappings());
}

const runNextUploadByInstance = async (w: WatchService) => {
    await w.runNextUpload();
};

export default new WatchService();
