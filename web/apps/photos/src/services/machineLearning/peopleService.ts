import log from "@/next/log";
import { Face, MLSyncContext, Person } from "services/ml/types";
import { getLocalFile, getOriginalImageBitmap } from "utils/machineLearning";
import mlIDbStorage from "utils/storage/mlIDbStorage";
import FaceService, { isDifferentOrOld } from "./faceService";

class PeopleService {
    async syncPeopleIndex(syncContext: MLSyncContext) {
        const filesVersion = await mlIDbStorage.getIndexVersion("files");
        if (
            filesVersion <= (await mlIDbStorage.getIndexVersion("people")) &&
            !isDifferentOrOld(
                syncContext.mlLibraryData?.faceClusteringMethod,
                syncContext.faceClusteringService.method,
            )
        ) {
            log.info(
                "[MLService] Skipping people index as already synced to latest version",
            );
            return;
        }

        // TODO: have faces addresable through fileId + faceId
        // to avoid index based addressing, which is prone to wrong results
        // one way could be to match nearest face within threshold in the file
        const allFacesMap = await FaceService.getAllSyncedFacesMap(syncContext);
        const allFaces = getAllFacesFromMap(allFacesMap);

        await FaceService.runFaceClustering(syncContext, allFaces);
        await this.syncPeopleFromClusters(syncContext, allFacesMap, allFaces);

        await mlIDbStorage.setIndexVersion("people", filesVersion);
    }

    private async syncPeopleFromClusters(
        syncContext: MLSyncContext,
        allFacesMap: Map<number, Array<Face>>,
        allFaces: Array<Face>,
    ) {
        const clusters =
            syncContext.mlLibraryData.faceClusteringResults?.clusters;
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
            const personFace = findFirstIfSorted(
                faces,
                (a, b) => b.detection.probability - a.detection.probability,
            );

            if (personFace && !personFace.crop?.cacheKey) {
                const file = await getLocalFile(personFace.fileId);
                const imageBitmap = await getOriginalImageBitmap(file);
                await FaceService.saveFaceCrop(
                    imageBitmap,
                    personFace,
                    syncContext,
                );
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
    }
}

export default new PeopleService();

function findFirstIfSorted<T>(
    elements: Array<T>,
    comparator: (a: T, b: T) => number,
) {
    if (!elements || elements.length < 1) {
        return;
    }
    let first = elements[0];

    for (let i = 1; i < elements.length; i++) {
        const comp = comparator(elements[i], first);
        if (comp < 0) {
            first = elements[i];
        }
    }

    return first;
}

function getAllFacesFromMap(allFacesMap: Map<number, Array<Face>>) {
    const allFaces = [...allFacesMap.values()].flat();

    return allFaces;
}
