import {
    TESSERACT_MAX_IMAGE_DIMENSION,
    TESSERACT_MIN_IMAGE_HEIGHT,
    TESSERACT_MIN_IMAGE_WIDTH,
    TextDetectionMethod,
    TextDetectionService,
    Versioned,
} from 'types/machineLearning';

import Tesseract, { createWorker, RecognizeResult } from 'tesseract.js';
import QueueProcessor from 'services/queueProcessor';
import { CustomError } from 'utils/error';
import { imageBitmapToBlob, resizeToSquare } from 'utils/image';
import { getFileType } from 'services/upload/readFileService';
import { FILE_TYPE } from 'constants/file';

class TesseractService implements TextDetectionService {
    private tesseractWorker: Tesseract.Worker;
    public method: Versioned<TextDetectionMethod>;
    private ready: Promise<void>;
    private textDetector = new QueueProcessor<
        Tesseract.RecognizeResult | Error
    >(1);
    public constructor() {
        this.method = {
            value: 'Tesseract',
            version: 1,
        };
    }

    private async init() {
        this.tesseractWorker = createWorker({
            workerBlobURL: false,
            workerPath: '/js/tesseract/worker.min.js',
            corePath: '/js/tesseract/tesseract-core.wasm.js',
        });
        await this.tesseractWorker.load();
        await this.tesseractWorker.loadLanguage('eng');
        await this.tesseractWorker.initialize('eng');
        await this.tesseractWorker.setParameters({
            tessedit_char_whitelist:
                '0123456789' +
                'abcdefghijklmnopqrstuvwxyz' +
                'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
                ' ',
            preserve_interword_spaces: '1',
        });
        console.log('loaded tesseract worker');
    }

    private async getTesseractWorker() {
        if (!this.tesseractWorker) {
            this.ready = this.init();
        }

        await this.ready;

        return this.tesseractWorker;
    }

    async detectText(
        imageBitmap: ImageBitmap
    ): Promise<RecognizeResult | Error> {
        const response = this.textDetector.queueUpRequest(async () => {
            const imageHeight = Math.min(imageBitmap.width, imageBitmap.height);
            const imageWidth = Math.max(imageBitmap.width, imageBitmap.height);
            if (
                !(
                    imageWidth >= TESSERACT_MIN_IMAGE_WIDTH &&
                    imageHeight >= TESSERACT_MIN_IMAGE_HEIGHT
                )
            ) {
                console.log(
                    `file too small for tesseract- (${imageWidth},${imageHeight}) skipping text detection...`
                );
                return Error(
                    `file too small for tesseract- (${imageWidth},${imageHeight}) skipping text detection...`
                );
            }
            if (imageHeight > TESSERACT_MAX_IMAGE_DIMENSION) {
                imageBitmap = resizeToSquare(
                    imageBitmap,
                    TESSERACT_MAX_IMAGE_DIMENSION
                ).image;
            }
            const file = new File(
                [await imageBitmapToBlob(imageBitmap)],
                'text-detection-dummy-image'
            );
            const fileTypeInfo = await getFileType(new FileReader(), file);

            if (
                fileTypeInfo.fileType !== FILE_TYPE.IMAGE &&
                !['png', 'jpg', 'bmp', 'pbm'].includes(fileTypeInfo.exactType)
            ) {
                console.log(
                    `unsupported file type- ${fileTypeInfo.exactType}, skipping text detection....`
                );
                return Error(
                    `unsupported file type- ${fileTypeInfo.exactType}, skipping text detection....`
                );
            }

            const tesseractWorker = await this.getTesseractWorker();
            const detections = await tesseractWorker.recognize(file);

            return detections;
        });
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

    public async dispose() {
        const tesseractWorker = await this.getTesseractWorker();
        tesseractWorker?.terminate();
        this.tesseractWorker = null;
    }
}

export default new TesseractService();
