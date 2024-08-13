import type { EnteFile } from "../../types/file";

export interface Person {
    id: number;
    name?: string;
    files: number[];
    displayFaceID: string;
    displayFaceFile: EnteFile;
}

// Forced disable clustering. It doesn't currently work.
//
// > Error: Failed to execute 'transferToImageBitmap' on
// > 'OffscreenCanvas': ImageBitmap construction failed

/*
export const syncPeopleIndex = async () => {

        if (
            syncContext.outOfSyncFiles.length <= 0 ||
            (syncContext.nSyncedFiles === batchSize && Math.random() < 0)
        ) {
            await this.syncIndex(syncContext);
        }

        public async syncIndex(syncContext: MLSyncContext) {
            await this.getMLLibraryData(syncContext);

            await syncPeopleIndex(syncContext);

            await this.persistMLLibraryData(syncContext);
        }

    const filesVersion = await mlIDbStorage.getIndexVersion("files");
    if (filesVersion <= (await mlIDbStorage.getIndexVersion("people"))) {
        return;
    }



    // await this.init();

    const allFacesMap = await mlIDbStorage.getAllFacesMap();
    const allFaces = [...allFacesMap.values()].flat();

    if (!allFaces || allFaces.length < 50) {
        log.info(
            `Skipping clustering since number of faces (${allFaces.length}) is less than the clustering threshold (50)`,
        );
        return;
    }

    log.info("Running clustering allFaces: ", allFaces.length);
    const faceClusteringResults = await clusterFaces(
        allFaces.map((f) => Array.from(f.embedding)),
    );
    log.info(
        "[MLService] Got face clustering results: ",
        JSON.stringify(faceClusteringResults),
    );

    const clusters = faceClusteringResults?.clusters;
    if (!clusters || clusters.length < 1) {
        return;
    }

    for (const face of allFaces) {
        face.personId = undefined;
    }
    await mlIDbStorage.clearAllPeople();
    for (const [index, cluster] of clusters.entries()) {
        const faces = cluster.map((f) => allFaces[f]).filter((f) => f);


        await mlIDbStorage.putPerson(person);

        faces.forEach((face) => {
            face.personId = person.id;
        });

    }

    await mlIDbStorage.updateFaces(allFacesMap);

    // await mlIDbStorage.setIndexVersion("people", filesVersion);
};

*/
