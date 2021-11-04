import React, { useEffect, useRef } from 'react';
import * as tf from '@tensorflow/tfjs';
import { FaceImage } from 'utils/machineLearning/types';

interface FaceImageProps {
    faceImage: FaceImage;
}

export default function TFJSImage(props: FaceImageProps) {
    const canvasRef = useRef(null);

    useEffect(() => {
        if (!props || !props.faceImage) {
            return;
        }
        const canvas = canvasRef.current;
        canvas.setAttribute('width', props.faceImage?.length);
        canvas.setAttribute('height', props.faceImage[0]?.length);
        const faceTensor = tf.tensor3d(props.faceImage);
        const normFaceImage = tf.div(tf.add(faceTensor, 1.0), 2);
        tf.browser.toPixels(normFaceImage as tf.Tensor3D, canvas);
    }, [props.faceImage]);

    return (
        <canvas
            ref={canvasRef}
            width={112}
            height={112}
            style={{ display: 'inline' }}
        />
    );
}
