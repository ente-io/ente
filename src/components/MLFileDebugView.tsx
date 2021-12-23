import React, { useEffect, useState } from 'react';
import { DetectedFace } from 'types/machineLearning';
import { imageBitmapToBlob } from 'utils/image';

interface MLFileDebugViewProps {
    // mlFileData: MlFileData
    faces: Array<DetectedFace>;
    images: Array<ImageBitmap>;
}

export default function MLFileDebugView(props: MLFileDebugViewProps) {
    return (
        <div>
            {props.faces?.map((face, i) => (
                <MLFaceDebugView key={i} face={face}></MLFaceDebugView>
            ))}
            {props.images?.map((image, i) => (
                <MLImageBitmapView key={i} image={image}></MLImageBitmapView>
            ))}
        </div>
    );
}

function MLFaceDebugView(props: { face: DetectedFace }) {
    const [imgUrl, setImgUrl] = useState<string>();

    useEffect(() => {
        const face = props?.face;
        if (!face?.faceCrop?.image) {
            return;
        }
        // console.log('faceCrop: ', face.faceCrop);
        setImgUrl(URL.createObjectURL(face.faceCrop.image));
    }, [props.face]);

    return (
        <>
            <img src={imgUrl}></img>
        </>
    );
}

function MLImageBitmapView(props: { image: ImageBitmap }) {
    const [imgUrl, setImgUrl] = useState<string>();

    useEffect(() => {
        const image = props?.image;
        if (!image) {
            return;
        }
        // console.log('image: ', image);
        async function loadImage() {
            const blob = await imageBitmapToBlob(image);
            setImgUrl(URL.createObjectURL(blob));
        }

        loadImage();
    }, [props.image]);

    return (
        <>
            <img src={imgUrl}></img>
        </>
    );
}
