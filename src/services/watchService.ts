import { Collection } from 'types/collection';
import { EnteFile } from 'types/file';
import { ElectronFile, FileWithCollection } from 'types/upload';
import { runningInBrowser } from 'utils/common';
import { removeFromCollection, syncCollections } from './collectionService';
import { syncFiles } from './fileService';
import debounce from 'debounce-promise';
import { logError } from 'utils/sentry';

export interface WatchMapping {
    collectionName: string;
    folderPath: string;
    files: {
        path: string;
        id: number;
    }[];
}

interface EventQueueType {
    type: 'upload' | 'trash';
    collectionName: string;
    paths: string[];
}

class WatchService {
    ElectronAPIs: any;
    allElectronAPIsExist: boolean = false;
    eventQueue: EventQueueType[] = [];
    isEventRunning: boolean = false;
    isUploadRunning: boolean = false;
    pathToIDMap = new Map<string, number>();
    setElectronFiles: (files: ElectronFile[]) => void;
    setCollectionName: (collectionName: string) => void;
    syncWithRemote: () => void;
    showProgressView: () => void;

    constructor() {
        this.ElectronAPIs = runningInBrowser() && window['ElectronAPIs'];
        this.allElectronAPIsExist = !!this.ElectronAPIs?.getWatchMappings;
    }

    setWatchServiceFunctions(
        setElectronFiles: (files: ElectronFile[]) => void,
        setCollectionName: (collectionName: string) => void,
        syncWithRemote: () => void,
        showProgressView: () => void
    ) {
        this.setElectronFiles = setElectronFiles;
        this.setCollectionName = setCollectionName;
        this.syncWithRemote = syncWithRemote;
        this.showProgressView = showProgressView;
    }

