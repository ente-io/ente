import {
    DEFAULT_ML_SEARCH_CONFIG,
    DEFAULT_ML_SYNC_CONFIG,
    DEFAULT_ML_SYNC_JOB_CONFIG,
    MAX_ML_SYNC_ERROR_COUNT,
} from 'constants/mlConfig';
import {
    openDB,
    deleteDB,
    DBSchema,
    IDBPDatabase,
    IDBPTransaction,
    StoreNames,
} from 'idb';
import { Config } from 'types/common/config';
import {
    Face,
    MlFileData,
    MLLibraryData,
    Person,
    RealWorldObject,
    Thing,
} from 'types/machineLearning';
import { IndexStatus } from 'types/machineLearning/ui';
import { runningInBrowser, runningInElectron } from 'utils/common';
import { addLogLine } from '@ente/shared/logging';
import { logError } from '@ente/shared/sentry';

export const ML_SYNC_JOB_CONFIG_NAME = 'ml-sync-job';
export const ML_SYNC_CONFIG_NAME = 'ml-sync';
export const ML_SEARCH_CONFIG_NAME = 'ml-search';

const MLDATA_DB_NAME = 'mldata';
interface MLDb extends DBSchema {
    files: {
        key: number;
        value: MlFileData;
        indexes: { mlVersion: [number, number] };
    };
    people: {
        key: number;
        value: Person;
    };
    things: {
        key: number;
        value: Thing;
    };
    versions: {
        key: string;
        value: number;
    };
    library: {
        key: string;
        value: MLLibraryData;
    };
    configs: {
        key: string;
        value: Config;
    };
}

class MLIDbStorage {
    public _db: Promise<IDBPDatabase<MLDb>>;

    constructor() {
        if (!runningInBrowser() || !runningInElectron()) {
            return;
        }

        this.db;
    }

    private openDB(): Promise<IDBPDatabase<MLDb>> {
        return openDB<MLDb>(MLDATA_DB_NAME, 3, {
            terminated: async () => {
                console.error('ML Indexed DB terminated');
                logError(new Error(), 'ML Indexed DB terminated');
                this._db = undefined;
                // TODO: remove if there is chance of this going into recursion in some case
                await this.db;
            },
            blocked() {
                // TODO: make sure we dont allow multiple tabs of app
                console.error('ML Indexed DB blocked');
                logError(new Error(), 'ML Indexed DB blocked');
            },
            blocking() {
                // TODO: make sure we dont allow multiple tabs of app
                console.error('ML Indexed DB blocking');
                logError(new Error(), 'ML Indexed DB blocking');
            },
            async upgrade(db, oldVersion, newVersion, tx) {
                if (oldVersion < 1) {
                    const filesStore = db.createObjectStore('files', {
                        keyPath: 'fileId',
                    });
                    filesStore.createIndex('mlVersion', [
                        'mlVersion',
                        'errorCount',
                    ]);

                    db.createObjectStore('people', {
                        keyPath: 'id',
                    });

                    db.createObjectStore('things', {
                        keyPath: 'id',
                    });

                    db.createObjectStore('versions');

                    db.createObjectStore('library');
                }
                if (oldVersion < 2) {
                    // TODO: update configs if version is updated in defaults
                    db.createObjectStore('configs');

                    await tx
                        .objectStore('configs')
                        .add(
                            DEFAULT_ML_SYNC_JOB_CONFIG,
                            ML_SYNC_JOB_CONFIG_NAME
                        );
                    await tx
                        .objectStore('configs')
                        .add(DEFAULT_ML_SYNC_CONFIG, ML_SYNC_CONFIG_NAME);
                }
                if (oldVersion < 3) {
                    await tx
                        .objectStore('configs')
                        .add(DEFAULT_ML_SEARCH_CONFIG, ML_SEARCH_CONFIG_NAME);
                }
                addLogLine(
                    `Ml DB upgraded to version: ${newVersion} from version: ${oldVersion}`
                );
            },
        });
    }

    public get db(): Promise<IDBPDatabase<MLDb>> {
        if (!this._db) {
            this._db = this.openDB();
            addLogLine('Opening Ml DB');
        }

        return this._db;
    }

    public async clearMLDB() {
        const db = await this.db;
        db.close();
        await deleteDB(MLDATA_DB_NAME);
        addLogLine('Cleared Ml DB');
        this._db = undefined;
        await this.db;
    }

    public async getAllFileIds() {
        const db = await this.db;
        return db.getAllKeys('files');
    }

    public async putAllFilesInTx(mlFiles: Array<MlFileData>) {
        const db = await this.db;
        const tx = db.transaction('files', 'readwrite');
        await Promise.all(mlFiles.map((mlFile) => tx.store.put(mlFile)));
        await tx.done;
    }

