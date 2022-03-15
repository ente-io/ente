import {
    MLSyncContext,
    MLSyncFileContext,
    DetectedText,
} from 'types/machineLearning';
import { imageBitmapToBlob } from 'utils/image';
import { isDifferentOrOld, getAllTextFromMap } from 'utils/machineLearning';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import ReaderService from './readerService';

class TextService {
    async syncFileTextDetections(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext
    ) {
        const { oldMlFile, newMlFile } = fileContext;
        if (
            !isDifferentOrOld(
                oldMlFile?.textDetectionMethod,
                syncContext.textDetectionService.method
            ) &&
            oldMlFile?.imageSource === syncContext.config.imageSource
        ) {
            newMlFile.text = oldMlFile?.text;
            newMlFile.imageSource = oldMlFile.imageSource;
            newMlFile.imageDimensions = oldMlFile.imageDimensions;
            newMlFile.textDetectionMethod = oldMlFile.textDetectionMethod;
            return;
        }

        newMlFile.textDetectionMethod = syncContext.textDetectionService.method;
        fileContext.newDetection = true;
        const imageBitmap = await ReaderService.getImageBitmap(
            syncContext,
            fileContext
        );
        const textDetections =
            await syncContext.textDetectionService.detectText(
                await imageBitmapToBlob(imageBitmap)
            );
        // console.log('3 TF Memory stats: ', tf.memory());
        // TODO: reenable faces filtering based on width
        const detectedText: DetectedText = {
            fileID: fileContext.enteFile.id,
            detection: textDetections,
        };
        newMlFile.text = detectedText;
        // ?.filter((f) =>
        //     f.box.width > syncContext.config.faceDetection.minFaceSize
        // );
        console.log('[MLService] Detected text: ', newMlFile.text);
    }

    async getAllSyncedTextMap(syncContext: MLSyncContext) {
        if (syncContext.allSyncedTextMap) {
            return syncContext.allSyncedTextMap;
        }

        syncContext.allSyncedTextMap = await mlIDbStorage.getAllTextMap();
        return syncContext.allSyncedTextMap;
    }

    public async getAllText() {
        const allTextMap = await mlIDbStorage.getAllTextMap();
        const allText = getAllTextFromMap(allTextMap);
        return allText;
    }

    // public async clusterThingClasses(
    //     syncContext: MLSyncContext
    // ): Promise<ThingClass[]> {
    //     const allTextMap = await this.getAllSyncedTextMap(syncContext);
    //     const allText = getAllTextFromMap(allTextMap);
    //     const textCluster = new Map<string, number[]>();
    //     allObjects.map((object) => {
    //         if (!objectClusters.has(object.detection.class)) {
    //             objectClusters.set(object.detection.class, []);
    //         }
    //         const objectsInCluster = objectClusters.get(object.detection.class);
    //         objectsInCluster.push(object.fileID);
    //     });
    //     return [...objectClusters.entries()].map(([className, files], id) => ({
    //         id,
    //         className,
    //         files,
    //     }));
    // }

    // async syncThingClassesIndex(syncContext: MLSyncContext) {
    //     const filesVersion = await mlIDbStorage.getIndexVersion('files');
    //     console.log(
    //         'thingClasses',
    //         await mlIDbStorage.getIndexVersion('thingClasses')
    //     );
    //     if (
    //         filesVersion <= (await mlIDbStorage.getIndexVersion('thingClasses'))
    //     ) {
    //         console.log(
    //             '[MLService] Skipping people index as already synced to latest version'
    //         );
    //         return;
    //     }

    //     const thingClasses = await this.clusterThingClasses(syncContext);

    //     if (!thingClasses || thingClasses.length < 1) {
    //         return;
    //     }

    //     await mlIDbStorage.clearAllThingClasses();

    //     for (const thingClass of thingClasses) {
    //         await mlIDbStorage.putThingClass(thingClass);
    //     }

    //     await mlIDbStorage.setIndexVersion('thingClasses', filesVersion);
    // }

    // async getAllThingClasses() {
    //     return await mlIDbStorage.getAllThingClasses();
    // }
}

export default new TextService();
