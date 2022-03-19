import {
    TextDetectionMethod,
    TextDetectionService,
    Versioned,
} from 'types/machineLearning';

import Tesseract, { createWorker, RecognizeResult } from 'tesseract.js';

class TesseractService implements TextDetectionService {
    private tesseractWorker: Tesseract.Worker;
    public method: Versioned<TextDetectionMethod>;
    private ready: Promise<void>;
    public constructor() {
        this.method = {
            value: 'Tesseract',
            version: 1,
        };
    }

    private async init() {
        this.tesseractWorker = createWorker({
            logger: (m) => console.log(m),
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

    async detectText(image: Blob): Promise<RecognizeResult> {
        console.log('tesseract detectText');
        const dummyFile = new File([image], 'dummy.jpg');
        const tesseractWorker = await this.getTesseractWorker();
        const detections = await tesseractWorker.recognize(dummyFile);
        console.log('tesseract detectedText', detections);

        return detections;
    }

    public async dispose() {
        const tesseractWorker = await this.getTesseractWorker();
        tesseractWorker?.terminate();
        this.tesseractWorker = null;
    }
}

export default new TesseractService();
