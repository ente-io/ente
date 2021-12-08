import TSNE from 'tsne-js';
import { TSNEConfig, TSNEData } from 'types/machineLearning';

export function toD3Tsne(tsne) {
    const data: TSNEData = {
        width: 800,
        height: 800,
        dataset: [],
    };
    data.dataset = tsne.map((t) => {
        return {
            x: (data.width * (t[0] + 1.0)) / 2,
            y: (data.height * (t[1] + 1.0)) / 2,
        };
    });

    return data;
}

export function toTSNE(denseInput: Array<Array<number>>, config: TSNEConfig) {
    if (!denseInput || denseInput.length < 1) {
        return null;
    }

    const model = new TSNE(config);

    model.init({
        data: denseInput,
        type: 'dense',
    });

    // `error`,  `iter`: final error and iteration number
    // note: computation-heavy action happens here
    model.run();

    // `outputScaled` is `output` scaled to a range of [-1, 1]
    return model.getOutputScaled();
}