    public async removeAllFilesInTx(fileIds: Array<number>) {
        const db = await this.db;
        const tx = db.transaction('files', 'readwrite');

        await Promise.all(fileIds.map((fileId) => tx.store.delete(fileId)));
        await tx.done;
    }

    public async newTransaction<
        Name extends StoreNames<MLDb>,
        Mode extends IDBTransactionMode = 'readonly'
    >(storeNames: Name, mode?: Mode) {
        const db = await this.db;
        return db.transaction(storeNames, mode);
    }

    public async commit(tx: IDBPTransaction<MLDb>) {
        return tx.done;
    }

    public async getAllFileIdsForUpdate(
        tx: IDBPTransaction<MLDb, ['files'], 'readwrite'>
    ) {
        return tx.store.getAllKeys();
    }

    public async getFileIds(
        count: number,
        limitMlVersion: number,
        maxErrorCount: number
    ) {
        const db = await this.db;
        const tx = db.transaction('files', 'readonly');
        const index = tx.store.index('mlVersion');
        let cursor = await index.openKeyCursor(
            IDBKeyRange.upperBound([limitMlVersion], true)
        );

        const fileIds: number[] = [];
        while (cursor && fileIds.length < count) {
            if (
                cursor.key[0] < limitMlVersion &&
                cursor.key[1] <= maxErrorCount
            ) {
                fileIds.push(cursor.primaryKey);
            }
            cursor = await cursor.continue();
        }
        await tx.done;

        return fileIds;
    }

    public async getFile(fileId: number) {
        const db = await this.db;
        return db.get('files', fileId);
    }

    public async getAllFiles() {
        const db = await this.db;
        return db.getAll('files');
    }

    public async putFile(mlFile: MlFileData) {
        const db = await this.db;
        return db.put('files', mlFile);
    }

    public async upsertFileInTx(
        fileId: number,
        upsert: (mlFile: MlFileData) => MlFileData
    ) {
        const db = await this.db;
        const tx = db.transaction('files', 'readwrite');
        const existing = await tx.store.get(fileId);
        const updated = upsert(existing);
        await tx.store.put(updated);
        await tx.done;

        return updated;
    }

    public async putAllFiles(
        mlFiles: Array<MlFileData>,
        tx: IDBPTransaction<MLDb, ['files'], 'readwrite'>
    ) {
        await Promise.all(mlFiles.map((mlFile) => tx.store.put(mlFile)));
    }

    public async removeAllFiles(
        fileIds: Array<number>,
        tx: IDBPTransaction<MLDb, ['files'], 'readwrite'>
    ) {
        await Promise.all(fileIds.map((fileId) => tx.store.delete(fileId)));
    }

    public async getFace(fileID: number, faceId: string) {
        const file = await this.getFile(fileID);
        const face = file.faces.filter((f) => f.id === faceId);
        return face[0];
    }

    public async getAllFacesMap() {
        const startTime = Date.now();
        const db = await this.db;
        const allFiles = await db.getAll('files');
        const allFacesMap = new Map<number, Array<Face>>();
        allFiles.forEach(
            (mlFileData) =>
                mlFileData.faces &&
                allFacesMap.set(mlFileData.fileId, mlFileData.faces)
        );
        addLogLine('getAllFacesMap', Date.now() - startTime, 'ms');

        return allFacesMap;
    }

    public async updateFaces(allFacesMap: Map<number, Face[]>) {
        const startTime = Date.now();
        const db = await this.db;
        const tx = db.transaction('files', 'readwrite');
        let cursor = await tx.store.openCursor();
        while (cursor) {
            if (allFacesMap.has(cursor.key)) {
                const mlFileData = { ...cursor.value };
                mlFileData.faces = allFacesMap.get(cursor.key);
                cursor.update(mlFileData);
            }
            cursor = await cursor.continue();
        }
        await tx.done;
        addLogLine('updateFaces', Date.now() - startTime, 'ms');
    }

    public async getAllObjectsMap() {
        const startTime = Date.now();
        const db = await this.db;
        const allFiles = await db.getAll('files');
        const allObjectsMap = new Map<number, Array<RealWorldObject>>();
        allFiles.forEach(
            (mlFileData) =>
                mlFileData.objects &&
                allObjectsMap.set(mlFileData.fileId, mlFileData.objects)
        );
        addLogLine('allObjectsMap', Date.now() - startTime, 'ms');

        return allObjectsMap;
    }

    public async getPerson(id: number) {
        const db = await this.db;
        return db.get('people', id);
    }

    public async getAllPeople() {
        const db = await this.db;
        return db.getAll('people');
    }

    public async putPerson(person: Person) {
        const db = await this.db;
        return db.put('people', person);
    }

    public async clearAllPeople() {
        const db = await this.db;
        return db.clear('people');
    }

    public async getAllThings() {
        const db = await this.db;
        return db.getAll('things');
    }
    public async putThing(thing: Thing) {
        const db = await this.db;
        return db.put('things', thing);
    }

