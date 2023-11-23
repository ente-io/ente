import { Face, MLSyncContext, Person } from 'types/machineLearning';
import { addLogLine } from '@ente/shared/logging';
import {
    isDifferentOrOld,
    getAllFacesFromMap,
    getLocalFile,
    findFirstIfSorted,
    getOriginalImageBitmap,
} from 'utils/machineLearning';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import FaceService from './faceService';

class PeopleService {
    async syncPeopleIndex(syncContext: MLSyncContext) {
        const filesVersion = await mlIDbStorage.getIndexVersion('files');
        if (
            filesVersion <= (await mlIDbStorage.getIndexVersion('people')) &&
            !isDifferentOrOld(
                syncContext.mlLibraryData?.faceClusteringMethod,
                syncContext.faceClusteringService.method
            )
        ) {
            addLogLine(
                '[MLService] Skipping people index as already synced to latest version'
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

        await mlIDbStorage.setIndexVersion('people', filesVersion);
    }

    private async syncPeopleFromClusters(
        syncContext: MLSyncContext,
        allFacesMap: Map<number, Array<Face>>,
        allFaces: Array<Face>
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
                (a, b) => b.detection.probability - a.detection.probability
            );

            if (personFace && !personFace.crop?.imageUrl) {
                const file = await getLocalFile(personFace.fileId);
                const imageBitmap = await getOriginalImageBitmap(
                    file,
                    syncContext.token
                );
                await FaceService.saveFaceCrop(
                    imageBitmap,
                    personFace,
                    syncContext
                );
            }

            const person: Person = {
                id: index,
                files: faces.map((f) => f.fileId),
                displayFaceId: personFace?.id,
                displayImageUrl: personFace?.crop?.imageUrl,
            };

            await mlIDbStorage.putPerson(person);

            faces.forEach((face) => {
                face.personId = person.id;
            });
            // addLogLine("Creating person: ", person, faces);
        }

        await mlIDbStorage.updateFaces(allFacesMap);
    }
}

export default new PeopleService();
