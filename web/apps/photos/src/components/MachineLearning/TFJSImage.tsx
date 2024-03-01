import * as tf from "@tensorflow/tfjs-core";
import { useEffect, useRef } from "react";
import { FaceImage } from "types/machineLearning";

interface FaceImageProps {
    faceImage: FaceImage;
    width?: number;
    height?: number;
}

export default function TFJSImage(props: FaceImageProps) {
    const canvasRef = useRef(null);

    useEffect(() => {
        if (!props || !props.faceImage) {
            return;
        }
        const canvas = canvasRef.current;
        const faceTensor = tf.tensor3d(props.faceImage);
        const resized =
            props.width && props.height
                ? tf.image.resizeBilinear(faceTensor, [
                      props.width,
                      props.height,
                  ])
                : faceTensor;
        const normFaceImage = tf.div(tf.add(resized, 1.0), 2);
        tf.browser.toPixels(normFaceImage as tf.Tensor3D, canvas);
    }, [props]);

    return (
        <canvas
            ref={canvasRef}
            width={112}
            height={112}
            style={{ display: "inline" }}
        />
    );
}
