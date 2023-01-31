import {
    MLSyncContext,
    MLSyncFileContext,
    DetectedText,
    WordGroup,
} from 'types/machineLearning';
import { addLogLine } from 'utils/logging';
import { isDifferentOrOld, getAllTextFromMap } from 'utils/machineLearning';
import mlIDbStorage from 'utils/storage/mlIDbStorage';
import ReaderService from './readerService';

class TextService {
    async syncFileTextDetections(
        syncContext: MLSyncContext,
        fileContext: MLSyncFileContext,
        textDetectionTimeoutIndex?: number
    ) {
        const startTime = Date.now();
        const { oldMlFile, newMlFile } = fileContext;
        if (
            !isDifferentOrOld(
                oldMlFile?.textDetectionMethod,
                syncContext.textDetectionService.method
            ) &&
            oldMlFile?.imageSource === syncContext.config.imageSource &&
            oldMlFile?.lastErrorMessage === null
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

        const textDetections =
            await syncContext.textDetectionService.detectText(
                imageBitmap,
                syncContext.config.textDetection.minAccuracy,
                oldMlFile?.errorCount ?? textDetectionTimeoutIndex ?? 0
            );
        if (textDetections instanceof Error) {
            addLogLine(
                `text detection time taken ${fileContext.enteFile.id}`,
                Date.now() - startTime,
                'ms'
            );

            newMlFile.errorCount = 2;
            newMlFile.lastErrorMessage = textDetections.message;
            return;
        }
        const detectedText: DetectedText[] = textDetections.map(
            ({ bbox, confidence, text }) => ({
                fileID: fileContext.enteFile.id,
                detection: { bbox, confidence, word: text.toLocaleLowerCase() },
            })
        );
        newMlFile.text = detectedText;
        addLogLine(
            `text detection time taken ${fileContext.enteFile.id}`,
            Date.now() - startTime,
            'ms'
        );
        addLogLine(
            '[MLService] Detected text: ',
            fileContext.enteFile.metadata.title,
            newMlFile.text?.length
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
    //     addLogLine(
    //         'thingClasses',
    //         await mlIDbStorage.getIndexVersion('thingClasses')
    //     );
    //     if (
    //         filesVersion <= (await mlIDbStorage.getIndexVersion('thingClasses'))
    //     ) {
    //         addLogLine(
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