    public async clearAllThings() {
        const db = await this.db;
        return db.clear('things');
    }

    public async getIndexVersion(index: string) {
        const db = await this.db;
        return db.get('versions', index);
    }

    public async incrementIndexVersion(index: StoreNames<MLDb>) {
        if (index === 'versions') {
            throw new Error('versions store can not be versioned');
        }
        const db = await this.db;
        const tx = db.transaction(['versions', index], 'readwrite');
        let version = await tx.objectStore('versions').get(index);
        version = (version || 0) + 1;
        tx.objectStore('versions').put(version, index);
        await tx.done;

        return version;
    }

    public async setIndexVersion(index: string, version: number) {
        const db = await this.db;
        return db.put('versions', version, index);
    }

    public async getLibraryData() {
        const db = await this.db;
        return db.get('library', 'data');
    }

    public async putLibraryData(data: MLLibraryData) {
        const db = await this.db;
        return db.put('library', data, 'data');
    }

    public async getConfig<T extends Config>(name: string, def: T) {
        const db = await this.db;
        const tx = db.transaction('configs', 'readwrite');
        let config = (await tx.store.get(name)) as T;
        if (!config) {
            config = def;
            await tx.store.put(def, name);
        }
        await tx.done;

        return config;
    }

    public async putConfig(name: string, data: Config) {
        const db = await this.db;
        return db.put('configs', data, name);
    }

    public async getIndexStatus(latestMlVersion: number): Promise<IndexStatus> {
        const db = await this.db;
        const tx = db.transaction(['files', 'versions'], 'readonly');
        const mlVersionIdx = tx.objectStore('files').index('mlVersion');

        let outOfSyncCursor = await mlVersionIdx.openKeyCursor(
            IDBKeyRange.upperBound([latestMlVersion], true)
        );
        let outOfSyncFilesExists = false;
        while (outOfSyncCursor && !outOfSyncFilesExists) {
            if (
                outOfSyncCursor.key[0] < latestMlVersion &&
                outOfSyncCursor.key[1] <= MAX_ML_SYNC_ERROR_COUNT
            ) {
                outOfSyncFilesExists = true;
            }
            outOfSyncCursor = await outOfSyncCursor.continue();
        }

        const nSyncedFiles = await mlVersionIdx.count(
            IDBKeyRange.lowerBound([latestMlVersion])
        );
        const nTotalFiles = await mlVersionIdx.count();

        const filesIndexVersion = await tx.objectStore('versions').get('files');
        const peopleIndexVersion = await tx
            .objectStore('versions')
            .get('people');
        const filesIndexVersionExists =
            filesIndexVersion !== null && filesIndexVersion !== undefined;
        const peopleIndexVersionExists =
            peopleIndexVersion !== null && peopleIndexVersion !== undefined;

        await tx.done;

        return {
            outOfSyncFilesExists,
            nSyncedFiles,
            nTotalFiles,
            localFilesSynced: filesIndexVersionExists,
            peopleIndexSynced:
                peopleIndexVersionExists &&
                peopleIndexVersion === filesIndexVersion,
        };
    }

    // for debug purpose
    public async getAllMLData() {
        const db = await this.db;
        const tx = db.transaction(db.objectStoreNames, 'readonly');
        const allMLData: any = {};
        for (const store of tx.objectStoreNames) {
            const keys = await tx.objectStore(store).getAllKeys();
            const data = await tx.objectStore(store).getAll();

            allMLData[store] = {};
            for (let i = 0; i < keys.length; i++) {
                allMLData[store][keys[i]] = data[i];
            }
        }
        await tx.done;

        const files = allMLData['files'];
        for (const fileId of Object.keys(files)) {
            const fileData = files[fileId];
            fileData.faces?.forEach(
                (f) => (f.embedding = Array.from(f.embedding))
            );
        }

        return allMLData;
    }

    // for debug purpose, this will overwrite all data
    public async putAllMLData(allMLData: Map<string, any>) {
        const db = await this.db;
        const tx = db.transaction(db.objectStoreNames, 'readwrite');
        for (const store of tx.objectStoreNames) {
            const records = allMLData[store];
            if (!records) {
                continue;
            }
            const txStore = tx.objectStore(store);

            if (store === 'files') {
                const files = records;
                for (const fileId of Object.keys(files)) {
                    const fileData = files[fileId];
                    fileData.faces?.forEach(
                        (f) => (f.embedding = Float32Array.from(f.embedding))
                    );
                }
            }

            await txStore.clear();
            for (const key of Object.keys(records)) {
                if (txStore.keyPath) {
                    txStore.put(records[key]);
                } else {
                    txStore.put(records[key], key);
                }
            }
        }
        await tx.done;
    }
}

export default new MLIDbStorage();
