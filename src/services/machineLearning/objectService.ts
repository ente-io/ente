import {
    MLSyncContext,
    MLSyncFileContext,
    DetectedObject,
    Thing,
} from 'types/machineLearning';
import { addLogLine } from 'utils/logging';
import {
    isDifferentOrOld,
    getObjectId,
    getAllObjectsFromMap,
} from 'utils/machineLearning';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import ReaderService from './readerService';

class ObjectService {
    async syncFileObjectDetections(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext
    ) {
        const startTime = Date.now();
        const { oldMlFile, newMlFile } = fileContext;
        if (
            !isDifferentOrOld(
                oldMlFile?.objectDetectionMethod,
                syncContext.objectDetectionService.method
            ) &&
            !isDifferentOrOld(
                oldMlFile?.sceneDetectionMethod,
                syncContext.sceneDetectionService.method
            ) &&
            oldMlFile?.imageSource === syncContext.config.imageSource
        ) {
            newMlFile.objects = oldMlFile?.objects;
            newMlFile.imageSource = oldMlFile.imageSource;
            newMlFile.imageDimensions = oldMlFile.imageDimensions;
            newMlFile.objectDetectionMethod = oldMlFile.objectDetectionMethod;
            newMlFile.sceneDetectionMethod = oldMlFile.sceneDetectionMethod;
            return;
        }

        newMlFile.objectDetectionMethod =
            syncContext.objectDetectionService.method;
        newMlFile.sceneDetectionMethod =
            syncContext.sceneDetectionService.method;

        fileContext.newDetection = true;
        const imageBitmap = await ReaderService.getImageBitmap(
            syncContext,
            fileContext
        );
        const objectDetections =
            await syncContext.objectDetectionService.detectObjects(
                imageBitmap,
                syncContext.config.objectDetection.maxNumBoxes,
                syncContext.config.objectDetection.minScore
            );
        objectDetections.push(
            ...(await syncContext.sceneDetectionService.detectScenes(
                imageBitmap,
                syncContext.config.sceneDetection.minScore
            ))
        );
        // addLogLine('3 TF Memory stats: ',JSON.stringify(tf.memory()));
        // TODO: reenable faces filtering based on width
        const detectedObjects = objectDetections?.map((detection) => {
            return {
                fileID: fileContext.enteFile.id,
                detection,
            } as DetectedObject;
        });
        newMlFile.objects = detectedObjects?.map((detectedObject) => ({
            ...detectedObject,
            id: getObjectId(detectedObject, newMlFile.imageDimensions),
            className: detectedObject.detection.class,
        }));
        // ?.filter((f) =>
        //     f.box.width > syncContext.config.faceDetection.minFaceSize
        // );
        addLogLine(
            `object detection time taken ${fileContext.enteFile.id}`,
            Date.now() - startTime,
            'ms'
        );

        addLogLine('[MLService] Detected Objects: ', newMlFile.objects?.length);
    }

    async getAllSyncedObjectsMap(syncContext: MLSyncContext) {
        if (syncContext.allSyncedObjectsMap) {
            return syncContext.allSyncedObjectsMap;
        }

        syncContext.allSyncedObjectsMap = await mlIDbStorage.getAllObjectsMap();
        return syncContext.allSyncedObjectsMap;
    }

    public async clusterThings(syncContext: MLSyncContext): Promise<Thing[]> {
        const allObjectsMap = await this.getAllSyncedObjectsMap(syncContext);
        const allObjects = getAllObjectsFromMap(allObjectsMap);
        const objectClusters = new Map<string, number[]>();
        allObjects.map((object) => {
            if (!objectClusters.has(object.detection.class)) {
                objectClusters.set(object.detection.class, []);
            }
            const objectsInCluster = objectClusters.get(object.detection.class);
            objectsInCluster.push(object.fileID);
        });
        return [...objectClusters.entries()].map(([className, files], id) => ({
            id,
            name: className,
            files,
        }));
    }

    async syncThingsIndex(syncContext: MLSyncContext) {
        const filesVersion = await mlIDbStorage.getIndexVersion('files');
        addLogLine('things', await mlIDbStorage.getIndexVersion('things'));
        if (filesVersion <= (await mlIDbStorage.getIndexVersion('things'))) {
            addLogLine(
                '[MLService] Skipping people index as already synced to latest version'
            );
            return;
        }

        const things = await this.clusterThings(syncContext);

        if (!things || things.length < 1) {
            return;
        }

        await mlIDbStorage.clearAllThings();

        for (const thing of things) {
            await mlIDbStorage.putThing(thing);
        }

        await mlIDbStorage.setIndexVersion('things', filesVersion);
    }

    async getAllThings() {
        return await mlIDbStorage.getAllThings();
    }
}

export default new ObjectService();
