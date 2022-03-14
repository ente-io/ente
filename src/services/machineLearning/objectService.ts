import {
    MLSyncContext,
    MLSyncFileContext,
    DetectedObject,
    ThingClass,
} from 'types/machineLearning';
import {
    isDifferentOrOld,
    getObjectId,
    getAllThingsFromMap,
} from 'utils/machineLearning';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import ReaderService from './readerService';

class ObjectService {
    async syncFileObjectDetections(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext
    ) {
        const { oldMlFile, newMlFile } = fileContext;
        if (
            !isDifferentOrOld(
                oldMlFile?.objectDetectionMethod,
                syncContext.objectDetectionService.method
            ) &&
            oldMlFile?.imageSource === syncContext.config.imageSource
        ) {
            newMlFile.things = oldMlFile?.things?.map((existingObject) => ({
                id: existingObject.id,
                fileID: existingObject.fileID,
                detection: existingObject.detection,
            }));

            newMlFile.imageSource = oldMlFile.imageSource;
            newMlFile.imageDimensions = oldMlFile.imageDimensions;
            newMlFile.objectDetectionMethod = oldMlFile.objectDetectionMethod;
            return;
        }

        newMlFile.objectDetectionMethod =
            syncContext.objectDetectionService.method;
        fileContext.newDetection = true;
        const imageBitmap = await ReaderService.getImageBitmap(
            syncContext,
            fileContext
        );
        const objectDetections =
            await syncContext.objectDetectionService.detectObjects(imageBitmap);
        // console.log('3 TF Memory stats: ', tf.memory());
        // TODO: reenable faces filtering based on width
        const detectedObjects = objectDetections?.map((detection) => {
            return {
                fileID: fileContext.enteFile.id,
                detection,
            } as DetectedObject;
        });
        newMlFile.things = detectedObjects?.map((detectedObjects) => ({
            ...detectedObjects,
            id: getObjectId(detectedObjects, newMlFile.imageDimensions),
        }));
        // ?.filter((f) =>
        //     f.box.width > syncContext.config.faceDetection.minFaceSize
        // );
        console.log('[MLService] Detected Objects: ', newMlFile.things?.length);
    }

    public async getAllSyncedThingsMap() {
        return await mlIDbStorage.getAllThingsMap();
    }

    public async getThingClasses(): Promise<ThingClass[]> {
        const allObjectsMap = await this.getAllSyncedThingsMap();
        const allObjects = getAllThingsFromMap(allObjectsMap);
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
            className,
            files,
        }));
    }
}

export default new ObjectService();
