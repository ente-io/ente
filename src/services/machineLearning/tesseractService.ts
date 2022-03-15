import {
    TextDetectionMethod,
    TextDetectionService,
    Versioned,
} from 'types/machineLearning';

import Tesseract, { createWorker, RecognizeResult } from 'tesseract.js';

class TesseractService implements TextDetectionService {
    private tesseractWorker: Tesseract.Worker;
    public method: Versioned<TextDetectionMethod>;

    public constructor() {
        this.method = {
            value: 'Tesseract',
            version: 1,
        };
    }

    private async init() {
        this.tesseractWorker = createWorker({
            logger: (m) => console.log(m),
        });
        await this.tesseractWorker.load();
        await this.tesseractWorker.loadLanguage('eng');
        await this.tesseractWorker.initialize('eng');
        console.log('loaded tesseract worker', this.tesseractWorker);
    }

    private async getTesseractWorker() {
        if (!this.tesseractWorker) {
            await this.init();
        }

        return this.tesseractWorker;
    }

    async detectText(image: Blob): Promise<RecognizeResult> {
        console.log('tesseract detectText');

        const tesseractWorker = await this.getTesseractWorker();
        const detections = await tesseractWorker.recognize(image);
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