    async init() {
        if (this.allElectronAPIsExist) {
            try {
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
                        const event: EventQueueType = {
                            type: 'upload',
                            collectionName: mapping.collectionName,
                            paths: filesToUpload,
                        };
                        this.eventQueue.push(event);
                    }

                    if (filesToRemove.length > 0) {
                        const event: EventQueueType = {
                            type: 'trash',
                            collectionName: mapping.collectionName,
                            paths: filesToRemove.map((file) => file.path),
                        };
                        this.eventQueue.push(event);
                    }
                }

                this.setWatchFunctions();
                this.syncWithRemote();
                await this.runNextEvent();
            } catch (e) {
                logError(e, 'error while initializing watch service');
            }
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
        if (this.allElectronAPIsExist) {
            try {
                await this.ElectronAPIs.addWatchMapping(
                    collectionName,
                    folderPath
                );
            } catch (e) {
                logError(e, 'error while adding watch mapping');
            }
        }
    }

    async removeWatchMapping(collectionName: string) {
        if (this.allElectronAPIsExist) {
            try {
                await this.ElectronAPIs.removeWatchMapping(collectionName);
            } catch (e) {
                logError(e, 'error while removing watch mapping');
            }
        }
    }

    getWatchMappings(): WatchMapping[] {
        if (this.allElectronAPIsExist) {
            try {
                return this.ElectronAPIs.getWatchMappings() ?? [];
            } catch (e) {
                logError(e, 'error while getting watch mappings');
                return [];
            }
        }
        return [];
    }

    async runNextEvent() {
        console.log('runNextEvent mappings', this.getWatchMappings());

        if (this.eventQueue.length === 0 || this.isEventRunning) {
            return;
        }

        if (this.eventQueue[0].type === 'upload') {
            this.runNextUpload();
        } else {
            this.runNextTrash();
        }
    }

    private async runNextUpload() {
        try {
            if (this.eventQueue.length === 0 || this.isEventRunning) {
                return;
            }

            this.isEventRunning = true;
            this.isUploadRunning = true;

            this.batchNextEvent();

            this.setCollectionName(this.eventQueue[0].collectionName);
            this.setElectronFiles(
                await Promise.all(
                    this.eventQueue[0].paths.map(async (path) => {
                        return await this.ElectronAPIs.getElectronFile(path);
                    })
                )
            );
        } catch (e) {
            logError(e, 'error while running next upload');
        }
    }

    async fileUploaded(fileWithCollection: FileWithCollection, file: EnteFile) {
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

    async allFileUploadsDone(
        filesWithCollection: FileWithCollection[],
        collections: Collection[]
    ) {
        if (this.allElectronAPIsExist) {
            try {
                const collection = collections.find(
                    (collection) =>
                        collection.id === filesWithCollection[0].collectionID
                );
                if (
                    !this.isEventRunning ||
                    this.eventQueue.length === 0 ||
                    this.eventQueue[0].collectionName !== collection?.name
                ) {
                    return;
                }

                const uploadedFiles: WatchMapping['files'] = [];

                for (const fileWithCollection of filesWithCollection) {
                    if (fileWithCollection.isLivePhoto) {
                        const imagePath = (
                            fileWithCollection.livePhotoAssets
                                .image as ElectronFile
                        ).path;
                        const videoPath = (
                            fileWithCollection.livePhotoAssets
                                .video as ElectronFile
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
                        const filePath = (
                            fileWithCollection.file as ElectronFile
                        ).path;

                        if (this.pathToIDMap.has(filePath)) {
                            uploadedFiles.push({
                                path: filePath,
                                id: this.pathToIDMap.get(filePath),
                            });

                            this.pathToIDMap.delete(filePath);
                        }
                    }
                }

                if (uploadedFiles.length > 0) {
                    const mappings = this.getWatchMappings();
                    const mapping = mappings.find(
                        (mapping) =>
                            mapping.collectionName ===
                            this.eventQueue[0].collectionName
                    );
                    mapping.files = [...mapping.files, ...uploadedFiles];

                    this.ElectronAPIs.setWatchMappings(mappings);
                    this.syncWithRemote();
                }

                this.eventQueue.shift();
                this.isEventRunning = false;
                this.isUploadRunning = false;
                this.runNextEvent();
            } catch (e) {
                logError(e, 'error while running all file uploads done');
            }
        }
    }

    private async runNextTrash() {
        try {
            if (this.eventQueue.length === 0 || this.isEventRunning) {
                return;
            }

            this.isEventRunning = true;

            this.batchNextEvent();

            const { collectionName, paths } = this.eventQueue[0];
            const filePathsToRemove = new Set(paths);

            const mappings = this.getWatchMappings();
            const mappingIdx = mappings.findIndex(
                (mapping) => mapping.collectionName === collectionName
            );
            if (mappingIdx === -1) {
                return;
            }

            const files = mappings[mappingIdx].files.filter((file) =>
                filePathsToRemove.has(file.path)
            );

            await this.trashByIDs(files, collectionName);

            mappings[mappingIdx].files = mappings[mappingIdx].files.filter(
                (file) => !filePathsToRemove.has(file.path)
            );
            this.ElectronAPIs.setWatchMappings(mappings);
            this.syncWithRemote();

            this.eventQueue.shift();
            this.isEventRunning = false;
            this.runNextEvent();
        } catch (e) {
            logError(e, 'error while running next trash');
        }
    }

    private async trashByIDs(
        toTrashFiles: WatchMapping['files'],
        collectionName: string
    ) {
        try {
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
        } catch (e) {
            logError(e, 'error while trashing by IDs');
        }
    }

    async getCollectionName(filePath: string) {
        try {
            const mappings = this.getWatchMappings();

            const collectionName = mappings.find((mapping) =>
                filePath.startsWith(mapping.folderPath)
            )?.collectionName;

            if (!collectionName) {
                return null;
            }

            return collectionName;
        } catch (e) {
            logError(e, 'error while getting collection name');
        }
    }

    async selectFolder(): Promise<string> {
        try {
            const folderPath = await this.ElectronAPIs.selectFolder();
            return folderPath;
        } catch (e) {
            logError(e, 'error while selecting folder');
        }
    }

    // Batches all the files to be uploaded (or trashed) from the
    // event queue of same collection as the next event
    private batchNextEvent() {
        const newEventQueue = [this.eventQueue[0]];
        const len = this.eventQueue.length;
        for (let i = 1; i < len; i++) {
            if (
                this.eventQueue[i].collectionName ===
                    newEventQueue[0].collectionName &&
                this.eventQueue[i].type === newEventQueue[0].type
            ) {
                newEventQueue[0].paths.push(...this.eventQueue[i].paths);
            } else {
                newEventQueue.push(this.eventQueue[i]);
            }
        }
        newEventQueue.push(...this.eventQueue.slice(len));
        this.eventQueue = newEventQueue;
    }
}

async function diskFileAddedCallback(instance: WatchService, filePath: string) {
    try {
        const collectionName = await instance.getCollectionName(filePath);

        if (!collectionName) {
            return;
        }

        console.log('added (upload) to event queue', collectionName, filePath);

        const event: EventQueueType = {
            type: 'upload',
            collectionName,
            paths: [filePath],
        };
        instance.eventQueue.push(event);
        await debounce(runNextEventByInstance, 300)(instance);
    } catch (e) {
        logError(e, 'error while calling diskFileAddedCallback');
    }
}

async function diskFileRemovedCallback(
    instance: WatchService,
    filePath: string
) {
    try {
        const collectionName = await instance.getCollectionName(filePath);

        console.log('added (trash) to event queue', collectionName, filePath);

        if (!collectionName) {
            return;
        }

        const event: EventQueueType = {
            type: 'trash',
            collectionName,
            paths: [filePath],
        };
        instance.eventQueue.push(event);
        await debounce(runNextEventByInstance, 300)(instance);
    } catch (e) {
        logError(e, 'error while calling diskFileRemovedCallback');
    }
}

const runNextEventByInstance = async (w: WatchService) => {
    await w.runNextEvent();
};

export default new WatchService();
