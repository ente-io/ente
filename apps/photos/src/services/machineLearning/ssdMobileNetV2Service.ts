import * as tf from "@tensorflow/tfjs-core";
import {
    ObjectDetection,
    ObjectDetectionMethod,
    ObjectDetectionService,
    Versioned,
} from "types/machineLearning";

import { addLogLine } from "@ente/shared/logging";
import * as SSDMobileNet from "@tensorflow-models/coco-ssd";
import { OBJECT_DETECTION_IMAGE_SIZE } from "constants/mlConfig";
import { resizeToSquare } from "utils/image";

class SSDMobileNetV2 implements ObjectDetectionService {
    private ssdMobileNetV2Model: SSDMobileNet.ObjectDetection;
    public method: Versioned<ObjectDetectionMethod>;
    private ready: Promise<void>;

    public constructor() {
        this.method = {
            value: "SSDMobileNetV2",
            version: 1,
        };
    }

    private async init() {
        this.ssdMobileNetV2Model = await SSDMobileNet.load({
            base: "mobilenet_v2",
            modelUrl: "/models/ssdmobilenet/model.json",
        });
        addLogLine("loaded ssdMobileNetV2Model", tf.getBackend());
    }

    private async getSSDMobileNetV2Model() {
        if (!this.ready) {
            this.ready = this.init();
        }
        await this.ready;
        return this.ssdMobileNetV2Model;
    }

    public async detectObjects(
        image: ImageBitmap,
        maxNumberBoxes: number,
        minScore: number,
    ): Promise<ObjectDetection[]> {
        const ssdMobileNetV2Model = await this.getSSDMobileNetV2Model();
        const resized = resizeToSquare(image, OBJECT_DETECTION_IMAGE_SIZE);
        const tfImage = tf.browser.fromPixels(resized.image);
        const detections = await ssdMobileNetV2Model.detect(
            tfImage,
            maxNumberBoxes,
            minScore,
        );
        tfImage.dispose();
        return detections;
    }

    public async dispose() {
        const ssdMobileNetV2Model = await this.getSSDMobileNetV2Model();
        ssdMobileNetV2Model?.dispose();
        this.ssdMobileNetV2Model = null;
    }
}

export default new SSDMobileNetV2();
