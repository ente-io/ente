import {
    TextDetectionMethod,
    TextDetectionService,
    Versioned,
} from 'types/machineLearning';

import Tesseract, { createWorker, RecognizeResult } from 'tesseract.js';
import QueueProcessor from 'services/queueProcessor';
import { CustomError } from 'utils/error';

class TesseractService implements TextDetectionService {
    private tesseractWorker: Tesseract.Worker;
    public method: Versioned<TextDetectionMethod>;
    private ready: Promise<void>;
    private textDetector = new QueueProcessor<Tesseract.RecognizeResult>(1);
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
        console.log('loaded tesseract worker');
    }

    private async getTesseractWorker() {
        if (!this.tesseractWorker) {
            this.ready = this.init();
        }

        await this.ready;

        return this.tesseractWorker;
    }

    async detectText(image: File): Promise<RecognizeResult> {
        const response = this.textDetector.queueUpRequest(async () => {
            console.log('tesseract detectText');
            const tesseractWorker = await this.getTesseractWorker();
            const detections = await tesseractWorker.recognize(image);
            console.log('tesseract detectedText', detections);

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
