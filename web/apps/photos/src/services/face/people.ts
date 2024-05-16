import mlIDbStorage from "services/face/db";
import { Face, MLSyncContext, Person } from "services/face/types";
import {
    getAllSyncedFacesMap,
    runFaceClustering,
    saveFaceCrop,
} from "./f-index";
import { fetchImageBitmap, getLocalFile } from "./image";

export const syncPeopleIndex = async (syncContext: MLSyncContext) => {
    const filesVersion = await mlIDbStorage.getIndexVersion("files");
    if (filesVersion <= (await mlIDbStorage.getIndexVersion("people"))) {
        return;
    }

    // TODO: have faces addresable through fileId + faceId
    // to avoid index based addressing, which is prone to wrong results
    // one way could be to match nearest face within threshold in the file
    const allFacesMap = await getAllSyncedFacesMap(syncContext);
    const allFaces = [...allFacesMap.values()].flat();

    await runFaceClustering(syncContext, allFaces);
    await syncPeopleFromClusters(syncContext, allFacesMap, allFaces);

    await mlIDbStorage.setIndexVersion("people", filesVersion);
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
