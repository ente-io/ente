import {
    TextDetectionMethod,
    TextDetectionService,
    Versioned,
} from 'types/machineLearning';

import Tesseract, { createWorker } from 'tesseract.js';
import QueueProcessor from 'services/queueProcessor';
import { CustomError } from 'utils/error';
import { imageBitmapToBlob, resizeToSquare } from 'utils/image';
import { getFileType } from 'services/typeDetectionService';
import { FILE_TYPE } from 'constants/file';
import { makeID } from 'utils/user';
import {
    TESSERACT_MAX_IMAGE_DIMENSION,
    TESSERACT_MIN_IMAGE_HEIGHT,
    TESSERACT_MIN_IMAGE_WIDTH,
    TEXT_DETECTION_TIMEOUT_MS,
} from 'constants/machineLearning/config';
import { promiseWithTimeout } from 'utils/common/promiseTimeout';
import { addLogLine } from 'utils/logging';

const TESSERACT_MAX_CONCURRENT_PROCESSES = 4;
class TesseractService implements TextDetectionService {
    public method: Versioned<TextDetectionMethod>;
    private ready: Promise<void>;
    private textDetector = new QueueProcessor<Tesseract.Word[] | Error>(
        TESSERACT_MAX_CONCURRENT_PROCESSES
    );
    private tesseractWorkerPool = new Array<Tesseract.Worker>(
        TESSERACT_MAX_CONCURRENT_PROCESSES
    );
    public constructor() {
        this.method = {
            value: 'Tesseract',
            version: 1,
        };
    }

    private async createTesseractWorker() {
        const tesseractWorker = createWorker({
            workerBlobURL: false,
            workerPath: '/js/tesseract/worker.min.js',
            corePath: '/js/tesseract/tesseract-core.wasm.js',
        });
        await tesseractWorker.load();
        await tesseractWorker.loadLanguage('eng');
        await tesseractWorker.initialize('eng');
        await tesseractWorker.setParameters({
            tessedit_char_whitelist:
                '0123456789' +
                'abcdefghijklmnopqrstuvwxyz' +
                'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
                ' ',
            preserve_interword_spaces: '1',
        });
        return tesseractWorker;
    }

    private async init() {
        for (let i = 0; i < TESSERACT_MAX_CONCURRENT_PROCESSES; i++) {
            this.tesseractWorkerPool[i] = await this.createTesseractWorker();
            addLogLine('loaded tesseract worker no', i);
        }
        addLogLine('loaded tesseract worker pool');
    }

    private async getTesseractWorker() {
        if (!this.ready && typeof this.tesseractWorkerPool[0] === 'undefined') {
            this.ready = this.init();
        }
        await this.ready;
        return this.tesseractWorkerPool.shift();
    }

    private releaseWorker(tesseractWorker: Tesseract.Worker) {
        this.tesseractWorkerPool.push(tesseractWorker);
    }

    async detectText(
        imageBitmap: ImageBitmap,
        minAccuracy: number,
        attemptNumber: number
    ): Promise<Tesseract.Word[] | Error> {
        const response = this.textDetector.queueUpRequest(() =>
            this.detectTextUsingModel(imageBitmap, minAccuracy, attemptNumber)
        );
        try {
            return await response.promise;
        } catch (e) {
            if (e.message === CustomError.REQUEST_CANCELLED) {
                // ignore
                return null;
            } else {
                throw e;
            }
        }
    }

    private detectTextUsingModel = async (
        imageBitmap: ImageBitmap,
        minAccuracy: number,
        attemptNumber: number
    ) => {
        const imageHeight = Math.min(imageBitmap.width, imageBitmap.height);
        const imageWidth = Math.max(imageBitmap.width, imageBitmap.height);
        if (
            !(
                imageWidth >= TESSERACT_MIN_IMAGE_WIDTH &&
                imageHeight >= TESSERACT_MIN_IMAGE_HEIGHT
            )
        ) {
            addLogLine(
                `file too small for tesseract- (${imageWidth},${imageHeight}) skipping text detection...`
            );
            return Error(
                `file too small for tesseract- (${imageWidth},${imageHeight}) skipping text detection...`
            );
        }
        if (imageHeight > TESSERACT_MAX_IMAGE_DIMENSION) {
            addLogLine(
                `original dimension (${imageBitmap.width}px,${imageBitmap.height}px)`
            );
            imageBitmap = resizeToSquare(
                imageBitmap,
                TESSERACT_MAX_IMAGE_DIMENSION
            ).image;
        }
        const file = new File(
            [await imageBitmapToBlob(imageBitmap)],
            'text-detection-dummy-image'
        );
        const fileTypeInfo = await getFileType(file);

        if (
            fileTypeInfo.fileType !== FILE_TYPE.IMAGE &&
            !['png', 'jpg', 'bmp', 'pbm'].includes(fileTypeInfo.exactType)
        ) {
            addLogLine(
                `unsupported file type- ${fileTypeInfo.exactType}, skipping text detection....`
            );
            return Error(
                `unsupported file type- ${fileTypeInfo.exactType}, skipping text detection....`
            );
        }

        let tesseractWorker = await this.getTesseractWorker();
        const id = makeID(6);
        addLogLine(
            `detecting text (${imageBitmap.width}px,${imageBitmap.height}px) fileType=${fileTypeInfo.exactType}`
        );
        try {
            console.time('detecting text ' + id);
            const detections = (await promiseWithTimeout(
                tesseractWorker.recognize(file),
                TEXT_DETECTION_TIMEOUT_MS[attemptNumber]
            )) as Tesseract.RecognizeResult;
            console.timeEnd('detecting text ' + id);
            const filteredDetections = detections.data.words.filter(
                ({ confidence }) => confidence >= minAccuracy
            );
            return filteredDetections;
        } catch (e) {
            if (e.message === CustomError.WAIT_TIME_EXCEEDED) {
                tesseractWorker?.terminate();
                tesseractWorker = await this.createTesseractWorker();
            }
            throw e;
        } finally {
            this.releaseWorker(tesseractWorker);
        }
    };

    public replaceWorkerWithNewOne() {}

    public async dispose() {
        for (let i = 0; i < TESSERACT_MAX_CONCURRENT_PROCESSES; i++) {
            this.tesseractWorkerPool[i]?.terminate();
            this.tesseractWorkerPool[i] = undefined;
        }
    }
}

export default new TesseractService();
