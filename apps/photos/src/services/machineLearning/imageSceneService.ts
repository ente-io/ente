import { addLogLine } from "@ente/shared/logging";
import * as tfjsConverter from "@tensorflow/tfjs-converter";
import * as tf from "@tensorflow/tfjs-core";
import { SCENE_DETECTION_IMAGE_SIZE } from "constants/mlConfig";
import {
    ObjectDetection,
    SceneDetectionMethod,
    SceneDetectionService,
    Versioned,
} from "types/machineLearning";
import { resizeToSquare } from "utils/image";

class ImageScene implements SceneDetectionService {
    method: Versioned<SceneDetectionMethod>;
    private model: tfjsConverter.GraphModel;
    private sceneMap: { [key: string]: string };
    private ready: Promise<void>;
    private workerID: number;

    public constructor() {
        this.method = {
            value: "ImageScene",
            version: 1,
        };
        this.workerID = Math.round(Math.random() * 1000);
    }

    private async init() {
        addLogLine(`[${this.workerID}]`, "ImageScene init called");
        if (this.model) {
            return;
        }

        this.sceneMap = await (
            await fetch("/models/imagescene/sceneMap.json")
        ).json();

        this.model = await tfjsConverter.loadGraphModel(
            "/models/imagescene/model.json",
        );
        addLogLine(
            `[${this.workerID}]`,
            "loaded ImageScene model",
            tf.getBackend(),
        );

        tf.tidy(() => {
            const zeroTensor = tf.zeros([1, 224, 224, 3]);
            // warmup the model
            this.model.predict(zeroTensor) as tf.Tensor;
        });
    }

    private async getImageSceneModel() {
        addLogLine(
            `[${this.workerID}]`,
            "ImageScene getImageSceneModel called",
        );
        if (!this.ready) {
            this.ready = this.init();
        }
        await this.ready;
        return this.model;
    }

    async detectScenes(image: ImageBitmap, minScore: number) {
        const resized = resizeToSquare(image, SCENE_DETECTION_IMAGE_SIZE);

        const model = await this.getImageSceneModel();

        const output = tf.tidy(() => {
            const tfImage = tf.browser.fromPixels(resized.image);
            const input = tf.expandDims(tf.cast(tfImage, "float32"));
            const output = model.predict(input) as tf.Tensor;
            return output;
        });

        const data = (await output.data()) as Float32Array;
        output.dispose();

        const scenes = this.parseSceneDetectionResult(
            data,
            minScore,
            image.width,
            image.height,
        );

        return scenes;
    }

    private parseSceneDetectionResult(
        outputData: Float32Array,
        minScore: number,
        width: number,
        height: number,
    ): ObjectDetection[] {
        const scenes = [];
        for (let i = 0; i < outputData.length; i++) {
            if (outputData[i] >= minScore) {
                scenes.push({
                    class: this.sceneMap[i.toString()],
                    score: outputData[i],
                    bbox: [0, 0, width, height],
                });
            }
        }
        return scenes;
    }
}

export default new ImageScene();
