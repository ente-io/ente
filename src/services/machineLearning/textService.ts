import {
    MLSyncContext,
    MLSyncFileContext,
    DetectedText,
    WordGroup,
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
        const imageBitmap: ImageBitmap = await ReaderService.getImageBitmap(
            syncContext,
            fileContext
        );
        if (
            !(
                (imageBitmap.width >= 44 && imageBitmap.height >= 20) ||
                (imageBitmap.width >= 20 && imageBitmap.height >= 44)
            )
        ) {
            return;
        }

        console.time('detecting text ' + fileContext.enteFile.id);
        const textDetections =
            await syncContext.textDetectionService.detectText(
                new File(
                    [await imageBitmapToBlob(imageBitmap)],
                    fileContext.enteFile.id.toString()
                )
            );
        console.timeEnd('detecting text ' + fileContext.enteFile.id);

        const detectedText: DetectedText[] = textDetections.data.words
            .filter(
                ({ confidence }) =>
                    confidence >= syncContext.config.textDetection.minAccuracy
            )
            .map(({ bbox, confidence, text }) => ({
                fileID: fileContext.enteFile.id,
                detection: { bbox, confidence, word: text.toLocaleLowerCase() },
            }));
        newMlFile.text = detectedText;
        console.log(
            '[MLService] Detected text: ',
            fileContext.enteFile.metadata.title,
            newMlFile.text
        );
    }

    async getAllSyncedTextMap(syncContext: MLSyncContext) {
        if (syncContext.allSyncedTextMap) {
            return syncContext.allSyncedTextMap;
        }

        syncContext.allSyncedTextMap = await mlIDbStorage.getAllTextMap();
        return syncContext.allSyncedTextMap;
    }

    public async clusterWords(): Promise<WordGroup[]> {
        const allTextMap = await mlIDbStorage.getAllTextMap();
        const allText = getAllTextFromMap(allTextMap);
        const textCluster = new Map<string, number[]>();
        allText.map((text) => {
            if (!textCluster.has(text.detection.word)) {
                textCluster.set(text.detection.word, []);
            }
            const objectsInCluster = textCluster.get(text.detection.word);
            objectsInCluster.push(text.fileID);
        });
        return [...textCluster.entries()]
            .map(([word, files]) => ({
                word,
                files,
            }))
            .sort((a, b) => b.files.length - a.files.length);
    }

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
