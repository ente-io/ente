import {
    openDB,
    deleteDB,
    DBSchema,
    IDBPDatabase,
    IDBPTransaction,
    StoreNames,
} from 'idb';
import { Face, MlFileData, MLLibraryData, Person } from 'types/machineLearning';
import { runningInBrowser } from 'utils/common';

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
    versions: {
        key: string;
        value: number;
    };
    library: {
        key: string;
        value: MLLibraryData;
    };
}

class MLIDbStorage {
    public db: Promise<IDBPDatabase<MLDb>>;

    constructor() {
        if (!runningInBrowser()) {
            return;
        }

        this.db = openDB<MLDb>('mldata', 1, {
            upgrade(db) {
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

                db.createObjectStore('versions');

                db.createObjectStore('library');
            },
        });
    }

    public async clearMLDB() {
        const db = await this.db;
        db.close();
        return deleteDB('mldata');
    }

    public async getAllFileIds1() {
        const db = await this.db;
        return db.getAllKeys('files');
    }

    public async putAllFiles1(mlFiles: Array<MlFileData>) {
        const db = await this.db;
        const tx = db.transaction('files', 'readwrite');
        await Promise.all(mlFiles.map((mlFile) => tx.store.put(mlFile)));
        await tx.done;
    }

    public async removeAllFiles1(fileIds: Array<number>) {
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

    public async putFile(mlFile: MlFileData) {
        const db = await this.db;
        return db.put('files', mlFile);
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

    public async getAllFacesMap() {
        console.time('getAllFacesMap');
        const db = await this.db;
        const allFiles = await db.getAll('files');
        const allFacesMap = new Map<number, Array<Face>>();
        allFiles.forEach(
            (mlFileData) =>
                mlFileData.faces &&
                allFacesMap.set(mlFileData.fileId, mlFileData.faces)
        );
        console.timeEnd('getAllFacesMap');

        return allFacesMap;
    }

    public async updateFaces(allFacesMap: Map<number, Face[]>) {
        console.time('updateFaces');
        const db = await this.db;
        const tx = db.transaction('files', 'readwrite');
        let cursor = await tx.store.openCursor();
        while (cursor) {
            const mlFileData = { ...cursor.value };
            mlFileData.faces = allFacesMap.get(cursor.key);
            cursor.update(mlFileData);
            cursor = await cursor.continue();
        }
        await tx.done;
        console.timeEnd('updateFaces');
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

    public async getIndexVersion(index: string) {
        const db = await this.db;
        return db.get('versions', index);
    }

    public async incrementIndexVersion(index: string) {
        const db = await this.db;
        const tx = db.transaction('versions', 'readwrite');
        let version = await tx.store.get(index);
        version = (version || 0) + 1;
        tx.store.put(version, index);
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
}

export default new MLIDbStorage();
