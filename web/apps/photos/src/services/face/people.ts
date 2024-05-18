import log from "@/next/log";
import mlIDbStorage from "services/face/db";
import { Face, Person } from "services/face/types";
import { type MLSyncContext } from "services/machineLearning/machineLearningService";
import { clusterFaces } from "./cluster";
import { saveFaceCrop } from "./f-index";
import { fetchImageBitmap, getLocalFile } from "./image";

export const syncPeopleIndex = async (syncContext: MLSyncContext) => {
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
    const allFaces = [...allFacesMap.values()].flat();

    await runFaceClustering(syncContext, allFaces);
    await syncPeopleFromClusters(syncContext, allFacesMap, allFaces);

    await mlIDbStorage.setIndexVersion("people", filesVersion);
};

const runFaceClustering = async (
    syncContext: MLSyncContext,
    allFaces: Array<Face>,
) => {
    // await this.init();

    if (!allFaces || allFaces.length < 50) {
        log.info(
            `Skipping clustering since number of faces (${allFaces.length}) is less than the clustering threshold (50)`,
        );
        return;
    }

    log.info("Running clustering allFaces: ", allFaces.length);
    syncContext.mlLibraryData.faceClusteringResults = await clusterFaces(
        allFaces.map((f) => Array.from(f.embedding)),
    );
    log.info(
        "[MLService] Got face clustering results: ",
        JSON.stringify(syncContext.mlLibraryData.faceClusteringResults),
    );
};

const syncPeopleFromClusters = async (
    syncContext: MLSyncContext,
    allFacesMap: Map<number, Array<Face>>,
    allFaces: Array<Face>,
) => {
    const clusters = syncContext.mlLibraryData.faceClusteringResults?.clusters;
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

        if (personFace && !personFace.crop?.cacheKey) {
            const file = await getLocalFile(personFace.fileId);
            const imageBitmap = await fetchImageBitmap(file);
            await saveFaceCrop(imageBitmap, personFace);
        }

        const person: Person = {
            id: index,
            files: faces.map((f) => f.fileId),
            displayFaceId: personFace?.id,
            faceCropCacheKey: personFace?.crop?.cacheKey,
        };

        await mlIDbStorage.putPerson(person);

        faces.forEach((face) => {
            face.personId = person.id;
        });
        // log.info("Creating person: ", person, faces);
    }

    await mlIDbStorage.updateFaces(allFacesMap);
};
