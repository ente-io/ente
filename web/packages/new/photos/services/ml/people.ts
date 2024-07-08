export interface Person {
    id: number;
    name?: string;
    files: number[];
    displayFaceId?: string;
}

// TODO-ML(MR): Forced disable clustering. It doesn't currently work,
// need to finalize it before we move out of beta.
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


    // TODO: have faces addresable through fileId + faceId
    // to avoid index based addressing, which is prone to wrong results
    // one way could be to match nearest face within threshold in the file

    const allFacesMap =
        syncContext.allSyncedFacesMap ??
        (syncContext.allSyncedFacesMap = await mlIDbStorage.getAllFacesMap());


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

        // TODO: take default display face from last leaves of hdbscan clusters
        const personFace = faces.reduce((best, face) =>
            face.detection.probability > best.detection.probability
                ? face
                : best,
        );

export async function getLocalFile(fileId: number) {
    const localFiles = await getLocalFiles();
    return localFiles.find((f) => f.id === fileId);
}

        if (personFace && !personFace.crop?.cacheKey) {
            const file = await getLocalFile(personFace.fileId);
            const imageBitmap = await fetchImageBitmap(file);
            await saveFaceCrop(imageBitmap, personFace);
        }


        const person: Person = {
            id: index,
            files: faces.map((f) => f.fileId),
            displayFaceId: personFace?.id,
        };

        await mlIDbStorage.putPerson(person);

        faces.forEach((face) => {
            face.personId = person.id;
        });
        // log.info("Creating person: ", person, faces);
    }

    await mlIDbStorage.updateFaces(allFacesMap);

    // await mlIDbStorage.setIndexVersion("people", filesVersion);
};

    public async regenerateFaceCrop(token: string, faceID: string) {
        await downloadManager.init(APPS.PHOTOS, { token });
        return mlService.regenerateFaceCrop(faceID);
    }

export const regenerateFaceCrop = async (faceID: string) => {
    const fileID = Number(faceID.split("-")[0]);
    const personFace = await mlIDbStorage.getFace(fileID, faceID);
    if (!personFace) {
        throw Error("Face not found");
    }

    const file = await getLocalFile(personFace.fileId);
    const imageBitmap = await fetchImageBitmap(file);
    return await saveFaceCrop(imageBitmap, personFace);
};
*/
